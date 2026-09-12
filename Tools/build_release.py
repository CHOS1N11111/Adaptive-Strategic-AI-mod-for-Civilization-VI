"""Build a verified, allowlisted release-candidate ZIP. Does not upload or push.

Example:
    python Tools/build_release.py --lua lua5.3 --game-lua-dll PATH_TO_GAME_HAVOK_DLL
    python Tools/build_release.py --lua-dll PATH_TO_LUA53_DLL --game-lua-dll PATH_TO_GAME_HAVOK_DLL

The reference gameplay database is opened read-only by validate_mod.py.
Internal docs, saved games, logs, tools, caches and Git data are never packaged.
The installed game's compiler is mandatory, including for --check. A missing,
failed or timed-out compiler check cannot fall back to standard Lua.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import subprocess
import sys
import xml.etree.ElementTree as ET
import zipfile

from validate_mod import EXPECTED_RELEASE, database_files, declared_files

ROOT = Path(__file__).resolve().parents[1]
EXTRAS = ("README.md", "README.zh-CN.md", "LICENSE", "CHANGELOG.md",
          "assets/cover.jpg", "assets/cover-workshop.jpg")
RELEASE = f"v{EXPECTED_RELEASE}-rc.1"


def package_files(root: Path = ROOT) -> list[Path]:
    root = root.resolve(strict=True)
    modinfo = root / "AdaptiveStrategicAI.modinfo"
    files = {modinfo, *declared_files(modinfo), *database_files(modinfo),
             *(root / name for name in EXTRAS)}
    for path in files:
        resolved = path.resolve(strict=True)
        if not resolved.is_relative_to(root) or path.is_symlink() or not path.is_file():
            raise ValueError(f"unsafe or missing package file: {path.name}")
        relative = path.relative_to(root).as_posix()
        if any(part.startswith(".") or part in {"Tools", "docs", "Saves", "Logs"}
               for part in PurePosixPath(relative).parts):
            raise ValueError(f"private/development file in package: {relative}")
    cover = root / "assets" / "cover-workshop.jpg"
    if not 0 < cover.stat().st_size < 1_000_000:
        raise ValueError("Workshop cover must remain under 1,000,000 bytes")
    return sorted(files, key=lambda path: path.relative_to(root).as_posix())


def create_archive(files: list[Path], root: Path = ROOT) -> tuple[bytes, dict[str, dict]]:
    payload = io.BytesIO()
    manifest: dict[str, dict] = {}
    with zipfile.ZipFile(payload, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for path in files:
            name = path.relative_to(root).as_posix()
            raw = path.read_bytes()
            if path.suffix.lower() in {".sql", ".lua", ".xml", ".modinfo", ".md"} or path.name == "LICENSE":
                raw = raw.replace(b"\r\n", b"\n")
            # Fixed timestamps and permissions make unchanged payloads reproducible.
            entry = zipfile.ZipInfo("AdaptiveStrategicAI/" + name, (1980, 1, 1, 0, 0, 0))
            entry.create_system = 3
            entry.compress_type = zipfile.ZIP_DEFLATED
            entry.external_attr = 0o100644 << 16
            archive.writestr(entry, raw, compresslevel=9)
            manifest[name] = {"bytes": len(raw), "sha256": hashlib.sha256(raw).hexdigest()}
    blob = payload.getvalue()
    with zipfile.ZipFile(io.BytesIO(blob)) as archive:
        if archive.testzip() is not None or len(archive.namelist()) != len(manifest):
            raise ValueError("ZIP readback failed")
        for name, expected in manifest.items():
            raw = archive.read("AdaptiveStrategicAI/" + name)
            if hashlib.sha256(raw).hexdigest() != expected["sha256"]:
                raise ValueError(f"ZIP content differs: {name}")
        modinfo = ET.fromstring(archive.read("AdaptiveStrategicAI/AdaptiveStrategicAI.modinfo"))
        for node in modinfo.findall(".//File"):
            if node.text and node.text not in manifest:
                raise ValueError(f"packaged modinfo references a missing file: {node.text}")
    return blob, manifest


def git(*args: str) -> str:
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def check_game_compiler(runtime: Path) -> dict:
    command = [sys.executable, "Tools/check_game_lua.py",
               "--game-lua-dll", str(runtime.resolve(strict=True))]
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True,
                            encoding="utf-8", errors="replace", timeout=60)
    if result.returncode:
        raise ValueError("game Lua compiler check failed:\n" + (result.stderr or result.stdout))
    report = json.loads(result.stdout)
    if report.get("passed") is not True:
        raise ValueError("game Lua compiler did not report success")
    return report


def require_compiled_lua(contents: dict[str, dict], report: dict) -> None:
    """Bind successful game compilation to the exact Lua bytes going into ZIP."""
    expected = {name: item["sha256"] for name, item in contents.items() if name.endswith(".lua")}
    results = report.get("files", [])
    observed = {item["path"]: item["packaged_sha256"] for item in results}
    if (not expected or len(results) != len(observed) or observed != expected or
            report.get("passed") is not True or
            report.get("mode") != "compile_only_no_lua_execution" or
            not report.get("compiler_sha256")):
        raise ValueError("game compiler evidence does not match all packaged Lua sources")
    for item in results:
        for variant in ("installed", "packaged"):
            if item[variant]["status"] != 0 or item[variant]["executed"] is not False:
                raise ValueError(f"missing compile-only success for {item['path']} ({variant})")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    runtime = parser.add_mutually_exclusive_group()
    runtime.add_argument("--lua")
    runtime.add_argument("--lua-dll", type=Path)
    parser.add_argument("--game-lua-dll", type=Path, required=True,
                        help="Installed game's Win64Steam/HavokScript_FinalRelease.dll")
    parser.add_argument("--db", type=Path, help="Read-only reference gameplay database")
    parser.add_argument("--check", action="store_true", help="Validate and inspect ZIP in memory; do not write files")
    args = parser.parse_args()
    compiler = check_game_compiler(args.game_lua_dll)
    print(f"GAME LUA COMPILE PASSED: {len(compiler['files'])} release scripts; "
          "installed and packaged bytes; no Lua execution", flush=True)
    sql = [sys.executable, "Tools/validate_mod.py"]
    if args.db:
        sql.extend(["--db", str(args.db.resolve(strict=True))])
    lua = [sys.executable, "Tools/run_lua_tests.py"]
    if args.lua:
        lua.extend(["--lua", args.lua])
    elif args.lua_dll:
        lua.extend(["--lua-dll", str(args.lua_dll.resolve(strict=True))])
    for command in (sql, lua):
        subprocess.run(command, cwd=ROOT, check=True)
    files = package_files()
    blob, contents = create_archive(files)
    # Verify deterministic packing and that no source file changed during it.
    repeated, repeated_contents = create_archive(files)
    if repeated != blob or repeated_contents != contents:
        raise ValueError("release source changed while building")
    require_compiled_lua(contents, compiler)
    print(f"PACKAGE CHECK PASSED: {len(files)} allowlisted files; {len(blob):,} bytes; deterministic ZIP")
    if args.check:
        print("No release files written. Native game acceptance is not implied.")
        return 0
    if git("status", "--porcelain", "--untracked-files=normal"):
        raise ValueError("commit reviewed source changes before building a release candidate")
    revision = git("rev-parse", "HEAD")
    for path in files:
        relative = path.relative_to(ROOT).as_posix()
        subprocess.run(["git", "ls-files", "--error-unmatch", "--", relative],
                       cwd=ROOT, check=True, stdout=subprocess.DEVNULL)
    digest = hashlib.sha256(blob).hexdigest()
    directory = ROOT / "docs" / "releases" / RELEASE
    directory.mkdir(parents=True, exist_ok=True)
    archive_path = directory / f"AdaptiveStrategicAI-{RELEASE}.zip"
    manifest = {
        "release": RELEASE, "gameplay_version": EXPECTED_RELEASE, "source_commit": revision,
        "text_line_endings": "LF",
        "archive": archive_path.name, "archive_bytes": len(blob), "archive_sha256": digest,
        "validation": {
            "sql_and_lua": "passed",
            "game_lua_compile": {
                "status": "passed", "mode": compiler["mode"],
                "compiler": compiler["compiler"],
                "compiler_sha256": compiler["compiler_sha256"],
                "packaged_lua": {item["path"]: item["packaged_sha256"]
                                 for item in compiler["files"]},
            },
            "zip_allowlist_and_readback": "passed",
            "native_game_acceptance": "pending",
            "publication": "not_uploaded",
        },
        "files": contents,
    }
    outputs = {
        archive_path: blob,
        directory / "manifest.json": (json.dumps(manifest, ensure_ascii=False, indent=2) + "\n").encode("utf-8"),
        directory / "SHA256SUMS.txt": f"{digest}  {archive_path.name}\n".encode("utf-8"),
    }
    # Never overwrite a different previously prepared artifact.
    for path, content in outputs.items():
        if path.exists() and path.read_bytes() != content:
            raise ValueError(f"existing release artifact differs; review it before replacement: {path}")
    if revision != git("rev-parse", "HEAD") or git("status", "--porcelain", "--untracked-files=normal"):
        raise ValueError("source changed before release artifacts were written")
    for path, content in outputs.items():
        if not path.exists():
            with path.open("xb") as handle:
                handle.write(content)
    print(f"PREPARED, NOT PUBLISHED: {archive_path}")
    print(f"SHA256: {digest}")
    print("Native acceptance remains pending; no upload, tag or push was performed.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, KeyError, subprocess.CalledProcessError,
            subprocess.TimeoutExpired) as error:
        print(f"RELEASE BUILD FAILED: {error}", file=sys.stderr)
        raise SystemExit(1)
