---
name: aicoding-mvp-planning
description: Define the minimum viable implementation slice for AiCoding engineering tasks using P0/P1/P2/P3 scope gates, risk-first validation, and incremental delivery.
---

# AiCoding MVP Planning
## Skill Type

This skill is both consistent-workflow and organization-standard.

- consistent-workflow: it defines a repeatable process for choosing and validating the smallest useful implementation slice.
- organization-standard: it records AiCoding scope priorities, acceptance criteria, and risk-based validation expectations.

## Workflow Contract

Trigger: use this skill when an engineering change needs a concrete MVP boundary, scope priorities, or an incremental delivery plan.

Inputs: user request, repository AGENTS instructions, existing requirements and acceptance criteria, current code and git state, known constraints and risks, and project verification commands.

Steps: read the project rules and requirements, identify the main risk, choose one useful end-to-end slice, classify scope as P0/P1/P2/P3, define acceptance and validation for the selected work, and record exclusions and follow-up items in the existing project plan or task response.

Exit criteria: the selected scope, acceptance criteria, validation approach, exclusions, and limitations are concrete and reviewable; implementation checks are required only when implementation is part of the task.

Validation: use repository tests, build checks, lint, skill validators, plugin validators, documentation sync checks, and manual review according to the local project.

Blocking hook: AiCoding platform repositories should wire scripts/check-documentation-sync.ps1 into pre-commit and CI so code/config/platform changes cannot finish without documentation review.

## Gate Rules

CLI checker: scripts/check-documentation-sync.ps1 -Mode all is the default documentation sync command when the AiCoding platform docs-sync files are installed; project-specific build, test, lint, and skill validation commands remain authoritative for code and Skill changes.

Hook gate: use .githooks/pre-commit and CI required checks to run docs-sync and repository governance gates before commit or merge; when hooks are not installed, run the CLI checker manually and report that hook enforcement is not active.

MCP tool library: no MCP is required for this workflow because repository-local scripts, tests, and docs provide deterministic gates; MCP tools may be added later for project discovery or long-running diagnostics, with the CLI/manual path remaining the fallback.

Human confirmation: owner/confirmation is the AiCoding maintainer or user integrating this workflow; accepted gates are CLI validation, pre-commit hook, CI docs-sync, repository tests, and manual review for requirements, architecture, release, and documentation judgment.

Skip rationale: skip only gates that are not available in the active repository, and replace them with an explicit manual review note or a project-specific command in the final report.
## Human Confirmation

Owner/confirmation: the AiCoding maintainer or user integrating this skill owns the scope priorities and accepts its independent use with the project's existing requirements and validation process.

Accepted gates: CLI validation, pre-commit hook, CI docs-sync, repository tests, plugin/skill validators, and manual review for requirements, architecture, release, and documentation judgment.

Manual review scope: product intent, MVP tradeoffs, architecture approval, behavior completeness, release readiness, and documentation adequacy remain human-reviewed when they cannot be reliably linted.

Decision: approved for AiCoding integration with the stated gates and manual review boundaries.

Use this skill from the user's requirements and existing project records. It can run independently; the project determines which design and implementation steps follow.

## Goal

Prevent the agent from implementing a large, unfocused design before validating the smallest useful end-to-end slice.

## Scope levels

- P0: mandatory for the first useful vertical slice.
- P1: important but can follow immediately after P0 or is needed to reduce high risk.
- P2: useful enhancement, not required for MVP.
- P3: explicitly out of scope for this change.

## MVP definition

An MVP is not a prototype without quality. It is the smallest production-shaped slice that validates the main risk and can be tested.

It must include:

- one end-to-end flow;
- clear acceptance criteria;
- minimal architecture path;
- test coverage for the main behavior;
- documentation impact;
- known limitations.

## Agent rule

Before implementation, output the MVP table and mark which items will be implemented now.

Use the [MVP plan template](references/mvp-template.md) when a structured plan is useful.
