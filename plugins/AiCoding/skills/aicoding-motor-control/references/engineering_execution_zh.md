# 工程执行契约与能力映射

本文件是“电机控制与伺服”总 skill 与21个内部专题的共同执行入口，随唯一注册的 `aicoding-motor-control` 打包一次。专题通过相对链接读取它，只读取当前任务一行及相应资产，不复制到各专题。下表保留的旧专项技术 ID 是 [skillkit.json](../skillkit.json)中的内部能力键，不表示独立注册 skill；总入口按清单中的 `source/entrypoint` 调度对应 `GUIDE.md`。单位、坐标与求和点仍以[公共控制契约](control_contracts_zh.md)为准。

来源核验使用同目录的 `research_provenance.json` 与[现有项目参考矩阵](repo_reference_matrix_motor_zh.md)。以记录的阅读范围、实际页码、Commit/符号及许可证为准；未核验全文或源码不升级为已核验，也不在本文件重复维护来源事实。

## 资产发现与命令

通过显式 `AICODING_HOME`、安装状态、`PATH` 或获准项目的 `config/codex-kit.json` 定位 CodingKit。先验证 manifest 的 `codingKitRoot` 和所需目录；不可用则返回 `INSUFFICIENT_EVIDENCE` 或能力不可用。不得从安装缓存向上猜测相邻源码仓库，也不得复制一份算法作为补救。

资产根下的唯一实现与验证入口：

| 资产 | 入口与职责 |
|---|---|
| `modules/common/controller/motor` | `motor.h`/`motor.c`：可组合领域计算；`python run_tests.py` 编译 C99 并与独立参考计算比较 |
| `modules/common/controller/pid/src/pid_pi.c` | 已有离散 PI 状态更新、限幅和外部跟踪；增益设计消费 `mc_pi_design` 的结果，禁止另造第二份 PI |
| `modules/common/controller/foc` | 已有 Clarke/Park、逆变换及 SVPWM；按真实 API 归一化，不在 Skill 中维护副本 |
| `modules/common/controller/IF` | 已有软件角度与电流闭环 I-f；按该资产 README 执行 CMake/CTest |
| `modules/common/controller/Signal generator` | 已有有界、可复位、多实例激励；`python run_tests.py` |
| `examples/servo-validation` | `python run_validation.py`：已有三条离线组合链及边界案例 |
| `tools/motor-engineering` | Go 工程识别与时序分析；`go test ./...`，`go run . inspect --project PROJECT --file relative/source.c`，`go run . analyze --input timing.json` |

命令在对应资产目录执行；文件路径、Schema、Exit Code、参数范围、数值容差和支持语法以资产 README、头文件与实际 `--help` 为准。`inspect` 的 `--file` 可重复，仅分析显式文件；先从构建配置缩小文件清单。`analyze` 不接受 Agent 偷补的硬件常数，必须给出来源或声明为待测输入。JSON 和原始输入一起保存；不要只保留自然语言摘要。

## L1—L7 的交付条件

| 层级 | 必须留下的可复核结果 |
|---|---|
| L1 数学模型 | 方程、符号/单位/轴侧、适用范围、模型假设、来源定位；模型误差与对象差异分开 |
| L2 方法选择 | 明确候选、准入约束、拒绝分支和降级；已稳定的规则调用工具，证据不全返回 `INSUFFICIENT_EVIDENCE` |
| L3 离散化 | 实际 `Ts`、输入采样/接收与输出生效时刻、ZOH/保持器、延迟拍数、状态顺序、离散极点和饱和；连续增益不等于已部署控制器 |
| L4 实现 | 唯一 C99 文件/符号、实例/配置/版本、Init/Update/Reset 或等价纯函数、错误/无效样本、限幅及状态保持语义；无动态内存和无界循环 |
| L5 数值验证 | 独立解析式/高精度模型生成的输入、期望与容差，边界/非法/变化案例、实际命令和输出；禁止调用被测函数生成期望 |
| L6 诊断 | 表象、候选原因、可区分实验、必要日志、修正建议与量化验收；只报告输入证据能够支持的原因 |
| L7 工程验收 | 以下六级证据逐项记录，不从低一级推断高一级；未执行项明确缺口与测量方法 |

证据等级为 `Mathematical Reference`、`Host Unit Test`、`Discrete Simulation`、`Target Build / Static Timing`、`Target-in-the-Loop`、`Hardware Measurement`。宿主耗时仅评价工具/数值实现，不代表目标 ISR 的 WCET。目标编译成功也不代表采样时序、机械稳定性或功率级通过。

每条结论记录 `CONFIRMED / DERIVED / ESTIMATED / NOT_MEASURED / UNKNOWN / INVALID` 之一和来源：源码需文件/行号/符号，构建需配置/工具链/输出摘要，测量需通道/采样时钟/窗口/原始记录。`CONFIRMED` 必须同时说明确认了什么，例如“源码包含该赋值”，不能提升为“硬件运行值”。`INSUFFICIENT_EVIDENCE` 是决策拒绝原因，不是擅自采用默认值的许可。

## 专项到实现与验证的映射

下表描述当前可复用的实现子集。每行的高级变体仍以该行缺口为准；表内符号存在不代表当前任务已通过全部 L1—L7。执行测试后读取实际通过项，未运行不写通过。

| 技术 ID | C99/工具与可执行子集 | 尚需专项实现或目标证据 |
|---|---|---|
| `aicoding-motor-control` | 已有 FOC/PI/I-f + `mc_schedule`；`servo-validation/run_validation.py` 检查组合链 | 多轴目标调度、最终 duty/保护和共享资源 WCET |
| `aicoding-motor-parameter-identification` | `mc_rl_init/add/fit`：固定 Ts、精确 ZOH 的标量 RL 回归，检查秩/激励；`motor/run_tests.py` 独立离散真值 | 饱和磁链图、在线全参数 RLS/EKF、机械参数联合辨识；不得用一个 RL 拟合冒充全部 |
| `aicoding-motor-sensorless-control` | 既有 `IF` 启动与 `mc_pll_init/update` 基础相位跟踪；各自宿主测试 | PLL 不产生可观测反电势；完整 SMO/磁链观测、HFI 极性及无传感器闭环切换仍需专门实现/板测 |
| `aicoding-motor-feedback-calibration` | `mc_align_angle`：物理锁存到使用时刻的有界预测；Go `analyze` 检查反馈年龄 | 编码器协议接收、方向/零偏与极对数标定状态机和板上延迟测量 |
| `aicoding-servo-controller-design` | `mc_pi_design`/`mc_pi_cfg` + 正式 `pid_pi.c`，匹配先积分顺序、参数无扰更新和延迟约束 | 柔性对象、高阶/非最小相位模型及目标闭环裕度 |
| `aicoding-servo-validation` | 既有 `scripts/metrics.py --self-test` 与 CSV 指标；`servo-validation` 组合案例 | 真实原始日志、产品阈值、板测故障恢复与环境覆盖 |
| `aicoding-pmsm-mtpa-field-weakening` | `mc_mtpa`、`mc_torque`、`mc_check_limits`：常参数正凸极 IPMSM 固定电流幅值解与稳态可行性 | 非线性磁链图 MTPA/MTPV、动态弱磁调节器与回馈/母线瞬态 |
| `aicoding-inverter-deadtime-compensation` | `mc_deadtime`：零和相电压候选；独立过零/方向/极限真值 | 死区幅值和极性板测标定、真实器件压降/门极/采样窗口 |
| `aicoding-pmsm-dq-decoupling` | `mc_dq_ff` + 正式 FOC/PI/SVPWM；独立正反转符号、参数与限压测试 | 非线性磁链表/交叉饱和、动态预测模型和高速实际串扰 |
| `aicoding-servo-velocity-feedforward` | 既有 `servo-validation` 轨迹→前馈→三环链，使用 `mc_schedule` 的多速率边界 | 时延匹配、位置外环最终限速与整机轨迹误差 |
| `aicoding-servo-torque-feedforward` | `mc_mech_ff`：同轴侧惯量/黏性/已知负载合成 | 重力模型、驱动传动弹性及真实可实现转矩 |
| `aicoding-motion-trajectory-planning` | `mc_traj_plan`/`mc_traj_sample`：静止到静止五次轨迹与采样 PVAJ；既有组合案例和 `mc_schedule` | 完整在线 jerk 受限非零初态重规划、不可行停止解与多轴时间同步 |
| `aicoding-servo-frequency-response` | `mc_frf`：离线整周期单频 DFT 的 Y/U 与幅相；正式激励资产 | 通用 Welch/H1/H2/相干性估计器及闭环偏差处理；单记录不能输出相干性或无偏闭环结论 |
| `aicoding-servo-auto-tuning` | `mc_pi_design` 可复算基线，`mc_frf` 提供受限离线单频数据 | 自动搜索/质量筛选/安全回退整定器和批量产品证据 |
| `aicoding-servo-vibration-suppression` | `mc_notch` 双线性系数、`mc_filter` 有界双二阶状态更新 | 自动选峰/整定、输入整形器、模态漂移鲁棒性及实机残振 |
| `aicoding-servo-disturbance-observer` | `mc_dob_init/update`：一阶 Q 精确 ZOH 与实际转矩输入 | 线性 ESO/柔性模型 DOB 及含噪实机残差；观测总扰动不能当唯一摩擦参数 |
| `aicoding-servo-friction-compensation` | `mc_friction`：静态库仑/黏性/Stribeck 候选，独立过零真值 | LuGre 等动态摩擦状态、温度与实机辨识残差 |
| `aicoding-servo-torque-ripple-compensation` | `mc_ripple`：有界谐波合成；独立角度/阶次验证 | 实测建图、编码器误差分离、负载/温度二维插值 |
| `aicoding-servo-dual-feedback-control` | `mc_dual_error`：传动比/轴侧换算与一致性拒绝 | 全闭环两惯量稳定性、回差/弹性切换与负载侧失效恢复 |
| `aicoding-control-frequency-analysis` | `mc_pi_design` 的声明模型与延迟准入，`mc_notch` 离散系数 | 通用多交越裕度/Nyquist/多变量鲁棒性计算，不能用单频约束代替稳定性证明 |
| `aicoding-excitation-signal-design` | 正式 `Signal generator` 与 `run_tests.py`；确定性激励、复位和多实例 | 真实功率级下幅值/温升/行程与信息量验收；请求值不能冒充实际激励 |
| `aicoding-motor-hardware-deployment` | Go `inspect/analyze`：显式源文件事实、静态 ISR 路径、结构化事件/截止与反馈年龄计算 | 完整 C 预处理/运行路径求值、芯片手册常数核验、目标构建/反汇编及实机 WCET/波形 |

## 硬件同步与电流采样拓扑

默认推荐PWM/定时器硬件事件触发ADC，并在芯片/接口支持时同步编码器锁存或采集启动。这能减少软件调度抖动，明确样本属于哪个控制周期。先核实触发路由、采样极性、结果可读时刻和Shadow截止；不是只把采样函数移进同名ISR。反馈不支持外部触发时，使用独立时戳、年龄界和有界预测，不能伪造同步。

F2838x可由ADCSOCA/B触发eQEP strobe，但必须同时配置strobe latch并读对应锁存寄存器；unit-timeout锁存不是同一个量。BiSS-C需核对MA锁存事件与传感器内部延迟；SPI的CS/读取不普遍代表物理采样。ADC电流在采样保持窗口末被捕获，共享SOC仍可能留下角度-电流时间差。型号/SDK不支持时选择可验证的替代方案，不把C2000配置写入通用核心。

| 拓扑 | 默认工程策略 | 必须拒绝或降级的条件 |
|---|---|---|
| 单DC-link电阻 | 在两个不同且独立的有源开关矢量稳定段分别采样；结合实际3bit上管状态求解两条母线电流方程和三相零和关系；SOC与使用的调制周期/扇区一致 | 000/111、相同或互补矢量导致秩亏；有源矢量过短；两个样本时间差导致电流变化超界；不得凭当前扇区解释上一周期样本 |
| 双低侧电阻 | 已安装的两相都在低侧导通稳定段有效，优先并行ADC/同步S/H，第三相取负和；根据真实PWM极性选择共同窗口 | 不能用未安装第三路代替无效测量；高占空比、调制边界、死区和窄脉冲使任一路窗口不足时，移动SOC/限制调制或采用验证过的重构策略 |
| 三低侧电阻 | 每拍选窗口有效的两相；三相均有效时检查零和残差以诊断offset/增益/相序；保留所选相位与有效位 | 三个电阻也有导通盲区，不能默认任意时刻可采；零和残差超界先查采样时差/校准，不直接重调PI |
| 三相inline | 相电流测量不依赖低侧持续导通，但仍避开共模跳变和放大器恢复段；按器件数据核对ADC输入驱动与过压恢复 | 不得套用低侧导通窗口；高dv/dt、饱和/恢复、噪声或实际采样不同步仍可令样本无效 |

窗口先统一参照点，再计算：门极命令参照的保守预算可累加deadtime、driver propagation、开关rise、blanking、amplifier settling、S/H与guard。若窗口来自实际开关边沿或已测“到稳定”时间，须剔除已经包含的项，避免重复计算。矢量总时长若被PWM拆成多个片段，必须使用实际连续片段，不能把两段加起来充当一个采样窗。SOC放在稳定起点之后，采样保持结束与guard必须早于下一边沿。

工具 `current_sampling` 接收实际窗口、采样偏移、已安装通道、开关状态和时间差界，输出可观测相位/重构条件和诊断；缺少这些证据时不暗填默认纳秒数。单电阻两个样本本来不同时，需要电流斜率、样本年龄与重构误差上界。C99 `mc_bus_current` 和 `mc_phase_current` 执行重构/校验，独立Golden测试覆盖矢量组合、非法窗口、错拍和无效数据。

窗口不足时按实际约束比较SOC相位调整、对称PWM移相/最小矢量整形、调制范围限制、更新率调整或采样拓扑更换；逐项说明电压误差、纹波、转矩能力与新deadline，保护逻辑优先。窗口无效应显式冻结本次控制积分/进入已定义降级或故障路径，保持上次值只能作为有最大年龄的降级，不得标为新有效样本。

## 固定规则与工程判断（执行）

- A 类计算：单位换算、dq 项、PI 基线、离散 RL、限幅、时序与数值比较交给正式实现，不让 LLM 心算替代工具。
- B 类选择：先检查工具 Schema/准入条件；采样/离散化/预测缺少时钟、延迟或参数有效范围时拒绝给定值，输出缺少的字段和最短测量路径。
- C 类判断：新控制结构、相互冲突的多目标与证据不足的异常由 Agent 提出可推翻假设和区分实验；稳定结论再变成规则/回归案例。

## 什么条件下采用什么路径

先定位来源索引的 `decision_evidence` 与 `sampling_semantics`，再执行当前问题对应行。表中只保留选择与验收，不重复书目、Commit、文件SHA或原始源码事实；来源ID的核读范围和工程交叉核验仍由 `research_provenance.json` 唯一维护。

| 条件/触发表现 | 动作与复用入口 | 理由与拒绝分支 | 工程来源/规则 | 本任务验收 |
|---|---|---|---|---|
| 当前工程已有完整ISR/FOC/保护，或已有C2000 CLA/FCL路径 | 保留原执行链，只适配缺失Primitive；先对照采样、状态更新、最终限制与保护契约 | `motor.c` 不是目标工程整栈替代品。CLA intrinsic、共享指针ABI和外设配置留在目标适配层，不能搬进通用C99 | `local-odrive-control`、`local-odri-cla`、`local-sguanfoc-g4` | 给出原路径→适配点→调用/数据时刻的最小改动；目标构建与整ISR测量单独验收 |
| SysConfig实例名、注释或阶段名似乎指向某硬件/模式 | 用 `inspect` 收集显式文件，再追实例的实际base绑定、生成调用和Park输入 | 变量 `clb1` 不保证是CLB1；`sensored`文件名或“电流闭环”阶段不保证Park消费编码器角度。绑定/路径未闭合就保留未知 | `RULE-TIMING-SOURCE-CHECK`、`RULE-STAGED-BRINGUP` | 给出源文件/行号→硬件base→触发→锁存→使用的链；软件角与实测角分开记录 |
| ADC取样窗够手册最小值，但切换通道/源阻抗后仍有幅值误差 | 先核模拟建立和S/H；理想一阶RC模型有证据时使用 `analyze` 的可选 `acquisition_rc`，并与器件最小窗比较 | 满量程阶跃达到N-bit half-LSB需 `(N+1)*ln(2)*R*C`；1LSB与half-LSB不是同一精度。多极点、运放恢复、ADC反冲不满足一阶模型时拒绝套该式 | `RULE-ADC-RC-SETTLING` | 保存R/C、阶跃/精度口径与适用证据；改变ACQPS做幅值收敛对照，不能只看ADC时钟 |
| 工程已有elapsed/maxElapsed或GPIO计时代码 | 先追实际起止符号/读写范围，再把未覆盖段、抖动和guard送入截止预算；无采集记录仍为 `NOT_MEASURED` | 算法消费者计时不等于整ISR，存在计时代码不等于已测数据。`OBSERVED_MAX_ONLY` 也不是形式化WCET | `RULE-WCET-MEASUREMENT-SCOPE` | 分开报告ADC ISR、消费者、核函数范围；原始捕获与配置可复现，完整路径满足真实Shadow截止 |
| 使用SDFM/sigma-delta，或想以更高bit-clock提高电流环 | 复用原SDK滤波/保护路径，分别取得输出更新率、滤波相位/群延迟、阶跃建立时间和过流检测延迟 | bit-clock不是有效样本率，建立时间不等于群延迟。当前ADC序列模型不能代表的SDFM流水保持不足证据，不填虚拟ADC常数；不能为控制带宽解除保护 | `RULE-SDFM-RATE-LATENCY` | 同一输入阶跃核对控制输出与保护通道的不同时间范围，均满足各自截止/阈值 |
| 有限日志可以计算DFT的Y/U，准备据此判稳态频响或稳定性 | 先核周期稳态、暂态剔除、漂移、同步/整周期、激励SNR及注入点，再用 `mc_frf` 的受限单频计算或既有频响工具 | 有限DFT存在不等于稳态FRF成立；不能用末段看似收敛替代终值定理前提。含积分器仍可研究非零频率的周期特解/广义频响，不能一概禁止Bode | `RULE-FRF-STEADY-ADMISSION`、`L-XIDIAN-DTFT-LECTURE` | 同频不同记录段/幅值结果一致且原波形无漂移/削顶；相干性、无偏与稳定性分别给对应证据，不由单记录比值代推 |
| 离线固定Ts、静止线性RL且已有实际区间电压/配对电流 | 直接调用 `mc_rl_init/add/fit`，沿用独立留出验证；先核现有工程/SDK再考虑新估计器 | 两点稳态不能提供电感动态信息；充分信息量及漂移需求同时存在才评估在线RLS。ODrive会arm/注能的R/L校准流程不是被动离线计算，不自动获得设备授权 | `RULE-IDENTIFICATION-ADMISSION`、`B-PARAM-ZHU`、`P-RPEM-PERERA`、`local-odrive-rl-calibration` | 秩/条件、实际电压、正负激励、训练外预测和参数物理范围同时合格 |
| 需要电流PI，或已有工程采用TI series、ODrive旧积分输出、Sguan Tustin | 优先保留目标原PI并按真实式复算；选用正式 `pid_pi_eval/track` 且模型匹配时才用 `mc_pi_design`/`mc_pi_cfg` | series/parallel、预乘Ts、先后更新和Tustin改变参数语义，不能直接共用一组离散系数；换PI须另有迁移目标与等价/恢复验证。额外延迟只计一次 | `S-TI-PI`、`L-TI-REALTIME-GUIDE`、`local-odrive-control`、`local-sguanfoc-g4` | 独立阶跃与离散频响使用真实更新顺序；包括最终限幅、切换和延迟变化 |
| 校准/启动阶段已有软件角电流闭环，希望直接进入编码器或无传感器控制 | 优先复用 `IF` 及工程已有的递增验证结构，按Park真实角度来源判断当前模式 | 软件角下电流可控不证明转子同步、编码器零位或观测器可观测；SDK LEVEL3与LEVEL4的差别须读真实分支，阶段编号不可跨项目照抄 | `RULE-STAGED-BRINGUP`、`L-TI-SENSORED-FOC` | 先交付离线/宿主与原有构建证据；运动、捕获、相位及恢复测试另按明确硬件授权执行 |
| 普通电流/遥测Butterworth LPF已有需求 | 复用 `controller/filter/巴特沃兹二阶滤波器` 的 `MotorBwLpf2_*`；特定陷波才用 `mc_notch` 与已检验执行器 | 既有LPF为TDF-II；新 `mc_filter` 为DF-I，使用double中间值且错误不更新。状态/错误语义不同，职责有重叠，不能按“同是biquad”直接换状态 | `codingkit-butterworth-vs-dfi` | 复用前核更新率、实际相位和噪声目标；若统一执行核，先用同系数独立脉冲/正弦与故障测试证明等价范围 |
| 高速dq串扰，或加前馈后畸变反而增大 | 先调用 `mc_dq_ff` 真值/正反转检查，再审 `inspect/analyze` 的采样、角度与PWM时刻，最后评估参数图/预测 | 饱和、错拍、机械/电速度换算、增量/视在电感和逆变器误差都能产生相似表现；未区分前不叠加第二个延迟补偿或继续加PI | `B-PARAM-ZHU`、`P-FRACTIONAL-DELAY-HU`、既有理论/工程对照 | 固定对象、PI和采样，仅开关一个补偿；记录交叉轴响应、最终电压、限制与时间戳 |
| 外部资料的极数、极对数、线/相量或peak/RMS与工程不一致 | 先按接法与坐标完成可复算换算，再让既有SI算法消费；缺少定义时返回不足证据 | 不能把转矩式系数3与峰值幅值不变模型的1.5混用，不能用机械rpm代替电角速度，也不能不看接法就把线电阻除2 | `RULE-PARAM-UNIT-CONVERSION`、`L-INFINEON-MOTOR-PARAM`、`B-PRACTICE-LI` | 原始量、单位/轴侧、换算依据和独立反算均保留；至少核对功率/转矩或相线量的一致性 |
| 准备复制参考工程的未启用分支，或本地缺少完整许可文件 | 先核编译开关、真实数据流和许可证，再以独立公式/模型交叉验证；当前仅有思想核读就保持思想参考 | 源码存在不代表该分支被运行验证；关闭前馈中的机械/电速度混用不能作为Golden。README声称许可不等于已核到许可文件 | `local-odri-cla`、`local-sguanfoc-g4` | 符号/单位、分支启用条件、许可与独立测试均可追溯后才考虑复用代码 |

窗口与采样拓扑优先使用上一节的 `current_sampling` 约束与正式重构函数；只有输入覆盖当前问题时才执行，不因工具存在而强塞不适用模型。若既有SDK或模块满足语义、许可和验证要求，优先适配接入；新建Primitive应解释现有资产缺少的真实职责及独立验收入口。

同一ADC的不同rank仍是顺序S/H，不因一次EOC/ISR一起读取就变成同时采样。`local-sguanfoc-g4` 的两相电流来自不同rank且软件启动转换；接入时分别恢复两相物理采样时刻和允许电流变化界，不能把ADC完成时刻填给两相，再直接宣称满足 `mc_phase_current` 的“已对齐”前提。类似地，ODrive分别对齐Park与PWM输出时刻的做法提示两者可能有不同年龄；这不是给同一个角度重复添加两次固定Td的理由。

## 组合、日志与失败验收

先固定采样→对齐→FOC→PI→dq 前馈→最终电压限制→逆变器补偿/调制→Shadow 生效时刻；慢环按整数多速率或明确时间戳契约交接。参数携带版本、有效范围和 apply 周期，整组校验后切换；无效样本和保护触发不得更新积分或发布新参数。一个延迟只补偿一次，一个补偿项只有一个所有者，最终可实现残差回到对应求和点的抗饱和接口。

宿主回归至少包含正反转、零/低速、高速、母线下降、电压/电流限幅、参数失配、过期样本、编码器丢帧、ADC 非有限值、deadline 违约、模式/参数切换及保护恢复。一个函数的非法输入测试不能替代整机故障恢复。

高速 dq 串扰按可区分证据排查：先校验 `omega_e = pole_pairs * omega_m` 和 Park 符号，再对比相同电流阶跃下的前馈开关、参数变化、物理锁存→使用延迟、最终电压饱和、过零死区和 ADC 所属周期；记录原始/对齐角度、三相/dq 电流、PI/前馈/最终电压、母线、限制位、时间戳及参数版本。只有原因已被区分的修正才进入参数候选，PI 重调不能掩盖错拍和相序错误。

实机待测使用 GPIO 或硬件 trace 同时观测 SOC、EOC/ISR 入口出口、Shadow 写入和实际 PWM/编码器锁存；明确通道延迟、采样率、触发条件和观察工况。窗口最大值仅是观测最大值，未覆盖的中断嵌套、总线争用、缓存/Flash wait-state 仍是 WCET 缺口。没有原始测量记录时统一写 `NOT_MEASURED`。
