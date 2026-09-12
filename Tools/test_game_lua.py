"""Test the installed-game compiler and its mandatory release gate.

Run with 64-bit Windows Python and --game-lua-dll pointing to the installed
HavokScript_FinalRelease.dll. Test chunks are compiled, never executed.
"""
from __future__ import annotations

import argparse
import copy
from pathlib import Path
import subprocess
import sys
import unittest
from unittest.mock import patch

import build_release
from check_game_lua import GameLuaCompiler, check_sources

ROOT = Path(__file__).resolve().parents[1]


class GameCompilerTests(unittest.TestCase):
    runtime: Path

    @classmethod
    def setUpClass(cls):
        cls.compiler = GameLuaCompiler(cls.runtime)
        cls.report = check_sources(cls.runtime)
        cls.contents = {
            item["path"]: {"sha256": item["packaged_sha256"]}
            for item in cls.report["files"]
        }

    def test_all_release_scripts_compile(self):
        self.assertTrue(self.report["passed"])
        self.assertIn("Lua/AdaptiveStrategicAI.lua", self.contents)
        self.assertIn("UI/ASAI_Diagnostics.lua", self.contents)
        for item in self.report["files"]:
            for variant in ("installed", "packaged"):
                self.assertEqual(item[variant]["status"], 0)
                self.assertFalse(item[variant]["executed"])

    def test_no_gameplay_api_is_executed(self):
        result = self.compiler.compile(
            b'Game.GetCurrentGameTurn(); error("THIS_CHUNK_MUST_NOT_EXECUTE");',
            "compile-only",
        )
        self.assertEqual(result["status"], 0)
        self.assertFalse(result["executed"])

    def test_invalid_syntax_fails_with_source_name(self):
        result = self.compiler.compile(b"local =", "invalid-fixture")
        self.assertNotEqual(result["status"], 0)
        self.assertIn("invalid-fixture", result["error"])

    def test_register_pressure_and_isolated_initializer(self):
        # Reproduce the same compiler limit without embedding old mod source.
        # Both variants are valid standard Lua; only the scoped constructor
        # fits in HavokScript's crowded top-level register frame.
        prefix = "local " + ",".join(f"v{i}" for i in range(190)) + ";\n"
        array = "{" + ",".join(str(i) for i in range(17)) + "}"
        old = prefix + "local callbacks=" + array + "; return callbacks"
        fixed = (prefix + "local callbacks; (function() callbacks=" + array
                 + "; end)(); return callbacks")
        rejected = self.compiler.compile(old.encode(), "register-pressure")
        accepted = self.compiler.compile(fixed.encode(), "isolated-initializer")
        self.assertNotEqual(rejected["status"], 0)
        self.assertIn("too many registers", rejected["error"])
        self.assertEqual(accepted["status"], 0)

    def test_matching_compiler_evidence_is_accepted(self):
        build_release.require_compiled_lua(self.contents, self.report)

    def test_incomplete_or_failed_evidence_is_rejected(self):
        variants = []
        missing = copy.deepcopy(self.report)
        missing["files"].pop()
        variants.append(missing)
        duplicate = copy.deepcopy(self.report)
        duplicate["files"].append(copy.deepcopy(duplicate["files"][0]))
        variants.append(duplicate)
        wrong_hash = copy.deepcopy(self.report)
        wrong_hash["files"][0]["packaged_sha256"] = "0" * 64
        variants.append(wrong_hash)
        failed = copy.deepcopy(self.report)
        failed["files"][0]["packaged"]["status"] = -4
        variants.append(failed)
        executed = copy.deepcopy(self.report)
        executed["files"][0]["installed"]["executed"] = True
        variants.append(executed)
        wrong_mode = copy.deepcopy(self.report)
        wrong_mode["mode"] = "standard_lua"
        variants.append(wrong_mode)
        no_runtime = copy.deepcopy(self.report)
        no_runtime["compiler_sha256"] = ""
        variants.append(no_runtime)
        not_passed = copy.deepcopy(self.report)
        not_passed["passed"] = False
        variants.append(not_passed)
        for number, report in enumerate(variants):
            with self.subTest(variant=number), self.assertRaises(ValueError):
                build_release.require_compiled_lua(self.contents, report)

    def test_changed_packaged_source_is_rejected(self):
        changed = copy.deepcopy(self.contents)
        changed["Lua/AdaptiveStrategicAI.lua"]["sha256"] = "f" * 64
        with self.assertRaises(ValueError):
            build_release.require_compiled_lua(changed, self.report)

    def test_extra_uncompiled_lua_is_rejected(self):
        changed = copy.deepcopy(self.contents)
        changed["Lua/unvalidated.lua"] = {"sha256": "f" * 64}
        with self.assertRaises(ValueError):
            build_release.require_compiled_lua(changed, self.report)

    def test_empty_compilation_is_rejected(self):
        report = copy.deepcopy(self.report)
        report["files"] = []
        with self.assertRaises(ValueError):
            build_release.require_compiled_lua({}, report)

    def test_runtime_argument_is_mandatory(self):
        result = subprocess.run(
            [sys.executable, "Tools/build_release.py", "--check"], cwd=ROOT,
            capture_output=True, text=True, timeout=10,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("--game-lua-dll", result.stderr)
        self.assertNotIn("PACKAGE CHECK PASSED", result.stdout)

    def test_failed_compiler_stops_before_other_validation_or_packaging(self):
        arguments = ["build_release.py", "--check", "--game-lua-dll", str(self.runtime)]
        with patch.object(sys, "argv", arguments), \
                patch.object(build_release, "check_game_compiler", side_effect=ValueError("failed")), \
                patch.object(build_release.subprocess, "run") as other_validation, \
                patch.object(build_release, "create_archive") as archive:
            with self.assertRaises(ValueError):
                build_release.main()
            other_validation.assert_not_called()
            archive.assert_not_called()

    def test_compiler_timeout_does_not_fall_back(self):
        with patch.object(build_release.subprocess, "run",
                          side_effect=subprocess.TimeoutExpired("game-compiler", 60)):
            with self.assertRaises(subprocess.TimeoutExpired):
                build_release.check_game_compiler(self.runtime)

    def test_failed_worker_exit_is_rejected(self):
        failed = subprocess.CompletedProcess("game-compiler", 1, '{"passed": false}', "syntax error")
        with patch.object(build_release.subprocess, "run", return_value=failed):
            with self.assertRaisesRegex(ValueError, "syntax error"):
                build_release.check_game_compiler(self.runtime)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--game-lua-dll", type=Path, required=True)
    args = parser.parse_args()
    GameCompilerTests.runtime = args.game_lua_dll.resolve(strict=True)
    suite = unittest.defaultTestLoader.loadTestsFromTestCase(GameCompilerTests)
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    return 0 if result.wasSuccessful() else 1


if __name__ == "__main__":
    raise SystemExit(main())
