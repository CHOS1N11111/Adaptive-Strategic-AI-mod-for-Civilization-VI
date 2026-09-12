"""Compile release Lua using the installed Windows game's HavokScript runtime.

Requires a 64-bit Windows Python and --game-lua-dll pointing to the installed
Base/Binaries/Win64Steam/HavokScript_FinalRelease.dll. Nothing is downloaded,
copied, patched or executed in the game. Compiled Lua chunks are NEVER executed.
Standard Lua behavioral tests remain a separate requirement.
"""
from __future__ import annotations

import argparse
import ctypes
import hashlib
import json
import os
from pathlib import Path
import sys

from validate_mod import declared_files

ROOT = Path(__file__).resolve().parents[1]


class GameLuaCompiler:
    """Thin compile-only binding to the shipped x64 HavokScript exports."""

    def __init__(self, runtime: Path):
        if os.name != "nt" or ctypes.sizeof(ctypes.c_void_p) != 8:
            raise RuntimeError("Game compiler validation requires 64-bit Windows Python.")
        self.path = runtime.resolve(strict=True)
        if self.path.name.lower() != "havokscript_finalrelease.dll":
            raise ValueError("Use the installed game's HavokScript_FinalRelease.dll, not standard Lua.")
        self.sha256 = hashlib.sha256(self.path.read_bytes()).hexdigest()
        with os.add_dll_directory(str(self.path.parent)):
            self.library = ctypes.CDLL(str(self.path))
        self.newstate = getattr(self.library, "?luaL_newstate@@YAPEAUlua_State@@XZ")
        self.newstate.argtypes = ()
        self.newstate.restype = ctypes.c_void_p
        self.load = getattr(self.library, "?luaL_loadbuffer@@YAHPEAUlua_State@@PEBD_K1@Z")
        self.load.argtypes = (ctypes.c_void_p, ctypes.c_char_p, ctypes.c_size_t, ctypes.c_char_p)
        self.load.restype = ctypes.c_int
        self.message = getattr(self.library, "?lua_tolstring@@YAPEBDPEAUlua_State@@HPEA_K@Z")
        self.message.argtypes = (ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t))
        self.message.restype = ctypes.c_void_p
        self.close = getattr(self.library, "?lua_close@@YAXPEAUlua_State@@@Z")
        self.close.argtypes = (ctypes.c_void_p,)
        self.close.restype = None

    def compile(self, source: bytes, name: str) -> dict:
        state = self.newstate()
        if not state:
            raise RuntimeError("The game compiler could not allocate a Lua state.")
        try:
            status = self.load(state, source, len(source), ("@" + name).encode("utf-8"))
            error = None
            if status:
                length = ctypes.c_size_t()
                pointer = self.message(state, -1, ctypes.byref(length))
                error = (ctypes.string_at(pointer, length.value).decode("utf-8", errors="replace")
                         if pointer else "Game compiler failed without an error string.")
            return {"status": status, "error": error, "executed": False}
        finally:
            self.close(state)


def lua_files(root: Path = ROOT) -> list[Path]:
    root = root.resolve(strict=True)
    files = sorted({path for path in declared_files(root / "AdaptiveStrategicAI.modinfo")
                    if path.suffix.lower() == ".lua"})
    if not files:
        raise ValueError("No declared release Lua files; refusing an empty compiler check.")
    for path in files:
        if path.is_symlink() or not path.resolve(strict=True).is_relative_to(root) or not path.is_file():
            raise ValueError(f"Unsafe or missing declared Lua source: {path}")
    return files


def check_sources(runtime: Path, root: Path = ROOT) -> dict:
    root = root.resolve(strict=True)
    files = lua_files(root)
    originals = {path: path.read_bytes() for path in files}
    compiler = GameLuaCompiler(runtime)
    results = []
    for path, original in originals.items():
        name = path.relative_to(root).as_posix()
        packaged = original.replace(b"\r\n", b"\n")
        # Check both installed bytes and the exact LF normalization used by
        # build_release.py. Do not silently accept only one representation.
        installed_result = compiler.compile(original, name)
        packaged_result = compiler.compile(packaged, name + " [packaged LF]")
        results.append({
            "path": name,
            "source_sha256": hashlib.sha256(original).hexdigest(),
            "packaged_sha256": hashlib.sha256(packaged).hexdigest(),
            "installed": installed_result, "packaged": packaged_result,
        })
    if any(path.read_bytes() != original for path, original in originals.items()):
        raise ValueError("Lua source changed during game compiler validation.")
    if hashlib.sha256(compiler.path.read_bytes()).hexdigest() != compiler.sha256:
        raise ValueError("Game runtime changed during compiler validation.")
    return {
        "compiler": compiler.path.name, "compiler_sha256": compiler.sha256,
        "mode": "compile_only_no_lua_execution",
        "passed": all(item[variant]["status"] == 0
                      for item in results for variant in ("installed", "packaged")),
        "files": results,
        "native_game_acceptance": "not_tested",
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-lua-dll", type=Path, required=True)
    args = parser.parse_args()
    result = check_sources(args.game_lua_dll)
    # JSON stdout lets the packager bind validation to the exact source/runtime
    # hashes without creating intermediate files or claiming gameplay success.
    print(json.dumps(result, ensure_ascii=True, indent=2))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, RuntimeError, AttributeError) as error:
        print(f"GAME LUA COMPILE CHECK FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
