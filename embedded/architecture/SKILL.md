---
name: architecture
description: 分析、设计和审查嵌入式系统的职责、模块边界、依赖、变化传播与平台适配。用于 App 解耦、分层决策、跨模块资源与执行关系，以及工程资产沉淀；围绕真实用例比较取舍，不预设层数或框架。对象身份与生命周期、内部字段与数据语义分别按需结合对象模型设计和数据模型设计。
---

# 嵌入式架构

默认使用简体中文；运行时入口为 `aicoding-architecture`。负责系统和模块之间的设计判断，细部问题按需使用专项知识。

## Skill 类型

属于 `reusable-domain-knowledge` 和 `team-expertise`：提供架构概念、判断方法、按需参考资料和可执行检查器。

- 覆盖 MCU、MPU、DSP、FPGA、SoC、裸机、RTOS 和 Linux 边缘固件。
- 只为已确认的变化点、测试替身或隔离需要增加边界，不默认引入 HAL/BSP/ops、第二实现或空 Port。
- 一次性简单解释、局部修复无需完整架构流程；探索阶段可以分析候选边界，不强制生成目录、映射文件或门禁。
- C 实现结合 `aicoding-c99-standard-c`；ARM 启动、中断和 cache 结合 `aicoding-arm`；FOC、PI、采样与多轴算法交给 `aicoding-motor-control`。

## 核心指导思想

- 沉淀基本概念、架构能力与设计判断方法，按 [AP-012](references/architecture_principles_zh.md#AP-012) 选择性固化；具体业务设计由当前工程推导，示例不自动成为约束。
- 按职责和变化原因划分模块，业务逻辑与硬件、OS、第三方库细节解耦；依赖围绕稳定接口组织，不按目录名判断。
- App 描述产品要做什么，Service 将底层能力组织为可复用系统能力。这是职责划分的参考；层数、名称和接口形式服从实际工程，不要求固定五层或每次调用逐层经过。
- 参数、运行状态、资源和数据明确归属与生命周期，保持单一状态来源。对象、数据、管理、配置与扩展按本次问题考虑，`cfg/ctx/data/ops` 是可选建模词汇。
- 采用能解决当前问题的最小结构，复用已有稳定接口；普通函数与静态绑定同样可以解耦，不为结构完整制造空层、第二实现或新文档。
- **工程开发必须考虑 App 层的资产沉淀**：保留可复用的产品流程、状态机、业务规则、数据模型和异常处理经验，同时积累有价值的服务、算法、测试工具与平台适配。

层级概念和组织示例查[语义模型](references/semantic_layer_model_zh.md)与[参考架构](references/reference_architecture_zh.md)；边界原则查 [DR-017](references/dependency_rules_and_gates_zh.md#DR-017)。对象建模按 [AM-012](references/architecture_methods_zh.md#AM-012)，轻量资产沉淀按 [AM-013](references/architecture_methods_zh.md#AM-013)。

## 专项子 Skill 路由

设计时重点思考：什么需要一起变化、谁拥有状态和资源、调用者真正需要什么、当前约束是什么，以及增加边界是否值得。比较适合当前用例的少量方案，给出取舍与最小验证；不把这些问题变成必须填写的新表单。

主 Skill 负责系统职责、依赖与资产积累，按问题调用专项：

| 问题 | 子 Skill |
|---|---|
| 对象职责、身份、协作与生命周期，以及是否需要统一管理 | **对象模型设计**（`aicoding-object-model-design`） |
| 对象内部字段、cfg/ctx/data/ops、类型、存储、读写权限与有效期 | **数据模型设计**（`aicoding-data-model-design`） |

三个入口都可直接使用。按主要设计问题选入口，只有遇到实质设计缺口时才结合专项，不要求依次执行或来回转交。普通字段整理不扩展为对象框架，身份与生命周期设计不重复维护内部数据细节。

## 如何推进设计

先理解产品用例和本次变化，再读取相关代码、构建、调用关系与已有记录。识别职责、状态和资源的所有者，找出具体环境细节如何影响业务；只对会改变方案的缺失信息提问。

围绕真实变化点比较少量可行方案，说明边界隔离了什么、增加了什么成本。能复用现有接口就复用，必要时落地一个最小切片。用户要求只分析时，在回复中给出具体方案与验证办法，不生成业务文件。

按影响选择构建、依赖与行为验证，交代结论的证据范围和未验证项。设计结果应让当前职责与变化传播更清楚，并保留后续可用的 App 成果；小任务复用现有代码、测试和记录即可。

## 先选路径

| 任务 | 最小工作路径 | 验收重点 |
|---|---|---|
| 新项目／新模块 | 从一个用例确定职责与接口，复用工程设施，落地最小可验证结构 | 按实际交付验证接口、构建接线及关键行为，替身和 smoke 按需选择 |
| 存量审查／迁移 | 读相关构建与调用链，判断实际职责，选一个变化点分析或迁移 | 受影响依赖和行为有证据；实际迁移明确新旧路径与退出条件 |
| 量产／升级边界 | 在已有架构上补充当前交付相关的镜像、参数、恢复与追溯契约 | 用相应故障、断电或现场证据判断；不把这些项目强加给普通骨架任务 |

边界与契约可查 [AM-002](references/architecture_methods_zh.md#AM-002)，最小结构可查 [AM-004](references/architecture_methods_zh.md#AM-004)，渐进迁移可查 [AM-007](references/architecture_methods_zh.md#AM-007)。这些是按问题选择的方法，不要求每次执行完整流程。全库角色映射、泄漏基线和成熟度仅用于需要该范围结论的审查。

### 检查器的使用条件

工具复核已完成的判断。日常分析不要求先创建全库映射或增加审批；采用本检查器做阻塞检查时，复用项目已有有效确认与配置，缺少时说明具体条件，不虚构确认人，也不把扫描零告警当作架构通过。

以下 `<SkillRoot>` 是当前 skill 目录，`<ProjectRoot>` 是目标工程；使用实际路径替换，从 skill 目录定位脚本，不假定业务仓库里已有同名脚本：

```powershell
pwsh -File "<SkillRoot>/scripts/check_layering.ps1" -Root "<ProjectRoot>" -Evidence
pwsh -File "<SkillRoot>/scripts/check_layering.ps1" -Root "<ProjectRoot>" -Map "<ProjectRoot>/arch-map.json" -BaselineOnly
```

证据模式只收集事实；基线模式用于报告；去掉 `-BaselineOnly` 才是阻塞检查。映射和环境规则不完整时返回 2，不能解释为零违规。覆盖与限制见[分层检查器说明](references/layering_check_tool_zh.md)。

## 按需读取参考

按当前问题读取对应行，不默认加载整套资料。规则正文保持唯一归属，适用时按 ID 引用；项目路径、数值和生产状态留在项目记录中。

| 问题 | 资料与唯一规则归属 |
|---|---|
| 抽象是否值得、固定板级实现是否应保留 | [架构原则 AP-*](references/architecture_principles_zh.md)、[决策矩阵](references/architecture_decision_matrix_zh.md) |
| 各层概念、厂商目录映射、采集与执行链路 | [语义角色 SL-*](references/semantic_layer_model_zh.md)、[通用参考架构](references/reference_architecture_zh.md) |
| APP 解耦、依赖方向、公共接口、占位与机器门禁 | [依赖规则 DR-* 与门禁 GATE-*](references/dependency_rules_and_gates_zh.md)，APP 参考 DR-017/GATE-011 |
| 对象职责、协作与生命周期 | 按需结合 `aicoding-object-model-design`；主架构保留 [AM-012](references/architecture_methods_zh.md#AM-012) 与 DR-018 的边界说明 |
| 对象内部字段、cfg/ctx/data/ops 与数据有效性 | 按需结合 `aicoding-data-model-design`，按字段语义、类型、所有权和寿命设计 |
| 工程结束后的代码、数据、测试与架构资产 | [方法 AM-013](references/architecture_methods_zh.md#AM-013)，参考 DR-019，重点包括 App 层 |
| 契约、骨架、切片与渐进迁移 | [方法 AM-*](references/architecture_methods_zh.md)、[模式 PAT-*](references/architecture_patterns_zh.md) |
| 存量基线与正式架构评估 | [泄漏信号 SIG-*](references/leak_signals_and_baseline_zh.md)、[成熟度 SYN-*](references/architecture_maturity_zh.md) |
| 量产、Bootloader、OTA、A/B、参数与校准区 | [生产与量产约束](references/production_firmware_constraints_zh.md)、[测试与发布门禁](references/testing_release_gate_zh.md) |
| 需求不足或参考工程选择 | [访谈清单](references/customer_interview_checklist_zh.md)、[参考仓库矩阵](references/repository_reference_matrix_zh.md)、[行为复刻边界](references/customer_function_replicate_options_zh.md)；先检查主控、需求、许可证和范围 |
| 多轮协作、正式记录或评审 | [AI 架构工作流](references/ai_architecture_workflow_zh.md)；按需要使用[项目说明](assets/project_architecture_template_zh.md)、[模块契约](assets/module_contract_template_zh.md)、[ADR](assets/adr_template_zh.md)、[任务契约](assets/ai_task_contract_template_zh.md)、[审查输出](assets/architecture_review_template_zh.md)、[检查表](assets/architecture_review_checklist_zh.md)、[客户确认](assets/customer_confirmation_template_zh.md) |

## 验证与工具

对可稳定重复判断的规则优先使用已有构建、测试、CLI、Hook 或 CI；不为普通设计分析新建门禁或审批。角色与边界取舍仍需结合用例和证据判断。需要正式发布结论时，采用该项目实际适用的门禁与确认要求，未运行项如实说明。

本 Skill 自身的文档、链接与 ID 归属由 `pwsh -File "<SkillRoot>/scripts/validate_document_architecture.ps1"` 校验；目标工程分层检查器的前提与限制见上文。工具不能证明它未覆盖的运行行为、时序或私有状态访问。

## 输出

先报告结论与本次路径，再给必要证据：改动或建议、职责与契约、边界理由、可复现命令及结果、未实现/未验证项和下一阶段条件。工程开发必须交代 App 层及其他有价值成果沉淀了什么、后续怎样使用和验证；复用已有记录，小任务在回复中说明即可。区分已验证事实、有根据推断和未验证假设；正式审查也按项目需要选择角色基线、成熟度或发布门禁记录。
