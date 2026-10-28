# Codex-Skills / AiCoding Architecture

## Architecture Diagram

<p align="center">
  <a href="assets/codex-skills-architecture-light.svg">
    <img src="assets/codex-skills-architecture-light.svg#gh-light-mode-only" alt="Codex-Skills landscape architecture Banner (light)" />
  </a>
  <a href="assets/codex-skills-architecture-dark.svg">
    <img src="assets/codex-skills-architecture-dark.svg#gh-dark-mode-only" alt="Codex-Skills landscape architecture Banner (dark)" />
  </a>
</p>

GitHub selects the light or dark SVG through its theme-only fragment markers. Mobile and remote README views reuse this same SVG pair, and each visible Banner links to its original. Both exports come from the canonical [Diagram IR](architecture/codex-skills-architecture.diagram.json); the editable [Visio VSDX](assets/codex-skills-architecture.vsdx) is retained for review.

## Repository Boundaries

`Codex-Skills` is the only source repository for maintained skills, plugin packaging, and Codex lifecycle hook source. `AiCoding` is the platform integration repository and new-machine entry point. It locks `Codex-Skills` through `CodingKit/agents/skills` as a Git submodule and must not copy or manually maintain skill source.

## Source And Generated Boundaries

Manual source:

- `embedded/`
- `platform/`
- `standalone/`
- `plugins/AiCoding/.codex-plugin/plugin.json`
- `plugins/AiCoding/hooks/`
- `plugins/AiCoding/README.md`
- `config/aicoding-plugin-pack.json`
- `scripts/*.ps1`

Motor-control sources form one nested kit under `embedded/motorcontrol/`. Its schema-v2 `skillkit.json` declares one `runtimeSkill`, `aicoding-motor-control`, plus 21 internal capabilities. Only the root `SKILL.md` and root UI metadata are registered; the internal entrypoints are `GUIDE.md` files in the existing Chinese category folders. The root skill routes to their relative paths and loads references only as needed. The global `config/aicoding-plugin-pack.json` selects the kit; `scripts/build-plugin.ps1` packages it into one runtime directory without flattening the internal capabilities. Shared contracts remain a single copy. BUILDINFO records hashes for both manifests, and source/package gates reject missing guides, nested `SKILL.md` files and old separate runtime entries.

Generated output:

- `plugins/AiCoding/skills/`
- `plugins/AiCoding/BUILDINFO.json`

Generated files are created by `scripts/build-plugin.ps1`. They must not be edited manually. The build writes `plugins/AiCoding/skills/.generated` as a local marker.

The embedded architecture skill at `embedded/architecture/`, exposed as `aicoding-architecture`, owns system responsibilities, module boundaries, stable dependencies, change propagation and platform adaptation. Embedded work involving modularization, platform design or adaptation, or decoupling must load this skill first. It supports design, review and incremental implementation through project-specific reasoning and proportionate verification; loading the entry does not require a full architecture review for every task.

MVP planning, behavior scenarios and documentation synchronization are independently usable skills. Each packages its own template or checklist under its local `references/` directory. The package does not require a separate SDD orchestrator, SDD skill or TDD fallback skill; the project and user request determine the development and test workflow.

The embedded architecture guidance fixes core ideas: clear responsibilities, business/hardware decoupling, controlled dependencies, explicit state ownership and lifecycle, and practical verification. APP/Service/Platform/Impl/Vendor and cfg/ctx/data/ops are reference organizations rather than mandatory layouts or universal acceptance conditions.

Skills preserve concepts, invariants and design reasoning. Reliable mechanical checks use existing compiler/lint/test tools; business-specific boundaries, representations and layering decisions remain contextual LLM judgments. Examples explain tradeoffs rather than prescribe universal structures.

Object-model design (对象模型设计) is an internal capability at `embedded/architecture/object-model-design/GUIDE.md`. It owns object responsibilities, identity, collaboration and lifecycle, including deciding whether unified management is worthwhile. Common object headers, managers and registries are optional representations.

Data-model design (数据模型设计) is an internal capability at `embedded/architecture/data-model-design/GUIDE.md`. It owns internal field semantics, types, ownership, storage, access, lifetime and data validity. cfg/ctx/data/ops provides vocabulary rather than a fixed layout. The architecture root is the only runtime Skill entry and selects either guide by the actual design question. Both capabilities retain their own references and evals, without child `SKILL.md` files or child UI metadata. The normal recursive build packages them inside `skills/aicoding-architecture/`; they have no separate flat runtime entries or kit manifest. Load only the guidance needed for the current task, without a mandatory sequence or repeated handoffs.

Engineering work must consider retaining App product flows, state machines, business rules, data models and recovery knowledge, alongside useful services, algorithms, tests and platform adapters. AM-012 supports object/data modeling; AM-013/DR-019 keep asset accumulation lightweight through existing code and records, minimal usage, verification entrypoints and applicable limits. No separate asset grading, ledger or second project is required.

## Local Standalone Skill Boundary

Locally maintained general-purpose Skills live under `standalone/<skill-name>/`. They are canonical source, but they are not bundled into the AiCoding plugin. AiCoding exposes only the approved runtime allowlist through individual user-level junctions; the repository root and the whole `standalone/` directory are never registered as Skill roots. `scripts/verify-skills.ps1` rejects canonical Skill entrypoints outside `embedded/`, `platform/`, `standalone/`, or declared `external/` sources and keeps the local standalone layout flat.

## External Standalone Skill Bindings

GitHub-sourced standalone Skills are URL-bound instead of copied. The dependency chain is:

```text
AiCoding
-> CodingKit/agents/skills (Codex-Skills submodule)
-> external/<repository> (upstream Skill repository submodule)
-> mapped directory containing SKILL.md
```

`.gitmodules` records the upstream repository URL, while `config/external-skill-bindings.json` records the runtime Skill name, real Skill subdirectory, and `latest-stable-tag` policy. One upstream repository may publish multiple Skills; those bindings share one gitlink and retain separate runtime names and nested Skill paths. `scripts/manage-external-skills.ps1 -Action Sync` fetches tags, selects the highest non-prerelease SemVer tag, and updates the gitlink only with `-Apply`. The gitlink still pins the selected release commit for reproducible clones. `scripts/verify-skills.ps1` rejects undeclared external directories, anonymous gitlinks, mismatched URLs, non-stable-tag gitlinks, missing mapped `SKILL.md` files, and frontmatter-name drift.

`scripts/manage-external-skills.ps1 -Action Remove -Name <name> -Apply` removes the selected binding. A shared `.gitmodules` section and gitlink remain while sibling bindings use the same submodule and are removed with the final binding. AiCoding removes the matching runtime registry entry and only deletes a user-level junction when its target exactly matches the registered source path.

External general-purpose Skills remain standalone and are not added to the AiCoding plugin unless plugin packaging is separately approved. AiCoding may expose them selectively through its standalone Skill profile by mapping the runtime name to the nested source path.

## BUILDINFO Model

`BUILDINFO.json` is intentionally non-self-referential. `sourceCommit` records the input `HEAD` used for the build before the generated `BUILDINFO.json` is committed. `BUILDINFO.json` is excluded from package digests, and `buildInfoModel` records this rule explicitly.

To avoid repeated-build drift, `buildTimestampUtc` uses the input commit time instead of wall-clock time. A repeated build with unchanged inputs must leave `git status` unchanged.

## Plugin Installation And Cache Refresh

Formal installation is through a Codex Marketplace entry, not by manually editing the Codex plugin cache. The development marketplace is `.agents/plugins/marketplace.json`; the AiCoding platform marketplace lives in `AiCoding/.agents/plugins/marketplace.json` and points at the submodule package path.

Codex may load plugins from an installed/cache copy. Updating the AiCoding submodule does not automatically refresh an already installed local plugin. The platform update flow must explicitly:

1. update the submodule;
2. verify the packaged plugin;
3. refresh or reinstall the plugin through supported Codex plugin surfaces when available;
4. re-check `/hooks` because changed plugin-bundled hooks require review/trust again.

Scripts must check whether the local Codex CLI supports plugin commands before invoking them. If the CLI is unavailable, scripts report the next manual `/plugins` step instead of editing cache directories directly.

## CodingKit Asset Discovery Protocol

Plugin skills and hooks do not copy `CodingKit/examples`, `CodingKit/modules`, `CodingKit/platforms`, `CodingKit/tests`, or `CodingKit/tools`. External assets are discovered by protocol:

1. prefer `AICODING_HOME` when explicitly set;
2. otherwise walk upward from the active repository `cwd` until `config/codex-kit.json` is found;
3. validate that the manifest contains `codingKitRoot` and that expected asset directories exist;
4. treat missing assets as capability unavailable, not as plugin failure.

AiCoding owns `config/codex-kit.json`. Codex-Skills only documents the protocol and may provide helpers later.

## Hook Boundary

Codex lifecycle hooks are auxiliary workflow constraints. They can remind, block, or route based on local repository state, but they are not a complete security boundary and must not be treated as a replacement for Git hooks, CI, branch protection, code review, or human release approval.

Plugin hooks must:

- use `PLUGIN_ROOT` and `PLUGIN_DATA` when accessing plugin-local or writable plugin state;
- avoid personal absolute paths;
- fail with clear JSON output;
- avoid modifying business source code;
- remain conservative when input JSON is missing or malformed.

## AiCoding Submodule Rule

AiCoding must not rebuild `plugins/AiCoding` inside `CodingKit/agents/skills`. The correct flow is:

```text
Codex-Skills: edit source -> build plugin -> verify -> commit -> push
AiCoding: update submodule -> verify/install -> commit platform pointer
```

This keeps submodule content reproducible and avoids dirty submodule working trees.
