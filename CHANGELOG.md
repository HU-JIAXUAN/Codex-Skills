# 更新日志

## 2026-10-28

### 更新 / Changed

- **fix(skill-creator)**：创建或修改任意 Skill 时必须先加载技能创建入口，并显式允许隐式调用；正文限定为触发、设计步骤、规则、例子和验证方法，清除自我说明及重复审批要求。 / Requires the creator workflow for Skill edits and limits instruction content to executable guidance.
- **feat(c99-kit)**：C99 保留单一入口，按任务、文件操作与代码语境路由十个内部专题；统一函数输入输出/失败合同、文件/函数/关键代码注释及格式配置，增加139条中性题干导航和可编译边界示例。 / Adds ten internal C99 topics, consistent interface/comment contracts and neutral navigation.
- **feat(c99-hooks)**：新增显式项目策略驱动的写前/写后/收尾辅助门禁，调用有界只读检查器；增加真实事件回归与套件资源/路由门禁。Hook 定义安装后仍需 `/hooks` 审阅。 / Adds opt-in bounded C99 checks and executable routing/package gates; runtime Hook trust remains separate.

- **build(plugin)**：从已提交的 `f1091c6` 源码生成 14 个运行时入口，对象/数据模型随架构入口内部打包；`dirtySource=false`，通过插件、文档依赖与重复构建检查。 / Packages 14 runtime skills from committed sources with internal architecture guides and deterministic output.
- **refactor(architecture-routing)**：对象模型与数据模型收为 `embedded/architecture/` 下的内部 `GUIDE.md`，保留各自 references/evals，删除独立运行时入口与子 UI 元数据，由 `aicoding-architecture` 按需路由；嵌入式模块化、平台化/平台适配、解耦必须先加载架构 Skill，按任务选用内容，不强制全套架构流程。 / Consolidates object and data modeling behind the architecture entry and requires that entry for embedded modularization, platform work and decoupling.
- **build(plugin)**：从已提交的 `53739b7` 源码生成 16 个运行时入口，包含对象/数据模型、通用 DSP 与单入口电机套件；`dirtySource=false`，通过插件、资源一致性和重复构建检查。 / Packages 16 verified runtime skills from committed sources with complete internal motor topics and deterministic output.
- **fix(buildinfo)**：构建检查按原始中文路径识别生成文件，避免电机专题迁移后的 Git 路径转义被误判为源码未提交。 / Preserves Unicode paths when determining source dirtiness for generated packages.
- **build(plugin-layout)**：打包清单同步对象/数据模型入口、单入口电机套件和独立开发辅助技能；更新仓库导航与构建说明，生成内容由源码构建维护。 / Aligns the focused plugin manifest, repository navigation and reproducible packaging documentation.
- **refactor(development-skills)**：删除 `aicoding-sdd-bdd-tdd-development-flow`、`aicoding-sdd-spec-driven-development`、`aicoding-tdd-fallback` 的 canonical source、插件打包项与专用模板；架构入口改用项目自身流程，MVP、BDD、文档同步独立使用，并将各自模板纳入 Skill 包内。 / Removes three development workflow entries and their unused resources, decouples retained skills and packages their own templates.
- **feat(data-model-design)**：新增“数据模型设计”子 Skill，按字段语义、类型、读写权限、存储与有效期解释 cfg/ctx/data/ops；补充配置共享、快照/新鲜度、行为兼容和示例量纲取舍，主架构及对象模型按需路由，继续保留轻量实现与 App 资产沉淀。 / Adds focused internal data-model design with typed ownership, storage and validity guidance.
- **docs(architecture-reasoning)**：选择性固化基本概念、不变量和可机械检查项，强调由 LLM 结合业务、变化与约束推导对象、数据和分层方案；示例用于解释取舍，避免固化结构和额外流程。 / Preserves concepts and design reasoning while leaving contextual architecture choices to project evidence.
- **feat(object-model-design)**：新增“对象模型设计”子 Skill，由架构主入口按需路由并可独立调用；覆盖对象职责、身份、协作与生命周期，将统一对象头、manager、C 首成员和 magic/type 作为按需知识，内部字段交由数据模型专项。 / Adds focused object responsibility, identity, collaboration and lifecycle reasoning with optional management representations.
- **refactor(motor-routing)**：将电机与伺服套件改为单一 `aicoding-motor-control` 入口，21个专项作为内部 `GUIDE.md` 及参考资料统一打包和按需路由；保留稳定能力ID与唯一算法/证据资产。构建器支持单入口SkillKit v2，门禁检查发现入口、路由、资源一致性与负例；构建与漂移检查共享有界互斥，拒绝重建失败和整个套件缺失。 / Consolidates 22 motor capabilities into one discoverable skill with 21 internal guides, serialized builds and executable packaging gates.
- **feat(dsp)**：将 DSP 完善为通用信号处理与固件工程入口，增加数值/ABI、滤波/FFT/采样、实时数据链/工具链三类方法及处理器系列参考；只读提炼个人 C2000 笔记并用官方资料复核，具体系列不成为主路由，新增 16 项行为评估。 / Expands the generic DSP skill with numeric, streaming, toolchain and family adaptation guidance without chip-specific routing.
- **feat(architecture-boundaries)**：补充 APP、中间件、OS、BSP、Core、Driver 的职责、输入输出与跨厂商语义映射，区分采集发布、调度同步和硬件绑定；新增 DR-017/GATE-011，围绕 APP 环境隔离和私有状态归属选择相称的行为、构建或符号证据，保留裸机及强实时静态绑定。 / Defines vendor-neutral layer concepts and proportionate APP decoupling verification while retaining static real-time execution.
- **feat(architecture-assets)**：贯通对象、数据与生命周期设计，明确工程开发必须考虑 App 产品流程、状态机、业务规则和数据模型的资产沉淀，保留轻量使用与验证说明。 / Adds object/lifecycle guidance and mandatory consideration of reusable App knowledge and code.
- **fix(architecture-guidance)**：固化解耦、职责、依赖与所有权思想，将五层与 cfg/ctx/data/ops 保留为参考；精简固定层级验收、资产分级与台账要求。 / Keeps architectural principles firm while leaving layouts, checks and asset records proportional to the project.
- **fix(architecture-evidence)**：明确分层扫描器的符号、未解析 include、传递污染与同角色状态访问盲区，修正门禁实现状态声明，增加四项行为评估并收紧过度抽象条款的适用边界。 / Documents checker limits and adds behavioral evaluations for APP boundaries and execution contexts.
- **refactor(architecture)**：架构、对象模型、数据模型按系统关系、对象协作和内部数据明确职责，按实际问题独立使用或协作；去掉重复流程、固定全套 Port/Adapter/Fake、机械成熟度封顶和普遍确认要求，移除普通软件骨架/验证的开发流程耦合，保留基本概念、设计推理与 App 资产沉淀要求。 / Separates the three design capabilities, removes prescribed structures and development-flow coupling, and retains contextual reasoning and App asset retention.
- **fix(architecture-workflow)**：精简触发说明和主入口，按新建骨架、存量审查/迁移及量产边界分流，按需加载参考；骨架、替身、真实实现与实机证据分别验收，更新 UI 名称、提示词和行为评估。 / Adds scoped routing, progressive references and distinct evidence for scaffolds, fakes, implementations and hardware.

## 2026-10-26

### 新增 / Added

- **feat(motor-engineering)**：新增电机控制实机部署与实时验证，MotorControl保留21项原路由并扩为22项；公共工程契约关联唯一C99算法/Golden与Go源码、时序、采样窗口工具，按L1—L7区分证据和未实现变体。 / Adds hardware deployment analysis and executable engineering contracts without duplicating algorithm sources.
- **feat(current-sampling)**：默认推荐硬件PWM/定时器触发ADC与反馈同一时基；补单电阻、双/三低侧及inline的窗口、重构、错拍和降级规则，并核对实际QEP/BiSS锁存边界。 / Adds evidence-backed synchronization and shunt sampling/reconstruction rules.
- **test(motor-contract)**：路由与生成资源检查验证公共事实只打包一次；来源索引记录教材核读页、论文阅读范围、开源Commit/符号/许可证，未测硬件仍为NOT_MEASURED。 / Adds route/resource checks and scoped source provenance.
- **feat(local-engineering-evidence)**：深读本地TI文章/教材/离散频域资料，对照ODrive、ODRI、STM32及F28388D工程，补充13条条件→动作→验收规则；修正9份专项参考中的伪接口和离散顺序歧义，优先适配已有控制链、PI、CLA与低通资产。 / Adds local source-backed decision rules and removes misleading implementation contracts.

### 构建 / Build

- **build(plugin)**：从已提交源码生成39项技能的可复现插件包，供AiCoding锁定已推送并核验的依赖；安装刷新和实机验收单独记录。 / Generates 39 bundled skills from committed sources; installation and hardware evidence remain separate.

## 2026-10-25

### 新增 / Added

- **feat(motor-servo)**：形成21个中文显示名称的电机/高性能伺服技能入口（保留兼容的ASCII技术ID），新增20个专项及各自方法选择、公式/离散实现、调参与工程验证references；覆盖参数辨识、反馈/无传感器、MTPA/弱磁、死区、dq解耦、前馈、轨迹、频响/整定、抑振/观测、摩擦/纹波与双反馈。 / Adds 20 specialized skills alongside the existing integration skill, with Chinese UI names and implementation references.
- **feat(validation)**：增加离线CSV误差/停稳/电流指标工具与自检，并定义外部CodingKit三条严格C99纵向案例的接入与证据边界。 / Adds offline metrics and contracts for three C99 host validation chains.

### 更新 / Changed

- **build(plugin)**：从已提交的5d70799技能源码生成38项正式插件技能，其中电机套件21项；保持dirtySource=false，核验Codex实际技能发现与完整资源。 / Builds 38 bundled skills from committed sources, including all 21 motor-control entries, with runtime discovery verification.

- **fix(c99-comments)**：普通注释默认使用简易中文块说明，不附Doxygen标签或句末句号；允许星号分区和重点标记，参数字段写清作用、单位和例子，移除默认函数历史表模板。 / Uses plain Chinese comments by default while allowing section banners and keeping field documentation practical.

- **fix(markdown)**：本地链接校验排除围栏代码和数学文本，避免将C二维数组或矩阵公式误判成引用链接；补充真实坏链接与代码/数学回归。 / Excludes fenced code and mathematics from reference-link parsing with regression coverage.
- **fix(motor-contracts)**：统一峰值/RMS、磁链与增量电感、异步反馈年龄、前馈求和点、最终调制约束与抗饱和评价点；采样策略按工程证据推荐，避免强制逐周期新编码器帧和不必要追问。 / Clarifies units, models, timing, realizability and anti-windup contracts.
- **build(motor-skillkit)**：技能、refs与套件配置集中到embedded/motorcontrol，增加经典频域设计与激励设计，参数辨识归系统辨识；构建器支持套件展开与资源include。推送前通过标准构建器生成全部成员，并验证运行时发现、资源完整性与Git门禁。 / Consolidates 21 skills into a nested source kit and verifies packaging, runtime discovery and publication gates.

## 2026-09-14

### 更新 / Changed

- **docs(external-skill)**：核对 `mattpocock/skills` 上游最新稳定版仍为 `v1.2.3`（`6acc160e4e0cd062dbbbd7a1b26ae92855edf07e`），正式 plugin 清单的 25 个 engineering/productivity Skills 与 `config/external-skill-bindings.json` 完全一致；本次保留既有外部 gitlink、绑定和上游源码。 / Confirms the pinned stable release and all 25 published Skill bindings without changing the upstream source or gitlink.
- **docs(runtime-skills)**：记录配套 AiCoding `config/codex-kit.json` 的 `profiles.full.standaloneSkills` 从 11 个 Matt Pocock Skill 扩展到全部 25 个，并通过 `runtime-skill` lifecycle 补齐 14 个独立 junction：`ask-matt`、`grill-with-docs`、`handoff`、`implement`、`improve-codebase-architecture`、`setup-matt-pocock-skills`、`teach`、`to-questionnaire`、`to-spec`、`to-tickets`、`triage`、`wait-what`、`wayfinder`、`wizard`。保留其他 standalone Skill，上游 `misc` / `in-progress` 不启用；严格运行时审计确认 25 个目标有效、无重复名称、无断链。 / Records the paired AiCoding runtime expansion from 11 to all 25 published Matt Pocock Skills, with 14 managed links added and unpublished directories excluded.

## 2026-08-28

### 更新 / Changed

- **docs(c99)**：补充函数按动作命名、完整单词或统一缩写、禁止汉语拼音、协议与系统专用缩写治理、反义动作和函数指针命名规则，并加入 `arg/buff/clk/cmd/cmp/cfg/dev/err/hex/inc/init/max/msg/min/para/prev/reg/sem/stat/sync/tmp` 统一表；add action-oriented function naming, governed abbreviations, no-pinyin, protocol/system abbreviation, antonym, and function-pointer rules with one canonical abbreviation table.
- **build(plugin)**：从已验证的干净 `7d095ec` canonical source commit 重新生成 AiCoding Plugin，同步函数动作命名与统一缩写规则并保持 `dirtySource=false`；regenerate the AiCoding package from the verified canonical source commit and preserve clean build metadata.

## 2026-08-24

### 更新 / Changed

- **docs(c99)**：明确注释只能位于所说明代码的右侧或紧邻上方，上方注释须与前段代码空行并保持同级缩进；要求枚举值逐项说明具体含义，并要求有意 fallthrough 在相邻 `case` 之间注明目标和原因；clarify comment placement, per-enumerator meaning, and explicit target-and-reason documentation for intentional fallthrough.
- **build(plugin)**：从已验证的干净 `8e80acc` canonical source commit 重新生成 AiCoding Plugin，同步 C99 枚举与控制流注释规则并保持 `dirtySource=false`；regenerate the AiCoding package from the verified canonical source commit and preserve clean build metadata.

## 2026-08-21

### 更新 / Changed

- **refactor(skills)**：将本地 standalone Skill 收敛到 `standalone/` 白名单，仅保留 JSON Canvas、MCP Builder、Obsidian Bases/CLI/Markdown、Visio Diagram 和 Webapp Testing；删除重复原生文件工作流、Anthropic 专用辅助、生成艺术及未采用的通用 Skill；converge local standalone Skills into one allowlisted directory and remove redundant or unused workflows.
- **refactor(plugin)**：停止打包宽泛的 `aicoding-embedded` 总入口，仅保留职责明确的细分 `aicoding-*` Skill，避免路由器与具体领域 Skill 重复触发；remove the broad embedded umbrella from the plugin and retain focused leaf workflows.
- **fix(build)**：生成 Skill 被删除时也按生成路径排除 Git dirty 判定，避免 plugin rebuild 将干净的 canonical source 误报为脏；ignore every generated-path status, including deletions, when computing plugin source dirtiness.
- **build(plugin)**：从干净的 `14744b9` canonical source 重新生成 AiCoding Plugin，删除生成的 `aicoding-embedded` 并记录 `dirtySource=false`；regenerate the focused plugin package from the verified clean source commit.
- **docs(architecture)**：在中英文 README 目录导航和架构文档中明确 `standalone/`、`external/`、canonical source 与生成插件之间的边界；document the converged repository navigation and source/package boundaries.
- **docs(c99)**：补强嵌入式 C99 函数命名、入参与函数/回调设计契约：新函数使用 `snake_case`，不超过 32 个字符、默认不超过两个下划线且每词不超过 12 个字符，多词模块使用统一短前缀；参数按上下文、输入、输出分组，超过 5 个进入设计审查而非机械封装；复杂度指标改为人工审查信号，并将可机器检查的名称形态与必须人工判断的职责、内聚性和生命周期明确分流；strengthen C99 naming, parameter, function, and callback contracts while keeping semantic design review human-owned.
- **build(plugin)**：从干净的 `57f8e1e` canonical source 重新生成 AiCoding Plugin，同步 C99 函数接口规则并记录 `dirtySource=false`；regenerate the AiCoding package from the verified C99 source commit and preserve clean build metadata.

## 2026-08-18

### 新增 / Added

- **feat(external-skill)**：以共享 Git submodule 将 `mattpocock/skills` 最新稳定版本 `v1.2.3` 固定到 `external/mattpocock-skills`，并按其正式 plugin 清单映射 25 个 engineering/productivity Skills；pin the latest stable upstream release and expose only its published Skill set through explicit nested paths.

### 更新 / Changed

- **build(plugin)**：从干净的 `8e15779` canonical source commit 重新生成 AiCoding Plugin，将共享外部仓库生命周期规则同步到 packaged `aicoding-kit-maintenance`，并记录 `dirtySource=false`；regenerate the package from the clean canonical source commit and preserve clean build metadata.
- **fix(external-skill)**：外部 Skill 生命周期现在支持一个上游仓库承载多个 Skill；同步只抓取一次共享 submodule，移除单个 binding 时保留仍被其他 binding 使用的 `.gitmodules` section 和 gitlink，最后一个 binding 移除时再清理仓库链接；support shared-repository bindings without redundant fetches or premature submodule removal.

## 2026-07-27

### 更新 / Changed

- **build(plugin)**：从干净的 `2a4a67c` canonical 源树重新生成 AiCoding Plugin，纳入架构 Skill 新增的规范、模板、检查脚本、治理章节与嵌入式路由更新，并将 `BUILDINFO.json` 固化为 `dirtySource=false`；regenerate the official AiCoding package from the clean canonical source tree and record clean build metadata.
- **fix(embedded-architecture)**：将门禁规则与人工反馈确认拆为独立治理章节，使 standard/workflow Skill 契约可由 `skill_gate.py validate` 阻断验证；split gate rules and human confirmation into independently verifiable governance sections.
- **feat(embedded-architecture)**：把架构 skill 重建为按 ID 引用的规范体系（`AP-*` 原则、`SL-*` 语义角色、`DR-*`/`GATE-*` 规则门禁、`AM-*` 方法、`PAT-*` 模式、`SYN-*` 成熟度、`SIG-*` 泄漏信号），新增 `document-architecture.json` 与自校验脚本强制单一所有权、依赖无环、链接与声明一致、锚点有效和 ID 唯一归属；rebuild the embedded architecture skill around a self-validating ID system.
- **feat(embedded-architecture)**：新增 `check_layering.ps1` 分层检查器，按语义角色而非目录名校验依赖方向、公共头环境纯度、组合根可见性，并给出过度抽象（`DR-012`）与"一条映射盖住契约+实现两个角色"（`DR-014`）警告；配置来自项目自身，脚本不含任何仓库路径；add a project-decoupled layering checker driven by the project's own role map.
- **fix(embedded-architecture)**：把工具明确置于人工判断的下游——「哪些是用户代码」「什么算环境类型」「目录意图」均非脚本可推断，故 `external_include_patterns`、`forbidden_public_types`、`analysis_confirmed_by` 或规则 `evidence` 缺失时拒绝给出结论并返回 2，不再静默报 0；新增 `-Evidence` 只抓事实模式与 `AM-011` 分析先行方法；make the checker refuse to conclude on incomplete judgement inputs instead of silently reporting zero.

## 2026-07-23

### 更新 / Changed

- **docs(git-readme)**：修正架构图小bug.

## 2026-07-22

### 更新 / Changed

- **fix(git-governance)**：在 Windows PowerShell 5 中按退出码捕获 README 治理验证器的预期 stderr，使缺徽章、能力漂移、四象限、凭据和 Mermaid 负例能够继续执行并断言错误码；capture expected validator stderr without terminating the negative-case matrix on Windows PowerShell 5.
- **docs(architecture)**：新增由单一 Diagram IR 生成的横版 Visio 架构图，以 light/dark SVG 和 GitHub `#gh-light-mode-only` / `#gh-dark-mode-only` 标记实现主题 Banner；README、README_CN、README_EN、移动端和远程端复用同一资产对，并支持点击阅读原图；add one semantic Visio source with theme-aware SVG Banners shared by every README surface.
- **feat(git-governance)**：将 canonical 标准升至 `2026.07.22`，加入可选的 README 三层结构、技术栈徽章投影、可再生双主题 banner、Mermaid 架构图、能力橱窗、四象限演进与安全 Star History profile；add portable opt-in README profiles while keeping repositories without the new TOML sections behavior-compatible.
- **test(git-governance)**：新增仓库中立 adapter 契约与非 AiCoding fixture，覆盖旧 TOML 兼容、版本徽章、能力缺行/幽灵行、四象限、Star History 凭据和 Mermaid 节点/命令负例；exercise portable README policy without coupling the standard to the AiCoding Kit registry.

## 2026-07-16

### 更新 / Changed

- **fix(plugin-buildinfo)**：将生成包中的 HTML 纳入稳定文本换行归一化，并按 ordinal 相对路径排序计算树摘要，消除 Windows PowerShell 与 `pwsh` 的文化排序差异；同时从当前源码重新生成 `BUILDINFO.json`，使 fresh worktree 重建和 installed-cache 漂移检查都对应同一 19-Skill 发布包；normalize generated HTML and use ordinal relative-path ordering so both PowerShell runtimes produce the same package digest.
- **feat(visio-diagram)**：新增通用 standalone `visio-diagram` Skill，以精简入口和按需 references 覆盖工程/控制框图、泳道图、流程图与状态机，并明确不包含时序图工作流；add a progressively loaded generic Visio workflow without coupling it to the AiCoding plugin.
- **fix(visio-diagram)**：将侧边中心/多端口车道、双端 glue、正交路由以及文字不得覆盖连接线、框线或其他文字设为阻断门禁；make connector geometry and text-clearance failures block final export.
- **fix(visio-diagram)**：新增紧凑布局、同轴可统一尺寸、逐维内容/端口尺寸包络、容器有界 padding，以及箭头头尾不得穿入节点的阻断规则；add measurable compactness, bounded sizing, container, and arrow-clearance gates.
- **fix(visio-diagram)**：新增连接文字相对中点锚定和有界漂移、框体外部标题绑定、profile Latin/Asian 字体、普通框 80% 文本安全区与真实检查门禁；add bounded label/caption anchors, requested fonts, and measured text-safe-area checks.
- **feat(visio-diagram)**：新增渐进加载的精简 JSON 样式 reference，仅暴露字体组、默认字号、文字安全区、线宽和圆角，默认保持早期紧凑视觉；标版字号仅按元素显式应用，并以真实字号/线宽/圆角门禁验证；add restrained configurable typography and line-style standards without global restyling.
- **fix(visio-diagram)**：同轴同尺寸族连续节点的框间距改用页面绝对边界检查，组内差值超过 `0.03 in` 即阻断；enforce equal absolute boundary gaps for comparable same-axis nodes.
- **docs(visio-diagram)**：吸收 Visiomaster 的场景契约、renderer-effective 字段和双阶段视觉回归思想，新增精简按需复刻/回归 reference，并明确不复制其品牌与在线标签缺陷；adapt the useful source-driven and no-op review loop without importing upstream coupling.
- **build(visio-diagram)**：补齐 consistent-workflow 类型、Workflow Contract、Gate Rules 与人工 PNG 复核契约；make the standalone workflow satisfy repository Skill governance.

## 2026-07-15

### 新增 / Added

- **feat(external-skill)**：以嵌套 Git submodule 将 Agents365-ai `drawio-skill` 最新稳定 tag `v1.34.0` 绑定到 `external/drawio-skill`，并通过 `config/external-skill-bindings.json` 映射真实入口 `skills/drawio-skill`；bind the latest stable upstream draw.io release without maintaining copied source.
- **feat(external-skill)**：新增 `scripts/manage-external-skills.ps1`，支持外部 Skill 稳定版本状态、同步更新和同步移除 manifest/`.gitmodules`/gitlink；add dry-run-first lifecycle management for URL-bound Skills.
- **fix(external-skill)**：同步操作会暂存新的 gitlink，卸载操作通过标准 `git rm` 原子更新 `.gitmodules` 并检查关键子命令结果；make sync and uninstall changes commit-ready and fail fast.
- **build(governance)**：规定后续所有 GitHub 来源 Skill 必须通过 `external/` 子模块链集成，并由 `verify-skills.ps1` 校验 gitlink、URL、稳定 tag、Skill 子路径和 frontmatter 名称；enforce latest-stable URL-bound integration for future GitHub sources.
- **refactor(drawio)**：移除仓库内旧的复制版 `drawio/`，由上游 URL 绑定的 `drawio-skill` 替代；replace the legacy copied Skill with the maintained upstream source.

## 2026-07-08

### 更新 / Changed

- **docs(c99)**：明确 C99 修改记录中的作者字段默认使用 `HU JIAXUAN`，但项目已有负责人、作者或文件头规则时按项目规范替换；clarify the default C99 change-record author while preserving project-specific owner and file-header rules.
- **docs(readme)**：治理 README/README_CN，移除个人本地绝对路径，补充英文 Runtime Principles 和中文 Release 链接，并扩展 lint 以检查 README 双语治理与本地路径泄漏；govern README/README_CN, remove personal local paths, add runtime/release links, and extend lint for bilingual README governance.
- **docs(readme)**：将 README/README_CN 收敛到同一 `minimal-internal` profile，补齐状态、快速开始、文档支持、更新日志和发布入口，并让 lint 按同一 profile 校验双语 README；align README/README_CN to one `minimal-internal` profile and enforce the same profile in lint.
- **docs(git-governance)**：建立统一 Git 治理 canonical URL，同步 README 默认中文首页、README_CN/README_EN 文件级分流、环境 badge、GitHub About 和 lint 模板，后续仓库必须通过 `[governance_standard]` 引用同一标准；establish the canonical Git governance URL and enforce Chinese-first README, README_CN/README_EN switching, environment badges, GitHub About, and lint templates for future repositories.
## 2026-06-27

### 新增 / Added
- **feat(git-governance)**：为 Codex-Skills 本仓库新增 `.githooks/`、`.github/repository-governance.toml` 和 `scripts/lint-git-governance.ps1`，把 README 中文链接、Git 治理标准、commit type 和 Release typed summary 规则接入当前 Git hook；wire the governance lint into this repository Git hook.
- **feat(git-governance)**：新增 `assets/lint-git-governance.ps1` hook/lint 模板，机器检查 README 中文链接、Git 治理标准、commit type 和 Release typed summary 规则；add a reusable hook/lint template that enforces README Chinese-link, Git governance, commit type, and release typed-summary rules.
- **docs(git-governance)**：补充分支命名、环境映射、commit type、单次提交约束和 Release typed commit summary 标准，要求所有 AiCoding 管理仓库在 README 或等价治理文档中写明；document branch/environment, commit type, single-commit, and release typed-summary standards for all AiCoding-governed repositories.
- **docs(repo)**：新增 Apache-2.0 `LICENSE`、`CONTRIBUTING.md`、`SECURITY.md` 和 `CITATION.cff`，补齐 GitHub About 侧栏可识别的仓库元数据文件；add repository metadata files recognized by GitHub About.
- **docs(git-governance)**：要求存在 `README_CN.md` 时 `README.md` 顶部提供显眼中文文档链接，并更新 Codex-Skills README 顶部链接为中英双语；require a visible top-of-file Chinese documentation link in `README.md` when `README_CN.md` exists.

- **feat(platform)**：新增 AiCoding SDD/MVP/BDD/架构优先/TDD fallback/文档同步 workflow skills 与共享 references，并将其纳入 AiCoding Plugin 打包清单；add standalone-capable SDD, MVP, BDD, architecture-first, TDD fallback, documentation synchronization workflow skills and shared references, and package them in the AiCoding Plugin.

## 2026-06-26

### 新增 / Added

- **docs**：新增 `README_CN.md` 中文入口，并在 `README.md` 链接中文说明；add a Chinese README entry and link it from the English README.

### 更新 / Changed

- **docs**：更新 `aicoding-git-governance` 的 README、CHANGELOG、Tag 和 GitHub Release 语言策略，默认采用中文优先的中英双语治理；update Git-Skill governance so README, CHANGELOG, Tag, and Release workflows default to bilingual Chinese/English handling.
- **fix(build)**：规范化 AiCoding Plugin 生成文本和 BUILDINFO digest，避免新 clone 或不同换行策略导致构建漂移；normalize generated plugin text and BUILDINFO digests so fresh clones do not drift because of line endings.
- **build**：新增 .gitattributes 约束并重新归一化 generated plugin 文本，确保新电脑 checkout 后重复构建不产生换行漂移；add generated plugin eol attributes and renormalize package text for clean fresh-checkout rebuilds.

### 修复

- **fix(skill)**：修复 `aicoding-git-governance` workflow contract 中残留的字面量换行标记，保持 canonical source 与生成 plugin 文档格式一致；fix the literal newline marker in the Git governance Skill workflow contract so canonical source and generated plugin docs render consistently.

- **fix(tooling)**：修复 `scripts/compare-generated.ps1` 对 `plugins/AiCoding/BUILDINFO.json` 的非自引用构建模型误报；漂移检查现在比较 BUILDINFO 稳定字段，并按字节恢复可变元数据，避免 `sourceCommit`、`sourceTag`、`buildTimestampUtc` 和 `dirtySource` 造成重复构建漂移。
## 2026-06-25

### 新增

- **feat**：新增 `platform/aicoding-kit-maintenance/`，定义 Codex-Skills/AiCoding 双仓库维护流程，明确 AGENTS 边界、架构文档、config/scripts 执行入口以及 Git hooks/CI 完成门禁。
- **docs**：新增根 `AGENTS.md`、`plugins/AiCoding/AGENTS.md` 和 `docs/PLUGIN_DEVELOPMENT.md`，明确人工维护区、自动生成区、Hook 辅助边界和跨仓库发布顺序。
- 新增 `skill-creator/`，将原 Anthropic skill creator 迁移为 Codex/OpenCode Agent Skill 创建、迁移和验证工作流。
- 新增 `platform/aicoding-user-skill-creator/scripts/skill_gate.py`，用于判断是否应该创建 skill、分类四类 skill，并阻塞缺失 workflow contract、gate rules 或人工确认的标准/流程类 skill。

### 更新

- 更新 `embedded/C99/`，把 C99 编码规范补充为 `consistent-workflow`、`organization-standard` 和 `team-expertise` 类型，并要求可机器检查规则落成 CLI/Hook/Lint/CI 门禁。
- 更新 `embedded/architecture/`，把架构平台化规范补充为四类 skill，并要求架构边界、发布门禁和量产约束优先机器化为阻塞规则。
- 更新 `README.md`，加入 `platform/aicoding-user-skill-creator/` 目录说明，并改为依赖 Git 管理 user-level skill 变更，避免散落临时备份。
- **docs**：更新 `embedded/git/` 提交治理规则，要求每次提交明确 `feat/fix/docs/style/refactor/perf/test/chore/build/ci` 类型，在 CHANGELOG 记录类型和影响，并通过 lint/hook 管理提交消息与 CHANGELOG 门禁。
- **docs**：新增 `embedded/git/references/repository-initialization.md`，把 Git 仓库初始化标准化为本地同步空远程、远程优先绑定本地、克隆已有远程、本地引导、模板引导和 submodule 感知初始化，并要求通过 CLI 配置 `.githooks` 后运行 hook/lint 验证。
- **docs**：补充大厂式 Git 分支/环境映射和单次提交纪律，覆盖 `main/develop/feature/test/release/hotfix`、`DEV/FAT/UAT/PRO`、同类提交、不超过 3 个议题以及禁止默认使用破坏性 reset。
- **feat**：新增 `plugins/AiCoding/`，按 Codex 官方 plugin 结构生成扁平化 `aicoding-*` skills、Codex lifecycle hooks 和 `BUILDINFO.json`，用于新电脑安装 AiCoding 嵌入式 Codex kit。
- **refactor**：将 `embedded/git/` 迁移为 `platform/aicoding-git-governance/`，把 Git-Skill 明确归类为跨领域平台治理能力。
- **build**：新增 `config/aicoding-plugin-pack.json`、`scripts/build-plugin.ps1`、`scripts/verify-plugin.ps1`、`scripts/compare-generated.ps1` 和 `scripts/verify-skills.ps1`，支持可重复构建、生成目录校验和构建漂移检查。
- **docs**：新增 `docs/ARCHITECTURE.md`，明确人工维护目录与自动生成目录、BUILDINFO 非自引用模型、local plugin 缓存刷新方式、CodingKit 外部资产发现协议、Hook 辅助边界以及禁止 AiCoding 在 submodule 中重新构建 Plugin。
- **docs**：将 `embedded/git/` 的 skill 名称从 `embedded-git-workflow` 改为 `Git-Skill`（frontmatter `name: git-skill`），保留嵌入式路径定位，同时说明其嵌入式优先、可通用的 Git 治理边界。

### 移除

- 移除旧的 `anthropic-skill-creator/` 路径，后续统一使用 `skill-creator/`。
## 2026-06-22

### 新增

- **feat**：新增 `platform/aicoding-kit-maintenance/`，定义 Codex-Skills/AiCoding 双仓库维护流程，明确 AGENTS 边界、架构文档、config/scripts 执行入口以及 Git hooks/CI 完成门禁。
- **docs**：新增根 `AGENTS.md`、`plugins/AiCoding/AGENTS.md` 和 `docs/PLUGIN_DEVELOPMENT.md`，明确人工维护区、自动生成区、Hook 辅助边界和跨仓库发布顺序。
- 新增 `embedded/git/`，覆盖嵌入式仓库分支、提交、PR、Tag、Release、README、CHANGELOG、版本文件、固件制品、测试基线、生产基线和客户交付治理。
- 新增 EtherCAT 开源项目与 MCP 设计参考，包含 SOEM/IgH、SSC/SOES、CiA402 开源实现、TwinCAT/LinuxCNC/ROS2 诊断、项目选型和维护路线。

### 更新

- 更新 `embedded/SKILL.md`、`embedded/readme.md` 和 `embedded/agents/openai.yaml`，将 Git/发布治理纳入嵌入式 skill 路由。
- 扩展 `embedded/ethercat/SKILL.md`、`embedded/ethercat/README.md` 和评估数据，增加新增参考资料的读取规则。
- `.gitignore` 增加 `*.bak-*`，避免本地备份文件误提交。
- 从 `README.md` 移除日期型 diff 摘要，并在 `embedded/git` 规则中明确 diff 摘要应进入 CHANGELOG、Tag 或 Release Notes。
- 收紧 `embedded/git` 的 GitHub Release 规则和模板：创建 Release 时必须包含 Deprecations、Full Changelog、New Contributors 等完整章节，非适用项写 `None`。
- 调整 Release 语言策略：中文仓库默认中文，首次创建 GitHub Release 需确认语言；Release Notes 模板和校验脚本支持中文优先的中英双语标题。

## 2026-06-20

### Diff 概览

- `embedded/c99-standard-c/` 删除并迁移至 `embedded/C99/`。
- 新增 `embedded/architecture/` 及其架构审查模板和参考资料。
- 扩充 `embedded/motorcontrol/` 的算法、时序、多轴、测试和参考工程资料。
- 扩充 `embedded/ethercat/` 的 EtherCAT/CiA402、TwinCAT、SSC/ET9300、DC 和故障排查资料，并新增解码脚本与评估数据。
- 更新 `embedded/SKILL.md`、相关 `agents/openai.yaml`、仓库 README 和发布说明。

### C99 通用规范

- 将当前 C99 Skill 作为唯一通用 C 编码规范，不保留来源 Skill 的品牌或重复触发词。
- 修改前必须判断项目自研、自动生成或第三方代码。
- 自动生成和第三方代码默认保持实际编码及局部风格。
- 新项目和项目自研代码统一命名、4 空格、大括号、函数头及函数内部注释规则。
- 新增或大改函数记录作者、日期、原因以及必要的缺陷根因和修复方式。
- 项目自研代码非 GBK 时必须询问是否转换；第三方和生成代码保持实际编码。

### 嵌入式架构与电机控制

- 新增 architecture Skill，明确系统架构与控制算法的职责边界。
- 增加 Bootloader、OTA、A/B、Manifest、参数区、校准区和量产发布门禁。
- motorcontrol 增加 PWM/ADC/Encoder 同步、FOC/SVPWM、三环带宽、补偿、多轴同步及故障验证资料。
- 增加 VESC、ODrive、moteus、ODRI、PX4、ArduPilot、Betaflight 和 TI SDK 的参考边界说明。

### EtherCAT/CiA402

- 强化 EtherCAT 从站、CiA402 状态机、TwinCAT 联调、PDO/SDO/CoE 和 DC 同步规则。
- 新增 SSC/ET9300、Working Counter、WcState、AL/ESM、NC 轴 Ready 和多轴同步排查资料。
- 新增 `scripts/decode_cia402.py`、`evals/evals.json` 和专项参考索引。

### 发布

- 发布 tag：`v2026.06.20`。
- README 增加当前版本的路径级 diff 摘要。

## 2026-06-17

### 新增

- **feat**：新增 `platform/aicoding-kit-maintenance/`，定义 Codex-Skills/AiCoding 双仓库维护流程，明确 AGENTS 边界、架构文档、config/scripts 执行入口以及 Git hooks/CI 完成门禁。
- **docs**：新增根 `AGENTS.md`、`plugins/AiCoding/AGENTS.md` 和 `docs/PLUGIN_DEVELOPMENT.md`，明确人工维护区、自动生成区、Hook 辅助边界和跨仓库发布顺序。
- 建立 `Codex-Skills` 远程同步仓库结构。
- 新增中文 `README.md`，说明仓库用途、目录、排除规则和维护方式。
- 新增此 `CHANGELOG.md`，记录 skills 仓库变更。

### embedded

- `embedded` 增加独立 `SKILL.md` 作为一级 skill 入口。
- `embedded/readme.md` 改为二级 skill 分流说明，避免 `c99-standard-c`、`review` 和领域 skill 冗余调用。
- `embedded/review` 增加 MaJerle/c-code-style 中文评审参考：
  - `review/references/majerle-c-code-style-review-cn.md`
  - 明确该参考只用于风格、Doxygen、命名、格式化和头/源文件组织评审。
  - 明确兼容优先级：项目规范 > `c99-standard-c` > MaJerle 风格参考。
- `embedded/c99-standard-c` 保持 C99、安全、实时性、并发、寄存器和可移植性规则的优先级。

### 同步策略

- 排除 `.system/`、`backup/`、`*.zip` 和缓存文件。
- 使用独立 git 仓库管理 `C:\Users\24322\.codex\skills`，避免误提交上层用户目录。
