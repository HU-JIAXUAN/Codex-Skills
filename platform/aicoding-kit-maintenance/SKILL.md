---
name: aicoding-kit-maintenance
description: Maintain the Codex-Skills and AiCoding two-repository kit. Use for architecture changes, plugin packaging, AGENTS boundaries, CodingKit assets, submodule updates, install/update scripts, hooks, CI gates, or requests to manage the AiCoding Codex kit lifecycle.
---

# AiCoding Kit Maintenance

## Purpose

Maintain the two-repository AiCoding Codex kit without creating a second skill source, bypassing plugin packaging, or mixing Codex hooks with Git hooks.

Use this skill when work touches any of these areas:

- `Codex-Skills` source skills, plugin assembly, plugin-bundled hooks, build scripts, package metadata, or release flow;
- `AiCoding` platform integration, Marketplace, install/update/status/uninstall scripts, CodingKit assets, submodule locking, or new-machine setup;
- AGENTS boundaries, maintenance docs, generated output, package drift, external asset discovery, or hook trust behavior.

## Skill Type

This skill is both `consistent-workflow` and `organization-standard`.

- `consistent-workflow`: every maintenance task must follow the same authority, execution, verification, and release order.
- `organization-standard`: it encodes the user's AiCoding/Codex-Skills platform governance rules.

## Authority Chain

Agents must use this order of authority:

1. `AGENTS.md` and closest nested `AGENTS.md` define non-negotiable boundaries.
2. This maintenance skill defines the task workflow.
3. Repository docs define architecture and rationale.
4. `config/` and `scripts/` define the executable truth.
5. Git hooks, CI, and local verification decide whether the work can be considered complete.

If these layers disagree, stop and report the conflict before writing or publishing changes.

## Workflow Contract

Trigger: use this workflow for any Codex-Skills/AiCoding maintenance, extension, synchronization, install, update, rollback, packaging, hook, CI, or documentation-governance task.

Inputs: user request, current repository path, relevant `AGENTS.md`, architecture docs, `config/aicoding-plugin-pack.json`, `config/codex-kit.json`, scripts, submodule state, plugin package state, and Git status.

Steps:

1. Resolve repository role: `Codex-Skills`, `AiCoding`, or both.
2. Read applicable `AGENTS.md` files before editing.
3. Identify whether the target file is canonical source, generated output, platform integration, install state, or external asset.
4. Select the task mode: skill-source, external-skill-binding, plugin-package, hook-change, platform-integration, submodule-update, install-refresh, asset-extension, docs-only, release, or rollback.
5. Use the repository scripts and config as the source of executable truth.
6. Apply the smallest change that satisfies the task.
7. Run the required gate checks for the selected mode.
8. Update README/docs/CHANGELOG when durable behavior, install flow, packaging, or governance changes.
9. Only update AiCoding submodule after the Codex-Skills commit exists and has been verified.
10. Report actual verification results and any gates that remain manual.

Validation: run the selected mode gates, Markdown link validation, skill/plugin validators when applicable, repository Git hooks or hook-equivalent lint, and `git diff --check`.

Exit criteria: boundaries were respected, canonical source was changed instead of generated copies, package drift is resolved, submodule rules are respected, docs and CHANGELOG match behavior, and required gates pass or are explicitly marked as manual/not run.

## Repository Boundaries

### Codex-Skills Owns

- canonical skills under `embedded/`, `platform/`, and standalone root skill directories;
- declared external Skill submodules under `external/`, `.gitmodules`, and `config/external-skill-bindings.json`;
- `plugins/AiCoding/.codex-plugin/`, `plugins/AiCoding/hooks/`, and plugin assets;
- `config/aicoding-plugin-pack.json`;
- plugin build and verification scripts;
- plugin package documentation and release notes.

### AiCoding Owns

- `.agents/plugins/marketplace.json`;
- `config/codex-kit.json`;
- install, update, status, verify, and uninstall scripts;
- `CodingKit/examples/`, `CodingKit/modules/`, `CodingKit/platforms/`, `CodingKit/tests/`, and `CodingKit/tools/`;
- project-level `.githooks/` and platform integration docs;
- the `CodingKit/agents/skills` submodule gitlink.

### Generated Or Read-Only Areas

Do not manually edit:

- `plugins/AiCoding/skills/`;
- `plugins/AiCoding/BUILDINFO.json`;
- `CodingKit/agents/skills` from AiCoding scripts or AiCoding maintenance tasks, except to initialize, inspect, fetch, checkout an approved commit/tag, validate, and update the parent gitlink.

## External GitHub Skill Binding

All Skills sourced from GitHub must use the same chained Git dependency model as AiCoding and Codex-Skills:

```text
AiCoding gitlink -> Codex-Skills gitlink -> external Skill gitlink -> mapped SKILL.md directory
```

- Add the upstream repository as `external/<repository-name>` with a declared `.gitmodules` URL.
- Record the runtime name, submodule path, nested Skill path, URL, `latest-stable-tag` update policy, and stable-tag pattern in `config/external-skill-bindings.json`.
- When one upstream repository publishes multiple Skills, keep one shared gitlink and one binding entry per runtime Skill name.
- Resolve the highest non-prerelease semantic-version tag and pin that release commit through the gitlink; do not follow an unreleased branch head, copy, vendor, or silently refresh external Skill files.
- Use `scripts/manage-external-skills.ps1 -Action Sync` for a dry-run status/update plan and add `-Apply` only after review.
- Removing an external Skill must use the same lifecycle command. It always removes that binding; a shared `.gitmodules` section and gitlink remain until the final binding is removed. The paired AiCoding change removes the matching runtime registry mapping and managed junction.
- If the repository root lacks `SKILL.md`, map the real nested directory rather than treating the root as installable.
- Keep general-purpose external Skills standalone unless plugin packaging is separately approved.
- Commit and verify Codex-Skills before updating the AiCoding parent submodule.

## Mode Gates

### Skill-Source Change

Run in Codex-Skills:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-skills.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-plugin.ps1 -Plugin AiCoding -Configuration Development -Clean -Verify
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/compare-generated.ps1
```

Also run `aicoding-user-skill-creator` quick and gate validation for any changed standard/process skill.

### Plugin Package Change

Run in Codex-Skills:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/build-plugin.ps1 -Plugin AiCoding -Configuration Development -Clean -Verify
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/compare-generated.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-plugin.ps1
```

Official plugin validation should be run when the validator is available.

### External Skill Binding

Run in Codex-Skills:

```powershell
git submodule status --recursive
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/manage-external-skills.ps1 -Action Status
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-skills.ps1
git diff --check
```

`verify-skills.ps1` must fail when an `external/` directory is not a declared gitlink, a binding does not match `.gitmodules`, the gitlink is not at the latest locally available stable tag, the mapped `SKILL.md` is missing, or its frontmatter name differs from the declared runtime name.

### Hook Change

Run plugin validation plus hook-focused smoke tests. Confirm hooks:

- use `PLUGIN_ROOT` and `PLUGIN_DATA`;
- have bounded timeout;
- avoid personal absolute paths;
- fail safely;
- are described as auxiliary constraints, not a full security boundary.

After installation, user review through `/hooks` remains mandatory when hook definitions change.

### AiCoding Platform Change

Run in AiCoding:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/verify-codex-kit.ps1
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/install-codex-kit.ps1 -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/status-codex-kit.ps1 -Json
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/update-codex-kit.ps1 -DryRun
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/lint-git-governance.ps1 -Mode all
```

### Cross-Repository Update

Required order:

```text
Codex-Skills change
→ build and verify plugin
→ commit Codex-Skills
→ push when authorized
→ update AiCoding submodule to that commit
→ verify AiCoding
→ update AiCoding CHANGELOG
→ commit AiCoding
```

Never point AiCoding at uncommitted Codex-Skills files or a dirty submodule.

## Gate Rules

CLI checker:

- Codex-Skills gates are `scripts/verify-skills.ps1`, `scripts/build-plugin.ps1`, `scripts/compare-generated.ps1`, and `scripts/verify-plugin.ps1`.
- AiCoding gates are `scripts/verify-codex-kit.ps1`, `scripts/install-codex-kit.ps1 -DryRun`, `scripts/status-codex-kit.ps1 -Json`, `scripts/update-codex-kit.ps1 -DryRun`, and `scripts/lint-git-governance.ps1 -Mode all`.
- Markdown, skill, plugin, and `git diff --check` validators must return non-zero for blocking failures.

Hook gate:

- Git hooks enforce repository-local commit and changelog rules.
- Codex hooks are plugin-bundled lifecycle helpers and require `/hooks` review after definition changes.

MCP tool library:

- no MCP is required for the core maintenance workflow;
- MCP may be added later for long-running services or structured external tool access, but scripts/config remain the first executable truth for this kit.

Skip rationale:

- CI may be absent in early local-only work; when absent, local hooks, repository scripts, and explicit final verification replace CI until required checks are configured.
- MCP is skipped for the core workflow because repository-local scripts and config provide deterministic maintenance gates and practical alternatives.

Human confirmation:

- the user accepts AGENTS as hard boundaries, this skill as the workflow, docs as architecture, scripts/config as execution entrypoints, and Git hooks/CI as completion gates;
- destructive Git operations, hook trust decisions, release tags, GitHub Releases, and plugin cache manipulation still require explicit approval.

## Human Confirmation

Owner/confirmation: the user defined the desired maintenance chain as `AGENTS.md` boundaries, maintenance Skill workflow, architecture docs, config/scripts executable state, and CI/Git hooks completion gates.

Accepted gates: repository scripts, Skill validation, Plugin validation, generated-drift checks, Markdown validation, Git hooks, CI when available, and manual review for destructive operations, Hook trust, and release publishing.

Decision: approved as the maintained AiCoding/Codex-Skills operating model; future changes must update this skill or the AGENTS/docs chain when the process changes.

External GitHub Skill decision: the user explicitly requires every future GitHub-downloaded Skill to use the chained submodule URL-binding model. The creation gate may classify this as `skip` because it extends an existing organization standard instead of creating a new Skill; that result does not cancel the owner-approved policy update. External upstream frontmatter beyond the local strict validator remains a documented manual compatibility review and must not be rewritten in the read-only submodule.

## Prohibited Actions

Do not:

- edit generated plugin skills or `BUILDINFO.json` manually;
- rebuild the plugin from AiCoding or from the AiCoding submodule checkout;
- copy skill source into AiCoding;
- copy or vendor GitHub-sourced Skills into Codex-Skills instead of declaring an `external/` submodule and binding manifest entry;
- copy CodingKit asset directories into the plugin;
- include `obsidian-*` in AiCoding plugin;
- use hard-coded personal absolute paths;
- directly modify Codex plugin cache files;
- bypass hook trust or Git hooks without explicit approval;
- discard user changes or use destructive Git cleanup without explicit authorization.

## Completion Report

Report:

```text
Maintenance Result
- Repository roles touched:
- Mode:
- AGENTS checked:
- Canonical sources changed:
- Generated outputs rebuilt:
- Submodule updated:
- README/docs updated:
- CHANGELOG updated:
- Verification performed:
- Manual gates remaining:
- Git state:
```
