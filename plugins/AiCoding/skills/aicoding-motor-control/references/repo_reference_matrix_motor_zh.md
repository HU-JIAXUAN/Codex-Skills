# 电机控制来源与工程实现矩阵

## 阅读范围与使用方式

本轮核对日期：2026-10-25。两项本地实现已沿真实符号与数据流读取；四项在线项目/官方库只按下表所列范围核对。源代码说明“怎样实现”，论文说明“在什么条件下成立”；二者都不能单独证明当前板卡的性能。

采用前先确认版本、单位、坐标、时基和执行器限制，参见[公共控制契约](control_contracts_zh.md)。具体反例与取舍见[理论与实践对照](theory_practice_comparison_zh.md)。这里只读源码与资料，未对这些项目构建、刷机或板测；不以“工业级”“全速域”等 README 表述替代证据。

## 外部资产映射

以下 `asset_id` 是查找标签，不是环境变量或自动安装接口。调用方提供真实根目录，确认文件与内容后拼接相对路径。插件不携带本地工程，也不依赖个人盘符。

| asset_id | 调用方应提供的资产 | 本轮身份与边界 |
|---|---|---|
| LOCAL-ODRIVE-V3 | `ODrive-master` 解压目录 | README 声明面向 ODrive v3.x（NRND），停止积极开发；本轮未发现 `.git` 身份，不能给它附会上游 commit |
| LOCAL-SGUAN-310 | `SguanFOC_Library-main` 解压目录中的 `SguanFOC库v3.1.0(无感foc，浮点运算，进阶)` | 只读这一浮点进阶变体，不把其他定点/有感版本当作相同行为；README121行自己说明参数辨识/极性辨识存在缺陷 |

本地快照的行号只用于定位本轮读取的文件。正式复用应记录完整文件 SHA256；不能用同名文件夹推断版本。供快速比对的核心文件摘要：

- LOCAL-ODRIVE-V3：`Firmware/MotorControl/foc.cpp`，SHA256 `349e387856d162a4f19ee3919ec95cb7d1635ac3c99bce676f99b2790e22f1ca`。
- LOCAL-SGUAN-310：`SguanFOC.c`，SHA256 `885abd60c5465326475a5cb1bec86eef379847f4e069768113f60b1431055b49`。

## 已追踪的本地控制链路

### S-LOCAL-ODRIVE：轨迹、三环与带时间戳的电流输出

来源为调用方映射的 LOCAL-ODRIVE-V3。[上游项目入口](https://github.com/odriverobotics/ODrive)用于核查版本，不能自动把本地快照认作当前上游。

| 步骤 | 相对文件与符号，本地行号 | 读取到的具体行为及假设 |
|---|---|---|
| 控制周期 | `Firmware/MotorControl/main.cpp`，`ODrive::control_loop_cb`：364、424–455 | 先更新两轴编码器，再依次运行估计器、`Controller::update`、`Motor::update` 和 `current_control_.update`；跨轴消费反馈的顺序有明确说明 |
| 闭环信号连接 | `Firmware/MotorControl/axis.cpp`：289–314 | `torque_output_`连接电机转矩输入，Idq/Vdq/角度/角速度连接电流控制律；不是只按同名变量猜测上下游 |
| 轨迹与机械环 | `Firmware/MotorControl/controller.cpp`，`Controller::update`：245–269、295–443 | 梯形轨迹给出位置、速度、加速度；`Ydd * inertia`形成转矩前馈，再经位置P、速度PI、转矩限幅；饱和时速度积分每次乘0.99 |
| 单位 | `Firmware/MotorControl/controller.hpp`：27–39 | 位置用turn、速度用turn/s；`inertia`注释是N·m/(turn/s²)，不能把SI转动惯量数值直接写入 |
| 电气映射 | `Firmware/MotorControl/motor.cpp`，`Motor::update`：513–592 | 转矩/Kt形成Iq，Id优先分配电流圆；模型电压前馈使用单一`phase_inductance`和Rs，可选反电势前馈；不等同完整IPMSM磁链图 |
| 控制快照与采样 | `foc.cpp`，`FieldOrientedController::update`：184–192；`motor.cpp`，`current_meas_cb`：600、652–657；`foc.cpp`：5–20、55–63 | `update`存控制快照；采样回调经Clarke进入`on_measurement`，保留采样时间戳。不能把快照更新与PWM计算当成同一次调用 |
| 输出计算 | `motor.cpp`，`pwm_update_cb`：686–706 → `foc.cpp`，`AlphaBetaFrameController::get_output`：23–44 → `FieldOrientedController::get_alpha_beta_output`：66–181 | 分别按采样时刻做Park、按输出时刻做逆Park；PI加模型前馈后矢量限幅，再SVM和定时器计数转换。`final_v_alpha/beta_`是依据调制与母线重建的电压，不是物理端电压测量 |

可借鉴的是信号连接、单位注释和时间戳语义。单L模型、梯形加速度及固定每次0.99的积分衰减都是有代价的工程选择，不能成为所有伺服的统一答案。

### S-LOCAL-SGUAN：模块化C实现与参数/限幅边界

以下相对文件以 LOCAL-SGUAN-310 为根；README 位于其父项目目录。[项目入口](https://github.com/Sguan-ZhouQing/SguanFOC_Library)只用于追溯作者资料，本轮没有核对其在线当前版本。

| 步骤 | 相对文件与符号，本地行号 | 读取到的具体行为及假设 |
|---|---|---|
| 快环入口 | `SguanFOC.c`，`SguanFOC_High_Loop`：2069–2084 → `Sguan_Calculate_High_Loop`：1937–2004 | `Current_Tick`先执行，然后更新编码器、角度补偿/sincos、控制模式、逆Park及PWM |
| 采样与角度 | `SguanFOC.c`，`Current_Tick`：827–842 | 当前采样先用结构内已有sin/cos完成Park，随后本周期才更新sin/cos。这是需要结合采样/PWM时刻解释的流水假设，未做硬件时序核对，不能直接宣布错一拍 |
| 位置/速度/电流 | `SguanFOC.c`，`Control_VelCur_DOUBLE`：1318–1404；`Control_PosVelCur_THREE`：1409–1493 | 降频机械环输出Iq，叠加MTPA/弱磁、速度项、DOB，再电流PI、dq模型前馈；小函数便于读，但静态计数器意味着复用前要检查实例归属 |
| 前馈含义 | `Sguan_Feedforward.c`：21–57；调用在`SguanFOC.c`：1355–1356、1460–1461 | D/Q项使用实际电流和电角速度；名为`Feedforward_Velocity`的函数返回`-Speed*Ba`，调用实参是实际机械速度，不是轨迹参考速度，不能按名称当成标准轨迹前馈 |
| MTPA/弱磁 | `Sguan_Optimize.c`，`MTPA_Loop`：26–40；`FW_Loop`：51–75 | MTPA缓存首次非零Lq−Ld，公式除以Lq−Ld；启用且Ld=Lq时存在除零反例。改变参数或多实例时缓存也须重新设计；不由此推断项目默认配置必然触发 |
| 最终输出 | `SguanFOC.c`，`PWM_Tick`：1497–1549 | 调制后执行`DeadZone_Loop`，再将duty裁到[0,1]，方向/相序处理后调用`User_PwmDuty_Set`；所查链路未见把此最终裁剪残差回传给前级PI |
| 离线辨识 | `Sguan_Identify.c`，`Identify_ReadRs_Init`：24–54；`Identify_ReadFlux_Init`：62–80 | 两档指令Ud的稳态电流差求Rs；用`(指令Uq−Iq*Rs)/We`求磁链。代码注释要求先对齐和稳态；需要额外核对端电压误差、速度下限和差值信噪比 |

这个实现适合解释公式如何插入C快环，也提供了有用反例：函数名不保证控制语义相同，参数可更新不等于缓存同步更新，补偿存在不等于最终输出约束已经闭环处理。

## 在线高级项目与官方库：四个有针对性的入口

| 稳定标识 | 一手来源、实际阅读范围 | 可迁移内容与限制 |
|---|---|---|
| S-TI-SFRA | [TI SPRUIK4A用户指南](https://www.ti.com/lit/ug/spruik4a/spruik4a.pdf)，2019修订，p6模块/原理、p17补偿设计；[Digital Power SDK 5.03 SFRA API](https://software-dl.ti.com/C2000/c2000_apps_public_sw/c2000ware_sdk/digitalpowersdk/5_03_00_00/html_guide/group__SFRA.html) | `SFRA_F32_inject`、`collect`、`runBackgroundTask`给出小信号注入/采集/后台扫频边界；该指南版本明确非重入、每项目单实例。文档以数字电源为对象，映射伺服需重新定义注入点与量纲 |
| S-VESC-FOC | [VESC官方`motor/mcpwm_foc.c`](https://github.com/vedderb/bldc/blob/master/motor/mcpwm_foc.c)，核读`control_current`、`update_valpha_vbeta`有关段落，移动`master` | 可选交叉耦合/反电势项、d轴优先电压分配；后者函数中的死区项修改电压估计用调制量，不能把这一段直接描述为额外输出duty补偿。未核全仓或全部硬件变体 |
| S-MOTEUS-AW | [mjbots作者说明：moteus position anti-windup](https://blog.mjbots.com/2021/03/09/moteus-position-anti-windup/)，2021-03-09设计说明 | `servo.max_position_slip`限制速度模式中位置跟踪器积累，抑制扰动释放后的追赶；改变“丢失位置要不要追回”的语义。仅核历史说明，未核当前固件默认值 |
| S-ODRIVE-CONTROL | [ODrive Controller官方文档](https://docs.odriverobotics.com/v/latest/manual/control.html)，核读Structure、Trajectory Control，读取时显示0.6.12 | 位置P/速度PI/电流PI、前馈以及turn/s²的惯量系数。在线新版文档与本地v3旧源码分别引用，不能混用字段/默认值 |

这些项目各自解决一组约束，不作综合“最好”排名。选型依据应是当前误差的来源：时延、饱和、磁模型、柔性、传感器或任务语义。

## 书籍与经典文献：精确页码和核读状态

| 稳定标识 | 准确信息与核读范围 | 可支持的判断 |
|---|---|---|
| S-ZHU-PARAM | 诸自强、刘侃、梁大为《永磁同步电机参数辨识》，ISBN9787111793960；书p7、21–22、27、32、41，分别PDF28、42–43、48、53、62；本轮沿用已读完整页 | 增量/视在电感、欠秩、逆变器误差和病态；用来审查参数定义与数据，而不是用估计器名字保证准确 |
| S-LI-PRACTICE | 李贵、童维勇《电机控制算法实战》，2024；书p25–28、34–35=PDF34–37、43–44，沿用已读完整页 | MTPA/MTPV、稳态电压约束、系统效率与标定。所用稳态近似不能自动覆盖强动态电压需求 |
| S-ZHU-SENSORLESS | 诸自强、吴溪蒙《永磁同步电机无位置传感器控制》；只核封面/书目及PDF21–24目录 | 用于进一步阅读的主题入口；尚不能据此声称核过HFI、交叉饱和或混合切换正文公式 |
| S-THEORY-AH1984 | Karl Johan Åström、Tore Hägglund，*Automatic Tuning of Simple Regulators with Specifications on Phase and Amplitude Margins*，Automatica20(5):645–651，1984；[DOI10.1016/0005-1098(84)90014-1及大学原文](https://lucris.lub.lu.se/ws/files/6340936/8509157.pdf)。已看文章p646–647（该大学PDF4–5页） | 继电反馈、描述函数近似及其适用条件；一个临界点不是完整频响 |
| S-THEORY-LJUNG1999 | Lennart Ljung，*System Identification—Theory for the User*，2nd ed.，PTR Prentice Hall，1999；[作者大学书页](https://www.control.isy.liu.se/books/sysid/) | 已核书目与资源入口，未核全书正文；用于后续模型结构、预测误差与实验设计系统学习，不编造页码/DOI |
| S-THEORY-PS2012 | Rik Pintelon、Johan Schoukens，*System Identification: A Frequency Domain Approach*，2nd ed.，2012；[Wiley原页/DOI10.1002/9781118287422](https://onlinelibrary.wiley.com/doi/book/10.1002/9781118287422) | 只核出版社简介/目录：ch2 FRF33–72、ch3–4非线性失真73–150、ch5激励151–175、ch11模型验证431–461；这些是待读正文的定位，不是假装已精读 |
| S-THEORY-SL2019 | Johan Schoukens、Lennart Ljung，*Nonlinear System Identification: A User-Oriented Roadmap*，2019预印本；[原文HTML](https://arxiv.org/html/1902.00683v1)，[arXiv DOI10.48550/arXiv.1902.00683](https://arxiv.org/abs/1902.00683) | 实读Experiment design、Cross Validation、Change the nature of the input及周期激励噪声/失真分析相关段落；激励统计与适用域、独立新数据验证。DOI是arXiv版本标识，不冒作期刊DOI |
| S-THEORY-SCHROEDER1970 | M. Schroeder，*Synthesis of low-peak-factor signals and binary sequences with low autocorrelation (Corresp.)*，IEEE TIT16(1):85–89，1970；[IEEE摘要/DOI10.1109/TIT.1970.1054411](https://ieeexplore.ieee.org/abstract/document/1054411/?signout=success) | 官方摘要与书目已核，全文未读。支持给定功率谱的相位/峰因数设计方向，不支持宣称某相位公式对任意频点全局最优 |
| S-MW-IDINPUT | [MathWorks `idinput`原始文档](https://www.mathworks.com/help/ident/ref/idinput.html)，核读PRBS/多正弦、Band、实际周期说明 | PRBS的实际周期/保持样本数与请求长度可能不同；工具产物仍需检查实际采样、幅值、频谱与回归矩阵信息量 |

## 未进入本轮实现证据的库存

本地还盘点到MBD/ST生成工程、ODRI、Dummy-Robot、VESC等目录，但本轮未沿其源码追链；它们是后续候选，不是已验证方案。本地moteus目录只见`XRE_moteus-amulet.zip`，没有解压核读，因此上表moteus结论仅来自作者在线说明。未把工程数量或算法数量当作成熟度证明。

从此矩阵作设计判断时，至少保留一项竞争解释与一个可证伪实验；具体模板见[理论与实践对照](theory_practice_comparison_zh.md)。
