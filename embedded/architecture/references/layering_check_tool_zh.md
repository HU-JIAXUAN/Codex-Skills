# 分层检查器使用说明

本文件只说明如何用仓库内的检查器把架构约束变成可阻塞的命令。规则含义在[依赖规则与门禁](dependency_rules_and_gates_zh.md)，角色定义在[语义层级模型](semantic_layer_model_zh.md)，指标记录格式在[泄漏信号与基线测量](leak_signals_and_baseline_zh.md)。

检查器与具体项目解耦：所有目录、角色映射、厂商头模式和例外都来自项目自己的配置文件；脚本不包含任何仓库的目录名。

## 两个脚本

| 脚本 | 检查对象 | 对应门禁 |
|---|---|---|
| `scripts/validate_document_architecture.ps1` | 本 skill 自身的文档拓扑、ID 唯一归属、链接与锚点 | [GATE-007](dependency_rules_and_gates_zh.md#GATE-007) |
| `scripts/check_layering.ps1` | 目标工程的角色映射、依赖方向、公共头纯度、组合根可见性和过度抽象信号 | [GATE-001](dependency_rules_and_gates_zh.md#GATE-001)、[GATE-002](dependency_rules_and_gates_zh.md#GATE-002)、[GATE-009](dependency_rules_and_gates_zh.md#GATE-009) |

## 工具的位置：判断的下游

**检查器不判断架构，它只复核已经做出的判断。** 「哪些是用户代码」「哪些是厂商代码」「这个目录想表达什么」「什么算环境类型」，没有一项是脚本能看出来的——它们全部来自配置，而配置是模型和人读代码后的结论。

因此顺序固定为：

```text
1. 模型分析   按 AM-011 读仓库，定出环境边界、用户/厂商分界、各目录真实意图
2. 人工确认   结论写进 arch-map.json，含 analysis_confirmed_by 与每条规则的 evidence
3. 工具复核   机械校验，失败可阻塞
```

把顺序倒过来的后果见 [SIG-011](leak_signals_and_baseline_zh.md#SIG-011)：脚本会拿着残缺输入安静地报出一个看起来干净的 0。

## 使用步骤

1. 先跑证据模式抓原材料。它只输出可复现的事实，不下任何结论：

```bash
pwsh -File scripts/check_layering.ps1 -Root <项目根> -Evidence
```

2. 由模型和人依据这些事实和源码完成 [AM-011](architecture_methods_zh.md#AM-011) 与 [AM-009](architecture_methods_zh.md#AM-009)，得到“实际路径 -> 角色 ID”映射。
3. 复制 `scripts/arch-map.example.json` 到目标工程填写。**公共头与实现常常分处两个子目录，此时必须分开映射**，整个父目录一刀切是 [SIG-010](leak_signals_and_baseline_zh.md#SIG-010) 的典型成因。
4. 跑基线，不阻塞：

```bash
pwsh -File scripts/check_layering.ps1 -Root <项目根> -Map <项目>/arch-map.json -BaselineOnly
```

5. 把基线数值按 [SIG-008](leak_signals_and_baseline_zh.md#SIG-008) 记入项目架构说明。
6. 收敛一个纵向切片后，去掉 `-BaselineOnly` 接入 pre-commit 或 CI required check，让新增违规阻塞合并。

## 配置字段

| 字段 | 作用 | 缺省行为 |
|---|---|---|
| `modules` | 路径正则 -> 角色 ID，按顺序先匹配先生效 | 必填；未匹配文件报 DR-014 |
| `source_extensions` | 参与扫描的扩展名 | `.c` `.h` `.cpp` `.hpp` `.cc` |
| `exclude_patterns` | 跳过的路径正则（构建产物、生成 UI 等） | 空 |
| `language_include_patterns` | 不承担角色的语言标准头 | 内置 C 标准库列表 |
| `external_include_patterns` | 一律按 SL-010 处理的厂商/RTOS/生成头 | 空 |
| `forbidden_public_types` | 公共头中禁止出现的类型正则 | 空 |
| `public_header_roles` | 需要做纯度检查的角色 | SL-001～SL-004 |
| `port_roles` / `implementation_roles` / `composition_roles` | 过度抽象与组合根检查的角色集合 | SL-004 / SL-005～SL-008 / SL-006、SL-011 |
| `test_double_patterns` | 识别测试替身的路径正则 | `fake` `stub` `mock` |
| `allowed_dependencies` | 覆盖 [DR-002](dependency_rules_and_gates_zh.md#DR-002) 默认矩阵 | 使用默认矩阵 |
| `exceptions` | 按 `path_pattern` + `rule` 豁免 | 空 |

以下字段缺失时脚本**拒绝给出结论并返回 2**，因为它们都是判断输入，不是脚本能推断的：

| 字段 | 缺失后果 |
|---|---|
| `external_include_patterns` | 未声明厂商头长什么样，环境接触面无法判定 |
| `forbidden_public_types` | 未声明什么算环境类型，公共头纯度检查形同虚设 |
| `analysis_confirmed_by` | 角色映射未经确认，不得作为门禁依据 |
| 每条规则的 `role` 与 `evidence` | 无法复核该角色是怎么判出来的 |

`exceptions` 必须写 `reason`、`owner` 和 `expires`，并在项目架构说明的例外表中登记；没有到期条件的豁免等于取消该规则。配置可以记录迁移债务，但 `exceptions` 或 `allowed_dependencies` 不能取消 [DR-017](dependency_rules_and_gates_zh.md#DR-017) 的 APP 边界；豁免后得到 0 违规仍不能据此判定 APP 已解耦。

## 输出与退出码

| 退出码 | 含义 |
|---|---|
| `0` | 无违规（或 `-BaselineOnly`） |
| `1` | 存在违规；`-Strict` 时警告也算失败 |
| `2` | 配置错误、判断输入不完整、路径不存在或无源文件 |

`-Evidence` 模式恒返回 0，因为它不做判断，也就无所谓通过与否。

违规是阻塞项，逐条给出规则 ID、门禁 ID、文件和来源/目标角色。警告有两类：

- `DR-012`：Port 没有实现、或只有单一实现且无测试替身；以及**该 Port 的适配只包装了一个本来就环境中立的接口**——后者意味着它没有隔离任何环境类型，只增加了间接层。
- `DR-014`：一条映射规则同时盖住"环境中立的公共头"和"直接接触环境的源"，这通常是契约层与实现层被合并映射了。

按 [AP-006](architecture_principles_zh.md#AP-006) 处理：说明真实变化轴或测试收益，必要时复用已有稳定接口，减少无收益的间接层。退回直接依赖不能使 APP 接触环境实现，也不要为消除警告制造第二实现。

## 工具的边界

检查器只看源码 include 关系和文本模式，因此：

- 未解析的 include 当前会跳过，路径解析也不等同于编译器实际的搜索路径；必须结合编译配置核对未覆盖项。环境传递包含链虽参与事实/基线输出，但不等于已完整实现公共头传递污染阻塞；
- 不解析符号调用、宏展开、寄存器表达式或 `typedef` 别名传播；手写 `extern` 调用 HAL、访问另一业务模块的私有状态，以及同角色之间的越权访问，都可能漏检；
- 它不能证明构建系统真的限制了可见性，[GATE-003](dependency_rules_and_gates_zh.md#GATE-003) 仍需构建目标层面的检查；
- 它不能证明运行时的实例所有权和生命周期，[GATE-008](dependency_rules_and_gates_zh.md#GATE-008) 仍需组合根审查；
- 它不能证明时序、并发和资源预算，[GATE-005](dependency_rules_and_gates_zh.md#GATE-005) 必须由目标板测量；
- 通过并不等于架构成熟，等级仍按[架构成熟度与证据分级](architecture_maturity_zh.md)判定。

结果应表述为“在给定映射、模式与扫描范围内未发现违规”，把未覆盖部分单列。按 [GATE-011](dependency_rules_and_gates_zh.md#GATE-011) 选择与本次范围相称的补充检查。
