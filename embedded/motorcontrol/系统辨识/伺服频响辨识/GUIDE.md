---
capability_id: aicoding-servo-frequency-response
description: 规划、分析和验证伺服频率响应测量，区分对象、开环、闭环与不同注入点，处理采样、谱估计、相干性、闭环偏差和模型拟合。用于Bode/SFRA/扫频/PRBS数据可信度与参数辨识；不直接替代自动整定或滤波器设计。
---

# 伺服频响辨识

本文件是[电机控制与伺服总入口](../../SKILL.md)调度的内部专题指南，不独立注册。`aicoding-servo-frequency-response` 是内部能力键；其他专题通过[skillkit.json](../../skillkit.json)的 `target → source/entrypoint` 定位并读取对应 `GUIDE.md`，不调用同名独立 skill。
共同约束读取[公共控制契约](../../references/control_contracts_zh.md)，执行与证据读取[工程执行契约](../../references/engineering_execution_zh.md)。

默认使用中文。先读取任务相关资料，按需加载参考；不将未实测候选写成产品已验证能力。

## Skill 类型

`reusable-domain-knowledge`、`team-expertise`。本技能保存可复用模型、设计判断与验证方法。

## 使用方式

1. 先画出实际信号链，命名注入、测量、控制器、滤波、限幅及延迟；明确要识别的是电气对象、机械对象还是完整闭环。
2. 按测量方案参考选择扫频、PRBS或多正弦，基于电流、行程、温升和噪声制定幅度与频段；不把FFT峰值当作FRF。
3. 核对时间戳、实际输入、反馈和饱和状态，按估计参考计算复数响应、不确定性和可信频段；闭环对象拟合时处理反馈相关偏差。
4. 交付原始信号定义、采样率、注入幅度、估计方法、复数FRF、可信度、模型与可复现步骤，环路指标与设计路由到[频域分析与环路设计](../../自动控制/经典控制/频域分析与环路设计/GUIDE.md)，批量候选路由到 [伺服自动整定](../../自动控制/控制器设计/伺服自动整定/GUIDE.md) 或 [伺服振动抑制](../../自动控制/补偿与观测/伺服振动抑制/GUIDE.md)。

## 按需参考

- [频响测量的对象、注入与采集](references/measurement_plan_zh.md)：模型、成立条件与常用设计。
- [复数频响估计、闭环偏差与模型](references/estimation_models_zh.md)：运行接口、失败表现和可观察验证。

## 组合与输出边界

输出原始数据契约、复数FRF、可信频段和候选模型；不会把测量本身称作整定完成，也不输出未经设计验证的滤波器系数。

与其他算法组合时，读取[公共控制契约](../../references/control_contracts_zh.md)，核对单位、坐标、时间戳、总限幅、状态与证据等级。公共参考缺失时报告打包不完整，不能省略本任务的单位、时刻与限制契约。涉及C实现结合C99技能，涉及数值与滤波实现结合DSP技能。

## 可执行工程入口

读取[工程执行契约与能力映射](../../references/engineering_execution_zh.md)，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

复用正式 `Signal generator`，通过 `mc_frf` 计算离线整周期单频 DFT 的 Y/U 幅相并拒绝无激励/非整周期记录。Welch/H1/H2/相干性与闭环偏差估计尚需专项实现，单记录不能生成相干性或无偏闭环声明。
