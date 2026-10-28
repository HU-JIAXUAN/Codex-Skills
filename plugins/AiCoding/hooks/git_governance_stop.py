#!/usr/bin/env python3
"""Adapt a Codex Stop event to the packaged Git governance Skill checker."""

from __future__ import annotations

import json
import os
import runpy
import sys
from pathlib import Path

def main() -> int:
    try:
        payload_raw = sys.stdin.read().strip()
        payload = json.loads(payload_raw) if payload_raw else {}
        if not isinstance(payload, dict):
            raise ValueError("Stop payload must be a JSON object")
        if payload.get("stop_hook_active"):
            print(json.dumps({"continue": True, "systemMessage": "Git governance 已请求过一次复核；仍有未通过项时须明确报告，不再自动续跑。"}, ensure_ascii=True))
            return 0
        plugin = Path(os.environ.get("PLUGIN_ROOT") or Path(__file__).resolve().parents[1])
        checker = plugin / "skills/aicoding-git-governance/scripts/check_stop.py"
        namespace = runpy.run_path(str(checker), run_name="aicoding_git_governance_stop")
        return namespace["main"](payload)
    except Exception as exc:
        print(json.dumps({"decision": "block", "reason": f"AiCoding Stop hook failed: {exc}"}, ensure_ascii=False))
        return 0


if __name__ == "__main__":
    raise SystemExit(main())
