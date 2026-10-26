---
name: aicoding-servo-torque-ripple-compensation
description: 辨识、建图和设计伺服齿槽、位置周期及负载相关转矩纹波补偿，处理机械角/电角度、阶次、标定、插值、延迟和电流限制。用于低速纹波、周期误差与位置索引补偿；先分离编码器误差、摩擦、逆变器非线性及采样伪影。
---

# 齿槽与转矩纹波补偿

默认使用中文。先读取任务相关资料，按需加载参考；不将未实测候选写成产品已验证能力。

## Skill 类型

`reusable-domain-knowledge`、`team-expertise`。本技能保存可复用模型、设计判断与验证方法。

## 使用方式

1. 核对电流、实际机械运动、角度坐标与同步时序，先排除编码器周期误差、欠采样/节拍伪影、相序和死区问题。
2. 按建图参考区分空载齿槽、带载电磁纹波和传动周期项，定义方向/温度/负载覆盖，给地图标定身份和可信范围。
3. 按运行参考输出角度索引的候选补偿转矩、有效位及延迟条件，交 aicoding-servo-torque-feedforward 统一合成；不在此直接改电流环或PWM。
4. 以多圈、正反转、多速度/电流对照检验阶次与残差，避免只在教学轨迹上有效；需要阶次/频域可信度时调用 aicoding-servo-frequency-response。

## 按需参考

- [齿槽、转矩纹波与补偿建图](references/classification_and_teaching_zh.md)：模型、成立条件与常用设计。
- [地图运行、相位对齐与对照验证](references/runtime_map_and_validation_zh.md)：运行接口、失败表现和可观察验证。

## 组合与输出边界

本技能产出可追溯的纹波/齿槽补偿模型与候选转矩；摩擦、编码器标定、死区和最终转矩合成分别调用相应技能。补偿表有效范围外不外推成已验证能力。

与其他算法组合时，按名称定位 `aicoding-motor-control` 的 `references/control_contracts_zh.md`，核对单位、坐标、时间戳、总限幅、状态与证据等级。当前环境缺该参考时，先显式写清本任务对应契约，不依赖跨技能相对路径。涉及C实现结合C99技能，涉及数值与滤波实现结合DSP技能。

## 可执行工程入口

按技能名定位 `aicoding-motor-control` 的 `references/engineering_execution_zh.md`，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

调用 `mc_ripple` 的有界谐波合成与独立角度/阶次真值；保持机械/电角度、零位和相位时基一致。实测建图、编码器误差分离与负载/温度插值仍需专项实现验证。
