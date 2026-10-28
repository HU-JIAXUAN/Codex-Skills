# 验证与 Hook

Skill 负责说明怎么写；项目选定的配置负责裁决可机械检查的风格；检查器负责给出事实；Hook 将事实及时反馈给模型。提交/CI 继续检查真实提交内容。它们不能互相冒充，也不构成完整的安全边界。

## 先选择实际检查对象

1. 确定本次候选 C/H、文件归属、实际编码及允许修改范围，保留当前公共契约。
2. 使用当前项目已有规则；没有基线时可参考[格式示例](../assets/clang-format.yaml)和[Hook 配置示例](../assets/c99-policy.example.json)，结合项目需要采用。不要覆盖已有文件。
3. 同一工具必须实际读取同一配置；规范文字、模板、formatter 与 lint 发生冲突时先修冲突，不能挑选最容易通过的一条路。
4. 编译、静态分析与行为测试分别说明对象和证据范围。路径或配置不同，不能复用通过结论。

## 当前工具的真实覆盖

| 工具/路径 | 能证明什么 | 不能证明什么 |
|---|---|---|
| `clang-format --dry-run --Werror` | 当前文件符合给定 formatter 配置 | 命名动作准确、C99 合法、无越界、实时性或需求符合 |
| AiCoding `skill c99-standard-c check` | 已登记 skill 配置下的格式检查 | 不能简写为“C99 安全检查全部通过”；也不能假定任意业务仓库都有平台配置 |
| C Kit `contract` | 当前配置、目标文件与 Agent 约束的可读合同 | 合同中的 requireBuild/requireTests 等字样不等于实际执行了构建/测试 |
| C Kit `lint` | 当前配置支持的命名、部分轻量结构/说明/禁止项诊断 | 不是完整 C AST、控制流、别名、ISR 或硬件副作用分析 |
| C Kit 外部 `verify` | 指定 target 快照的 lint、实际 host 编译、头文件探针和指定 host 行为验证 | 默认 demo 通过不代表用户文件通过，host 通过不代表目标固件/板级通过 |
| 项目编译、分析器和行为测试 | 该命令覆盖的真实源文件、宏配置与用例 | 一次零告警不能证明所有宏分支、运行环境或边界都正确 |

命名模式、复杂度诊断等级与新配置是否受当前安装的 C Kit 支持，必须先读实际 `contract`/版本与命令帮助；旧安装不能仅靠新增 overlay 字段获得未实现能力。

## 复用 C Kit，不把 demo 当作用户模板

通过 `AICODING_HOME`、平台安装状态或项目发现协议定位 Kit；找不到时报告不可用，使用项目已有工具。禁止依赖个人绝对路径或从插件缓存向上猜相邻源码。

下面的 `<KitRoot>`、`<AiCodingRoot>`、`<ProjectRoot>` 需要替换成实际已验证的位置。相对 `--target`/`--overlay` 路径由 AiCoding 控制面解析，因此业务目标宜用绝对路径：

```powershell
# 在 Kit 根运行，明确检查业务候选；不要拿 Kit 的 Git index 代替业务 index
ckit contract --config "<ProjectRoot>/c-kit.json" --file "<ProjectRoot>/src/sensor.c"
ckit lint --config "<ProjectRoot>/c-kit.json" --scope files --file "<ProjectRoot>/src/sensor.c" --json

# 有完整 host target 时，分别采用 fast 或 full，不用默认 demo 证明业务代码
"<AiCodingRoot>/bin/aicoding.exe" skill c99-standard-c verify --depth fast --target "<ProjectRoot>/verify-target.json" --overlay "<ProjectRoot>/c-kit.overlay.json" --repo-root "<AiCodingRoot>" --json
```

`ckit` 指当前 Kit 构建的 CLI，不保证已在 PATH。无预编译 CLI 时可以按 Kit 自身说明运行 Go 源码；不要把会首次编译的 `go run` 塞进短时同步 Hook。声明旧 DEMO 前缀的配置只用于该示例；通用项目使用匹配当前命名/注释的配置或便携 overlay。复杂度 review/warning 需要解释和人工判断，不得被描述为已经满足度量上限。

## 项目显式启用 C99 Hook

插件包含 C99 guard 的 `PreToolUse`、`PostToolUse` 和 `Stop` 适配。没有项目 `.c99-policy.json` 时，明确 C/H patch 只得到简短编码提醒，不启用一套未经项目选择的硬门禁。

启用步骤：

1. 按当前项目确定自研 include、排除范围与确实禁止修改的 protected 路径。第三方/生成目录默认排除检查；是否禁止修改是另一项明确的项目决定。
2. 在项目根采用配置示例为 `.c99-policy.json`，保留/复用已确认的 `.clang-format`。无已有格式基线时才采用格式示例。检查命令必须真实可用。
3. `checks` 只登记只读验证，不能包含格式化 `-i`、自动修复、commit/push、设备烧录或部署。项目确认的是命令本身的职责；guard 不会证明任意配置命令没有副作用。
4. 先在小型改动中观察写前提示、写后诊断、失败恢复和一次收尾复核；将稳定检查接入项目已有提交 Hook/CI，防止直接 shell 提交、外部编辑器或其他未覆盖路径绕过会话观察。
5. 插件 Hook 定义变化后通过 Codex `/hooks` 审阅并信任，之后才可报告“运行时已启用”。源码、打包通过与运行时信任是不同状态。

配置的稳定字段为：`schemaVersion: 1`、`include`、`exclude`、`protected`、`checks`。每个 check 使用 `id`、`argv` 数组和 `timeoutSeconds`；`{root}`/`{pluginRoot}` 替换路径，独立的 `{files}` 展开为本轮候选文件。需要重复 `--file` 的工具可设置 `fileArgument: "--file"`。不用 shell 拼接参数，中文、空格路径保持独立 argv 元素。

检查器必须同步执行。主进程返回时仍有后台子进程、超时或输出超过 64 KiB 均判为未验证，并回收受管进程树；命令配置不能把后台运行当作完成。

示例的 formatter 明确读取 `{root}/.clang-format`，配置缺失应报失败；不会退回某种默认风格后假装采用了用户基线。Cppcheck 的 include、宏、平台模型仍须按项目设置，不能为了得到绿色结果而扩大 suppress 或排除全部源文件。

## 每个事件的作用

| 事件 | guard 的职责 | 覆盖边界 |
|---|---|---|
| PreToolUse | 识别结构化 patch 路径，注入简短约束；显式 protected 写入事前拒绝；记录工具前文件指纹 | 启用策略时拒绝受管 symlink/junction；跨项目 C/H patch 要求在目标 cwd 分别执行，不预测任意脚本的写入 |
| PostToolUse | 发现相对工具前基线变化的项目 C/H，运行选定只读检查并回传具体诊断 | 文件已经修改；反馈或拒绝工具结果不会撤销改动 |
| Stop | 复核本轮变更及配置，对未通过结果请求一次修复；续跑后仍失败则明确未完成 | 不无限续跑，也不能证明已经加载 Skill 或满足需求语义 |

未变化的预存脏文件不能自动算成本轮修改。结果必须对应当前文件与配置；再次变化需要重查。命令缺失、超时、异常、配置在本轮变化或状态不可用，都不能作为通过。状态只写入 `PLUGIN_DATA`，不修改业务源文件。

状态按仓库、session 和 turn 隔离，父子 Agent 共用 session 时也不覆盖基线。Stop 仅复核同 turn 的已观察仓库；不同 turn 缺少原基线时报告未验证，不猜测它与旧续跑的关联。

同步 Hook 有短时预算，适合快速格式和轻量 lint。完整固件构建、host 行为验证、WCET 与板级检查在正式命令中执行和记录，不强塞进每次编辑。Stop 的反馈是自动继续提示，最终提交/CI 门禁必须独立存在。

shell 内部自行切换目录、未被显式 patch 观察到的 Git ignored 文件、其他工具或编辑器写入等路径不在完整覆盖范围内。Hook 反馈只能说明其实际观察和调用的检查，提交/CI 必须独立验证最终内容。
