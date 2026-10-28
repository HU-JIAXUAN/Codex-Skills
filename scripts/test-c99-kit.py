#!/usr/bin/env python3
"""Validate the single C99 entry, topic routes, neutral index and packaged resources."""

from __future__ import annotations

import argparse
from collections import Counter
import json
from pathlib import Path
import re
import shutil
import tempfile

TOPICS = {"files", "functions", "comments", "style", "keywords", "data", "expressions", "safety", "realtime", "verification"}
RUNTIME = "aicoding-c99-standard-c"
TEXT = {".md", ".json", ".yaml", ".yml", ".c", ".h"}
FORBIDDEN = re.compile(r"华为|huawei|DKBA|HW-C99|source-evidence|N1256", re.IGNORECASE)
LINK = re.compile(r"(?<!!)\[[^\]\n]+\]\(([^)\n]+)\)")


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def contained(root: Path, value: str) -> Path:
    path = (root / value).resolve()
    require(path.is_relative_to(root.resolve()), f"path escapes C99 kit: {value}")
    return path


def normalize(path: Path, runtime: bool = False) -> str:
    value = path.read_text(encoding="utf-8-sig").replace("\r\n", "\n").replace("\r", "\n")
    if runtime:
        value = re.sub(r"(?m)^name:\s*[^\r\n]+\s*$", "name: " + RUNTIME, value)
    return value


def validate(source: Path, package: Path | None = None) -> dict:
    manifest = json.loads((source / "skillkit.json").read_text(encoding="utf-8"))
    require(manifest["schemaVersion"] == 2 and manifest["runtimeSkill"] == RUNTIME, "invalid C99 single-entry manifest")
    entries = [item for item in manifest["skills"] if item.get("enabled", True)]
    roots = [item for item in entries if item["source"] == "."]
    require(len(roots) == 1 and roots[0]["target"] == RUNTIME and roots[0]["entrypoint"] == "SKILL.md", "C99 needs exactly one root entry")
    require(len(entries) == 11 and len({item["target"] for item in entries}) == 11, "C99 capability IDs must be unique")
    require({item["source"].split("/")[-1] for item in entries if item["source"] != "."} == TOPICS, "C99 topic set is incomplete")
    require(list(source.rglob("SKILL.md")) == [source / "SKILL.md"], "nested C99 runtime entry is forbidden")
    require(list(source.rglob("openai.yaml")) == [source / "agents/openai.yaml"], "child C99 UI metadata is forbidden")
    root_text = (source / "SKILL.md").read_text(encoding="utf-8")
    for entry in (item for item in entries if item["source"] != "."):
        guide = contained(source, entry["source"] + "/GUIDE.md")
        require(entry["entrypoint"] == "GUIDE.md" and guide.is_file(), f"missing C99 guide: {entry['source']}")
        require(guide.relative_to(source).as_posix() in root_text, f"C99 root does not route to {entry['source']}")
        require(re.search(r"(?m)^capability_id:\s*" + re.escape(entry["target"]) + r"\s*$", guide.read_text(encoding="utf-8")) is not None,
                f"C99 capability ID mismatch: {entry['source']}")
        require(bool(entry.get("keywords")), f"missing routing keywords: {entry['source']}")
    files: dict[str, Path] = {}
    for name in roots[0]["include"]:
        path = contained(source, name)
        require(path.exists(), f"missing C99 package input: {name}")
        members = path.rglob("*") if path.is_dir() else [path]
        for member in members:
            if member.is_file() and "__pycache__" not in member.parts:
                files[member.relative_to(source).as_posix()] = member
    require(not any("legacy" in name for name in files), "legacy C99 rules must not enter the runtime kit")
    for name, path in files.items():
        if path.suffix in TEXT:
            content = normalize(path)
            require(not FORBIDDEN.search(content), f"source-specific text leaked into C99 runtime: {name}")
            require(re.search(r"[A-Za-z]:[\\/]", content) is None, f"absolute machine path in C99 runtime: {name}")
            require(all(line == line.rstrip() for line in content.splitlines()), f"trailing whitespace: {name}")
            if path.suffix == ".md":
                for target in LINK.findall(content):
                    value = target.split("#", 1)[0]
                    if not value or re.match(r"\w+://|mailto:", value):
                        continue
                    resolved = (path.parent / value).resolve()
                    require(resolved.is_relative_to(source.resolve()) and resolved.is_file(), f"broken or escaping route in {name}: {target}")
                    require(resolved.relative_to(source).as_posix() in files, f"route targets omitted resource in {name}: {target}")
    index = json.loads((source / "references/rule-topic-index.json").read_text(encoding="utf-8"))
    rules = index["rules"]
    require(len(rules) == 139 and index["coverage"]["ruleCount"] == 139, "C99 rule index is incomplete")
    require({item["id"] for item in rules} == {f"C99-R{i:03d}" for i in range(1, 140)}, "C99 rule IDs are missing or duplicated")
    require(len({item["title"] for item in rules}) == 139, "duplicate C99 rule titles")
    require({item["topic"] for item in rules} == TOPICS, "C99 rule index misses a topic")
    require(dict(Counter(item["topic"] for item in rules)) == index["coverage"]["topicCounts"], "C99 topic counts disagree with records")
    require(dict(Counter(item["kind"] for item in rules)) == index["coverage"]["kindCounts"], "C99 kind counts disagree with records")
    for item in rules:
        require(bool(item["title"]) and bool(item["keywords"]) and item["topic"] in TOPICS, f"invalid C99 rule {item['id']}")
    evals = json.loads((source / "evals/evals.json").read_text(encoding="utf-8"))["evals"]
    require(len(evals) >= 16 and len({item["id"] for item in evals}) == len(evals), "C99 eval scenarios are missing or duplicated")
    require(all(item["primary_topic"] in TOPICS and item["prompt"] and item["expected_output"] for item in evals), "invalid C99 eval scenario")
    if package is not None:
        actual = {path.relative_to(package).as_posix(): path for path in package.rglob("*") if path.is_file()}
        require(set(actual) == set(files), "C99 package resource set differs from declared source inputs")
        require(list(package.rglob("SKILL.md")) == [package / "SKILL.md"], "packaged C99 contains nested SKILL.md")
        for name, path in files.items():
            if path.suffix in TEXT:
                require(normalize(path, name == "SKILL.md") == normalize(actual[name]), f"C99 resource drift: {name}")
            else:
                require(path.read_bytes() == actual[name].read_bytes(), f"C99 binary resource drift: {name}")
    return {"runtimeEntries": 1, "guides": 10, "rules": len(rules), "files": len(files), "package": package is not None}


def self_test(source: Path) -> None:
    with tempfile.TemporaryDirectory(prefix="c99-kit-fixtures-") as directory:
        root = Path(directory)
        for name in ("missing-guide", "duplicate-runtime", "leaked-source", "incomplete-index"):
            fixture = root / name
            shutil.copytree(source, fixture, ignore=shutil.ignore_patterns("__pycache__"))
            if name == "missing-guide":
                (fixture / "topics/functions/GUIDE.md").unlink()
            elif name == "duplicate-runtime":
                (fixture / "topics/functions/SKILL.md").write_text("unexpected entry\n", encoding="utf-8")
            elif name == "leaked-source":
                path = fixture / "topics/comments/GUIDE.md"
                path.write_text(path.read_text(encoding="utf-8") + "\nDKBA\n", encoding="utf-8")
            else:
                path = fixture / "references/rule-topic-index.json"
                index = json.loads(path.read_text(encoding="utf-8"))
                index["rules"].pop()
                path.write_text(json.dumps(index, ensure_ascii=False), encoding="utf-8")
            try:
                validate(fixture)
            except ValueError:
                continue
            raise ValueError(f"C99 mutation was not rejected: {name}")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--package", action="store_true")
    parser.add_argument("--plugin-path", type=Path)
    parser.add_argument("--self-test", action="store_true")
    args = parser.parse_args()
    repo = Path(__file__).resolve().parents[1]
    source = repo / "embedded/C99"
    plugin = args.plugin_path or repo / "plugins/AiCoding"
    try:
        config = json.loads((repo / "config/aicoding-plugin-pack.json").read_text(encoding="utf-8"))
        require(sum(item["source"] == "embedded/C99/skillkit.json" and item.get("enabled", True) for item in config["skillKits"]) == 1, "C99 kit must be selected exactly once in pack manifest")
        require(not any(item["target"] == RUNTIME for item in config["skills"]), "C99 must be selected through its kit exactly once")
        result = validate(source, plugin / "skills" / RUNTIME if args.package else None)
        if args.self_test:
            self_test(source)
            result["mutationCases"] = 4
        print("PASS: " + json.dumps(result, sort_keys=True))
        return 0
    except (ValueError, OSError, KeyError) as exc:
        print(f"FAIL: {exc}")
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
