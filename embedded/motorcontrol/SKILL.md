---
name: aicoding-motor-control
description: 电机控制集成与伺服产品设计。用于从产品指标建立控制链、分配采样与执行时序、组合辨识/反馈/控制器/前馈/补偿，以及定位跨模块问题。专项算法交给对应技能；本技能负责共同接口、约束传播与系统验证。
---

# 电机控制集成

## Skill Type

`reusable-domain-knowledge`、`team-expertise`。

默认使用中文输出。

## 核心边界

- 聚焦控制链路、实时采样、控制算法、保护、调试和验证。
- 将目录分层、平台抽象、Bootloader、OTA、量产和发布门禁交给 `architecture`。
- 涉及 C 实现时同时使用 `C99`。
- 涉及定点数学、滤波、饱和或数值稳定性时同时使用 `dsp`。
- 涉及具体 ARM 中断、NVIC、cache 或寄存器时同时使用 `arm`。

## 工作流

### 1. 建立控制上下文

优先从代码、原理图和配置中识别，缺失且影响方案时再询问：

- 电机类型、参数、极对数、母线和功率级；
- 主控、PWM 频率和计数模式；
- 电流采样拓扑、ADC 时序和转换延迟；
- 编码器或观测器类型、时间戳和延迟；
- 控制模式、环路更新率、机械负载和通信周期；
- 保护阈值、停机策略和可观测变量。

### 2. 用事件语义还原实时链路

不要根据 ISR 名称推断控制顺序。验证：

```text
PWM 同步事件
  -> ADC 采样与完成
  -> 按所属时刻对齐反馈（锁存/有界外推/多速率）
  -> offset 修正与 FOC
  -> SVPWM
  -> PWM shadow 更新
```

明确电流、角度和速度的采样时刻、有效性与数据年龄，以及PWM输出生效时刻；`cycle_id`是可选实现手段。测量deadline、overrun和jitter，允许可解释的异步采集与多速率。先读取[公共控制契约](references/control_contracts_zh.md)，时序细节读取 `references/pwm_adc_encoder_timing_zh.md`。

真实 MCU、编译配置、PWM/ADC/反馈事件、ISR 路径和 Shadow 截止的只读分析使用 `aicoding-motor-hardware-deployment`。已知计算先执行确定性工具；不得将静态调用路径或指令估计写成实测 WCET。

### 3. 选择采样和更新策略

默认优先硬件PWM/定时器触发ADC，并让支持锁存/触发的反馈接口关联同一时基；对无法外部触发的编码器保留物理采样时间与年龄。单/双/三电阻按实际安装位置、开关状态与稳定窗口选择，调用公共工程执行契约中的拓扑规则与工具，不凭电阻数量推断波谷/波峰均可采样。

在波谷、波峰、双采单更和双采双更之间，根据采样窗口、ADC 带宽、计算时间和 shadow load 点选择。用户未给出足够数据时，列出推荐起点、成立条件和需要测量的参数，不武断指定高复杂度方案。

### 4. 设计环路与补偿

- 区分更新频率和闭环带宽；
- 电流环默认 PI，并包含输出限幅、积分限幅和 anti-windup；
- 速度和位置环按噪声、延迟、机械共振和负载确定带宽；
- 仅在基础相序、方向、offset、极对数和闭环稳定后增加前馈或补偿。

频域指标与离散环路综合使用aicoding-control-frequency-analysis；系统辨识的模型/实验/估计边界读取[系统辨识基础](references/system_identification_foundations_zh.md)。需要带宽、补偿和测试细节时读取 `references/pid_bandwidth_compensation_zh.md`。

### 5. 处理多轴和故障

保持每轴独立状态，使用统一 `cycle_id` 或 timestamp、shadow command 和同步 apply。定义单轴停机、全轴停机或降级策略。读取 `references/multi_axis_sync_debug_zh.md` 获取同步误差和调试检查项。

### 6. 使用参考项目

仅在主控和问题匹配时读取：

- `references/repo_reference_matrix_motor_zh.md`：快速匹配 VESC、ODrive、moteus、ODRI、TI SDK 等；
- `references/customer_motor_function_replicate_options_zh.md`：比较算法思想、接口行为、代码参考和许可证边界。

不得因主控相同就默认复刻；先确认目标功能、功率级、传感器、安全要求和许可证。

实践比较读取[理论与工程实现的辩证比较](references/theory_practice_comparison_zh.md)，检查前提、反例和更优候选。

### 7. 验证

读取 `references/testing_validation_zh.md`。至少覆盖 bring-up 顺序、三环阶跃、正反转、低速、高速限压、负载扰动、多轴同步和故障注入。没有波形、trace 或测量数据时，不宣称参数已调好或实时性已满足。

## 输出

把定位/跟随精度、停稳时间、低速纹波、抗扰、效率、整定时间和成本转成可检查的产品目标。为每项建议说明收益、成立条件、算力与标定成本；对照测试必须使用相同对象、轨迹与控制器配置。

按任务规模输出必要部分：

1. 平台、控制目标和已确认假设；
2. PWM/ADC/Encoder 事件链与 deadline；
3. 环路带宽、限幅、前馈和补偿策略；
4. 多轴同步与故障策略；
5. 观测变量、测试步骤和通过标准；
6. 参考项目匹配与待用户确认的复刻范围。

正式审查可使用 `assets/motor_control_review_template_zh.md`；需要确认复刻方式时使用 `assets/implementation_replicate_decision_template_zh.md`。

## 专项能力路由

按技能清单中的实际路径加载以下入口，只读取当前问题所需references；不假设源码目录与安装缓存相邻。

| 当前问题 | 中文技能名称与技术ID |
|---|---|
| 真实工程目标、PWM/ADC/ISR、Shadow截止与WCET证据 | 电机控制实机部署与实时验证 `aicoding-motor-hardware-deployment` |
| Bode、带宽、裕度、离散环路综合 | 频域分析与环路设计 aicoding-control-frequency-analysis |
| 激励波形、频段/幅值/时长与信息量 | 激励信号设计 aicoding-excitation-signal-design |
| 参数未知、辨识结果不可信 | 电机参数辨识 `aicoding-motor-parameter-identification` |
| 编码器/旋变、方向/零位、速度噪声 | 电机反馈与标定 `aicoding-motor-feedback-calibration` |
| 观测器、HFI、无传感器启动/切换 | 无传感器电机控制 `aicoding-motor-sensorless-control` |
| 三环、离散设计、稳定性 | 伺服控制器设计 `aicoding-servo-controller-design` |
| 最小电流、高速限压、电流分配 | 最大转矩电流比与弱磁控制 `aicoding-pmsm-mtpa-field-weakening` |
| dq耦合与反电动势 | 电流环解耦与电压前馈 `aicoding-pmsm-dq-decoupling` |
| 逆变器误差、小电流畸变 | 逆变器死区补偿 `aicoding-inverter-deadtime-compensation` |
| 轨迹跟踪和加减速误差 | 伺服速度前馈 `aicoding-servo-velocity-feedforward`；伺服转矩前馈 `aicoding-servo-torque-feedforward` |
| S曲线、改目标、多轴同步 | 运动轨迹规划 `aicoding-motion-trajectory-planning` |
| 动态对象未知、批量调参 | 伺服频响辨识 `aicoding-servo-frequency-response`；伺服自动整定 `aicoding-servo-auto-tuning` |
| 机械振动、未知负载、低速/周期扰动 | 伺服振动抑制 `aicoding-servo-vibration-suppression`；伺服扰动观测 `aicoding-servo-disturbance-observer`；伺服摩擦补偿 `aicoding-servo-friction-compensation`；齿槽与转矩纹波补偿 `aicoding-servo-torque-ripple-compensation` |
| 电机侧/负载侧双反馈 | 双反馈伺服控制 `aicoding-servo-dual-feedback-control` |
| 产品指标、对照数据与验收 | 伺服性能验证 `aicoding-servo-validation` |

能力缺失时说明当前可用资产，仍可按已确定的契约给出接口与最小实现。跨模块集成遵循“一个补偿项一个所有者”，逐层传递速度、转矩/电流与最终可实现电压约束。

## 可执行工程入口

按[工程执行契约与能力映射](references/engineering_execution_zh.md)定位每个专项的唯一 C99 资产、Golden Reference、测试入口和未实现变体。数值核心位于 CodingKit 的 `modules/common/controller/motor`，复用既有 FOC/PI/I-f；工程配置与时序工具位于 `tools/motor-engineering`。通过批准的资产发现协议定位它们，不复制进插件，不假设安装缓存与源码相邻。运行 `motor/run_tests.py`、Go `go test ./...` 及相关 `servo-validation` 组合案例后，只报告实际通过的证据等级。
