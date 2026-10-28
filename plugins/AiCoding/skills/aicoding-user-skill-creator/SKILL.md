---
name: aicoding-user-skill-creator
description: 任何创建或修改 Skill 的任务都必须先使用本 Skill，无需用户点名；包括 SKILL.md、触发描述、元数据、脚本、references、assets、evals 的新增、修改、优化和迁移。也用于 Skill 分类、评审、验证及 CLI/Hook/Lint 门禁设计。正文只保留触发条件、设计步骤、规则、例子和验证方法，删除背景解释、自我评价及资源数量或覆盖程度的元叙述。适用于 Codex/OpenCode 与兼容 SKILL.md 的技能目录。
---

# Agent Skill Creator

## 必须触发

- 用户要求创建、修改、优化或迁移任何 Skill，或其他任务中需要修改 Skill 文件时，先加载 `aicoding-user-skill-creator`，再开展修改；不要求用户显式点名。
- 触发范围包括 `SKILL.md`、触发描述、`agents/openai.yaml`、脚本、参考资料、模板、资源和评估用例。创建门禁只判断怎样实施，不决定是否加载本 Skill。
- 当前上下文已经加载时直接复用；不重复读取，不重复确认已有授权。仅使用某个 Skill 完成业务任务、不修改 Skill 时，不因此触发创建流程。

## 固定写作规则

- Skill 正文只保留：触发条件、设计步骤、规则、例子和验证方法。输入、前提、边界和例外并入对应步骤或规则。
- 删除背景介绍、命名来历、改写历程、价值说明、自我评价、泛泛总结，以及围绕参考文件数量或覆盖程度的解释。
- 每段必须提供可执行动作、适用条件、具体约束、例子或可复现检查；删掉不影响执行的句子。
- 例子直接展示输入、操作和结果；必要取舍写成条件与规则，不追加自我评价。
- 这些规则同时适用于新建或修改的 `SKILL.md`、内部指南、references 和本 Skill 自身。不要把用户批评的表述改写成另一段自我说明。
- 本次讨论、审批记录与编辑取舍留在会话或项目已有记录，不写入生成 Skill 正文。

## Runtime Compatibility

- Do not assume `claude -p`, `.claude/commands`, `present_files`, or Claude-only slash commands exist.
- Use Codex tools, local scripts, and available subagents when present; fall back to inline validation when they are not.
- Treat the bundled eval and benchmark assets as legacy/optional helpers unless the current runtime has the tools they require.
- Prefer static files or conversation summaries over browser-only review flows in headless environments.
- Use UTF-8 when reading or writing `SKILL.md`; Windows default encodings can otherwise break validation.

## Skill Type

Use `consistent-workflow` and `organization-standard` for this creation workflow.

Supported skill types:

1. `consistent-workflow`: repeated tasks that must follow the same ordered process.
2. `organization-standard`: company/team-specific procedures, standards, or policies.
3. `reusable-domain-knowledge`: deep domain knowledge encoded as reusable references, scripts, schemas, or assets.
4. `team-expertise`: senior professional knowledge preserved as team-operational guidance.

When deciding whether to propose a new skill, skip the proposal for a one-time simple task or an unstable exploratory workflow. Follow an explicit user request to create or modify a skill.

## Skill/CLI/MCP/Hook Model

创建标准或流程类 skill 时，按以下职责拆分，不要把所有责任都塞进 `SKILL.md`：

- **Skill 是流程说明书**：写清何时触发、输入、步骤、完成标准、人工判断点和例外。
- **CLI 是检查器**：把可稳定判断的规则做成可本地运行的命令，失败用非零退出码和可读错误信息表达。
- **MCP 是工具库**：把需要长期复用的外部能力、项目诊断、查询或自动化能力封装为可调用工具；没有 MCP 时写清替代 CLI 或人工路径。
- **Hook 是门禁系统**：把 CLI 或测试接入 pre-commit、Git hook、CI required check、发布脚本或产线包生成流程，明确在哪个阶段阻塞。

对 `consistent-workflow` 或 `organization-standard` skill，必须判断是否需要 CLI/Hook/Lint/CI/MCP。若规则可机器检查，必须补 `Gate Rules`；若暂不实现，必须写明原因、人工替代项和确认人。

## Skill Creation Gate

Before creating a new skill, run a creation gate mentally or with the CLI:

```bash
python scripts/skill_gate.py assess --prompt "<user request>"
python scripts/skill_gate.py assess --prompt-file request.txt --json
```

For a proposed new skill, check for at least one reuse signal:

- consistent repeated workflow;
- company/team-specific process or standard;
- reusable deep domain knowledge;
- advanced professional knowledge that should become team knowledge.

When the user has not explicitly requested a skill and skip signals dominate, use an ordinary answer:

- one-time and simple task;
- base model can handle it without specialized instructions or resources;
- exploration/prototype phase before the workflow stabilizes.

If the gate returns `skip`, report the applicable reason briefly. An explicit creation request authorizes that scope: proceed and keep any material tradeoff in the delivery report. An existing-skill update does not require repeating the creation decision.

For `consistent-workflow` or `organization-standard`, define gate rules and apply the confirmation conditions below; reuse existing authorization.

## Workflow Contract

Trigger: every Skill creation or modification must use this workflow before editing, including changes discovered during another task; also use it for migration, review and validation.

Inputs: user request, existing skill path when present, target runtime, expected reuse pattern, and any project/company standard that must be preserved.

Steps:

1. For a proposed new Skill, assess reuse and classify its type; for an existing Skill update, reuse the applicable classification and authorization.
2. For `consistent-workflow`, define the required ordered steps before writing detailed instructions.
3. Decide whether resources belong in `scripts/`, `references/`, or `assets/`.
4. Edit only the files needed for the skill behavior; apply the fixed writing rules to every changed instruction or example.
5. Validate frontmatter and skill type with `quick_validate.py` and `skill_gate.py validate`, then manually review the five allowed content categories and trigger scope.
6. Forward-test when the skill controls a real workflow or deliverable.

Exit Criteria: the skill has a clear trigger description, a recognized skill type, required resources are present, workflow skills have an explicit contract, and validation commands pass.

Validation: run `python scripts/quick_validate.py path/to/skill` and `python scripts/skill_gate.py validate path/to/skill`.

Blocking Hook: use `skill_gate.py validate` in pre-commit, CI, or local review scripts so missing skill type, gate rules, human confirmation, or incomplete workflow contract returns a non-zero exit code.

## Gate Rules

For standard/process skills, document these checks before declaring the skill ready:

- CLI checker: command name, input files, pass/fail condition, non-zero exit behavior, and example failure message.
- Hook gate: whether the CLI is wired to pre-commit, Git hook, CI required check, release packaging, or production-package generation.
- MCP tool library: MCP tools required by the workflow, or the explicit reason no MCP is needed and which CLI/manual path replaces it.
- Human confirmation: identify the owner and reuse accepted gates; ask only for a material undecided choice or an approval explicitly required by the project or user.
- Skip rationale: if any gate is not implemented, record why it is not stable enough for automation and what manual review replaces it.

A `consistent-workflow` or `organization-standard` skill without `Gate Rules` is incomplete unless the user explicitly accepts the documented skip rationale.

## Human Confirmation

For a standard/process skill, use these authorization and review rules:

- Owner/确认人: the current user or project owner; an explicit request authorizes the stated creation or modification scope.
- Accepted gates: reuse confirmed CLI, Hook, CI, MCP and manual review choices; apply actual project approval rules to new external actions.
- Manual review scope: review trigger accuracy, instruction consistency and writing rules; do not treat structural validator success as semantic approval.
- Explicit decision: preserve an existing approval or rejection; record new approval decisions in the delivery report or project record.

Ask only when an unresolved condition changes the implementation or a specific required approval is absent. Do not request approval again merely because a Skill is being created or modified.

## Creating a New Skill

Use the user-specified path and the repository's canonical source rules. Otherwise reuse the project-local Skill layout or the active user skill location. Ask only if the path cannot be determined and affects the implementation. Do not edit generated packages or installed caches when a canonical source and supported build/install workflow exist.

Use the initializer instead of hand-assembling the folder:

```bash
python scripts/init_skill.py my-new-skill --path ~/.codex/skills
python scripts/init_skill.py my-new-skill --path .agents/skills --resources scripts,references
```

Then edit the generated `SKILL.md`:

- Keep frontmatter to `name` and `description` unless the local runtime explicitly supports more.
- Put trigger guidance in `description`, because it is visible before the body is loaded.
- Apply the fixed writing rules: only trigger conditions, design steps, rules, examples and validation methods; place detailed material in the matching resource.
- Add scripts only when deterministic behavior or repeated code is worth the maintenance cost.
- Split long reference material into `references/` and point to it from `SKILL.md`.

If `agents/openai.yaml` needs to be regenerated, use:

```bash
python scripts/generate_openai_yaml.py path/to/skill --interface display_name="Display Name" --interface short_description="Short UI description"
```

Preserve existing `policy` and `dependencies` when updating UI metadata. The generator writes `interface` only; merge retained fields before replacing the file. Keep `policy.allow_implicit_invocation: true` for this Skill.

## Migrating an Existing Claude/Anthropic Skill

Use `rewrite_skill.py` for the first mechanical pass:

```bash
python scripts/rewrite_skill.py path/to/old-skill path/to/new-skill-codex
python scripts/quick_validate.py path/to/new-skill-codex
```

After the script runs, review the migrated `SKILL.md` against the actual workflow and fixed writing rules.

Focus the review on:

- Removing hard requirements for Claude-only mechanisms such as `claude -p`, `.claude/commands`, `present_files`, and Claude slash commands.
- Replacing Claude-specific language with runtime-neutral language such as "agent", "Codex", "available tools", or "subagents if available".
- Checking current runtime requirements and optional tools in `Runtime Compatibility`; keep migration history outside the Skill body.
- Keeping resources needed by the current workflow and removing obsolete resources after migration.
- Updating `description` so Codex triggers the skill for the migrated workflow rather than only for Anthropic-specific prompts.

## Improving an Existing Skill

Before editing, inspect the current skill folder and identify the smallest change that addresses the observed problem.

Use this sequence:

1. Read `SKILL.md` and only the directly relevant bundled files.
2. State the success criteria in concrete terms, such as "validator passes" or "forward test creates the expected file".
3. Edit the resource or instruction that directly controls the behavior.
4. Remove only code or instructions made obsolete by the current edit.
5. Run validation and a focused smoke test.

For triggering issues, update the frontmatter `description` first. It should say what the skill does and when to use it, while staying concise enough to survive truncation in large skill sets.

## Validation

Run the validator after every structural change:

```bash
python scripts/quick_validate.py path/to/skill
python scripts/quick_validate.py path/to/skill/SKILL.md
```

The validator checks:

- `SKILL.md` exists or the supplied path points to one.
- Frontmatter is present and parseable.
- `name` and `description` exist and are strings.
- `name` is lowercase hyphen-case and no longer than 64 characters.
- `description` avoids angle brackets and stays within the supported length.
- Only compatible top-level frontmatter keys are used.

修改本 Skill 时，还需核对 `description` 首句覆盖所有 Skill 创建/修改任务，`agents/openai.yaml` 保留布尔值 `policy.allow_implicit_invocation: true`，默认提示包含 `$aicoding-user-skill-creator`。人工逐段检查固定写作规则；结构校验不替代内容审查。

## Forward Testing

Forward-test when the skill is complex, modifies files, creates deliverables, or changes behavior that users rely on.

Good forward tests look like real user requests. They should not reveal your diagnosis, expected answer, or hidden implementation notes. If subagents are available, give each one only the skill path, the task, and any input artifacts. If subagents are unavailable, run the same prompt yourself in a fresh, minimal context.

Useful checks include:

- The intended skill would trigger from the prompt.
- The instructions lead to the expected workflow without extra user hand-holding.
- Bundled scripts run successfully in the target environment.
- Outputs are inspectable and match the user-visible success criteria.

## Conditional Evaluation Tools

Check the commands and runtime dependencies before using evaluation viewers, benchmark scripts or description optimization helpers.

- If a script shells out to `claude -p`, do not use it in Codex unless the user explicitly has Claude CLI available and wants that path.
- If a review viewer requires a browser server but the environment is headless, generate a static artifact or summarize results inline.
- Prefer Codex-native forward testing for day-to-day skill changes.

## Packaging

Package only after validation passes and the user wants a distributable artifact:

```bash
python scripts/package_skill.py path/to/skill
```

If packaging an installed user-level skill, copy it to a writable staging location first, package the staged copy, and then copy the final artifact to the requested output location.
