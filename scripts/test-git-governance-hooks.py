#!/usr/bin/env python3
"""Exercise the Git Stop adapter and Skill checker in disposable repositories."""

from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest


REPO = Path(__file__).resolve().parents[1]
SOURCE_HOOK = REPO / "plugins/AiCoding/hooks/git_governance_stop.py"
SOURCE_CHECKER = REPO / "platform/aicoding-git-governance/scripts/check_stop.py"
PLUGIN_UNDER_TEST: Path | None = None
POWERSHELL = shutil.which("pwsh") or shutil.which("powershell")


@unittest.skipUnless(shutil.which("git"), "Git is required for real event fixtures")
class GitStopTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="git-stop-test-")
        self.addCleanup(self.temp.cleanup)
        self.base = Path(self.temp.name)
        self.root = self.base / "project 中文"
        self.root.mkdir()
        self.git("init", "-q")
        if PLUGIN_UNDER_TEST is None:
            self.plugin = self.base / "plugin 中文 root"
            hook = self.plugin / "hooks/git_governance_stop.py"
            checker = self.plugin / "skills/aicoding-git-governance/scripts/check_stop.py"
            hook.parent.mkdir(parents=True)
            checker.parent.mkdir(parents=True)
            shutil.copyfile(SOURCE_HOOK, hook)
            shutil.copyfile(SOURCE_CHECKER, checker)
        else:
            self.plugin = PLUGIN_UNDER_TEST.resolve()
        self.hook = self.plugin / "hooks/git_governance_stop.py"
        self.env = dict(os.environ, PLUGIN_ROOT=str(self.plugin), PYTHONDONTWRITEBYTECODE="1", GIT_OPTIONAL_LOCKS="0")

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, capture_output=True, check=True,
                              text=True, encoding="utf-8", timeout=10)

    def write(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text, encoding="utf-8")

    def policy(self, body='enabled = true\nmode = "unreleased"\nfile = "CHANGELOG.md"\nrequire_typed_entries = true\n'):
        self.write(".github/repository-governance.toml", "[changelog]\n" + body)

    def invoke(self, payload=None, *, env=None, raw=None, hook=None, cwd=None):
        if raw is None:
            raw = json.dumps(payload if payload is not None else {"cwd": str(self.root), "stop_hook_active": False})
        result = subprocess.run([sys.executable, "-B", "-X", "utf8", str(hook or self.hook)],
                                input=raw, cwd=cwd or self.root, env=env or self.env,
                                capture_output=True, text=True, encoding="utf-8", timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)

    def assert_passes(self, **kwargs):
        result = self.invoke(**kwargs)
        self.assertTrue(result.get("continue"), result)
        self.assertNotIn("decision", result)

    def assert_blocked(self, token, **kwargs):
        result = self.invoke(**kwargs)
        self.assertEqual(result.get("decision"), "block", result)
        self.assertIn(token, result["reason"])

    def test_scoped_types_match_repository_lint_syntax(self):
        self.policy()
        for kind in ("feat", "fix", "docs", "style", "refactor", "perf", "test", "build", "ci", "chore"):
            with self.subTest(kind=kind):
                self.write("CHANGELOG.md", f"# Change log\n\n## [Unreleased]\n\n- **{kind}(recorder)**: 效果说明。\n")
                self.assert_passes()

    def test_plain_type_is_accepted(self):
        self.policy()
        self.write("CHANGELOG.md", "## [Unreleased]\n- **docs**: usage\n")
        self.assert_passes()

    def test_missing_type_is_rejected(self):
        self.policy()
        self.write("CHANGELOG.md", "## [Unreleased]\n- untyped entry\n")
        self.assert_blocked("typed entries")

    def test_missing_unreleased_is_rejected_for_unreleased_profile(self):
        self.policy()
        self.write("CHANGELOG.md", "## 2026-10-28\n- **fix**: effect\n")
        self.assert_blocked("[Unreleased]")

    def test_dated_profile_does_not_require_unreleased(self):
        self.policy('mode = "dated"\n')
        self.write("CHANGELOG.md", "## 2026-10-28\n- **fix(hook)**: effect\n")
        self.assert_passes()

    def test_custom_changelog_path_and_unicode_are_supported(self):
        self.policy('mode = "unreleased"\nfile = "docs/变更 记录.md"\n')
        self.write("docs/变更 记录.md", "## [Unreleased]\n- **refactor(recorder)**: effect\n")
        self.assert_passes()

    def test_disabled_changelog_has_no_file_requirement(self):
        self.policy("enabled = false\n")
        self.assert_passes()

    def test_typed_entries_can_be_disabled_by_profile(self):
        self.policy('mode = "dated"\nrequire_typed_entries = false\n')
        self.write("CHANGELOG.md", "## 2026-10-28\n- entry\n")
        self.assert_passes()

    def test_release_and_aggregation_profiles_do_not_require_live_main_file(self):
        for mode in ("fragments", "release-only", "generated"):
            with self.subTest(mode=mode):
                self.policy(f'mode = "{mode}"\n')
                self.assert_passes()

    def test_malformed_toml_fails_explicitly(self):
        self.write(".github/repository-governance.toml", "[changelog\n")
        self.assert_blocked("Stop check failed")

    def test_invalid_profile_value_is_rejected(self):
        self.policy('mode = "typo"\n')
        self.assert_blocked("unsupported changelog.mode")

    def test_invalid_boolean_is_rejected(self):
        self.policy('enabled = "false"\n')
        self.assert_blocked("must be booleans")

    def test_configured_path_cannot_escape_repository(self):
        self.policy('file = "../outside.md"\n')
        self.assert_blocked("escapes the repository")

    def test_missing_configured_changelog_is_rejected(self):
        self.policy('file = "docs/CHANGES.md"\n')
        self.assert_blocked("docs/CHANGES.md")

    def test_dirty_unreleased_repository_requires_changelog_update(self):
        self.policy()
        self.write("CHANGELOG.md", "## [Unreleased]\n- **fix**: baseline\n")
        self.git("add", "--", ".github/repository-governance.toml", "CHANGELOG.md")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture")
        self.write("main.c", "int changed;\n")
        self.assert_blocked("CHANGELOG.md was not updated")

    def test_clean_unreleased_repository_is_accepted(self):
        self.policy()
        self.write("CHANGELOG.md", "## [Unreleased]\n- **fix**: baseline\n")
        self.git("add", "--", ".github/repository-governance.toml", "CHANGELOG.md")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture")
        self.assert_passes()

    def test_unmanaged_repository_is_not_governed_by_changelog_presence(self):
        self.write("CHANGELOG.md", "# Unmanaged changelog\n")
        self.assert_passes()

    def test_continuation_does_not_require_or_reload_checker(self):
        env = dict(self.env, PLUGIN_ROOT=str(self.base / "absent plugin"))
        self.assert_passes(payload={"stop_hook_active": True}, env=env)

    def test_missing_skill_checker_is_not_reported_as_pass(self):
        env = dict(self.env, PLUGIN_ROOT=str(self.base / "absent plugin"))
        self.assert_blocked("Stop hook failed", env=env)

    def test_malformed_event_is_not_reported_as_pass(self):
        self.assert_blocked("Stop hook failed", raw="{")
        self.assert_blocked("JSON object", raw="[]")

    def test_non_repository_directory_is_accepted(self):
        outside = self.base / "non-repository"
        outside.mkdir()
        self.assert_passes(payload={"cwd": str(outside)})

    def test_hook_does_not_modify_business_files(self):
        self.policy()
        self.write("CHANGELOG.md", "## [Unreleased]\n- **refactor(recorder)**: effect\n")
        before = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob("*")
                  if p.is_file() and ".git" not in p.relative_to(self.root).parts}
        self.assert_passes()
        after = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob("*")
                 if p.is_file() and ".git" not in p.relative_to(self.root).parts}
        self.assertEqual(before, after)

    @unittest.skipUnless(POWERSHELL, "PowerShell is required for repository lint integration")
    def test_repository_lint_is_authoritative_without_duplicate_changelog_rules(self):
        # This profile deliberately delegates a nonstandard changelog to local lint.
        self.write(".github/repository-governance.toml", "deliberately not TOML\n")
        self.write("scripts/lint-git-governance.ps1", 'param([string]$Mode)\nif ($Mode -ne "all") { exit 9 }\nWrite-Output "local profile accepted"\nexit 0\n')
        self.assert_passes()

    @unittest.skipUnless(POWERSHELL, "PowerShell is required for repository lint integration")
    def test_repository_lint_failure_is_preserved(self):
        self.write("scripts/lint-git-governance.ps1", 'param([string]$Mode)\nWrite-Output "fixture policy rejected"\n[Console]::Error.WriteLine("fixture stderr detail")\nexit 7\n')
        result = self.invoke()
        self.assertEqual(result.get("decision"), "block", result)
        self.assertIn("fixture policy rejected", result["reason"])
        self.assertIn("fixture stderr detail", result["reason"])

    @unittest.skipUnless(POWERSHELL, "PowerShell is required for timeout integration")
    def test_repository_lint_timeout_is_not_a_pass(self):
        self.write("scripts/lint-git-governance.ps1", "Start-Sleep -Seconds 12\n")
        self.assert_blocked("timed out")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--plugin-path", type=Path, help="test a built plugin instead of source resources")
    args, remaining = parser.parse_known_args()
    PLUGIN_UNDER_TEST = args.plugin_path
    unittest.main(argv=[sys.argv[0], *remaining], verbosity=2)
