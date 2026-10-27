# 测试与发布门禁

本文件只把门禁落到具体测试项和参考做法。门禁的规范定义在[依赖规则与门禁](dependency_rules_and_gates_zh.md)，此处不改写其含义。

## 1. 按影响选择验证

| 涉及的内容 | 可选择的验证 | 对应门禁 |
|---|---|---|
| 领域／算法核心 | 纯函数单元测试、边界值、定点/浮点一致性 | [GATE-004](dependency_rules_and_gates_zh.md#GATE-004) |
| 公共能力接口 | 公共头独立编译；需要隔离或故障注入时使用 fake/mock/stub | [GATE-002](dependency_rules_and_gates_zh.md#GATE-002)、[GATE-004](dependency_rules_and_gates_zh.md#GATE-004) |
| APP／应用编排／服务状态机 | 隔离构建与运行、状态迁移、非法输入、超时、故障恢复，复核私有状态与装配 | [GATE-004](dependency_rules_and_gates_zh.md#GATE-004)、[GATE-011](dependency_rules_and_gates_zh.md#GATE-011) |
| 器件协议／板级绑定 | 初始化失败原子性、错误映射、拔出/无响应 | [GATE-004](dependency_rules_and_gates_zh.md#GATE-004)、[GATE-006](dependency_rules_and_gates_zh.md#GATE-006) |
| Bootloader/OTA | 断电、CRC 错误、版本错误、防降级、回滚 | [GATE-010](dependency_rules_and_gates_zh.md#GATE-010) |
| 强实时路径 | WCET、抖动、栈深、overrun 统计 | [GATE-005](dependency_rules_and_gates_zh.md#GATE-005) |
| 全仓库结构 | 依赖方向、组件可见性、三视图差异、角色映射完整性 | [GATE-001](dependency_rules_and_gates_zh.md#GATE-001)、[GATE-003](dependency_rules_and_gates_zh.md#GATE-003)、[GATE-008](dependency_rules_and_gates_zh.md#GATE-008)、[GATE-009](dependency_rules_and_gates_zh.md#GATE-009) |
| 对象与数据模型变更 | 多实例隔离、参数生效/状态复位、失效数据、部分初始化失败及停止取消，按本切片选取 | DR-018、[GATE-004](dependency_rules_and_gates_zh.md#GATE-004) |

先根据变更影响、现有证据和项目要求选择适用项。适用但未执行的检查说明为 NOT RUN；不适用的项可以省略或标记 N/A。概念讨论和局部可逆调整不需要额外生成全套测试；实际硬件、时序与升级结论仍需相应证据。

## 2. 持续检查的接入位置

| 阶段 | 建议接入的门禁 | 载体 |
|---|---|---|
| 本地提交 | GATE-001、GATE-002、GATE-007 | pre-commit、git hook、构建 target |
| CI 合并 | GATE-001～GATE-004、GATE-008、GATE-009；按实际需要选择 GATE-011 | required check |
| 发布打包 | GATE-005、GATE-006、GATE-010 | 发布脚本、制品校验 |
| 产线烧录 | GATE-010 | 产线包生成与追溯记录 |

此表供有对应交付流程的项目选用。已经采用的必需检查应执行；未涉及发布、产线或相关硬件行为的任务，不因引用本 Skill 扩展这些工作。

## 3. 可参考的工程化做法

只作为门禁实现方式的参考，不建议直接照搬目录：

```text
PX4：modules/drivers/boards/msg/ROMFS、参数、日志、SITL/HITL
ArduPilot：AP_HAL、libraries、vehicle 分离、日志和参数长期维护
Betaflight：target 配置、Blackbox、CLI 参数、强实时板级裁剪
TI SDK：Datalog、SFRA、DCL、SysConfig、官方示例回归
Zephyr：devicetree 绑定、KConfig 分域、twister 回归
```

## 4. 交付说明

围绕本次目标说明边界变化、实际执行的检查和仍需验证的内容。涉及发布或升级时再说明对应策略与证据；涉及 App 时考虑业务成果、数据模型和经验怎样沉淀。普通分析与可逆改动不另设客户确认步骤，需用户决定的真实取舍应具体说明。
