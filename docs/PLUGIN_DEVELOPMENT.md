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

Motor-control sources form one nested kit under embedded/motorcontrol/. Its skillkit.json owns relative member paths and resource includes. The global config/aicoding-plugin-pack.json remains the authority for selecting kits and direct skills; scripts/build-plugin.ps1 expands enabled members into flat runtime skills. The integration member uses an explicit include list so nested skills are not copied twice. BUILDINFO records hashes for both the global manifest and enabled kit manifests.

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

## Cross-Repository Rule

AiCoding must consume a committed Codex-Skills state through `CodingKit/agents/skills`. Do not make AiCoding depend on uncommitted generated plugin output.
