---
name: aicoding-behavior-driven-development
description: Convert requirements and agreed scope into BDD behavior scenarios, acceptance criteria, examples, edge cases, and regression obligations that map to the project's tests.
---

# AiCoding BDD: Behavior-Driven Development
## Skill Type

This skill is both consistent-workflow and organization-standard.

- consistent-workflow: it defines a repeatable process for expressing requirements as observable behavior scenarios.
- organization-standard: it records AiCoding scenario coverage and traceability expectations for project tests.

## Workflow Contract

Trigger: use this skill when requirements need observable acceptance scenarios, edge cases, or regression obligations before implementation or test design.

Inputs: user request, repository AGENTS instructions, agreed requirements and scope, existing behavior and tests, relevant architecture constraints, and project verification commands.

Steps: read the requirements and existing behavior, write Given/When/Then scenarios for the agreed scope, cover relevant boundaries and failures, and map each scenario to an appropriate project test or verification obligation.

Exit criteria: scenarios describe observable results, cover the relevant behavior and risks, and map to project verification obligations; executing those checks is required only when implementation or validation is part of the task.

Validation: use repository tests, build checks, lint, skill validators, plugin validators, documentation sync checks, and manual review according to the local project.

Blocking hook: AiCoding platform repositories should wire scripts/check-documentation-sync.ps1 into pre-commit and CI so code/config/platform changes cannot finish without documentation review.

## Gate Rules

CLI checker: scripts/check-documentation-sync.ps1 -Mode all is the default documentation sync command when the AiCoding platform docs-sync files are installed; project-specific build, test, lint, and skill validation commands remain authoritative for code and Skill changes.

Hook gate: use .githooks/pre-commit and CI required checks to run docs-sync and repository governance gates before commit or merge; when hooks are not installed, run the CLI checker manually and report that hook enforcement is not active.

MCP tool library: no MCP is required for this workflow because repository-local scripts, tests, and docs provide deterministic gates; MCP tools may be added later for project discovery or long-running diagnostics, with the CLI/manual path remaining the fallback.

Human confirmation: owner/confirmation is the AiCoding maintainer or user integrating this workflow; accepted gates are CLI validation, pre-commit hook, CI docs-sync, repository tests, and manual review for requirements, architecture, release, and documentation judgment.

Skip rationale: skip only gates that are not available in the active repository, and replace them with an explicit manual review note or a project-specific command in the final report.
## Human Confirmation

Owner/confirmation: the AiCoding maintainer or user integrating this skill owns acceptance behavior and accepts its independent use with the project's requirements and test process.

Accepted gates: CLI validation, pre-commit hook, CI docs-sync, repository tests, plugin/skill validators, and manual review for requirements, architecture, release, and documentation judgment.

Manual review scope: product intent, MVP tradeoffs, architecture approval, behavior completeness, release readiness, and documentation adequacy remain human-reviewed when they cannot be reliably linted.

Decision: approved for AiCoding integration with the stated gates and manual review boundaries.

Use the agreed requirements and scope, whether recorded in an issue, specification, plan, or the current task. Map the scenarios to the test process selected by the project.

BDD means **Behavior-Driven Development / 行为驱动开发**.

## Purpose

BDD describes what the system must do from an observable behavior perspective. It bridges requirements and tests.

## Scenario format

Use `Given / When / Then`.

```gherkin
Scenario: <observable behavior>
  Given <initial context>
  And <relevant precondition>
  When <user/system action>
  Then <expected observable result>
  And <state, event, output, or error is correct>
```

## Required scenario coverage

For each in-scope requirement (P0 when priorities are used), define at least:

- normal path;
- boundary path;
- error path;
- compatibility or migration path if relevant;
- regression path if modifying existing behavior.

For embedded / firmware, also consider:

- initialization;
- ISR or RTOS context;
- timing;
- watchdog;
- communication loss;
- power loss;
- boot / OTA / rollback;
- memory alignment and endianness.

## Mapping to tests

Every BDD scenario should map to at least one test obligation:

```text
Scenario → Unit / Contract / Integration / System / HIL test
```

Use the [BDD scenarios template](references/bdd-scenarios-template.md) when a structured scenario record is useful.
