---
name: aicoding-documentation-synchronization
description: Keep project requirements, behavior scenarios, API, architecture, README, changelog, test, release, and embedded documentation synchronized with relevant changes; use the project's hooks and CI when available.
---

# AiCoding Documentation Synchronization
## Skill Type

This skill is both consistent-workflow and organization-standard.

- consistent-workflow: it defines a repeatable process for reviewing documentation impact and updating affected project records.
- organization-standard: it records AiCoding expectations for keeping implementation, documentation, and validation evidence consistent.

## Workflow Contract

Trigger: use this skill when a change may affect documented behavior, interfaces, architecture, configuration, tests, builds, releases, installation, or generated exposure.

Inputs: user request, repository AGENTS instructions, the actual change and git state, affected requirements and project documentation, validation evidence, and available documentation checks.

Steps: inspect the actual change, identify affected documentation, update the existing records needed to reflect the change, run available documentation and project checks, and explain any no-documentation-change decision.

Exit criteria: affected documentation matches the implementation and validation evidence, available checks pass, and any decision to leave documentation unchanged has a concrete justification.

Validation: use repository tests, build checks, lint, skill validators, plugin validators, documentation sync checks, and manual review according to the local project.

Blocking hook: AiCoding platform repositories should wire scripts/check-documentation-sync.ps1 into pre-commit and CI so code/config/platform changes cannot finish without documentation review.

## Gate Rules

CLI checker: scripts/check-documentation-sync.ps1 -Mode all is the default documentation sync command when the AiCoding platform docs-sync files are installed; project-specific build, test, lint, and skill validation commands remain authoritative for code and Skill changes.

Hook gate: use .githooks/pre-commit and CI required checks to run docs-sync and repository governance gates before commit or merge; when hooks are not installed, run the CLI checker manually and report that hook enforcement is not active.

MCP tool library: no MCP is required for this workflow because repository-local scripts, tests, and docs provide deterministic gates; MCP tools may be added later for project discovery or long-running diagnostics, with the CLI/manual path remaining the fallback.

Human confirmation: owner/confirmation is the AiCoding maintainer or user integrating this workflow; accepted gates are CLI validation, pre-commit hook, CI docs-sync, repository tests, and manual review for requirements, architecture, release, and documentation judgment.

Skip rationale: skip only gates that are not available in the active repository, and replace them with an explicit manual review note or a project-specific command in the final report.
## Human Confirmation

Owner/confirmation: the AiCoding maintainer or user integrating this skill owns documentation adequacy and accepts its independent use with the project's existing records and validation process.

Accepted gates: CLI validation, pre-commit hook, CI docs-sync, repository tests, plugin/skill validators, and manual review for requirements, architecture, release, and documentation judgment.

Manual review scope: product intent, MVP tradeoffs, architecture approval, behavior completeness, release readiness, and documentation adequacy remain human-reviewed when they cannot be reliably linted.

Decision: approved for AiCoding integration with the stated gates and manual review boundaries.

Use this skill before finishing any task that changes code, behavior, architecture, interfaces, protocols, configuration, tests, build, release, installation, hooks, or generated plugin exposure.

## Principle

Documentation synchronization is not optional. Docs are part of the implementation contract.

This skill tells the agent what to update. The repository hook and CI gate enforce that relevant documentation updates are present.

## Change-to-document mapping

Review the affected records below and update those needed to reflect the change. Use the project's existing requirements and design records; the list does not require creating every document type.

### Functional behavior change

Update:

- target behavior and requirements in the project's specification or existing requirements record;
- BDD scenarios;
- README or usage docs;
- test plan or validation evidence;
- CHANGELOG when user-visible or release-relevant.

### API / interface / protocol change

Update:

- interface contract in the project's existing specification or API record;
- API docs or header comments;
- README examples;
- compatibility notes;
- CHANGELOG.

### Architecture change

Update:

- architecture impact in the project's existing requirements or design record;
- PDR / ADR;
- architecture diagram or module boundary notes;
- dependency rules;
- migration / rollback notes.

### Configuration / build / install change

Update:

- config documentation;
- install/update/status docs;
- CI or verification docs;
- AGENTS.md if agent workflow changes.

### Test / CI change

Update:

- test strategy;
- validation command list;
- coverage expectation;
- CI documentation.

### Embedded / firmware change

Update when relevant:

- memory map;
- linker command notes;
- boot flow;
- OTA / rollback behavior;
- watchdog and power-loss assumptions;
- SIL/PIL/HIL plan;
- hardware binding notes.

## Same-commit / same-PR rule

If code and docs both need changes, they must be submitted in the same branch and preferably the same commit or PR.

## No-doc-change justification

If the agent determines documentation does not need to change, it must state why.

Acceptable examples:

- purely internal formatting change;
- no behavior, interface, architecture, configuration, test, build, or release impact;
- generated file only and source docs already describe generation behavior.

## Hook integration

When the hook package is installed, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-documentation-sync.ps1 -Mode pre-commit -Staged
powershell -NoProfile -ExecutionPolicy Bypass -File scripts/check-documentation-sync.ps1 -Mode all
```

Use the [documentation synchronization checklist](references/documentation-sync-checklist.md) to select documentation affected by the change.
