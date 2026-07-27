# AI 辅助架构工作流

本文件只定义人和 AI 如何完成一次架构任务，不重新定义架构规则或方法。判断依据来自[架构原则](architecture_principles_zh.md)，约束来自[依赖规则与门禁](dependency_rules_and_gates_zh.md)，目录归一来自[语义层级模型](semantic_layer_model_zh.md)，步骤从[架构方法](architecture_methods_zh.md)选择，定级与证据分级来自[架构成熟度与证据分级](architecture_maturity_zh.md)。

## 输入包

开始前由人提供或确认：

- [项目架构说明模板](../assets/project_architecture_template_zh.md)：系统边界、变化轴、角色映射、模块与门禁。
- [模块契约模板](../assets/module_contract_template_zh.md)：本次涉及模块的职责、Port、状态和资源。
- [架构决策记录模板](../assets/adr_template_zh.md)：存在多个合理方案时记录取舍。
- [AI 任务契约模板](../assets/ai_task_contract_template_zh.md)：限定目标、非目标、文件范围和验收证据。
- [架构评审检查表](../assets/architecture_review_checklist_zh.md)：完成后逐条挂接证据。

缺少信息时，先列出已知事实、可验证假设和真正阻塞项；不得用臆测补全硬件行为或接口契约。信息不足且会改变方案时才提问，其余部分继续推进。

## 七步闭环

| 阶段 | AI 主要动作 | 人的决策点 | 输出证据 |
|---|---|---|---|
| 1. 侦察 | 读取构建、目录、公共头、初始化与调用链 | 确认范围和真实基线 | 文件清单、构建状态、事实/推断分栏 |
| 2. 建模 | 执行 [AM-001](architecture_methods_zh.md#AM-001)、[AM-002](architecture_methods_zh.md#AM-002) 与 [AM-009](architecture_methods_zh.md#AM-009) | 确认职责与语义角色 | 变化矩阵、角色映射、资源表 |
| 3. 基线 | 执行 [AM-010](architecture_methods_zh.md#AM-010) 测出泄漏与占位数量 | 确认基线可接受或需先收敛 | 可复现命令与数值 |
| 4. 约束 | 选择适用规则 ID 和门禁 ID | 批准例外与风险 | 任务契约、例外记录 |
| 5. 设计 | 给出最小方案、备选和代价 | 选择不可逆决策 | ADR、接口草图、迁移切片 |
| 6. 实施与验证 | 仅修改授权范围；按 [AM-006](architecture_methods_zh.md#AM-006) 由近到远运行门禁 | 审核外部行为变化、接受未覆盖风险 | 精确 diff、编译/lint/测试/资源数据 |
| 7. 交付 | 按 [AM-008](architecture_methods_zh.md#AM-008) 分级报告结论 | 最终签收 | 检查表、已知限制、回滚点 |

## AI 的工作边界

AI 适合机械化发现依赖、生成映射表和图、创建 Fake、执行检查、比较方案和整理证据。涉及安全状态、硬件电气条件、实时预算、产品取舍、许可证判断和正式豁免时，由人作最终决定。

每项结论必须按 [SYN-010](architecture_maturity_zh.md#SYN-010) 标注为已验证事实、有根据推断或未验证假设。不得把“静态检查通过”写成“硬件验证通过”，也不得把目录命名当成依赖已隔离。

## 变更粒度

一个架构任务应围绕一个变化轴形成闭环：契约、一个真实实现、一个替身、组合接线和对应门禁。若需要同时重构多个无关子系统，应拆分任务，避免在大范围改写中掩盖边界回归。

## 提示词中的引用方式

给 AI 的任务描述按 ID 引用规则，不复制规则正文，例如：

```text
适用规则：DR-003, DR-004, DR-008, DR-016
适用门禁：GATE-001, GATE-002, GATE-004
目标角色：SL-004 保持环境纯净；SL-002 不直接依赖 SL-010
方法：AM-005 单一纵向切片；AM-010 给出前后基线
```

复制正文会导致规则在多处漂移；按 ID 引用可让 [GATE-007](dependency_rules_and_gates_zh.md#GATE-007) 检出未定义或失效引用。

## 交付格式

每次交付最少包含：结果摘要、改动范围、所遵循的规则/门禁 ID、验证命令与结果、未验证项、已知风险和回滚位置。检查表只记录证据，不重写规则含义。
