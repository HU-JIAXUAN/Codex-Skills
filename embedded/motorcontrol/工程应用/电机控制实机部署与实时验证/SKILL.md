---
name: aicoding-motor-hardware-deployment
description: 从真实电机工程分析 MCU、编译配置、PWM/ADC/反馈事件、ISR 调用链及实时预算，连接 C99 算法与目标实现并设计可复现实测。用于 C2000/F28388D 首先支持的只读部署分析、错拍诊断、Shadow deadline、编码器年龄及 WCET 证据；不用于通用软件发布、OTA，也不授权使能功率级或烧写设备。
---

# 电机控制实机部署与实时验证

## Skill 类型

`reusable-domain-knowledge`、`team-expertise`。默认中文。本技能负责算法到 MCU、PWM、ADC、反馈、编译器、ISR 和功率级的工程连接；FOC、PI、辨识与补偿的算法所有者保持原边界。实现结合 `aicoding-c99-standard-c`，数值结合 `aicoding-dsp`，平台分层结合 `aicoding-architecture`；Cortex-M 中断/cache 细节结合 `aicoding-arm`。

默认只读分析、离线计算、宿主测试、编译和静态检查。未经单独明确授权，不得下载/烧写固件、使能功率级、注入可能引起运动的激励、发布参数到设备、修改或解除硬件保护。停机依赖明确故障状态和硬件保护，不能依赖一般软件延迟。不要把本技能当成设备操作授权。

## 最小输入与可执行入口

从工程配置确认源码根、构建配置和当前 Git 状态，再收集相关 `.c/.h`、SysConfig、`.project/.cproject`、Make/CMake、Linker CMD、MAP 与可用反汇编；优先显式列出当前问题的文件，避免反复全仓扫描。

按技能名定位 `aicoding-motor-control` 的 `references/control_contracts_zh.md` 和 `references/engineering_execution_zh.md`。通过 `AICODING_HOME`、安装状态、`PATH` 或获准项目 manifest 发现 CodingKit；不得依赖源码与安装缓存相邻。不可用时报告缺少的资产，不复制第二份实现。

在资产 `tools/motor-engineering` 执行：

```text
go run . inspect --project PROJECT --file relative/source.c --file relative/config.syscfg
go run . analyze --input timing.json
go test ./...
```

先读取该工具 README 和输入 Schema，使用其支持的语法、单位和 fixture；不虚构字段。`inspect` 提供文件/行号事实与静态路径，`analyze` 消费明确来源的结构化事件，输出 JSON、诊断及 Exit Code。所有自动推断均保留证据有效范围；条件编译、条件分支、多次寄存器写、宏未解析或间接调用未闭合时返回未知/不足证据，不取最后一个字符串当运行配置。

## 工程分析

默认先推荐**硬件 PWM/定时器事件触发 ADC**，并在器件与反馈支持时用同一硬件时基触发编码器锁存或采集启动；由硬件排定事件，ISR消费已完成的结果。软件触发是需要给出抖动上界与适用条件的例外。不是所有编码器都支持外部物理采样触发；对连续/流水反馈记录真实锁存、接收、年龄和有界预测。共享触发也不代表ADC采样窗末与编码器锁存同刻。

先读取公共工程执行契约的“硬件同步与电流采样拓扑”。单电阻、双低侧电阻、三低侧电阻、三相inline不能套用同一采样策略；使用 `analyze` 的 `current_sampling` 检查窗口、实际采样偏移、通道可观测性、时差和单电阻矢量秩，再接入唯一C99 `mc_phase_current`/`mc_bus_current` 重构。未经窗口与状态验证，不把上一拍值冒充本拍有效电流。

1. **识别真实目标**：用器件/CPU 宏、构建目标、SDK 头文件及 Linker 区域交叉核对 MCU、核心、主频/外设时钟。识别编译器/版本、优化、FPU/CLA/DSP、单/多核、DMA/cache、Flash/RAM 与共享资源。资料使用 F28388D 不等于目标也是 F28388D；不匹配时停止使用该器件常数。
2. **还原 PWM 事件**：追踪时钟源→EPWMCLK→CLKDIV/HSPCLKDIV→TBCLK，TBCTL/计数方式/TBPRD、CMPA/B、CMPCTL/Shadow、AQCTLA/B、dead-band、ETSEL/ETPS、SOCA/B、Global Load、同步与 Trip Zone/Digital Compare。每个事件记录来源、条件、相对时刻、有效性；保护动作优先于调制性能。
3. **还原采样所属周期**：追踪 ADC 时钟、SOC/通道/触发、ACQPS、采样保持和转换、EOC→ADCINT、清除/overflow、DMA/多 ADC 并行。区分 ADCINT 提前/完成脉冲，确认实际结果寄存器在 ISR 读取前已更新；不得只依 ISR 名称判断顺序。
4. **闭合真实调用链**：向量注册→ISR→采样读取→Clarke/Park→PI→前馈/补偿→逆 Park→SVPWM→Shadow 写入→Load→PWM 输出。源码直接调用图只证明可能路径，函数指针、内联库、条件路径、中断嵌套和生成代码需构建/反汇编补证。
5. **计算截止预算**：用真实事件时间计算 `T_available = T_deadline - T_fixed_delay - T_guard`。分别列出 ADC、调度/入口、FOC、反馈年龄、Shadow 截止和实际 PWM 生效；记录最坏 jitter。100 kHz 的 10 μs 是载波周期，不能自动作为全部 ISR 可用时间。单采/双采、单更/双更、波峰/波谷各有自己的事件和截止，检查跨拍读取和无效窗口。
6. **核对角度时基**：分别记录物理锁存、接收完成、ADC 采样、Park 使用、PWM 生效。BiSS-C/SPI/QEP/旋变的接收时间不是采样时间；仅在最大年龄、速度/加速度界和误差预算成立时有界预测。检查 FOC/反馈/前馈三个模块是否重复补偿同一延迟。
7. **划定 WCET 证据**：区分源码静态路径、反汇编周期估计和硬件测量。入口/退出、调用/栈、数学库、优化/内联、Flash/RAM、DMA/CLA/多核争用与嵌套均进入预算。无 GPIO、trace、周期计数或硬件观测原始数据时 WCET 写 `NOT_MEASURED`；指令数不能冒充实测周期。

## 约束驱动优化

先由诊断确定瓶颈，再比较 SOC/Load 相位、ADC 并行、CLA/DMA/FCL、快慢算法拆分、预计算/LUT、快速数学与优化等级、PWM/更新率配比、多速率和角度时间对齐。每项只输出“适用芯片/SDK/当前工程条件、预期减少的哪一段时间、数值/控制精度影响、新风险、复测方法”；未测收益标记 `ESTIMATED`。硬件特性未在当前型号和工程确认时不推荐直接启用。

算法本体和 Golden Reference 由对应专项及 CodingKit 唯一资产提供；本技能不在平台无关核心写入 C2000 寄存器，也不在硬实时 ISR 引入动态内存、文件 I/O、阻塞或无界算法。

## 报告与验收

输出可复现命令、输入文件/摘要、目标/构建配置、带来源和条件的事件链、采样周期归属、静态调用路径、各段预算/反馈年龄、保护优先级、诊断与证据缺口。结果按 `CONFIRMED / DERIVED / ESTIMATED / NOT_MEASURED / UNKNOWN / INVALID` 标记；条件不足以决策时报告 `INSUFFICIENT_EVIDENCE`。理论、宿主、离散仿真、目标构建/静态时序、TIL 与真实测量六级分开。

先运行 `tools/motor-engineering` 的 `go test ./...` 与 `modules/common/controller/motor/run_tests.py`；目标编译仅在现有构建配置和工具链已识别时执行。测试包含无效配置、采样未完成、旧样本、丢帧、Overrun 和限幅，禁止用生成 fixture 的通过结果代替实际工程结论。

实机待测表须具体到通道与数据：SOC/ADC EOC、ISR 入口/出口、Shadow 写/Load、实际 PWM、编码器物理锁存/接收、CPU 周期、嵌套/overflow、母线和限制位；记录采样率、触发点、窗口、工况、最大值/抖动、阈值和后处理命令。保护触发/恢复、Flash/RAM/总线争用与极限工况未测时保留待测项，不宣称实机通过。
