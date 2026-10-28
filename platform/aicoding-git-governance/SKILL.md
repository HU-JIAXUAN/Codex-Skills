---
name: aicoding-git-governance
description: >
  Configurable Git, GitHub, documentation, version, tag, release, and firmware-governance workflow for embedded-first and general repositories. Use for branch, commit, push, pull request, merge, README, CHANGELOG,
  repository initialization, hook installation, version files, Git tags, GitHub Releases, release notes, firmware artifacts, test baselines,
  production baselines, customer deliveries, or requests such as "ref readme", "ref changelog",
  "ref release", "ref tag", and "ref branch". First resolve repository needs, then select and apply
  an appropriate profile instead of forcing one Linux, OpenAI, PX4, Git Flow, or README style.
---

# Git-Skill

## Purpose

Apply a selectable, repository-specific Git and release standard. This skill lives under `platform/aicoding-git-governance/` because Git governance is a cross-domain platform capability, while AiCoding packages it with embedded development workflows.

This skill combines mainstream engineering ideas without copying one project wholesale:

- Linux/Git: logical commits, clear motivation, reviewable history, trailers, backport awareness;
- GitHub: Pull Requests, branch protection, generated release notes, contributors, compare links;
- OpenAI/Codex: small routing file with references, assets, scripts, and explicit evaluation cases;
- mature firmware projects: compatibility, deprecations, migration, artifacts, checksums, baselines;
- strong README practices: navigable structure, relative links, external URLs, version and release links.

The skill must apply the user standard by default: Chinese-first bilingual README, file-level README_CN/README_EN switching, environment badges, canonical governance URL, typed commits, curated Release notes, and local lint gates. Repository-specific differences may extend this baseline, but must not silently weaken it.

## Skill Type

This skill is both `consistent-workflow` and `organization-standard`.

- `consistent-workflow`: repository initialization, commit, changelog, branch, hook, release, and push work must follow repeatable ordered steps.
- `organization-standard`: the workflow records the user's preferred Git governance standard for embedded-first development while staying reusable for general repositories.

## Workflow Contract

Trigger: use this workflow for Git repository initialization, branch policy, commit and CHANGELOG governance, hook/lint setup, README/CHANGELOG decisions, Tag/Release planning, firmware artifact governance, and push/PR/release operations.

Inputs: repository path, current Git state, user request, remote URL when applicable, repository governance config, README/CHANGELOG/version files, and any branch/environment constraints.

Steps:

1. Read repository policy and applicable references.
2. Inspect local and remote Git state.
3. Resolve only material decision questions.
4. Select branch, README, CHANGELOG, version, release, artifact, hook, and lint profiles.
5. Output the governance decision before write, commit, push, Tag, or Release actions.
6. Apply the smallest relevant file changes.
7. Run configured lint, hook-equivalent checks, markdown validators, and skill validators when modifying this skill.
8. Stage only selected files, commit with a typed subject, update CHANGELOG, and push only when authorized.
9. Report actual Git results and remaining work.

Validation: run repository lint or hook-equivalent checks, `scripts/validate_markdown_links.py` for README/CHANGELOG when applicable, `scripts/validate_release_notes.py` for releases, `git diff --check`, and `platform/aicoding-user-skill-creator/scripts/quick_validate.py` plus `platform/aicoding-user-skill-creator/scripts/skill_gate.py validate` when this skill changes.

Exit criteria: selected profiles are recorded, README and CHANGELOG decisions are applied, hook/lint checks pass or have a documented rationale, destructive operations are avoided unless explicitly approved, and the final report names the commit type and verification performed.
## Gate Rules

CLI checker:

- repository-specific lint command, such as `scripts/lint-git-governance.ps1`, must return non-zero when typed commits, CHANGELOG updates, README Chinese-link policy, README Git governance standard, Release typed-summary policy, governance files, or required hook checks fail;
- bundled validators include `scripts/validate_markdown_links.py` and `scripts/validate_release_notes.py` for README, CHANGELOG, and release-note checks;
- skill validation uses `platform/aicoding-user-skill-creator/scripts/quick_validate.py` and `platform/aicoding-user-skill-creator/scripts/skill_gate.py validate`.

Hook gate:

- repositories using this policy should configure `git config core.hooksPath .githooks`;
- `pre-commit` should call the repository lint command and require the configured CHANGELOG path when `changelog.mode = "unreleased"`;
- `commit-msg` should enforce `<type>(<scope>): <summary>` or a stricter configured pattern.

Codex Stop hook:

- Keep the plugin hook as an adapter to this Skill's `scripts/check_stop.py`; package the checker with the Skill instead of maintaining a second policy in the hook.
- Run the repository's `scripts/lint-git-governance.ps1 -Mode all` when present and use its result without an additional CHANGELOG format check.
- Without repository lint, read the local governance TOML and apply the configured CHANGELOG file, mode and typed-entry requirement. Accept both `**type**` and `**type(scope)**`; require `[Unreleased]` only for `mode = "unreleased"`.
- Do not fetch or execute Markdown standards at hook runtime. Regenerate the plugin when this checker changes; refreshing an installed plugin and reviewing `/hooks` are separate installation steps.

Skip rationale:

- no MCP gate is required for the core workflow because Git CLI plus repository-local hooks/lint provide deterministic checks; MCP remains optional for GitHub metadata and automation.
- CI gates are recommended but may be deferred for local-only or newly initialized repositories; when deferred, local hooks and explicit final verification replace CI until the repository enables it.

MCP tool library:

- no MCP is required for the core workflow; Git CLI and repository-local lint scripts are the canonical path;
- GitHub MCP or CLI may be used for PR, review, CI, release, and remote metadata when available.

Human confirmation:

- owner/confirmation: user confirmed this workflow should be named `Git-Skill`, serve embedded-first and general repositories, and encode typed commits, CHANGELOG entries, branch/environment rules, CLI lint, and hook management;
- manual review remains required for release notes, destructive Git actions, branch protection changes, and history rewriting.
## Human Confirmation

Owner/confirmation: the user confirmed that this workflow should be named `Git-Skill` and encode an embedded-first but generally reusable Git governance workflow.

Accepted gates: CLI lint, repository-local Git hooks, typed commit messages, mandatory CHANGELOG evaluation, branch/environment mapping, and manual review for release notes and destructive operations.

Manual review scope: release suitability, production baseline meaning, branch protection changes, generated contributor lists, firmware artifact compatibility, and any history rewrite remain human-approved decisions.

Decision: approved with the stated embedded-first scope and reusable Git governance boundary.
## Operating model

The workflow has four layers:

1. **Questions** — resolve what this repository actually needs.
2. **Profiles** — select branch, README, changelog, version, release, and artifact policies.
3. **Actions** — inspect, standardize, commit, merge, release, or package.
4. **Verification** — validate links, required sections, version consistency, and actual Git results.

## Step 1: Read repository policy

Read applicable files:

```text
AGENTS.md
AGENTS.override.md
CONTRIBUTING.md
README.md
README_CN.md
README.zh-CN.md
CHANGELOG.md
VERSION
VERSION.txt
version.h
docs/VERSION_RECORDS.md
.github/repository-governance.toml
.github/release.yml
.github/
firmware/
```

If `.github/repository-governance.toml` exists, use it as the repository's selectable-policy configuration.

This file is a convention used by this skill, not a built-in GitHub file.

If it does not exist:

- infer current practice from the repository;
- for ordinary work, propose a configuration but do not create one silently;
- when the user asks to establish or standardize policy, create it from
  `assets/REPOSITORY_GOVERNANCE_TEMPLATE.toml`, `assets/lint-git-governance.ps1`, and README/Release templates;
- replace or remove every unresolved placeholder before committing.

Repository-specific explicit rules override this skill when safe. Report conflicts before write or publish actions.

## Step 2: Inspect state

Use read-only checks appropriate to the task:

```bash
git rev-parse --show-toplevel
git status --short --branch
git branch -vv
git log --oneline --decorate --graph -15
git remote -v
git tag --sort=-version:refname
git diff --stat
git diff
git diff --cached
```

When remote freshness matters and network access is allowed:

```bash
git fetch --prune --tags
```

State when remote branch, contributor, PR, or Tag information may be stale.

## Step 3: Resolve the decision questions

Read `references/decision-questionnaire.md`.

Resolve only questions material to the request. Do not interrogate the user about values that can be determined from the repository.

Key decisions:

```text
repository audience
repository visibility
release consumers
branch/environment model
README profile and language, including Chinese-first README.md, README_CN.md, README_EN.md, badges, GitHub About, and canonical URL policy
CHANGELOG mode and bilingual entry policy
version scheme
Tag policy
Release Notes profile and bilingual Tag/Release language
release notes language
firmware artifact policy
automation level
permission boundary
```

If a missing answer would change a destructive or externally visible action, ask before acting.

## Step 4: Select profiles

Select one value for each applicable policy:

```text
branch.profile
readme.profile
changelog.mode
version.scheme
release.profile
release.notes_mode
firmware.storage
```

Profiles are defined in `references/profile-catalog.md`.

Use `existing-custom` when the repository already has a sound model that does not match a supplied profile.

Profiles are composable. For example:

```text
branch.profile = github-flow-lite
readme.profile = open-source-firmware
changelog.mode = unreleased
release.profile = firmware-minor
firmware.storage = github-release
```

Do not add unused long-lived branches, README sections, changelog categories, or release sections.
### Standard branch, environment, and commit taxonomy

AiCoding-governed repositories should document this policy in README or an equivalent governance file:

- `main` or `master`: stable production branch; do not edit code directly except approved release or hotfix integration.
- `develop`: DEV integration branch for accepted development work.
- `feature/<scope>`: feature branch created from `develop`; use lowercase descriptive names such as `feature/user-module`.
- `test`: FAT branch when a shared functional acceptance test environment exists.
- `release/<version>`: UAT/pre-production branch for release hardening; merge tested changes into it instead of developing directly on it.
- `hotfix/<scope>`: urgent production fix branch created from `main`; merge back to `main` and `develop`.
- Environment mapping: `DEV` for developer debugging, `FAT` for functional acceptance testing, `UAT` for user acceptance/pre-production, and `PRO` for production.
- Commit types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, and `chore` are the default taxonomy; repository-specific additions must be documented.
- Single commit rule: one category, no more than three tightly related topics, and a typed subject.

## Step 5: Classify the primary mode

Choose one:

```text
inspect
quick-ref
standardize
commit
push
pull-request
merge
release
hotfix
firmware-package
```

Read `references/task-modes.md` for the selected mode.

### Quick Ref commands

Treat these forms as quick-reference requests:

```text
ref readme [profile]
ref changelog [mode]
ref commit
ref branch [profile]
ref tag
ref release [profile]
ref firmware
ref links
```

For a Quick Ref request:

- remain read-only unless the user also asks to apply it;
- load only the named reference;
- show the decision rules, minimal checklist, and relevant asset;
- do not dump every policy file;
- offer the exact path or command needed to apply the profile.

Quick Ref routing is in `references/quick-ref-index.md`.

## Step 6: Output the governance decision

Before write actions, output:

```text
Git Governance Decision
- Mode:
- Branch profile:
- README profile:
- CHANGELOG mode and bilingual entry policy:
- Version scheme:
- Release profile:
- Release language:
- Artifact storage:
- Current branch:
- Source branch:
- Target branch:
- README:
- README LINKS:
- CHANGELOG:
- VERSION:
- VERSION RECORD:
- COMMIT:
- PUSH:
- PULL REQUEST:
- MERGE:
- BACK-MERGE:
- TAG:
- TAG PUSH:
- RELEASE NOTES:
- FIRMWARE PACKAGE:
- GITHUB RELEASE:
- Reason:
```

Use:

```text
REQUIRED
NOT REQUIRED
RELEASE ONLY
PROPOSE
BLOCKED
NOT APPLICABLE
```

Do not omit README, CHANGELOG, version, Tag, or Release decisions merely because the user did not mention them.

## Step 7: Respect separate permissions

Treat these independently:

```text
edit files
stage
commit
push branch
create PR
merge
create Tag
push Tag
create GitHub Release
upload assets
```

Examples:

- “提交修改” authorizes commit, not push, merge, Tag, or Release.
- “提交并推送” authorizes commit and branch push, not merge or Tag.
- “创建 Tag” does not authorize pushing it.
- “发布版本” selects release mode but remains subject to repository approval rules.

## Step 8: Apply only relevant references

| Need | Reference |
|---|---|
| resolve requirements | `references/decision-questionnaire.md` |
| choose profiles | `references/profile-catalog.md` |
| task actions | `references/task-modes.md` |
| repository initialization | `references/repository-initialization.md` |
| branch/merge | `references/branch-policy.md` |
| README/links | `references/readme-policy.md` |
| commit/changelog | `references/commit-changelog-policy.md` |
| version/Tag/Release | `references/release-tag-policy.md` |
| firmware artifacts | `references/firmware-policy.md` |
| quick reference | `references/quick-ref-index.md` |
| behavior tests | `references/eval-cases.md` |

Do not load every reference by default.

## Commit governance gate

For every commit managed by this skill, classify the commit before staging or committing.

Allowed commit types:

```text
feat     user-visible feature or capability
fix      bug fix
docs     documentation-only change
style    formatting or whitespace change with no meaning change
refactor code restructuring without feature or bug-fix intent
perf     performance improvement
test     test addition or correction
build    build system or dependency change
ci       CI or automation workflow change
chore    repository maintenance, tooling, hooks, or auxiliary files
```

Rules:

- each commit must have one primary type;
- one commit should contain one logical purpose and no more than three tightly related change topics;
- the commit subject should use `<type>(<scope>): <summary>` when the repository has no stricter convention;
- `CHANGELOG.md` must be evaluated for every commit;
- when `changelog.mode = "unreleased"`, every non-release commit must update `[Unreleased]` with entries that explicitly name the commit type, for example `- **docs**: ...`;
- if a commit is intentionally not user-notable, record the type and reason in the changelog or in the repository's configured release-note exclusion mechanism;
- repository lint and Git hooks must enforce the typed commit subject and required CHANGELOG update whenever the repository has hooks enabled.

Before committing, run the repository's configured lint or hook-equivalent checks. Do not bypass hooks unless the user explicitly approves the bypass and the completion report names the skipped check.
## Core defaults

For an ordinary development commit:

```text
VERSION: RELEASE ONLY
VERSION RECORD: RELEASE ONLY
TAG: NOT REQUIRED
TAG PUSH: NOT REQUIRED
RELEASE NOTES: NOT REQUIRED
FIRMWARE PACKAGE: RELEASE ONLY
GITHUB RELEASE: NOT REQUIRED
```

README and CHANGELOG must still be evaluated.

For repository initialization or first binding to a remote, read `references/repository-initialization.md` and configure repository-local hooks with `git config core.hooksPath .githooks` before the first normal commit whenever hooks are part of the selected policy.

### README changes are normally required when

- project purpose, audience, support scope, or status changes;
- setup, build, usage, programming, upgrade, or download instructions change;
- repository navigation or documentation locations change;
- stable-release, issue, contribution, security, or license links change.

README is normally not changed for an internal bug fix with no effect on project entry or usage.

README must describe current, durable repository identity, navigation, and usage. Do not add dated diff summaries, raw release notes, or changelog-style change lists to README. Put change summaries in CHANGELOG during development, and in Tag/GitHub Release notes for formal releases.

### CHANGELOG changes are normally required when

- users, testers, integrators, operators, production, or customers need to know;
- behavior, defaults, compatibility, procedures, deprecations, removals, security, packaging, or notable limitations change.

Do not copy raw `git log` into CHANGELOG.


### Bilingual documentation default

For AiCoding-governed repositories, durable Git documentation is Chinese-first and bilingual by default:

- `README.md` is the GitHub default entry and must be Chinese-first.
- `README_CN.md` is the explicit Chinese file-level entry for language switching and GitHub About/Homepage links.
- `README_EN.md` is the explicit English file-level entry.
- `README.md` must include visible top-of-file links to both `README_CN.md` and `README_EN.md`.
- `README.md` must keep environment badges with explicit URLs, including Release, PowerShell, Python, and License by default; add repository-specific tool badges when applicable.
- `.github/repository-governance.toml` must include `[governance_standard]` pointing to the canonical standard URL and raw URL.
- `CHANGELOG.md` entries should include Chinese-first text plus concise English meaning for externally visible changes.
- Annotated Tag messages stay short but bilingual when the repository is Chinese-first or mixed-language, for example `Release v2026.06.26 / 发布 v2026.06.26`.
- GitHub Release notes should use bilingual headings and Chinese-first content unless the repository policy explicitly selects English-only.
### Release language

GitHub Release notes support Chinese, English, or bilingual content.

- Infer the default from the repository's README and CHANGELOG language.
- For Chinese-first repositories, default to Chinese.
- For the first GitHub Release in a repository, ask for the release language when the user has not specified it; present Chinese as the default.
- If bilingual notes are selected, write Chinese first and keep the canonical English section name after a slash, for example `摘要 / Summary`, so tooling can still validate required sections.
- Do not silently publish English-only release notes for a Chinese-first repository.
### Tag and Release
A Tag identifies one commit. A GitHub Release presents detailed notes and assets for a Tag.

If `GITHUB RELEASE` is `REQUIRED`, then `RELEASE NOTES` is also `REQUIRED`. Do not downgrade a GitHub Release to `TAG MESSAGE ONLY`; the release body must be curated before publishing or editing.

Keep annotated Tag messages short:

```text
Release v1.2.0 / 发布 v1.2.0
```

Place detailed content in Release Notes.
Release Notes must include a typed commit summary for the full release range. Group all included commits under headings such as `feat`, `fix`, `docs`, `build`, `ci`, `chore`, `test`, `refactor`, `perf`, and `style`; omit empty groups only after checking the actual commit list. State the primary release type and then describe the concrete changes and impact.

Formal Release Notes normally include:

```text
Summary
What's Changed
Compatibility
Deprecations
Release Notes
Full Changelog
New Contributors
Known Issues
Traceability
```

Selectively include:

```text
Highlights / Major Changes
Deprecations
Breaking Changes / Migration
New Contributors
Assets / Checksums
Upgrade / Programming
Rollback
Security
```

For configured minor/major/formal firmware releases, make `Deprecations` explicit. Write `None` when there are no deprecations.

For any GitHub Release, include explicit `Deprecations` and `New Contributors` headings. If they do not apply, write `None`. Never publish a GitHub Release body that contains only `Summary` or a generated stub.

Derive `New Contributors` from real PR/contributor data. Never invent it.

Generated GitHub notes are a draft source for merged PRs, contributors, and compare links. Curate them and add compatibility, deprecation, migration, known-issue, and firmware information as needed.

## Standardization tools

### Create a repository policy

Copy and fill:

```text
assets/REPOSITORY_GOVERNANCE_TEMPLATE.toml -> .github/repository-governance.toml
assets/lint-git-governance.ps1 -> scripts/lint-git-governance.ps1
scripts/validate_readme_governance.py -> scripts/validate_readme_governance.py
```

The README validator is required only when an optional `[readme.*]` portable profile is declared.
Repositories with an older TOML that has none of those sections keep the existing lint path.

### Render selected templates

```bash
python scripts/render_governance_templates.py \
  --config .github/repository-governance.toml \
  --output-dir .
```

The script creates only files enabled by the configuration and refuses to overwrite existing files unless `--force` is supplied.

### Validate Markdown

```bash
python scripts/validate_markdown_links.py README.md CHANGELOG.md
```

### Validate a Release Notes draft

```bash
python scripts/validate_release_notes.py \
  --config .github/repository-governance.toml \
  RELEASE_NOTES.md
```

Scripts do not replace review. They only make selected standards reproducible.

## Safety

Never do these without explicit authorization and a recovery explanation:

```bash
git reset --hard
git clean -fd
git clean -fdx
git push --force
git push --force-with-lease
git branch -D
git tag -d
git push origin --delete <branch>
git push origin :refs/tags/<tag>
git rebase <shared-branch>
git commit --amend
```

Also:

- do not discard user changes;
- do not rewrite shared history;
- do not move a published Tag;
- do not bypass branch protection;
- do not use `git push --tags` as the default;
- do not publish unresolved template placeholders;
- do not invent contributors, tests, compatibility, or release status;
- do not commit private signing keys, credentials, or secrets.

## Completion report

After acting, report actual results:

```text
Git Result
- Profiles selected:
- README created/updated:
- README links validated:
- CHANGELOG updated:
- VERSION updated:
- VERSION RECORD updated:
- Commit created:
- Branch pushed:
- Pull request created:
- Merge completed:
- Back-merge completed:
- Tag created:
- Tag pushed:
- Release Notes created:
- Firmware package updated:
- GitHub Release created:
- Verification performed:
- Remaining work:
```

## Definition of done

Applicable items must be true:

- repository rules and required questions were resolved;
- profiles were selected and recorded;
- only relevant sections and files were created;
- local Markdown links and placeholders were validated;
- CHANGELOG decision was applied;
- Tag and Release remained distinct;
- Release Notes met the selected profile;
- contributor and compare information came from real data;
- only authorized operations were executed;
- blockers and remaining work were reported.
