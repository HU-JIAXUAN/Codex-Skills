---
name: aicoding-servo-vibration-suppression
description: 依据机械频响和残余振动设计伺服陷波、低通、超前滞后及输入整形，核对离散系数、插入点、模态漂移和延迟。用于共振噪声、定位尾振和柔性传动问题；频响测量、基线增益综合和轨迹约束规划由对应技能负责。
---

# 伺服振动抑制

默认使用中文。先读取任务相关资料，按需加载参考；不将未实测候选写成产品已验证能力。

## Skill 类型

`reusable-domain-knowledge`、`team-expertise`。本技能保存可复用模型、设计判断与验证方法。

## 使用方式

1. 识别振动来自反馈不稳定、命令激励、转矩周期扰动还是结构间隙；接收电机/负载侧FRF、模态与实际动作数据。
2. 共振反馈问题读取数字滤波参考；终点残余振动读取输入整形参考。先选择插入点，再设计系数与状态管理。
3. 对完整闭环重新计算幅相、噪声、执行量与模态漂移范围，不能用“滤波后波形更平滑”代替稳定性证据。
4. 输出采样率、系数或整形脉冲、状态/延迟、适用模态范围和对照实验；必要时交 aicoding-servo-auto-tuning 联合综合，验证用 aicoding-servo-validation。

## 按需参考

- [陷波器的插入点、设计和离散化](references/notch_and_digital_filters_zh.md)：模型、成立条件与常用设计。
- [输入整形与定位残余振动](references/input_shaping_and_residuals_zh.md)：运行接口、失败表现和可观察验证。

## 组合与输出边界

本技能输出滤波器或整形器及其状态和延迟；不采集未经授权的实机频响，不代替轨迹约束规划，也不以移除谱峰承诺全工况稳定。

与其他算法组合时，按名称定位 `aicoding-motor-control` 的 `references/control_contracts_zh.md`，核对单位、坐标、时间戳、总限幅、状态与证据等级。当前环境缺该参考时，先显式写清本任务对应契约，不依赖跨技能相对路径。涉及C实现结合C99技能，涉及数值与滤波实现结合DSP技能。

## 可执行工程入口

按技能名定位 `aicoding-motor-control` 的 `references/engineering_execution_zh.md`，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

调用 `mc_notch` 计算双线性离散系数，`mc_filter` 推进每实例双二阶状态；运行 `motor/run_tests.py` 的独立系数/边界验证。自动选峰/整定、输入整形、模态漂移与实机残振仍需专项证据。
