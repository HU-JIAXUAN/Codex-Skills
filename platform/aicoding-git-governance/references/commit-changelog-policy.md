# Commit and CHANGELOG Policy

## Commit style

Use the repository's existing convention. Without one, choose a simple style such as:

```text
<area>: <imperative summary>
```

or:

```text
<type>(<scope>): <imperative summary>
```

The message must explain motivation and effect. For bug fixes, link the introducing commit when known.

## Typed commit taxonomy

Use Conventional Commit-style types unless the repository defines a stricter local taxonomy:

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

Every commit must choose one primary type. Keep a commit to one logical purpose and no more than three tightly related change topics.

## Mandatory CHANGELOG linkage

For repositories using `changelog.mode = "unreleased"`, every non-release commit must stage a CHANGELOG update unless the repository policy defines a specific exclusion mechanism. The changelog entry must explicitly name the commit type:

```markdown
- **docs**: Add repository usage and submodule initialization instructions.
- **chore**: Install Git hooks that enforce typed commits and changelog updates.
- **refactor(recorder)**: Publish completed capture blocks for the application to consume.
```

The scope is optional in a typed CHANGELOG label. Both `**refactor**` and
`**refactor(recorder)**` explicitly identify the same commit type. A Codex hook must
accept the repository lint's decision instead of imposing a second label format.

For commits that are not user-notable, write the type and exclusion reason in the configured changelog or release-note exclusion path instead of silently omitting it.

## Hook and lint enforcement

Repositories with hook management enabled should enforce:

- commit message subject matches `<type>(<scope>): <summary>` or the configured stricter pattern;
- staged changes include the configured CHANGELOG file for every normal commit;
- required README, CHANGELOG, governance, and release-note files have no unresolved placeholders;
- repository-specific Markdown or release-note validators pass.

Do not use `--no-verify` unless explicitly approved. If a hook is bypassed, report the skipped check and reason.

The plugin Stop adapter loads this Skill's `scripts/check_stop.py` from the installed
plugin. That checker delegates to repository lint when available; its fallback reads
the repository's CHANGELOG configuration. Update and validate the canonical checker,
rebuild the plugin, then refresh installation through the supported plugin workflow.
Do not patch cache copies or interpret the online standard during a hook invocation.

## Single-commit discipline

A single commit should follow these rules:

1. The commit has one primary type from the taxonomy above.
2. The commit contains no more than three tightly related issue topics.
3. If the staged change does not match the intended type, stop and split or restage before committing.
4. If the local unpublished commit message is wrong, use `git commit --amend` after reviewing the staged diff.
5. If the commit was already pushed, prefer a follow-up corrective commit instead of rewriting shared history.

`git reset --hard` is destructive and is not a default fix for a bad commit. Use it only when the user explicitly authorizes the operation and the recovery impact is clear.

## Atomicity

One commit represents one logical purpose. Include required test, documentation, and changelog changes for that purpose.

Avoid unrelated formatting, generated files, and another feature.

## CHANGELOG modes

### unreleased

Add notable changes to `[Unreleased]` during development.

### fragments

Create the configured fragment and aggregate at release.

### release-only

Record release-note eligibility in the PR; edit the main changelog in release mode.

### generated

Generate a draft from PR metadata and curate it.

## Categories

Core categories:

```text
Added
Changed
Deprecated
Removed
Fixed
Security
```

Optional categories:

```text
Compatibility
Build
Documentation
Firmware
Known Issues
```

Keep only useful categories.

## Compare links

Recommended:

```markdown
[Unreleased]: https://github.com/OWNER/REPO/compare/v1.1.0...HEAD
[1.1.0]: https://github.com/OWNER/REPO/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/OWNER/REPO/releases/tag/v1.0.0
```

## Bilingual CHANGELOG policy

For AiCoding-governed repositories, write externally visible CHANGELOG entries in Chinese first with concise English meaning in the same bullet or the next sentence. The entry must still name the commit type.

Recommended form:

```markdown
- **feat**: 新增 standalone skill 清单和 profile 安装规则；add standalone skill registry and profile installation rules.
- **fix**: 修复 BUILDINFO 非自引用漂移误报；fix false drift detection for non-self-referential BUILDINFO metadata.
```

Purely internal repositories may choose one language only, but the repository policy must say so explicitly.

## Entry style

Write effect and impact:

```markdown
- Preserve the reported firmware version after an upgrade ([#123](...)).
```

Do not write:

```markdown
- Modified app.c.
- Updated code.
- Merged branch.
```

## Normal inclusion

- externally meaningful feature;
- released-behavior fix;
- default/compatibility/procedure change;
- deprecation/removal/security;
- artifact naming or delivery change;
- notable known limitation.

## Normal exclusion

- internal refactor with unchanged external behavior;
- formatting;
- typo-only comments;
- merge-only changes;
- internal test cleanup.

## Standard commit taxonomy

- `feat`: add functionality.
- `fix`: repair a bug.
- `docs`: documentation-only change.
- `style`: formatting, whitespace, missing semicolons, or similar changes with no semantic impact.
- `refactor`: code change that neither fixes a bug nor adds a feature.
- `perf`: performance improvement.
- `test`: add missing tests or correct existing tests.
- `chore`: build process, auxiliary tools, libraries, or maintenance files.

Single commits should contain one category of change and no more than three tightly related topics. If a commit is wrong after creation, prefer an explicit corrective commit unless the user has authorized history rewriting.
