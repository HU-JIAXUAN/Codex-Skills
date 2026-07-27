# 架构成熟度与证据分级

本文件只负责综合判断：如何给一个固件架构定级、如何区分证据强度、以及常见误判怎样避免。判断依据引用[架构原则](architecture_principles_zh.md)，约束引用[依赖规则与门禁](dependency_rules_and_gates_zh.md)，角色引用[语义层级模型](semantic_layer_model_zh.md)，步骤引用[架构方法](architecture_methods_zh.md)，结构名称引用[模式目录](architecture_patterns_zh.md)，可观察信号引用[泄漏信号与基线测量](leak_signals_and_baseline_zh.md)。本文件不重复它们的定义。

<a id="SYN-001"></a>
### SYN-001 成熟度阶梯

```text
L0 生成基线：芯片、SDK、OS 可以构建
L1 语义分类：模块按职责和变化原因映射到角色，映射表存在且被引用
L2 契约隔离：公共 Port 不泄漏环境类型，核心可用 Fake 驱动
L3 构建隔离：public/private 与依赖方向由构建系统和 lint 限制
L4 组合收敛：实例、注册和生命周期集中在唯一组合根
L5 适应度门禁：依赖、资源、时序和三视图差异持续自动验证
```

等级不能通过创建空目录、改名或补写文档跳跃。每一级的判据都必须由 [AM-006](architecture_methods_zh.md#AM-006) 转成可重复命令；没有命令的等级声明只能记为意图。

<a id="SYN-002"></a>
### SYN-002 成熟度不能按目录评分

分层命名、`Platform` 目录、`Port`/`Wrapper` 文件名和架构说明文档都只表达候选边界。评级必须检查 [AP-008](architecture_principles_zh.md#AP-008) 的三个视图，并按 [DR-013](dependency_rules_and_gates_zh.md#DR-013) 区分 planned 与 implemented。存在完整目录骨架但未接入构建的项目，其等级不高于 L0。

<a id="SYN-003"></a>
### SYN-003 一个边界必须成套落地

真正的解耦切片需要同时具备：稳定 Port、至少一个真实 Adapter、一个测试替身、唯一组合接线和对应门禁。缺任意一项都不能计入 L2 以上，可分别参考 [PAT-002](architecture_patterns_zh.md#PAT-002)、[PAT-006](architecture_patterns_zh.md#PAT-006) 和 [PAT-007](architecture_patterns_zh.md#PAT-007)。

<a id="SYN-004"></a>
### SYN-004 起步方式取决于项目状态

新项目容易犯的错误是先铺满模块占位，存量项目容易犯的错误是一次重写全部层次。正确顺序：新项目用 [AM-004](architecture_methods_zh.md#AM-004) 建立可校验脚手架后立即用 [AM-005](architecture_methods_zh.md#AM-005) 打通一个真实变化点；存量项目先用 [AM-010](architecture_methods_zh.md#AM-010) 测出泄漏基线，再用 [AM-007](architecture_methods_zh.md#AM-007) 绞杀式迁移。

<a id="SYN-005"></a>
### SYN-005 模式识别必须区分证据强度

Factory、Registry、状态机等名称只有在代码结构和职责同时吻合时才能使用。资源表与注册函数可以证明 [PAT-008](architecture_patterns_zh.md#PAT-008) 或 [PAT-021](architecture_patterns_zh.md#PAT-021) 的结构特征，却不自动证明 [PAT-009](architecture_patterns_zh.md#PAT-009)；空目录两者都不能证明。常见误判信号见 [SIG-007](leak_signals_and_baseline_zh.md#SIG-007)。

<a id="SYN-006"></a>
### SYN-006 先归一语义，再讨论层级

不同 SDK、教材和团队对 `Core`、`Device`、`Platform` 的含义不一致。依据 [AP-009](architecture_principles_zh.md#AP-009)，审查时先执行 [AM-009](architecture_methods_zh.md#AM-009) 把实际模块映射到角色 ID，再检查依赖。厂商换名只改变映射表，不改变通用架构。命名与角色不一致的可观察信号见 [SIG-001](leak_signals_and_baseline_zh.md#SIG-001)。

<a id="SYN-007"></a>
### SYN-007 Device 应拆为四类知识

外部器件链路至少要区分设备服务、器件协议、板级绑定和 MCU/OS 机制。`Device`、`BSP` 或 `Platform` 目录可以物理合并文件，但架构分析不能把这四类变化视为一个层，依据见 [DR-015](dependency_rules_and_gates_zh.md#DR-015)。

<a id="SYN-008"></a>
### SYN-008 解耦同时包含资源与时间契约

函数接口解耦只是第一步。资源 owner、初始化失败原子性、执行上下文、超时、错误映射和恢复责任必须一起进入模块契约，依据见 [DR-007](dependency_rules_and_gates_zh.md#DR-007) 与 [DR-011](dependency_rules_and_gates_zh.md#DR-011)。只声明函数签名而不声明上下文的 Port 不能计入 L2。

<a id="SYN-009"></a>
### SYN-009 C 技巧不是架构本身

函数指针表、回调、宏和动态内存可以实现模式，但不能代替变化分析。函数指针表可能是 Port/Strategy，也可能只是间接调用；静态对象同样可以完成依赖注入。模式判定以职责和选择权为准，而不是语法形状。

<a id="SYN-010"></a>
### SYN-010 结论必须按证据分级报告

依据 [AP-010](architecture_principles_zh.md#AP-010)，每条结论标注为以下之一：

| 级别 | 允许的依据 | 不允许的表述 |
|---|---|---|
| 已验证事实 | 命令、文件位置、构建日志、测试输出、硬件测量 | 用目录名或命名约定作为依据 |
| 有根据推断 | 职责、依赖和类型证据支撑的判断 | 写成“已解耦”“已平台化” |
| 未验证假设 | 需要目标板或未执行的测试 | 计入完成度或发布结论 |

“静态检查通过”不等于“硬件验证通过”；“目录已分层”不等于“依赖已隔离”。缺少同级别证据时，只能降级表述，不得升级。

<a id="SYN-011"></a>
### SYN-011 定级速查

| 提问 | 若答否，等级上限 |
|---|---|
| 是否存在“实际路径 -> 语义角色”的映射表并被引用？ | L0 |
| 公共 Port 头是否不含厂商/RTOS/寄存器类型？ | L1 |
| 核心逻辑能否用 Fake 在主机侧跑通正常与异常路径？ | L1 |
| 构建系统是否限制 include 可见性而非全局搜索路径？ | L2 |
| 实例创建与注册是否集中在唯一组合根？ | L3 |
| 依赖、资源、时序与三视图差异是否有持续执行的检查？ | L4 |

任何一项“否”都直接封顶，不能用其它项的完成度补偿。
