# Plugin Development

This document defines how Codex-Skills changes become the installable AiCoding Codex plugin.

## Maintenance Chain

Agents must follow this chain:

```text
AGENTS.md boundaries
-> aicoding-kit-maintenance workflow
-> docs/ARCHITECTURE.md rationale
-> config and scripts executable truth
-> Git hooks, CI, and verification gates
```

## Manual And Generated Areas

Manual plugin sources:

- `plugins/AiCoding/.codex-plugin/plugin.json`
- `plugins/AiCoding/hooks/`
- `plugins/AiCoding/assets/`
- `plugins/AiCoding/README.md`
- `config/aicoding-plugin-pack.json`

Motor-control sources form one nested kit under `embedded/motorcontrol/`. Schema v2 declares one `runtimeSkill` and explicit internal `GUIDE.md` entrypoints; only `aicoding-motor-control/SKILL.md` is registered. Keep child guides and references in their existing relative category paths, omit child UI metadata, and route through the root skill. The root include list packages the complete kit once. The global `config/aicoding-plugin-pack.json` remains the kit selection authority, and BUILDINFO records both manifest hashes. `scripts/test-motor-contract.py --package --self-test` checks the single-entry contract, internal routes, resource equality and negative cases; it is also wired into the repository verification flow.

Architecture sources use one runtime entry, `embedded/architecture/SKILL.md`. Object-model and data-model guidance lives at `object-model-design/GUIDE.md` and `data-model-design/GUIDE.md` beneath that root, together with each topic's references and evals. The ordinary recursive skill build packages these resources into `skills/aicoding-architecture/`; no additional kit schema or separate runtime mapping is needed. Do not add child `SKILL.md` files or child `agents/openai.yaml` metadata. The root skill must route to the guides through relative links, and `document-architecture.json` must declare their Markdown documents and dependencies. Embedded modularization, platform design or adaptation, and decoupling require loading the architecture entry first; the task determines how much guidance and verification to apply.

C99 uses `embedded/C99/skillkit.json`: one runtime entry, ten internal `topics/*/GUIDE.md` guides, a shared baseline and a neutral rule-title index. Edit the declared canonical resources; the legacy reference is retained outside the package include list. Keep source names, personal paths and original document identifiers out of runtime guides/references. `test-c99-kit.py` runs in source and package verification and rejects missing routes, extra runtime entries, source-specific text and resource drift.

Generated plugin outputs:

- `plugins/AiCoding/skills/`
- `plugins/AiCoding/BUILDINFO.json`

Do not manually edit generated outputs. Rebuild them with `scripts/build-plugin.ps1`.

## Standard Change Flow

```text
change canonical source
-> update pack manifest when needed
-> build plugin
-> compare generated output
-> verify plugin
-> verify skills
-> update docs and CHANGELOG
```

## Required Commands

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-plugin.ps1 -Plugin AiCoding -Configuration Development -Clean -Verify
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/compare-generated.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-plugin.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-skills.ps1
python -B scripts/test-c99-kit.py --package --self-test
python -B scripts/test-c99-hooks.py
```

Run official plugin validation when available.

Build and generated-drift verification share a bounded, per-repository process mutex. The drift checker invokes the builder in the same PowerShell process so it can hold that lock across the before/after snapshots; parallel builds cannot replace the staging or generated tree mid-check. A failed rebuild must fail verification immediately. Source edits remain independent of this lock, so finish source changes before taking a reproducibility snapshot.

## C99 Hook Contract

`hooks/c99_guard.py` provides PreToolUse/PostToolUse/Stop adapters. Without `.c99-policy.json`, explicit C/H patches receive a short routing reminder. With policy, include/exclude/protected paths and argv checkers are project-owned decisions. Checkers must run synchronously without rewriting code; missing tools, timeout, excessive output, changed policy and unavailable state cannot count as a pass. State uses `PLUGIN_DATA`; diagnostics are bounded. Shell-internal directory changes, unobserved ignored files and other editing surfaces require separate Git/CI checks. The guard never proves that a Skill was read or that comments are semantically correct.

Hook tests use disposable repositories and real event payloads. Review changed definitions through Codex `/hooks` after installation. Source/package verification does not grant Hook trust or update an installed cache.

## C99 Maintenance Inputs

The 2026-10-28 editorial review used local documents; this record is not packaged or loaded by the runtime Skill.

| Input | SHA-256 | Review use |
|---|---|---|
| 华为C语言编程规范.pdf, DKBA 2826-2011.5, 61 pages | `80d23ac9cacb83aebaa1c28889271f744d5866ca45d09266533895f256262200` | Chapter/principle/rule-title coverage, reorganized into neutral engineering topics |
| 华为C语言面试题.doc | `abe19ad2fdafc04628f7a66d4b55a2044c150e84280579e9d84971dfecd88c9d` | Negative cases for sequencing, overlapping memory, unsafe input and language mixing; snippets are not normative templates |

## Cross-Repository Rule

AiCoding must consume a committed Codex-Skills state through `CodingKit/agents/skills`. Do not make AiCoding depend on uncommitted generated plugin output.
