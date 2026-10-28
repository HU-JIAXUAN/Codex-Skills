# AiCoding Git Governance Standard

Standard ID: `aicoding-git-governance`
Standard version: `2026.07.22`
Canonical source: https://github.com/JiaxI2/Codex-Skills/blob/main/platform/aicoding-git-governance/references/aicoding-git-governance-standard.md
Raw source: https://raw.githubusercontent.com/JiaxI2/Codex-Skills/main/platform/aicoding-git-governance/references/aicoding-git-governance-standard.md

## Repository Policy Contract

Every AiCoding-governed repository must keep `.github/repository-governance.toml` as the local policy instance and must include a `[governance_standard]` section pointing back to this canonical standard.

Required fields:

```toml
[governance_standard]
id = "aicoding-git-governance"
version = "2026.07.22"
source_url = "https://github.com/JiaxI2/Codex-Skills/blob/main/platform/aicoding-git-governance/references/aicoding-git-governance-standard.md"
raw_url = "https://raw.githubusercontent.com/JiaxI2/Codex-Skills/main/platform/aicoding-git-governance/references/aicoding-git-governance-standard.md"
sync_policy = "track-canonical-url"
```

Repositories may pin a version for a release branch, but normal active repositories should track the canonical URL and update local lint/templates when the standard changes.

## README Standard

Default README governance for the user's repositories is Chinese-first and bilingual:

- `README.md` is the GitHub default entry and must be Chinese-first. English text may appear after a slash in headings.
- `README_CN.md` is the Chinese file-level entry for explicit language switching and GitHub About/Homepage links.
- `README_EN.md` is the English file-level entry.
- The top of `README.md` must include visible links to `README_CN.md` and `README_EN.md`.
- `README.md` must keep an environment badge preview near the top.
- Required baseline badges: latest Release, PowerShell, Python, and License.
- Add repository-specific badges such as Go, Taskfile, CMake, MATLAB, or toolchain badges when those tools are part of the default workflow.
- Badge links must use explicit HTTPS URLs to the tool or GitHub resource.
- README content must describe current durable repository identity and navigation. Dated diff summaries belong in `CHANGELOG.md`, annotated Tag messages, or GitHub Release notes, not README.

### Portable README profiles

The baseline stays backward compatible: a repository that does not declare any of the optional
`[readme.*]` profile sections keeps its existing lint result. New repositories may opt into the
following portable contracts. Stable semantic markers such as
`<!-- governance:section:quick-start -->` identify a section without binding the standard to a
Chinese or English heading.

- **30 seconds / 3 minutes / persona**: the first screen states one user outcome; Quick Start has
  at most three copyable steps, an expected result, and a doctor/troubleshooting entry; persona
  rows link to authoritative detail instead of expanding it in the README.
- **Badge projection**: badges describe only the real default technology stack, change with that
  stack, and bind displayed versions to a repository-owned source adapter. Language badges use
  brand colors, toolchains neutral colors, first-party capabilities a product color, and status
  badges semantic colors. Badge and target URLs use HTTPS, and bilingual files keep the same badge
  block. No arbitrary badge-count limit is imposed.
- **Capability showcase**: each enabled capability has exactly one line, one user outcome, and one
  HTTPS detail URL. A repository-owned adapter supplies enabled capability identities; the standard
  does not prescribe a registry shape. Missing and ghost entries both fail when the profile is
  enabled.
- **Regenerable banner**: public/product profiles may declare light and dark SVG outputs generated
  from one diffable source. README references use `#gh-light-mode-only` and
  `#gh-dark-mode-only`; unresolved placeholders and missing source/output files fail. Private and
  minimal profiles may leave the banner disabled.
- **Architecture graph**: an enabled graph uses GitHub-native Mermaid, no more than 20 explicit
  nodes, and layered `subgraph` groups. A graph that represents a loop contains a real back edge.
  Command labels use `cmd:<command>` and are checked against a repository-owned command adapter.
- **Four-quadrant evolution view**: `known-known`, `known-unknown`, `unknown-known`, and
  `unknown-unknown` form a reusable empty table whose rows name the durable asset produced by each
  quadrant. The table may live in README or a vision document. `recommended` emits a warning when
  absent, `required` fails, and `off` disables the check.
- **Star History**: public profiles may use an HTTPS page link, or an anonymous chart only after its
  endpoint has been tested. `sealed_token`, `token`, `credential`, and `auth` query parameters fail
  closed. Private repositories and profiles that do not need it use `off`.

The optional adapter contract is process-based and repository-neutral. The configured executable
receives `-Contract badges`, `-Contract capabilities`, or `-Contract commands`, plus `-RepoRoot`,
and returns JSON. This allows a Go module list, service catalog, or another repository-owned source
to drive the same checks without depending on AiCoding internals.

Supported semantic values for `readme.required_sections` include `value-proposition`, `status`,
`quick-start`, `personas`, `repository-navigation`, `git-workflow`, `capabilities`, and `evolution`.
Repositories using the portable structure profile mark enabled values with
`<!-- governance:section:<value> -->`.

An empty four-quadrant starting point is:

| Semantic marker | Repository knowledge | Durable asset |
|---|---|---|
| `known-known` | Confirmed and repeatable | Baseline, contract, or regression test |
| `known-unknown` | Named gap or question | Plan, experiment, or acceptance criterion |
| `unknown-known` | Tacit capability being surfaced | Guide, adapter, or reusable example |
| `unknown-unknown` | Unexplored risk | Probe, incident evidence, or discovery backlog |

## GitHub About Standard

Repositories should expose bilingual metadata:

- `.github/repository-governance.toml` should include `[github_about]`.
- `require_bilingual = true` is the default.
- `homepage` should point to the Chinese-first README entry, usually `README_CN.md` or the default `README.md` when `README.md` is Chinese-first.
- Topics should describe stable repository purpose, not temporary implementation details.

## Branch and Commit Standard

- `main` or `master`: stable production branch.
- `develop`: DEV integration branch when a separate integration branch exists.
- `feature/<scope>`: feature branch.
- `test` or `test/<scope>`: FAT or shared test work.
- `release/<version>`: UAT or pre-production hardening.
- `hotfix/<scope>`: urgent production fix from stable branch.
- Standard commit types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`.
- A commit should contain one category of change and no more than three tightly related topics.

## CHANGELOG Standard

- Evaluate `CHANGELOG.md` for every normal commit.
- Entries should be Chinese-first with concise English meaning for externally visible changes.
- Do not paste raw `git log` into CHANGELOG.
- Diff summaries are permitted in CHANGELOG and Release notes, not README.
- Typed labels may include a scope: `**refactor(recorder)**` and `**refactor**` are both valid. Require `[Unreleased]` only when the repository selects `changelog.mode = "unreleased"`.

## Tag and GitHub Release Standard

- Tag identifies one commit; GitHub Release contains curated notes.
- Annotated tag messages should be short and bilingual when the repository is Chinese-first.
- GitHub Release notes must be curated, not a stub.
- Required release headings: Summary, What's Changed, Compatibility, Deprecations, Release Notes, Full Changelog, New Contributors, Known Issues, Traceability.
- Chinese-first releases should use bilingual headings such as `摘要 / Summary` while preserving canonical English names.
- `Deprecations` and `New Contributors` must be explicit. Write `None` when not applicable.
- New Contributors must come from real contributor data. Never invent contributors.

## Local Gate Standard

Each repository should keep local hook-equivalent checks:

- `.githooks/pre-commit` calls the configured governance lint.
- `.githooks/commit-msg` enforces typed commit subjects.
- The lint must check README language switching, required badges, canonical governance URL, CHANGELOG typing, release-note policy, placeholders, and markdown links when configured.
- Codex Stop hooks must use the Git Skill's packaged checker. Delegate only to an explicit `[automation] stop_lint_mode = "working-tree"` and a read-only `-Mode working-tree` checker; never run `all` or commit/push modes at Stop. Without opt-in, check configured CHANGELOG format only. Enforce update/staging requirements at Git pre-commit, not on dirty or partially staged work at the end of a turn. Update checks through plugin build and installation rather than fetching or executing the standard at runtime.
