# 测试与发布门禁

本文件只把门禁落到具体测试项和参考做法。门禁的规范定义在[依赖规则与门禁](dependency_rules_and_gates_zh.md)，此处不改写其含义。

## 1. 按语义角色的最低测试项

| 角色 | 必须测试 | 对应门禁 |
|---|---|---|
| 领域／算法核心 | 纯函数单元测试、边界值、定点/浮点一致性 | [GATE-004](dependency_rules_and_gates_zh.md#GATE-004) |
| 能力契约 Port | fake/mock/stub 注入测试、公共头独立编译 | [GATE-002](dependency_rules_and_gates_zh.md#GATE-002)、[GATE-004](dependency_rules_and_gates_zh.md#GATE-004) |
| 应用编排／服务状态机 | 状态迁移、非法输入、超时、故障恢复 | [GATE-004](dependency_rules_and_gates_zh.md#GATE-004) |
| 器件协议／板级绑定 | 初始化失败原子性、错误映射、拔出/无响应 | [GATE-004](dependency_rules_and_gates_zh.md#GATE-004)、[GATE-006](dependency_rules_and_gates_zh.md#GATE-006) |
| Bootloader/OTA | 断电、CRC 错误、版本错误、防降级、回滚 | [GATE-010](dependency_rules_and_gates_zh.md#GATE-010) |
| 强实时路径 | WCET、抖动、栈深、overrun 统计 | [GATE-005](dependency_rules_and_gates_zh.md#GATE-005) |
| 全仓库结构 | 依赖方向、组件可见性、三视图差异、角色映射完整性 | [GATE-001](dependency_rules_and_gates_zh.md#GATE-001)、[GATE-003](dependency_rules_and_gates_zh.md#GATE-003)、[GATE-008](dependency_rules_and_gates_zh.md#GATE-008)、[GATE-009](dependency_rules_and_gates_zh.md#GATE-009) |

未执行的项标记为 NOT RUN，不得按“结构上不会出问题”跳过。

## 2. 门禁的阻塞阶段

| 阶段 | 建议接入的门禁 | 载体 |
|---|---|---|
| 本地提交 | GATE-001、GATE-002、GATE-007 | pre-commit、git hook、构建 target |
| CI 合并 | GATE-001～GATE-004、GATE-008、GATE-009 | required check |
| 发布打包 | GATE-005、GATE-006、GATE-010 | 发布脚本、制品校验 |
| 产线烧录 | GATE-010 | 产线包生成与追溯记录 |

## 3. 可参考的工程化做法

只作为门禁实现方式的参考，不建议直接照搬目录：

```text
PX4：modules/drivers/boards/msg/ROMFS、参数、日志、SITL/HITL
ArduPilot：AP_HAL、libraries、vehicle 分离、日志和参数长期维护
Betaflight：target 配置、Blackbox、CLI 参数、强实时板级裁剪
TI SDK：Datalog、SFRA、DCL、SysConfig、官方示例回归
Zephyr：devicetree 绑定、KConfig 分域、twister 回归
```

## 4. 交付前必须给客户确认

```text
最终组件清单与语义角色映射
模块边界与 owner
升级策略
门禁清单、阻塞阶段与当前 PASS/FAIL/NOT RUN
参考仓库是否复刻
不能复刻或不建议复刻的原因
未验证项与硬件待验项
```
