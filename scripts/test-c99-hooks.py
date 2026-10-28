#!/usr/bin/env python3
"""Exercise hook decisions in disposable Git repositories, never business files."""

from __future__ import annotations

import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import time
from types import SimpleNamespace
import unittest
from unittest import mock

REPO = Path(__file__).resolve().parents[1]
PLUGIN = REPO / "plugins/AiCoding"
HOOK = PLUGIN / "hooks/c99_guard.py"
SPEC = importlib.util.spec_from_file_location("c99_guard", HOOK)
GUARD = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GUARD)
CHECK_CODE = ("import pathlib,sys; "
              "bad=any('BAD' in pathlib.Path(p).read_text(encoding='utf-8') "
              "for p in sys.argv[1:] if pathlib.Path(p).is_file()); "
              "print('fixture: BAD token' if bad else 'fixture passed'); sys.exit(1 if bad else 0)")


@unittest.skipUnless(shutil.which("git"), "Git is required for real baseline fixtures")
class GuardTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="c99-guard-test-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "project 中文"
        self.root.mkdir()
        self.data = Path(self.temp.name) / "plugin-data"
        self.env = dict(os.environ, PLUGIN_ROOT=str(PLUGIN), PLUGIN_DATA=str(self.data))
        self.git("init", "-q")
        self.write("main.c", "int value = 0;\n")
        self.write("README.md", "# Fixture\n")
        self.git("add", "--", "main.c", "README.md")
        self.git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "-qm", "fixture")

    def git(self, *args):
        return subprocess.run(["git", *args], cwd=self.root, check=True,
                              stdout=subprocess.PIPE, stderr=subprocess.PIPE)

    def write(self, path, content):
        target = self.root / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8", newline="\n")

    def policy(self, checks=None, **options):
        value = {"schemaVersion": 1,
                 "checks": checks or [{"id": "fixture", "argv": [sys.executable, "-c", CHECK_CODE, "{files}"]}]}
        value.update(options)
        self.write(".c99-policy.json", json.dumps(value, ensure_ascii=False))
        return value

    def event(self, event, path="main.c", tool="apply_patch", session="session-1", turn="turn-1", active=False):
        command = f"*** Begin Patch\n*** Update File: {path}\n@@\n-old\n+new\n*** End Patch" if tool == "apply_patch" else "python generator.py"
        return {"hook_event_name": event, "cwd": str(self.root), "session_id": session,
                "turn_id": turn, "tool_name": tool, "tool_input": {"command": command},
                "stop_hook_active": active}

    def invoke(self, payload, env=None):
        result = subprocess.run([sys.executable, str(HOOK)], input=json.dumps(payload, ensure_ascii=False),
                                text=True, encoding="utf-8", cwd=self.root, env=env or self.env,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=25)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, "")
        return json.loads(result.stdout)

    def state(self, session="session-1", turn="turn-1"):
        session_key = __import__("hashlib").sha256(session.encode()).hexdigest()[:24]
        key = __import__("hashlib").sha256(turn.encode()).hexdigest()[:24] + ".json"
        paths = list(self.data.glob("c99_guard/*/" + session_key + "/" + key))
        self.assertEqual(len(paths), 1)
        return json.loads(paths[0].read_text(encoding="utf-8"))

    def begin(self, **kwargs):
        return self.invoke(self.event("PreToolUse", **kwargs))

    def finish(self, **kwargs):
        return self.invoke(self.event("PostToolUse", **kwargs))

    def test_non_c_without_profile_skips(self):
        self.assertEqual(self.begin(path="README.md"), {})
        self.write("README.md", "# Changed\n")
        self.assertEqual(self.finish(path="README.md"), {})
        self.assertEqual(self.invoke(self.event("Stop")), {})

    def test_without_profile_only_reminds_c_patch(self):
        result = self.begin()
        self.assertIn("自动阻塞检查未启用", result["hookSpecificOutput"]["additionalContext"])
        self.assertIn("functions", result["hookSpecificOutput"]["additionalContext"])
        self.assertNotIn("permissionDecision", result["hookSpecificOutput"])
        self.assertEqual(self.finish(), {})

    def test_profile_non_c_edit_is_not_checked(self):
        self.policy()
        self.begin(path="README.md")
        self.write("README.md", "# Changed\n")
        self.assertEqual(self.finish(path="README.md"), {})
        self.assertTrue(self.state()["lastResult"]["ok"])
        self.assertEqual(self.state()["lastResult"]["files"], [])

    def test_utf8_space_rename_new_and_deleted_paths(self):
        self.write("源 文件.c", "int source = 0;\n")
        self.git("add", "--", "源 文件.c")
        self.policy()
        payload = self.event("PreToolUse")
        payload["tool_input"]["command"] = "*** Begin Patch\n*** Update File: 源 文件.c\n*** Move to: 目录 空格/新 文件.c\n*** Add File: 新增.h\n*** End Patch"
        self.invoke(payload)
        (self.root / "源 文件.c").unlink()
        self.write("目录 空格/新 文件.c", "int moved = 1;\n")
        self.write("新增.h", "#define VALUE 1\n")
        self.assertIn("文件 lint 不覆盖删除", self.finish()["systemMessage"])
        self.assertEqual(self.state()["lastResult"]["files"], ["新增.h", "源 文件.c", "目录 空格/新 文件.c"])
        self.assertEqual(self.state()["lastResult"]["checkedFiles"], ["新增.h", "目录 空格/新 文件.c"])

    def test_deletions_skip_file_checker_but_run_global_checker(self):
        self.policy(checks=[
            {"id": "file-only", "argv": ["missing-file-checker-fixture", "{files}"]},
            {"id": "global", "argv": [sys.executable, "-c", "print('global ran')"]}])
        payload = self.event("PreToolUse")
        payload["tool_input"]["command"] = "*** Begin Patch\n*** Delete File: main.c\n*** End Patch"
        self.invoke(payload)
        (self.root / "main.c").unlink()
        result = self.finish()
        self.assertIn("CI/构建复核", result["systemMessage"])
        checks = self.state()["lastResult"]["checks"]
        self.assertTrue(checks[0]["skipped"])
        self.assertEqual(checks[1]["exitCode"], 0)
        self.assertIn("global ran", checks[1]["reason"])

    def test_existing_unchanged_dirty_file_is_not_checked(self):
        self.write("main.c", "BAD preexisting edit\n")
        self.write("owned.c", "int owned = 0;\n")
        self.policy()
        self.begin(path="owned.c")
        self.write("owned.c", "int owned = 1;\n")
        self.assertEqual(self.finish(), {})
        self.assertEqual(self.state()["lastResult"]["files"], ["owned.c"])

    def test_opaque_shell_write_is_detected_afterward(self):
        self.policy()
        self.begin(tool="Bash")
        self.write("generated_name.c", "BAD new shell file\n")
        result = self.finish(tool="Bash")
        self.assertEqual(result["decision"], "block")
        self.assertIn("fixture", result["reason"])
        self.assertIn("不撤销修改", result["hookSpecificOutput"]["additionalContext"])

    def test_protected_patch_denied_before_write(self):
        self.policy(protected=["vendor/**"], exclude=["vendor/**"])
        result = self.begin(path="vendor/registers.h")
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertFalse((self.root / "vendor/registers.h").exists())

    def test_protected_shell_edit_reported_after_write(self):
        self.write("vendor/registers.h", "int original;\n")
        self.policy(protected=["vendor/**"], exclude=["vendor/**"])
        self.begin(tool="Bash")
        self.write("vendor/registers.h", "int changed;\n")
        result = self.finish(tool="Bash")
        self.assertEqual(result["decision"], "block")
        self.assertIn("保护路径已发生变化", result["reason"])

    def symlink(self, target, link, directory=False):
        try:
            link.symlink_to(target, target_is_directory=directory)
        except OSError as exc:
            if directory and os.name == "nt":
                result = subprocess.run(["cmd", "/d", "/c", "mklink", "/J", str(link), str(target)], capture_output=True)
                if result.returncode == 0:
                    return
            self.skipTest(f"System does not permit fixture symlinks: {exc}")

    def test_preexisting_link_to_internal_ignored_target_denies_shell_pre(self):
        self.write(".gitignore", "ignored/\n")
        self.write("ignored/target.c", "int ignored = 0;\n")
        self.symlink(Path("ignored/target.c"), self.root / "link.c")
        self.policy()
        before = (self.root / "ignored/target.c").read_bytes()
        result = self.begin(tool="Bash")
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertIn("SYMLINK", result["hookSpecificOutput"]["permissionDecisionReason"])
        self.assertEqual((self.root / "ignored/target.c").read_bytes(), before)

    def test_preexisting_link_to_external_target_denies_patch_pre(self):
        target = Path(self.temp.name) / "outside.c"
        target.write_text("int outside = 0;\n", encoding="utf-8")
        self.symlink(target, self.root / "link.h")
        self.policy()
        result = self.begin(path="link.h")
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertIn("SYMLINK", result["hookSpecificOutput"]["permissionDecisionReason"])
        self.assertEqual(target.read_text(encoding="utf-8"), "int outside = 0;\n")

    def test_link_directory_is_not_followed_even_to_internal_target(self):
        self.write(".gitignore", "ignored/\n")
        self.write("ignored/target.c", "int ignored = 0;\n")
        self.symlink(self.root / "ignored", self.root / "alias", directory=True)
        self.policy()
        result = self.begin(path="alias/target.c")
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertIn("SYMLINK", result["hookSpecificOutput"]["permissionDecisionReason"])
        if os.name == "nt":
            # Exercise the actual junction while simulating Python 3.10/3.11.
            with mock.patch.object(Path, "is_junction", None, create=True):
                with self.assertRaisesRegex(GUARD.GuardError, "SYMLINK"):
                    GUARD.snapshot(self.root, GUARD.read_policy((self.root / ".c99-policy.json").read_bytes()),
                                   ["alias/target.c"], time.monotonic() + 2)

    def test_new_link_after_pre_is_reported_unverified(self):
        self.policy()
        self.begin(tool="Bash")
        self.symlink(self.root / "main.c", self.root / "new_link.h")
        result = self.finish(tool="Bash")
        self.assertEqual(result["decision"], "block")
        self.assertIn("SYMLINK", result["reason"])

    def test_absolute_cross_repo_patch_to_enabled_policy_is_denied(self):
        other = Path(self.temp.name) / "另一个 repo"
        other.mkdir()
        subprocess.run(["git", "init", "-q"], cwd=other, check=True, capture_output=True)
        (other / ".c99-policy.json").write_text(json.dumps({"schemaVersion": 1, "checks": [
            {"id": "reject", "argv": [sys.executable, "-c", "raise SystemExit(1)"]}]}), encoding="utf-8")
        target = other / "outside.c"
        target.write_text("int original = 0;\n", encoding="utf-8")
        for line in (f"*** Update File: {target}", f"*** Add File: {other / 'new.h'}",
                     f"*** Update File: main.c\n*** Move to: {other / 'moved.c'}"):
            with self.subTest(line=line):
                payload = self.event("PreToolUse")
                payload["tool_input"]["command"] = "*** Begin Patch\n" + line + "\n*** End Patch"
                result = self.invoke(payload)
                self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")
                self.assertIn("CROSS-REPO", result["hookSpecificOutput"]["permissionDecisionReason"])
                self.assertIn("正确 cwd", result["hookSpecificOutput"]["permissionDecisionReason"])
        self.assertEqual(target.read_text(encoding="utf-8"), "int original = 0;\n")

    def test_cross_repo_patch_without_policies_reports_scope_gap(self):
        target = Path(self.temp.name) / "outside.c"
        result = self.begin(path=str(target))
        self.assertNotIn("permissionDecision", result["hookSpecificOutput"])
        self.assertIn("CROSS-REPO", result["hookSpecificOutput"]["additionalContext"])
        self.assertIn("未为这些外部目标建立基线", result["hookSpecificOutput"]["additionalContext"])

    def test_failed_tool_still_checks_its_file_effects(self):
        self.policy()
        self.begin()
        self.write("main.c", "BAD partial tool write\n")
        payload = self.event("PostToolUse")
        payload["tool_response"] = {"exit_code": 1}
        self.assertEqual(self.invoke(payload)["decision"], "block")

    def test_missing_checker_and_nonzero_exit_are_not_passes(self):
        for argv in (["c99-checker-does-not-exist-fixture", "{files}"],
                     [sys.executable, "-c", "import sys;sys.exit(7)", "{files}"]):
            with self.subTest(argv=argv):
                self.policy(checks=[{"id": "failure", "argv": argv}])
                self.begin(turn=str(argv))
                self.write("main.c", "int changed = 1;\n" + str(argv))
                result = self.finish(turn=str(argv))
                self.assertEqual(result["decision"], "block")
                self.assertFalse(self.state(turn=str(argv))["lastResult"]["ok"])

    def test_checker_timeout_is_bounded_and_not_passed(self):
        self.policy(checks=[{"id": "slow", "argv": [sys.executable, "-c", "import time;time.sleep(5)"], "timeoutSeconds": 0.1}])
        self.begin()
        self.write("main.c", "int changed = 1;\n")
        started = time.monotonic()
        result = self.finish()
        self.assertLess(time.monotonic() - started, 3)
        self.assertEqual(result["decision"], "block")
        self.assertIn("超时", result["reason"])

    def tree_fixture(self, mode):
        ready = Path(self.temp.name) / f"{mode}-ready.txt"
        escaped = Path(self.temp.name) / f"{mode}-escaped.txt"
        lifetime = 3.0 if mode == "timeout" else 0.8
        child = (f"from pathlib import Path;import time;Path({str(ready)!r}).write_text('ready');"
                 f"time.sleep({lifetime});Path({str(escaped)!r}).write_text('escaped')")
        wrapper = ("import pathlib,subprocess,sys,time\n"
                   f"subprocess.Popen([sys.executable,'-c',{child!r}])\n"
                   f"ready=pathlib.Path({str(ready)!r})\n"
                   "while not ready.exists(): time.sleep(0.005)\n")
        wrapper += {"timeout": "time.sleep(10)", "background": "sys.exit(0)",
                    "nonzero": "sys.exit(7)", "noise": "print('x'*200000,flush=True);time.sleep(10)",
                    "exception": "time.sleep(10)"}[mode]
        script = Path(self.temp.name) / f"{mode}-wrapper.py"
        script.write_text(wrapper, encoding="utf-8")
        return ready, escaped, {"id": "tree", "argv": [sys.executable, str(script)], "timeoutSeconds": 2}

    def assert_tree_contained(self, mode, expected):
        ready, escaped, check = self.tree_fixture(mode)
        self.policy(checks=[check])
        self.begin()
        self.write("main.c", "int changed = 1;\n")
        result = self.finish()
        self.assertEqual(result["decision"], "block")
        self.assertIn(expected, result["reason"])
        self.assertTrue(ready.exists(), "The fixture child must actually have started")
        time.sleep(3.2 if mode == "timeout" else 0.9)
        self.assertFalse(escaped.exists(), "Checker descendants must not outlive hook cleanup")

    def test_timeout_reaps_checker_descendants(self):
        self.assert_tree_contained("timeout", "超时")

    def test_background_success_is_failure_and_descendants_are_reaped(self):
        self.assert_tree_contained("background", "后台子进程")

    def test_nonzero_wrapper_also_reaps_checker_descendants(self):
        self.assert_tree_contained("nonzero", "后台子进程")

    def test_output_limit_also_reaps_checker_descendants(self):
        self.assert_tree_contained("noise", "输出超过")

    def test_checker_exception_also_reaps_descendants(self):
        ready, escaped, check = self.tree_fixture("exception")
        process_class = GUARD.WindowsJobProcess if os.name == "nt" else GUARD.PosixProcessGroup
        real_poll = process_class.poll

        def fail_after_child_started(process):
            if ready.exists():
                raise OSError("fixture interrupted poll")
            return real_poll(process)

        with mock.patch.object(process_class, "poll", fail_after_child_started):
            result = GUARD.run_checker(check, [], self.root, time.monotonic() + 3)
        self.assertFalse(result["ok"])
        self.assertTrue(ready.exists())
        time.sleep(0.9)
        self.assertFalse(escaped.exists())

    def test_policy_change_or_removal_invalidates_result(self):
        for remove in (False, True):
            with self.subTest(remove=remove):
                turn = f"policy-{remove}"
                self.policy()
                self.begin(turn=turn)
                self.write("main.c", f"int changed = {int(remove)};\n")
                self.finish(turn=turn)
                if remove:
                    (self.root / ".c99-policy.json").unlink()
                else:
                    self.policy(exclude=["**"])
                result = self.finish(turn=turn)
                self.assertEqual(result["decision"], "block")
                self.assertIn("POLICY-CHANGED", result["reason"])

    def test_changed_content_never_reuses_previous_pass(self):
        self.policy()
        self.begin()
        self.write("main.c", "int changed = 1;\n")
        self.assertEqual(self.finish(), {})
        self.begin()
        self.write("main.c", "BAD second write\n")
        self.assertEqual(self.finish()["decision"], "block")

    def test_observing_new_patch_does_not_overwrite_old_baseline(self):
        self.policy()
        self.begin()
        self.write("main.c", "BAD first edit\n")
        self.begin(path="new.h")
        self.write("new.h", "#define VALUE 1\n")
        self.assertEqual(self.finish()["decision"], "block")
        self.assertEqual(self.state()["lastResult"]["files"], ["main.c", "new.h"])

    def test_stop_requests_only_one_repair_for_same_turn_continuation(self):
        self.policy()
        self.begin()
        self.write("main.c", "BAD current edit\n")
        self.finish()
        self.assertEqual(self.invoke(self.event("Stop"))["decision"], "block")
        self.begin()
        self.write("main.c", "BAD still wrong\n")
        self.finish()
        result = self.invoke(self.event("Stop", active=True))
        self.assertNotIn("decision", result)
        self.assertIn("未通过", result["systemMessage"])
        self.assertTrue(self.state()["closed"])

    def test_same_session_interleaved_turns_keep_independent_baselines(self):
        self.policy()
        self.begin(turn="parent")
        self.write("main.c", "BAD parent write\n")
        self.begin(turn="child")
        self.write("other.h", "#define CHILD_VALUE 1\n")
        self.assertEqual(self.finish(turn="parent")["decision"], "block")
        self.assertEqual(self.finish(turn="child"), {})
        self.assertEqual(self.state(turn="parent")["lastResult"]["files"], ["main.c", "other.h"])
        self.assertEqual(self.state(turn="child")["lastResult"]["files"], ["other.h"])
        self.assertEqual(self.invoke(self.event("Stop", turn="parent"))["decision"], "block")

    def test_new_turn_never_adopts_previous_stop_request(self):
        self.policy()
        self.begin(turn="old-turn")
        self.write("main.c", "BAD old write\n")
        self.assertEqual(self.invoke(self.event("Stop", turn="old-turn"))["decision"], "block")
        unknown = self.invoke(self.event("Stop", turn="unlinked-turn", active=True))
        self.assertNotIn("decision", unknown)
        self.assertIn("未观察到有效的本轮写前基线", unknown["systemMessage"])
        self.begin(turn="new-user-turn")
        self.assertEqual(self.finish(turn="new-user-turn"), {})
        self.assertFalse(self.state(turn="new-user-turn")["stopRequested"])
        self.assertEqual(self.state(turn="old-turn")["baseline"]["main.c"],
                         __import__("hashlib").sha256(b"int value = 0;\n").hexdigest())

    def test_failed_post_result_remains_visible_for_unchanged_fingerprint(self):
        self.policy()
        self.begin()
        self.write("main.c", "BAD current write\n")
        first = self.finish()
        second = self.finish(path="README.md")
        self.assertEqual(first["decision"], "block")
        self.assertEqual(second["decision"], "block")
        self.assertEqual(first["reason"], second["reason"])

    def test_stop_rechecks_even_after_passing_post(self):
        self.policy()
        self.begin()
        self.write("main.c", "int changed = 1;\n")
        self.assertEqual(self.finish(), {})
        self.write("main.c", "BAD changed after PostToolUse\n")
        self.assertEqual(self.invoke(self.event("Stop"))["decision"], "block")

    def test_sessions_do_not_share_touched_files_or_results(self):
        self.policy()
        self.begin(session="first")
        self.write("main.c", "BAD first session\n")
        self.finish(session="first")
        self.begin(session="second")
        self.assertEqual(self.finish(session="second"), {})
        self.assertEqual(self.state("second")["lastResult"]["files"], [])
        self.assertEqual(self.state("first")["lastResult"]["files"], ["main.c"])

    def test_state_unavailable_explicitly_says_unverified(self):
        self.policy()
        env = dict(self.env)
        env.pop("PLUGIN_DATA")
        result = self.invoke(self.event("PreToolUse"), env)
        self.assertEqual(result["hookSpecificOutput"]["permissionDecision"], "deny")
        self.assertIn("未建立本轮基线", result["hookSpecificOutput"]["permissionDecisionReason"])

    @unittest.skipUnless(os.name == "nt" and shutil.which("powershell") and (shutil.which("py") or shutil.which("python")), "Windows launcher integration")
    def test_windows_command_supports_plugin_root_with_spaces(self):
        plugin = Path(self.temp.name) / "插件 root 有 空格"
        (plugin / "hooks").mkdir(parents=True)
        shutil.copyfile(HOOK, plugin / "hooks/c99_guard.py")
        shutil.copyfile(PLUGIN / "hooks/git_governance_stop.py", plugin / "hooks/git_governance_stop.py")
        hooks = json.loads((PLUGIN / "hooks/hooks.json").read_text(encoding="utf-8"))
        command = hooks["hooks"]["PreToolUse"][0]["hooks"][0]["commandWindows"]
        env = dict(self.env, PLUGIN_ROOT=str(plugin))
        result = subprocess.run(["powershell", "-NoProfile", "-Command", command],
                                input=json.dumps(self.event("PreToolUse")).encode(),
                                cwd=self.root, env=env, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertIn("自动阻塞检查未启用", json.loads(result.stdout)["hookSpecificOutput"]["additionalContext"])
        command = hooks["hooks"]["Stop"][0]["hooks"][0]["commandWindows"]
        result = subprocess.run(["powershell", "-NoProfile", "-Command", command],
                                input=json.dumps(self.event("Stop", active=True)).encode(),
                                cwd=self.root, env=env, stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE, timeout=15)
        self.assertEqual(result.returncode, 0, result.stderr.decode("utf-8", "replace"))
        self.assertNotIn("decision", json.loads(result.stdout))

    def test_structured_workdir_uses_target_repo_and_stop_rechecks_it(self):
        self.policy()
        session_cwd = Path(self.temp.name) / "session root"
        session_cwd.mkdir()
        subprocess.run(["git", "init", "-q"], cwd=session_cwd, check=True, capture_output=True)
        pre = self.event("PreToolUse", tool="Bash")
        pre["cwd"] = str(session_cwd)
        pre["tool_input"]["workdir"] = str(self.root)
        self.invoke(pre)
        self.write("main.c", "int changed = 1;\n")
        post = dict(pre, hook_event_name="PostToolUse")
        self.assertEqual(self.invoke(post), {})
        self.assertEqual(self.state()["lastResult"]["files"], ["main.c"])
        self.write("main.c", "BAD after target PostToolUse\n")
        stop = self.event("Stop")
        stop["cwd"] = str(session_cwd)
        self.assertEqual(self.invoke(stop)["decision"], "block")

    def test_hook_does_not_change_business_files(self):
        self.policy()
        before = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        self.begin()
        self.finish()
        self.invoke(self.event("Stop"))
        after = {p.relative_to(self.root): p.read_bytes() for p in self.root.rglob("*") if p.is_file()}
        self.assertEqual(before, after)

    def test_output_is_bounded(self):
        self.policy(checks=[{"id": "noisy", "argv": [sys.executable, "-c", "print('x'*200000)"]}])
        self.begin()
        self.write("main.c", "int changed = 1;\n")
        result = self.finish()
        self.assertEqual(result["decision"], "block")
        self.assertIn("输出超过", result["reason"])
        self.assertLess(len(json.dumps(result)), 12000)


class ContractTests(unittest.TestCase):
    @unittest.skipUnless(os.name == "nt", "Windows legacy reparse metadata contract")
    def test_snapshot_legacy_junction_fallback_preserves_cloud_files(self):
        with tempfile.TemporaryDirectory(prefix="c99-reparse-contract-") as temporary:
            root = Path(temporary)
            (root / "alias").mkdir()
            (root / "alias/target.c").write_bytes(b"int value;\n")
            real_lstat = Path.lstat
            policy = {"include": ["**/*.c"], "exclude": [], "protected": []}
            for tag in (0xA0000003, 0xA000000C, 0x9000001A, None):
                metadata = SimpleNamespace(st_file_attributes=0x400)
                if tag is not None:
                    metadata.st_reparse_tag = tag

                def legacy_lstat(path):
                    return metadata if path.name == "alias" else real_lstat(path)

                with self.subTest(tag=tag), mock.patch.object(Path, "is_junction", None, create=True), \
                        mock.patch.object(Path, "is_symlink", return_value=False), \
                        mock.patch.object(Path, "lstat", legacy_lstat), \
                        mock.patch.object(GUARD, "git", return_value=b"alias/target.c\0"):
                    if tag == 0x9000001A:  # A readable cloud file is not a directory junction.
                        self.assertIn("alias/target.c", GUARD.snapshot(root, policy, [], time.monotonic() + 2))
                    else:
                        expected = "PATH" if tag is None else "SYMLINK"
                        with self.assertRaisesRegex(GUARD.GuardError, expected):
                            GUARD.snapshot(root, policy, [], time.monotonic() + 2)

    def test_snapshot_rejects_preexisting_symlink_before_hashing_target(self):
        # Real Windows file symlinks require an unavailable OS privilege. This
        # branch contract still runs there; real-link fixtures run where allowed.
        with tempfile.TemporaryDirectory(prefix="c99-link-contract-") as temporary:
            root = Path(temporary)
            (root / "link.c").write_bytes(b"link placeholder")
            real_is_symlink = Path.is_symlink
            for target in ("ignored/target.c", "../outside.c", "unchanged-target.c"):
                with self.subTest(target=target), mock.patch.object(GUARD, "git", return_value=b"link.c\0"), \
                        mock.patch.object(Path, "is_symlink", lambda path: path.name == "link.c" or real_is_symlink(path)), \
                        mock.patch.object(Path, "open", side_effect=AssertionError("Must not hash linked target")):
                    with self.assertRaisesRegex(GUARD.GuardError, "SYMLINK"):
                        GUARD.snapshot(root, {"include": ["**/*.c"], "exclude": [], "protected": []}, [], time.monotonic() + 2)

    def test_argv_expansion_is_structured_and_supports_file_prefix(self):
        root = Path(tempfile.gettempdir()).resolve() / "project with space"
        check = {"argv": ["checker", "--style=file:{root}/.clang-format", "{files}"], "fileArgument": "--file"}
        actual = GUARD.checker_argv(check, ["目录/main.c", "other.h"], root)
        self.assertEqual(actual, ["checker", f"--style=file:{root}/.clang-format", "--file", str(root / "目录/main.c"), "--file", str(root / "other.h")])

    def test_schema_rejects_shell_embedded_files_and_unbounded_timeout(self):
        for change in ({"shell": True}, {"argv": ["checker", "x{files}"]}, {"timeoutSeconds": 9}):
            policy = {"schemaVersion": 1, "checks": [{"id": "bad", "argv": ["checker", "{files}"], **change}]}
            with self.subTest(change=change), self.assertRaises(GUARD.GuardError):
                GUARD.read_policy(json.dumps(policy).encode())

    def test_globs_include_root_files_and_respect_directory_components(self):
        self.assertTrue(GUARD.matches("main.c", ["**/*.c"]))
        self.assertTrue(GUARD.matches("src/deeper/main.c", ["src/**"]))
        self.assertFalse(GUARD.matches("src/deeper/main.c", ["src/*.c"]))

    def test_git_stop_does_not_loop_after_continuation(self):
        result = subprocess.run([sys.executable, str(PLUGIN / "hooks/git_governance_stop.py")],
                                input=json.dumps({"stop_hook_active": True}), capture_output=True,
                                text=True, encoding="utf-8", timeout=2)
        self.assertEqual(result.returncode, 0)
        output = json.loads(result.stdout)
        self.assertNotIn("decision", output)
        self.assertTrue(output["continue"])

    def test_hook_registration_is_synchronous_and_bounded(self):
        hooks = json.loads((PLUGIN / "hooks/hooks.json").read_text(encoding="utf-8"))["hooks"]
        for event in ("PreToolUse", "PostToolUse", "Stop"):
            guards = [h for group in hooks[event] for h in group["hooks"] if "c99_guard.py" in h["command"]]
            self.assertEqual(len(guards), 1)
            self.assertFalse(guards[0].get("async", False))
            self.assertLessEqual(guards[0]["timeout"], 30)
            self.assertIn("PLUGIN_ROOT", guards[0]["commandWindows"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
