#!/usr/bin/env python3
"""Verify motor SkillKit source routes, external asset bindings and generated resources."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import tempfile
from urllib.parse import unquote
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


RUNTIME_TARGET = "aicoding-motor-control"
TEXT_SUFFIXES = {".md", ".json", ".yaml", ".yml", ".txt", ".py", ".ps1", ".html", ".toml"}


def file_digest(path: Path) -> str:
    data = read_text(path).encode("utf-8") if path.suffix.lower() in TEXT_SUFFIXES else path.read_bytes()
    return hashlib.sha256(data).hexdigest()


def markdown_targets(path: Path, kit_root: Path) -> list[Path]:
    """Resolve local Markdown file links, excluding code and mathematical notation."""
    text = read_text(path)
    text = re.sub(r"(?ms)^(`{3,}|~{3,})[^\n]*\n.*?^\1\s*$", "", text)
    text = re.sub(r"\$\$.*?\$\$", "", text, flags=re.S)
    text = re.sub(r"(`+).*?\1", "", text)
    text = re.sub(r"(?<!\\)\$(?!\$).*?(?<!\\)\$", "", text)
    targets: list[Path] = []
    for match in re.finditer(r"(?<!!)\[[^\]\r\n]+\]\(([^)\r\n]+)\)", text):
        raw = match.group(1).strip().strip("<>")
        if re.match(r"^[A-Za-z][A-Za-z0-9+.-]*:", raw):
            continue
        relative = unquote(raw.split("#", 1)[0])
        if not relative or Path(relative).suffix.lower() not in {".md", ".markdown"}:
            continue
        destination = (path.parent / relative).resolve()
        if not destination.is_relative_to(kit_root.resolve()):
            raise ValueError(f"Markdown link escapes motor kit: {path}: {raw}")
        targets.append(destination)
    return targets


def validate(root: Path, *, package: bool, coding_kit: Path | None,
             plugin_path: Path | None = None) -> dict:
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
    check(manifest["schemaVersion"] == 2, "motor kit requires single-entry schemaVersion 2")
    check(manifest.get("runtimeSkill") == RUNTIME_TARGET, "unexpected motor runtime skill")
    selected = [k for k in pack.get("skillKits", []) if k.get("enabled", True)
                and k["source"] == "embedded/motorcontrol/skillkit.json"]
    check(len(selected) == 1, "motor kit must be selected exactly once by pack manifest")
    direct_targets = {m["target"] for m in pack.get("skills", []) if m.get("enabled", True)}
    check(not direct_targets.intersection(targets), "motor members also declared as direct skills")
    roots = [m for m in members if m["target"] == RUNTIME_TARGET]
    check(len(roots) == 1, "motor kit requires exactly one root member")
    integration = roots[0] if roots else {}
    check(integration.get("source") == "." and integration.get("entrypoint") == "SKILL.md",
          "runtime member must use root SKILL.md")
    includes = integration.get("include", [])
    for required in ("SKILL.md", "agents", "references", "assets", "README.md", "skillkit.json"):
        check(required in includes, f"runtime member missing include: {required}")
    included_files: dict[Path, str] = {}
    for include in includes:
        include_path = contained(kit_root, include)
        check(include_path.exists(), f"missing packaged include: {include}")
        candidates = [include_path] if include_path.is_file() else include_path.rglob("*")
        for path in candidates:
            if not path.is_file() or "__pycache__" in path.parts or ".git" in path.parts:
                continue
            if path.name.endswith(".zip") or ".bak" in path.name:
                continue
            included_files[path.resolve()] = path.relative_to(kit_root).as_posix()

    common = kit_root / COMMON_REFERENCE
    check(common.is_file(), "missing shared engineering contract")
    common_text = read_text(common) if common.is_file() else ""
    provenance_file = kit_root / "references/research_provenance.json"
    check(provenance_file.is_file(), "missing canonical motor research provenance")
    if provenance_file.is_file():
        provenance = json.loads(read_text(provenance_file))
        identities = [item["id"] for item in provenance.get("sources", [])]
        identities += [item["id"] for item in provenance.get("decision_evidence", [])]
        check(len(identities) == len(set(identities)), "duplicate source/rule identities in provenance")
        referenced = set(re.findall(
            r"`((?:[BDLPS]-[A-Z0-9-]+|RULE-[A-Z0-9-]+|local-[a-z0-9-]+|codingkit-[a-z0-9-]+))`",
            common_text))
        for identity in sorted(referenced):
            check(identity in identities, f"unresolved engineering source/rule identity: {identity}")
    check(set(kit_root.rglob("engineering_execution_zh.md")) == {common},
          "shared engineering contract has duplicate canonical copies")
    check(set(kit_root.rglob("SKILL.md")) == {kit_root / "SKILL.md"},
          "motor source must have only the root SKILL.md")
    check(set(kit_root.rglob("openai.yaml")) == {kit_root / "agents/openai.yaml"},
          "motor source must have only root UI metadata")
    root_skill = kit_root / "SKILL.md"
    root_links = set(markdown_targets(root_skill, kit_root)) if root_skill.is_file() else set()
    source_directories: set[Path] = set()
    guide_files: set[Path] = set()
    for member in members:
        target = member["target"]
        source = contained(kit_root, member["source"])
        check(source not in source_directories, f"duplicate source route: {member['source']}")
        source_directories.add(source)
        entry_name = member.get("entrypoint")
        is_root = target == RUNTIME_TARGET
        check(entry_name == ("SKILL.md" if is_root else "GUIDE.md"), f"invalid entrypoint: {target}")
        if not isinstance(entry_name, str):
            continue
        entry_file = contained(source, entry_name)
        check(entry_file.is_file(), f"missing source entry: {target}")
        if not is_root:
            guide_files.add(entry_file)
            check(entry_file.resolve() in root_links, f"internal guide not linked from root: {target}")
            check(not (source / "agents/openai.yaml").exists(), f"internal guide has UI metadata: {target}")
        if not entry_file.is_file():
            continue
        text = read_text(entry_file)
        frontmatter = re.match(r"\A---\n(.*?)\n---(?:\n|$)", text, flags=re.S)
        check(bool(frontmatter), f"missing entry metadata: {target}")
        header = frontmatter.group(1) if frontmatter else ""
        key = "name" if is_root else "capability_id"
        identity = re.search(rf"(?m)^{key}:\s*([^\r\n]+)", header)
        check(bool(identity) and identity.group(1).strip("\"' ") == target,
              f"source metadata does not match route: {target}")
        check(bool(re.search(r"(?m)^description:\s*\S", header)), f"missing description: {target}")
        if not is_root:
            check(not re.search(r"(?m)^name:", header), f"internal guide must not register a name: {target}")
        check(COMMON_REFERENCE in text, f"missing engineering execution route: {target}")
        check(f"`{target}`" in common_text, f"missing capability/evidence row: {target}")
        check(entry_file.resolve() in included_files, f"entry not included in runtime bundle: {target}")
    check(set(kit_root.rglob("GUIDE.md")) == guide_files, "unregistered or missing canonical guide")
    for markdown_file in sorted(kit_root.rglob("*.md")):
        for target_path in markdown_targets(markdown_file, kit_root):
            check(target_path.is_file(), f"broken Markdown route: {markdown_file.relative_to(kit_root)} -> {target_path.relative_to(kit_root.resolve())}")

    if package:
        plugin = plugin_path if plugin_path is not None else root / "plugins/AiCoding"
        generated_root = plugin / "skills"
        generated = generated_root / RUNTIME_TARGET
        check(generated.is_dir(), "missing motor runtime bundle")
        check(set(generated.rglob("SKILL.md")) == {generated / "SKILL.md"},
              "motor runtime must expose only the root SKILL.md")
        check(set(generated.rglob("openai.yaml")) == {generated / "agents/openai.yaml"},
              "motor runtime must have only root UI metadata")
        for target in sorted(expected - {RUNTIME_TARGET}):
            check(not (generated_root / target).exists(), f"obsolete flat runtime skill: {target}")
        expected_files = set(included_files.values())
        actual_files = {p.relative_to(generated).as_posix() for p in generated.rglob("*") if p.is_file()}
        check(actual_files == expected_files,
              f"runtime resource set differs: missing={sorted(expected_files-actual_files)}, extra={sorted(actual_files-expected_files)}")
        for source_path, relative in included_files.items():
            runtime_file = generated / relative
            check(runtime_file.is_file(), f"missing generated resource: {relative}")
            if runtime_file.is_file():
                check(file_digest(source_path) == file_digest(runtime_file), f"generated resource differs: {relative}")
        copies = list(generated_root.rglob("engineering_execution_zh.md"))
        check(set(copies) == {generated / COMMON_REFERENCE}, "shared engineering contract must be packaged exactly once")
        for markdown_file in sorted(generated.rglob("*.md")):
            for target_path in markdown_targets(markdown_file, generated):
                check(target_path.is_file(), f"broken generated Markdown route: {markdown_file.relative_to(generated)}")
        for forbidden in ("motor.c", "motor.h"):
            check(not list(generated.rglob(forbidden)), f"external algorithm source copied into plugin: {forbidden}")

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
            for symbol in sorted(set(re.findall(r"\bmc_[a-z][a-z0-9_]*\b", common_text))):
                check(bool(re.search(r"\bMcStatus\s+" + re.escape(symbol) + r"\s*\(", header_text)),
                      f"documented C99 primitive absent from canonical header: {symbol}")
    return {"ok": not errors, "checks": checks, "runtime_skills": len(roots),
            "internal_topics": len(members) - len(roots), "capabilities": len(members),
            "original_routes_preserved": ORIGINAL_TARGETS.issubset(targets),
            "package_checked": package, "external_assets_checked": coding_kit is not None,
            "errors": errors}


def self_test(root: Path, plugin_path: Path | None) -> dict:
    """Mutation tests use real source/package copies and never touch the checkout."""
    plugin = plugin_path if plugin_path is not None else root / "plugins/AiCoding"
    baseline = validate(root, package=True, coding_kit=None, plugin_path=plugin)
    if not baseline["ok"]:
        return {"ok": False, "self_test": True, "errors": ["baseline must pass before mutation tests"], "baseline": baseline}
    cases = ("missing-guide", "duplicate-id", "nested-skill", "flat-runtime", "tampered-resource", "path-escape", "broken-route")
    results = []
    with tempfile.TemporaryDirectory(prefix="motor-contract-") as directory:
        temp_root = Path(directory)
        for case in cases:
            fixture = temp_root / case
            source = fixture / "embedded/motorcontrol"
            runtime_plugin = fixture / "plugins/AiCoding"
            runtime = runtime_plugin / "skills" / RUNTIME_TARGET
            shutil.copytree(root / "embedded/motorcontrol", source)
            shutil.copytree(plugin / "skills" / RUNTIME_TARGET, runtime)
            (fixture / "config").mkdir(parents=True)
            shutil.copyfile(root / "config/aicoding-plugin-pack.json", fixture / "config/aicoding-plugin-pack.json")
            manifest_path = source / "skillkit.json"
            manifest = json.loads(read_text(manifest_path))
            internal = next(m for m in manifest["skills"] if m["target"] != RUNTIME_TARGET)
            guide = source / internal["source"] / internal["entrypoint"]
            if case == "missing-guide":
                guide.unlink()
            elif case == "duplicate-id":
                manifest["skills"].append(dict(internal))
            elif case == "nested-skill":
                (guide.parent / "SKILL.md").write_text("---\nname: hidden\n---\n", encoding="utf-8")
            elif case == "flat-runtime":
                (runtime.parent / internal["target"]).mkdir()
            elif case == "tampered-resource":
                item = runtime / COMMON_REFERENCE
                item.write_text(read_text(item) + "\nMutation\n", encoding="utf-8")
            elif case == "path-escape":
                internal["source"] = "../../escape"
            elif case == "broken-route":
                entry = source / "SKILL.md"
                entry.write_text(read_text(entry).replace("GUIDE.md", "MISSING.md", 1), encoding="utf-8")
            manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
            try:
                result = validate(fixture, package=True, coding_kit=None, plugin_path=runtime_plugin)
                caught = not result["ok"]
                diagnostics = result["errors"]
            except (OSError, ValueError, KeyError, StopIteration, TypeError) as exc:
                caught = True
                diagnostics = [str(exc)]
            results.append({"case": case, "detected": caught, "diagnostic_count": len(diagnostics)})
    return {"ok": all(result["detected"] for result in results), "self_test": True,
            "cases": len(results), "results": results,
            "errors": [result["case"] for result in results if not result["detected"]]}


def main() -> int:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package", action="store_true", help="also inspect already generated plugin")
    parser.add_argument("--plugin-path", type=Path, help="explicit plugin root; defaults to plugins/AiCoding")
    parser.add_argument("--coding-kit", type=Path, help="explicit external CodingKit root; no automatic discovery")
    parser.add_argument("--self-test", action="store_true", help="run source/package mutation checks in temporary copies")
    args = parser.parse_args()
    start = time.perf_counter()
    try:
        root = Path(__file__).resolve().parents[1]
        plugin_path = args.plugin_path.resolve() if args.plugin_path else None
        if args.self_test:
            result = self_test(root, plugin_path)
        else:
            result = validate(root, package=args.package,
                              coding_kit=args.coding_kit.resolve() if args.coding_kit else None,
                              plugin_path=plugin_path)
        result["duration_ms"] = round((time.perf_counter() - start) * 1000, 3)
        print(json.dumps(result, ensure_ascii=False, indent=2, allow_nan=False))
        return 0 if result["ok"] else 1
    except (OSError, ValueError, KeyError, StopIteration, TypeError) as exc:
        print(json.dumps({"ok": False, "error": str(exc)}, ensure_ascii=False), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
