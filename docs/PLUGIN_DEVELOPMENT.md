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
```

Run official plugin validation when available.

Build and generated-drift verification share a bounded, per-repository process mutex. The drift checker invokes the builder in the same PowerShell process so it can hold that lock across the before/after snapshots; parallel builds cannot replace the staging or generated tree mid-check. A failed rebuild must fail verification immediately. Source edits remain independent of this lock, so finish source changes before taking a reproducibility snapshot.

## Cross-Repository Rule

AiCoding must consume a committed Codex-Skills state through `CodingKit/agents/skills`. Do not make AiCoding depend on uncommitted generated plugin output.
