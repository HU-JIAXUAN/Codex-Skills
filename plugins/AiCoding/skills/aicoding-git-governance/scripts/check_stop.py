#!/usr/bin/env python3
"""Check a Stop event using repository lint, then the selected CHANGELOG profile."""

from __future__ import annotations

import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tomllib


TYPED_ENTRY = re.compile(r"\*\*(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([^)]*\))?\*\*")
CHANGELOG_MODES = {"unreleased", "dated", "fragments", "release-only", "generated"}


def run(args: list[str], cwd: Path) -> subprocess.CompletedProcess[str]:
    return subprocess.run(args, cwd=cwd, text=True, encoding="utf-8", errors="replace",
                          stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10)


def output(reason: str | None = None) -> int:
    result = {"decision": "block", "reason": reason[:4000]} if reason else {"continue": True}
    print(json.dumps(result, ensure_ascii=False))
    return 0


def repo_path(root: Path, name: str) -> Path:
    if not isinstance(name, str) or not name or Path(name).is_absolute():
        raise ValueError("changelog.file must be a nonempty repository-relative path")
    path = (root / name).resolve()
    if not path.is_relative_to(root.resolve()):
        raise ValueError("changelog.file escapes the repository")
    return path


def changed_paths(root: Path) -> set[str]:
    result = run(["git", "status", "--porcelain=v1", "-z", "--untracked-files=all"], root)
    if result.returncode:
        raise RuntimeError(result.stderr.strip() or "git status failed")
    paths: set[str] = set()
    records = iter(result.stdout.split("\0"))
    for record in records:
        if not record:
            continue
        status = record[:2]
        paths.add(record[3:])
        if "R" in status or "C" in status:
            next(records, None)
    return paths


def fallback(root: Path, governance: Path) -> str | None:
    with governance.open("rb") as handle:
        config = tomllib.load(handle)
    policy = config.get("changelog", {})
    if not isinstance(policy, dict):
        raise ValueError("changelog must be a TOML table")
    enabled = policy.get("enabled", True)
    require_typed = policy.get("require_typed_entries", True)
    if not isinstance(enabled, bool) or not isinstance(require_typed, bool):
        raise ValueError("changelog enabled and require_typed_entries must be booleans")
    if not enabled:
        return None
    mode = policy.get("mode", "unreleased")
    if mode not in CHANGELOG_MODES:
        raise ValueError(f"unsupported changelog.mode: {mode}")
    # Fragment generation and release-only work have no mandatory live main file.
    # Their aggregation/release gates belong to the repository's lint workflow.
    if mode not in {"unreleased", "dated"}:
        return None
    changelog = repo_path(root, policy.get("file", "CHANGELOG.md"))
    if not changelog.is_file():
        return f"AiCoding governance: configured CHANGELOG is missing: {changelog.relative_to(root).as_posix()}"
    text = changelog.read_text(encoding="utf-8")
    if mode == "unreleased" and "[Unreleased]" not in text:
        return "AiCoding governance: configured CHANGELOG must contain [Unreleased]."
    if require_typed and not TYPED_ENTRY.search(text):
        return "AiCoding governance: configured CHANGELOG must include typed entries such as **docs** or **refactor(scope)**."
    if mode == "unreleased":
        paths = changed_paths(root)
        name = changelog.relative_to(root).as_posix()
        if paths and name not in paths:
            return f"AiCoding governance: repository has changes but {name} was not updated."
    return None


def main(payload: dict | None = None) -> int:
    try:
        if payload is None:
            raw = sys.stdin.read().strip()
            payload = json.loads(raw) if raw else {}
        if not isinstance(payload, dict):
            raise ValueError("Stop payload must be a JSON object")
        if payload.get("stop_hook_active"):
            return output()
        cwd = Path(payload.get("cwd") or os.getcwd())
        result = run(["git", "rev-parse", "--show-toplevel"], cwd)
        if result.returncode:
            return output()
        root = Path(result.stdout.strip()).resolve()
        lint = root / "scripts/lint-git-governance.ps1"
        governance = root / ".github/repository-governance.toml"
        if lint.is_file():
            powershell = shutil.which("pwsh") or shutil.which("powershell")
            if not powershell:
                return output("AiCoding governance: PowerShell is required to run repository lint.")
            result = run([powershell, "-NoProfile", "-ExecutionPolicy", "Bypass", "-File", str(lint), "-Mode", "all"], root)
            if result.returncode:
                detail = "\n".join(part.strip() for part in (result.stdout, result.stderr) if part.strip())
                return output(detail or "AiCoding governance lint failed.")
            return output()
        if governance.is_file():
            return output(fallback(root, governance))
        return output()
    except Exception as exc:
        return output(f"AiCoding Stop check failed: {exc}")


if __name__ == "__main__":
    raise SystemExit(main())
