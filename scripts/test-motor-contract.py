#!/usr/bin/env python3
"""Verify motor SkillKit source routes, external asset bindings and generated resources."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import sys
import time


ORIGINAL_TARGETS = frozenset({
    "aicoding-motor-control", "aicoding-motor-parameter-identification",
    "aicoding-motor-sensorless-control", "aicoding-motor-feedback-calibration",
    "aicoding-servo-controller-design", "aicoding-servo-validation",
    "aicoding-pmsm-mtpa-field-weakening", "aicoding-inverter-deadtime-compensation",
    "aicoding-pmsm-dq-decoupling", "aicoding-servo-velocity-feedforward",
    "aicoding-servo-torque-feedforward", "aicoding-motion-trajectory-planning",
    "aicoding-servo-frequency-response", "aicoding-servo-auto-tuning",
    "aicoding-servo-vibration-suppression", "aicoding-servo-disturbance-observer",
    "aicoding-servo-friction-compensation", "aicoding-servo-torque-ripple-compensation",
    "aicoding-servo-dual-feedback-control", "aicoding-control-frequency-analysis",
    "aicoding-excitation-signal-design",
})
DEPLOYMENT_TARGET = "aicoding-motor-hardware-deployment"
COMMON_REFERENCE = "references/engineering_execution_zh.md"


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8-sig").replace("\r\n", "\n")


def digest(path: Path) -> str:
    return hashlib.sha256(read_text(path).encode("utf-8")).hexdigest()


def contained(base: Path, relative: str) -> Path:
    candidate = (base / relative).resolve()
    if Path(relative).is_absolute() or not candidate.is_relative_to(base.resolve()):
        raise ValueError(f"path escapes source root: {relative}")
    return candidate


def validate(root: Path, *, package: bool, coding_kit: Path | None) -> dict:
    errors: list[str] = []
    checks = 0

    def check(condition: bool, message: str) -> None:
        nonlocal checks
        checks += 1
        if not condition:
            errors.append(message)

    kit_root = root / "embedded/motorcontrol"
    manifest = json.loads(read_text(kit_root / "skillkit.json"))
    pack = json.loads(read_text(root / "config/aicoding-plugin-pack.json"))
    members = [m for m in manifest["skills"] if m.get("enabled", True)]
    targets = [m["target"] for m in members]
    expected = ORIGINAL_TARGETS | {DEPLOYMENT_TARGET}
    check(len(targets) == len(set(targets)), "duplicate motor targets")
    check(set(targets) == expected, f"motor routes changed: missing={sorted(expected-set(targets))}, extra={sorted(set(targets)-expected)}")
    check(manifest["schemaVersion"] == 1, "unexpected SkillKit schema")
    selected = [k for k in pack.get("skillKits", []) if k.get("enabled", True)
                and k["source"] == "embedded/motorcontrol/skillkit.json"]
    check(len(selected) == 1, "motor kit must be selected exactly once by pack manifest")
    direct_targets = {m["target"] for m in pack.get("skills", []) if m.get("enabled", True)}
    check(not direct_targets.intersection(targets), "motor members also declared as direct skills")
    common = kit_root / COMMON_REFERENCE
    check(common.is_file(), "missing shared engineering contract")
    common_text = read_text(common)
    provenance_file = kit_root / "references/research_provenance.json"
    check(provenance_file.is_file(), "missing canonical motor research provenance")
    if provenance_file.is_file():
        provenance = json.loads(read_text(provenance_file))
        source_ids = [item["id"] for item in provenance.get("sources", [])]
        rule_ids = [item["id"] for item in provenance.get("decision_evidence", [])]
        identities = source_ids + rule_ids
        check(len(identities) == len(set(identities)), "duplicate source/rule identities in provenance")
        referenced = set(re.findall(
            r"`((?:[BDLPS]-[A-Z0-9-]+|RULE-[A-Z0-9-]+|local-[a-z0-9-]+|codingkit-[a-z0-9-]+))`",
            common_text))
        for identity in sorted(referenced):
            check(identity in identities, f"unresolved engineering source/rule identity: {identity}")
    integration = next(m for m in members if m["target"] == "aicoding-motor-control")
    check("references" in integration.get("include", []), "integration must package shared references")
    check(integration.get("source") == "." and "include" in integration,
          "integration must use explicit includes to prevent nested skill duplication")
    shared_copies = list(kit_root.rglob("engineering_execution_zh.md"))
    check(shared_copies == [common], "shared engineering contract has duplicate canonical copies")
    source_directories: set[Path] = set()
    for member in members:
        target = member["target"]
        source = contained(kit_root, member["source"])
        check(source not in source_directories, f"duplicate source route: {member['source']}")
        source_directories.add(source)
        skill_file = source / "SKILL.md"
        check(skill_file.is_file(), f"missing source entry: {target}")
        if not skill_file.is_file():
            continue
        text = read_text(skill_file)
        name = re.search(r"(?m)^name:\s*([^\r\n]+)", text)
        check(bool(name) and name.group(1).strip("\"' ") == target,
              f"source frontmatter does not match route: {target}")
        check(COMMON_REFERENCE in text, f"missing engineering execution route: {target}")
        check(f"`{target}`" in common_text, f"missing capability/evidence row: {target}")
        check((source / "agents/openai.yaml").is_file(), f"missing runtime UI metadata: {target}")
        for include in member.get("include", []):
            include_path = contained(source, include)
            check(include_path.exists(), f"missing packaged include: {target}/{include}")
        if package:
            generated = root / "plugins/AiCoding/skills" / target
            check((generated / "SKILL.md").is_file(), f"missing generated skill: {target}")
            if (generated / "SKILL.md").is_file():
                check(COMMON_REFERENCE in read_text(generated / "SKILL.md"),
                      f"generated execution route missing: {target}")
            nested = [p for p in generated.rglob("SKILL.md") if p.parent != generated]
            check(not nested, f"nested skill copied inside flat runtime member: {target}")
            check(not (generated / "motor.c").exists() and not (generated / "motor.h").exists(),
                  f"external algorithm source copied into plugin: {target}")
    if package:
        generated_root = root / "plugins/AiCoding/skills"
        copies = list(generated_root.rglob("engineering_execution_zh.md"))
        expected_common = generated_root / "aicoding-motor-control" / COMMON_REFERENCE
        check(copies == [expected_common], "shared engineering contract must be packaged exactly once")
        if expected_common.is_file():
            check(digest(common) == digest(expected_common), "generated shared contract differs from canonical source")
    assets = manifest.get("codeAssets", [])
    check(len(assets) == len(set(assets)), "duplicate external code asset bindings")
    for required in ("modules/common/controller/motor", "tools/motor-engineering"):
        check(required in assets, f"missing external code asset binding: {required}")
    if coding_kit is not None:
        for relative in assets:
            check(contained(coding_kit, relative).exists(), f"external code asset unavailable: {relative}")
        for relative in ("modules/common/controller/motor/run_tests.py", "tools/motor-engineering/go.mod"):
            check(contained(coding_kit, relative).is_file(), f"external execution entry unavailable: {relative}")
        header = contained(coding_kit, "modules/common/controller/motor/motor.h")
        check(header.is_file(), "canonical motor header unavailable")
        if header.is_file():
            header_text = read_text(header)
            symbols = sorted(set(re.findall(r"\bmc_[a-z][a-z0-9_]*\b", common_text)))
            for symbol in symbols:
                check(bool(re.search(r"\bMcStatus\s+" + re.escape(symbol) + r"\s*\(", header_text)),
                      f"documented C99 primitive absent from canonical header: {symbol}")
    return {"ok": not errors, "checks": checks, "motor_skills": len(members),
            "original_routes_preserved": ORIGINAL_TARGETS.issubset(targets),
            "package_checked": package, "external_assets_checked": coding_kit is not None,
            "errors": errors}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", action="store_true", help="also inspect already generated plugin")
    parser.add_argument("--coding-kit", type=Path, help="explicit external CodingKit root; no automatic discovery")
    args = parser.parse_args()
    start = time.perf_counter()
    try:
        result = validate(Path(__file__).resolve().parents[1], package=args.package,
                          coding_kit=args.coding_kit.resolve() if args.coding_kit else None)
        result["duration_ms"] = round((time.perf_counter() - start) * 1000, 3)
        print(json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False))
        return 0 if result["ok"] else 1
    except (OSError, ValueError, KeyError, StopIteration, TypeError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
