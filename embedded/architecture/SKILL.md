---
name: architecture
description: 设计、审查和重构嵌入式固件系统架构，覆盖 MCU、MPU、DSP、FPGA、SoC、裸机、RTOS 和 Linux 边缘设备。先把厂商目录名归一为语义角色（SL-*），再按依赖规则（DR-*）判断边界、按可观察信号（SIG-*）测出泄漏基线、按门禁（GATE-*）机器化验证、按方法（AM-*）执行分析与迁移、按模式（PAT-*）命名结构、按成熟度阶梯（L0-L5）与证据分级给出结论。规则与具体项目解耦，不携带任何仓库的路径或数值。用于职责分层、真实变化点抽象、App/算法平台化、Port/Adapter/组合根、Bootloader、OTA、A/B、Manifest、参数与校准区、产线烧录、依赖注入、测试与发布门禁，以及将架构约束落实为 CLI/Hook/CI Lint 阻塞规则。仅在系统边界、目录结构、平台适配或量产交付是主问题时使用；FOC、SVPWM、PI/PID、采样时序和多轴控制算法改用 motorcontrol。参考开源或厂商工程前先确认主控、需求、许可证和复刻范围，不得默认照搬。
---

# 嵌入式架构平台化

默认使用中文输出。

## Skill 类型

本 Skill 属于 `consistent-workflow`、`organization-standard`、`reusable-domain-knowledge` 和 `team-expertise`：它把嵌入式架构审查流程、团队平台化标准、量产交付知识和高级架构经验固化为按 ID 引用的可复用规则。

使用本 Skill 当：任务涉及重复架构审查流程、团队平台化标准、可复用架构知识、量产/升级/发布门禁，或需要把架构约束落成 CLI/Hook/CI Lint 阻塞规则。

跳过本 Skill 当：任务只是一次性简单解释、只是在探索原型且边界未稳定、或主问题是具体控制算法而应改用 `motorcontrol`。

## 规范 ID 体系

所有架构结论按 ID 引用规范，不复制规则正文。ID 的唯一归属如下：

| 前缀 | 含义 | 唯一定义位置 |
|---|---|---|
| `AP-*` | 判断原则 | [架构原则](references/architecture_principles_zh.md) |
| `SL-*` | 语义角色 | [语义层级模型](references/semantic_layer_model_zh.md) |
| `DR-*` / `GATE-*` | 边界约束与门禁 | [依赖规则与门禁](references/dependency_rules_and_gates_zh.md) |
| `AM-*` | 分析与迁移方法 | [架构方法](references/architecture_methods_zh.md) |
| `PAT-*` | 结构模式 | [模式目录](references/architecture_patterns_zh.md) |
| `SYN-*` | 成熟度与证据分级 | [架构成熟度与证据分级](references/architecture_maturity_zh.md) |
| `SIG-*` | 可观察泄漏信号与基线指标 | [泄漏信号与基线测量](references/leak_signals_and_baseline_zh.md) |

角色之间的装配关系见[通用参考架构](references/reference_architecture_zh.md)。

## 分析在前，工具在后

**工具不判断架构，它只复核已经做出的判断。** 「哪些是用户代码」「哪些是厂商代码」「这个目录想表达什么」「什么算环境类型」——没有一项是脚本能看出来的，全部是模型和人读代码后的结论。把顺序倒过来的直接后果是：脚本会拿着一份残缺的输入，安静地报出一个看起来很干净的 0。

正确顺序固定为三步，不得跳过第一步：

```text
1. 模型分析   读仓库，按 AM-011 定出环境边界、用户代码与厂商代码的分界、各目录的真实意图
2. 人工确认   把结论写进 arch-map.json，含 analysis_confirmed_by 与每条规则的 evidence
3. 工具复核   机械校验依赖方向、公共头纯度、角色映射完整性，失败可阻塞
```

第 1 步可以先用证据模式抓原材料。它只输出可复现的事实，**不下任何结论**：

```bash
pwsh -File scripts/check_layering.ps1 -Root <项目根> -Evidence
```

第 3 步才是校验。判断输入不完整时脚本会拒绝给出结论并返回 2，不会报 0：

```bash
pwsh -File scripts/check_layering.ps1 -Root <项目根> -Map <项目>/arch-map.json -BaselineOnly
```

去掉 `-BaselineOnly` 即为阻塞模式，可接入 pre-commit 或 CI required check。它报告未分类模块、依赖方向违规、公共头环境类型泄漏、非组合根引用实现头，并给出过度抽象警告（DR-012）与「一条映射盖住了契约+实现两个角色」警告（DR-014）。

两个检查器的完整用法见[分层检查器使用说明](references/layering_check_tool_zh.md)。

校验本 skill 自身的文档拓扑与 ID 归属（GATE-007）：

```bash
pwsh -File scripts/validate_document_architecture.ps1
```

## 工作流契约

触发：系统边界、目录结构、平台适配、量产交付、发布门禁或架构规则机器化任务。

输入：主控/OS/SDK、项目阶段、真实变化点、强实时路径、升级/产线需求、现有构建和 CI 工具。

步骤：先建立上下文，再把实际目录归一为语义角色，然后测出泄漏基线，只对真实变化点抽象，最后把可机器检查的架构约束落实为 CLI、Hook、Lint、CI 或发布脚本门禁。

完成标准：角色映射覆盖全部模块，边界和依赖方向明确，不新增无法解释的抽象，量产/升级风险有门禁，机器化规则说明命令入口和阻塞阶段。

验证：依赖扫描、include graph、公共头纯度、状态机测试、故障注入、升级断电测试、强实时测量和发布门禁通过。

阻塞 Hook：新增架构边界或发布规则时，若可稳定机器检查但没有 CLI/Hook/CI 阻塞方案，必须在输出中标为未完成风险，不得宣称架构已可发布。

## 核心边界

- 目录名不授予架构语义（AP-009）；先归一角色，再讨论层级。
- 只抽象真实变化点（AP-006、DR-012），不为目录美观增加层次。
- 保持 App、算法核心、协议语义、升级与故障状态机不依赖具体芯片和厂商 HAL。
- 允许固定板级 GPIO、bring-up 和一次性实验保留薄实现。
- 结论必须分级（AP-010、SYN-010）：目录结构不能证明解耦，静态检查不能证明硬件验证。
- 本 skill 的规则、信号和模板保持与具体项目解耦：只描述可观察信号、判定条件和命令模板，不写入任何具体仓库的路径、目录名、模块名或快照数值。项目事实属于该项目自己的架构说明和评审记录。
- 将 FOC、SVPWM、PI/PID、采样时序和多轴控制算法交给 `motorcontrol`。
- 涉及 C 实现时同时使用 `c99`；涉及具体 ARM 启动、中断或 cache 时同时使用 `arm`。

## 工作流

### 1. 建立上下文

先从仓库证据识别，缺失且会改变方案时再询问：

- 主控、编译器、操作系统和厂商 SDK 版本；
- 项目阶段：Demo、bring-up、产品化、平台化或量产维护；
- 强实时路径、周期、WCET、抖动和安全状态；
- 真实变化点：主控、板卡、协议、编码器、功率板或产品型号；
- Bootloader、升级、回滚、签名、参数、校准和产线追溯需求。

需要组织问题时读取[客户访谈清单](references/customer_interview_checklist_zh.md)。不要默认引入 HAL/BSP/ops、跨 RTOS、A/B 或全量 GPIO 抽象。

### 2. 语义归一（先做，不可跳过）

按 AM-009 忽略目录名，逐模块判定职责、变化原因、掌握的知识、公共类型和资源所有权，输出“实际路径/构建目标 -> 角色 ID -> planned/implemented”映射表。角色定义与常见名称歧义见[语义层级模型](references/semantic_layer_model_zh.md)，命名与角色不一致的可观察信号见[泄漏信号与基线测量](references/leak_signals_and_baseline_zh.md)。

未分类模块必须列出；带着未分类模块做的依赖判断不成立（DR-014、GATE-009）。

### 3. 测出基线并定级

按 AM-010 和 SIG-008 的记录格式，用可复现命令测出未分类模块数、各角色区域的环境头包含数、全局 include 路径条数、重复能力组数、组合位置数和 planned/弱实现占位数，并同时记录命令与快照标识。再按[架构成熟度与证据分级](references/architecture_maturity_zh.md)的 L0-L5 阶梯给出当前等级和封顶原因。

没有命令支撑的等级声明只能记为意图，不得写入完成度。

### 4. 只针对真实变化点提出方案

对每个新增边界说明：

- 它隔离了哪个已确认的变化；
- 哪些调用方依赖它；
- 如何测试或替换；
- 不增加该边界的实际代价是什么。

无法回答时不新增抽象。抽象与否的判据见[架构决策矩阵](references/architecture_decision_matrix_zh.md)，结构命名与代价见[模式目录](references/architecture_patterns_zh.md)。

反向同样要处理：检查器报出的每条 DR-012 警告（Port 无实现，或只有单一实现且无测试替身）必须给出结论——补出第二实现或替身、说明真实变化轴、或退回直接依赖并删除该 Port。不允许保留“为将来准备”的空接口。

### 5. 用最小纵向切片落地

按 AM-005 和 SIG-009 的选点规则挑一条链路，贯通用例、核心模块、Port、真实 Adapter、Fake、组合接线和门禁；存量项目按 AM-007 绞杀式迁移，保持旧路径可回退。切片成立的判据是：替换实现或注入故障只改动适配与组合侧，核心测试不需要目标板初始化。不要同时开多个切片。

### 6. 处理量产和升级

涉及交付、现场维护或升级时，读取[固件生产与量产约束](references/production_firmware_constraints_zh.md)，明确镜像验证、断电恢复、回滚、参数保护、版本追溯和调试口策略（GATE-010）。

### 7. 使用参考项目

仅当主控、产品形态或问题相近时读取：

- [参考仓库矩阵](references/repository_reference_matrix_zh.md)：快速匹配参考工程；
- [客户功能复刻方案速查](references/customer_function_replicate_options_zh.md)：比较可复刻行为、代价和许可证风险。

区分架构思想、行为重实现、代码参考和不建议照搬的部分。未经用户确认，不复制参考工程的目录或功能。

### 8. 定义验证和发布门禁

读取[测试与发布门禁](references/testing_release_gate_zh.md)，按语义角色确定最低测试项，并给出每条门禁的命令、阻塞阶段和当前 PASS/FAIL/NOT RUN。没有证据时，不宣称架构已验证或可发布。

### 9. 将架构约束机器化

凡是能被仓库结构、依赖图、构建脚本、静态扫描或测试稳定判断的架构约束，不能只写在设计文档中；必须实现为 CLI、Hook、Lint、CI required check 或发布脚本门禁，并让失败明确阻塞合并、发布或产线包生成。

优先机器化：依赖方向（GATE-001）、公共头纯度（GATE-002）、组件可见性（GATE-003）、主机替身测试（GATE-004）、资源与时序预算（GATE-005）、三视图一致性（GATE-008）、角色映射完整性（GATE-009）、量产与升级（GATE-010）。其中 GATE-001／GATE-002／GATE-009 可直接用 `scripts/check_layering.ps1` 落地，其余按项目构建系统和测试框架补齐。

提出新边界或发布规则时同步给出：判定条件、推荐命令或 hook 入口、阻塞阶段、暂不能机器化的原因和人工确认方式。

## 门禁与人工确认

- CLI 检查器：失败必须返回非零退出码并指出违规文件、来源角色和目标角色。
- Hook 门禁：可机器检查的约束应接入 pre-commit、Git hook、CI required check、发布打包或产线包生成。
- MCP 工具库：若存在项目诊断、仓库/依赖分析、构建或测试 MCP，优先作为工具库；没有时用 CLI/构建日志/人工审查替代并说明原因。
- 人工确认：记录 Owner、已接受门禁、人工审查范围（真实变化点、抽象代价、许可证边界、量产风险、升级策略）和明确决定（通过／带风险通过／退回）。没有确认时不得声称架构已完全可发布。
- 暂不实现原因：无法稳定自动判断、项目结构未稳定、原型阶段变化太快，或需要团队先确认架构边界时，必须写明人工替代项。

## AI 协作与输出

多轮或多人协作时按[AI 辅助架构工作流](references/ai_architecture_workflow_zh.md)的七步闭环推进，并使用以下输入包：

- [项目架构说明模板](assets/project_architecture_template_zh.md)
- [模块契约模板](assets/module_contract_template_zh.md)
- [架构决策记录模板](assets/adr_template_zh.md)
- [AI 任务契约模板](assets/ai_task_contract_template_zh.md)

按任务规模输出必要部分：

1. 当前平台、阶段、基线和已确认假设；
2. 实际路径到语义角色映射与未分类项；
3. 泄漏基线数值与成熟度等级；
4. 真实变化点与不应抽象点；
5. 建议边界、依赖方向、纵向切片和目录映射；
6. 参考项目的匹配理由与复刻边界；
7. 门禁清单、阻塞阶段、验证结果和待用户确认项；
8. 结论证据分级：已验证事实／有根据推断／未验证假设。

正式审查使用[架构审查输出模板](assets/architecture_review_template_zh.md)并逐条挂接[架构评审检查表](assets/architecture_review_checklist_zh.md)；需要方案签字确认时使用[客户确认模板](assets/customer_confirmation_template_zh.md)。
