---
name: aicoding-servo-frequency-response
description: 规划、分析和验证伺服频率响应测量，区分对象、开环、闭环与不同注入点，处理采样、谱估计、相干性、闭环偏差和模型拟合。用于Bode/SFRA/扫频/PRBS数据可信度与参数辨识；不直接替代自动整定或滤波器设计。
---

# 伺服频响辨识

默认使用中文。先读取任务相关资料，按需加载参考；不将未实测候选写成产品已验证能力。

## Skill 类型

`reusable-domain-knowledge`、`team-expertise`。本技能保存可复用模型、设计判断与验证方法。

## 使用方式

1. 先画出实际信号链，命名注入、测量、控制器、滤波、限幅及延迟；明确要识别的是电气对象、机械对象还是完整闭环。
2. 按测量方案参考选择扫频、PRBS或多正弦，基于电流、行程、温升和噪声制定幅度与频段；不把FFT峰值当作FRF。
3. 核对时间戳、实际输入、反馈和饱和状态，按估计参考计算复数响应、不确定性和可信频段；闭环对象拟合时处理反馈相关偏差。
4. 交付原始信号定义、采样率、注入幅度、估计方法、复数FRF、可信度、模型与可复现步骤，环路指标与设计路由到aicoding-control-frequency-analysis，批量候选路由到 aicoding-servo-auto-tuning 或 aicoding-servo-vibration-suppression。

## 按需参考

- [频响测量的对象、注入与采集](references/measurement_plan_zh.md)：模型、成立条件与常用设计。
- [复数频响估计、闭环偏差与模型](references/estimation_models_zh.md)：运行接口、失败表现和可观察验证。

## 组合与输出边界

输出原始数据契约、复数FRF、可信频段和候选模型；不会把测量本身称作整定完成，也不输出未经设计验证的滤波器系数。

与其他算法组合时，按名称定位 `aicoding-motor-control` 的 `references/control_contracts_zh.md`，核对单位、坐标、时间戳、总限幅、状态与证据等级。当前环境缺该参考时，先显式写清本任务对应契约，不依赖跨技能相对路径。涉及C实现结合C99技能，涉及数值与滤波实现结合DSP技能。
