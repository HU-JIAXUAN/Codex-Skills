# 架构决策矩阵

本文件只回答“何时抽象、何时不抽象、怎样使用参考仓库”。层级判定不在此处定义，使用[语义层级模型](semantic_layer_model_zh.md)；边界约束不在此处定义，使用[依赖规则与门禁](dependency_rules_and_gates_zh.md)。

## 1. 不按固定层名判断

按 [DR-014](dependency_rules_and_gates_zh.md#DR-014)，层级由职责、变化原因、掌握的知识、依赖方向和资源所有权判断，目录名不授予语义。下表只是常见命名的入口线索，不是判定依据；概念需要澄清时查[语义层级模型](semantic_layer_model_zh.md)，不要求每次分析填写角色 ID。

| 语义角色 | STM32 常见命名 | TI C2000 常见命名 | 飞控/机器人常见命名 | 真正的判断标准 |
|---|---|---|---|---|
| [SL-001](semantic_layer_model_zh.md#SL-001)／[SL-002](semantic_layer_model_zh.md#SL-002) | UserApp / app | app | modules / vehicle / user_app | 是否只表达产品行为与用例顺序 |
| [SL-003](semantic_layer_model_zh.md#SL-003) | algorithm / math / service | control / DCL / foc | commander / estimator / controller | 是否能脱离硬件单测 |
| [SL-004](semantic_layer_model_zh.md#SL-004) | bsp_api / driver_if / port | hal / board_if | device / driver api | 是否可 fake/mock/stub，公共类型是否稳定 |
| [SL-005](semantic_layer_model_zh.md#SL-005)／[SL-006](semantic_layer_model_zh.md#SL-006) | Drivers / BSP | device / board | boards / target | 器件寄存器与板级绑定是否分开 |
| [SL-007](semantic_layer_model_zh.md#SL-007)／[SL-008](semantic_layer_model_zh.md#SL-008) | HAL/LL 适配、osal | driverlib 适配 | AP_HAL / hal 适配 | 是否只把环境能力转成契约 |
| [SL-010](semantic_layer_model_zh.md#SL-010) | HAL/LL/CMSIS/FreeRTOS | C2000Ware/DriverLib | NuttX/ChibiOS/vendor SDK | 是否为第三方或可重新生成代码 |

同一目录出现多个角色时按模块或构建目标分别映射。

## 2. 何时抽象

判据是 [AP-006](architecture_principles_zh.md#AP-006) 的成本公式和 [DR-012](dependency_rules_and_gates_zh.md#DR-012) 的准入问题。

可能支持增加边界的线索：

```text
硬件或主控未来可能变化
协议语义长期稳定
算法需要跨平台复用
模块需要单元测试/仿真/故障注入
多个板卡/轴/通道复用同一能力
```

通常可以保持简单的场景：

```text
一次性 demo
固定 GPIO
固定板级电源使能
固定 LED/风扇/继电器
不会迁移且不影响测试的 bring-up 代码
```

无法说明变化轴或测试收益时，保持同一变化域内的简单实现，或直接复用已有稳定公共接口，并记录未来触发条件；不豁免 DR-017 的 APP 边界。资产沉淀优先提炼已验证的稳定部分，不以“以后通用”为由预建统一框架。

## 3. 参考仓库使用方式

不要照搬目录名。先判断：

```text
参考项目解决的问题是什么？
当前项目是否有同样真实变化点？
客户是否需要同样功能？
当前主控是否匹配？
许可证、实时性、安全性是否允许复刻？
```

根据这些事实区分使用方式：借鉴架构思想、行为重实现、代码参考或不建议采用。只引入当前任务需要且已授权的内容，不把参考目录或功能当成默认范围。
