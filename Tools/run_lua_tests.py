"""Run behavioral regression tests with a local Lua 5.3/5.4 runtime.

Accepts either a Lua executable or, on Windows, an existing compatible Lua DLL.
Does not install/configure a runtime or modify the Civilization VI cache.
"""
from __future__ import annotations

import argparse
import ctypes
import os
from pathlib import Path
import shutil
import subprocess


def run_dll(library_path: Path, script: str) -> int:
    directory = os.add_dll_directory(str(library_path.parent)) if os.name == "nt" else None
    try:
        lua = ctypes.CDLL(str(library_path))
        lua.luaL_newstate.restype = ctypes.c_void_p
        lua.luaL_openlibs.argtypes = (ctypes.c_void_p,)
        lua.luaL_loadfilex.argtypes = (ctypes.c_void_p, ctypes.c_char_p, ctypes.c_char_p)
        lua.luaL_loadfilex.restype = ctypes.c_int
        lua.lua_pcallk.argtypes = (ctypes.c_void_p, ctypes.c_int, ctypes.c_int,
                                  ctypes.c_int, ctypes.c_ssize_t, ctypes.c_void_p)
        lua.lua_pcallk.restype = ctypes.c_int
        lua.lua_tolstring.argtypes = (ctypes.c_void_p, ctypes.c_int,
                                     ctypes.POINTER(ctypes.c_size_t))
        lua.lua_tolstring.restype = ctypes.c_char_p
        lua.lua_close.argtypes = (ctypes.c_void_p,)
        state = lua.luaL_newstate()
        if not state:
            raise RuntimeError("Lua state allocation failed")
        try:
            lua.luaL_openlibs(state)
            status = lua.luaL_loadfilex(state, script.encode("utf-8"), b"t")
            if status == 0:
                status = lua.lua_pcallk(state, 0, 0, 0, 0, None)
            if status:
                message = lua.lua_tolstring(state, -1, None)
                print(message.decode("utf-8", errors="replace") if message else "Lua error")
            return int(status != 0)
        finally:
            lua.lua_close(state)
    finally:
        if directory is not None:
            directory.close()


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--lua", help="Lua 5.3/5.4 executable")
    group.add_argument("--lua-dll", type=Path, help="Existing compatible Lua shared library")
    args = parser.parse_args()
    root = Path(__file__).resolve().parents[1]
    script = "Tools/test_execution.lua"
    if args.lua_dll:
        library = args.lua_dll.resolve(strict=True)
        previous = Path.cwd()
        try:
            os.chdir(root)
            return run_dll(library, script)
        finally:
            os.chdir(previous)
    executable = args.lua or shutil.which("lua5.3") or shutil.which("lua53") or shutil.which("lua")
    if not executable:
        parser.error("Lua runtime not found; supply --lua or --lua-dll. Nothing was installed.")
    return subprocess.run([executable, script], cwd=root, check=False).returncode


if __name__ == "__main__":
    raise SystemExit(main())
