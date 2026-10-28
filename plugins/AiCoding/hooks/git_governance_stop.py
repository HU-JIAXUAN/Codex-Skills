#!/usr/bin/env python3
"""Plugin-bundled Codex Stop hook for AiCoding Git governance."""

from __future__ import annotations

import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

TYPED_TOKENS = (
    "**feat**", "**fix**", "**docs**", "**style**", "**refactor**",
    "**perf**", "**test**", "**build**", "**ci**", "**chore**",
)


def run(args: list[str], cwd: str | Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=str(cwd), text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)


def repo_root(cwd: str | Path) -> Path | None:
    result = run(["git", "rev-parse", "--show-toplevel"], cwd)
    if result.returncode != 0:
        return None
    return Path(result.stdout.strip())


def ok() -> int:
    print(json.dumps({"continue": True}, ensure_ascii=False))
    return 0


def block(reason: str) -> int:
    print(json.dumps({"decision": "block", "reason": reason}, ensure_ascii=False))
    return 0


def powershell_name() -> str:
    return "pwsh" if shutil.which("pwsh") else "powershell"


def changed_paths(root: Path) -> list[str]:
    result = run(["git", "status", "--short"], root)
    if result.returncode != 0:
        return []
    paths: list[str] = []
    for line in result.stdout.splitlines():
        if len(line) >= 4:
            paths.append(line[3:].strip().strip('"'))
    return paths


def validate_changelog(root: Path) -> str | None:
    changelog = root / "CHANGELOG.md"
    if not changelog.exists():
        return "AiCoding governance: CHANGELOG.md is required for governed repositories."
    text = changelog.read_text(encoding="utf-8", errors="replace")
    if "[Unreleased]" not in text:
        return "AiCoding governance: CHANGELOG.md must contain [Unreleased]."
    if not any(token in text for token in TYPED_TOKENS):
        return "AiCoding governance: CHANGELOG.md must include typed entries such as **docs** or **chore**."
    return None


def main() -> int:
    try:
        payload_raw = sys.stdin.read().strip()
        payload = json.loads(payload_raw) if payload_raw else {}
        if payload.get("stop_hook_active"):
            print(json.dumps({"continue": True, "systemMessage": "Git governance 已请求过一次复核；仍有未通过项时须明确报告，不再自动续跑。"}, ensure_ascii=True))
            return 0
        cwd = Path(payload.get("cwd") or os.getcwd())
        root = repo_root(cwd)
        if root is None:
            return ok()

        governance = root / ".github" / "repository-governance.toml"
        lint_ps1 = root / "scripts" / "lint-git-governance.ps1"
        changelog = root / "CHANGELOG.md"
        if not governance.exists() and not lint_ps1.exists() and not changelog.exists():
            return ok()

        paths = changed_paths(root)
        if paths and not any(path.replace("\\", "/") == "CHANGELOG.md" for path in paths):
            return block("AiCoding governance: repository has changes but CHANGELOG.md was not updated.")

        reason = validate_changelog(root)
        if reason:
            return block(reason)

        if lint_ps1.exists():
            result = run([powershell_name(), "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(lint_ps1), "-Mode", "all"], root)
            if result.returncode != 0:
                return block((result.stderr or result.stdout).strip() or "AiCoding governance lint failed.")

        return ok()
    except Exception as exc:
        return block(f"AiCoding Stop hook failed: {exc}")


if __name__ == "__main__":
    raise SystemExit(main())
