---
capability_id: aicoding-servo-friction-compensation
description: 辨识和设计伺服库仑、粘性、Stribeck及必要的动态摩擦补偿，处理低速、过零、温度、方向、标定残差和限幅。用于换向误差、爬行与摩擦前馈；输出摩擦模型/候选转矩，不负责最终前馈合成或把齿槽和重力误归为摩擦。
---

# 伺服摩擦补偿

本文件是[电机控制与伺服总入口](../../SKILL.md)调度的内部专题指南，不独立注册。`aicoding-servo-friction-compensation` 是内部能力键；其他专题通过[skillkit.json](../../skillkit.json)的 `target → source/entrypoint` 定位并读取对应 `GUIDE.md`，不调用同名独立 skill。
共同约束读取[公共控制契约](../../references/control_contracts_zh.md)，执行与证据读取[工程执行契约](../../references/engineering_execution_zh.md)。

默认使用中文。先读取任务相关资料，按需加载参考；不将未实测候选写成产品已验证能力。

## Skill 类型

`reusable-domain-knowledge`、`team-expertise`。本技能保存可复用模型、设计判断与验证方法。

## 使用方式

1. 先确认电流尺度、转矩映射、传动坐标、机械释放和基线闭环；读取辨识参考定义方向、速度和温度采样。
2. 优先从库仑加粘性或平滑Stribeck起步；只有数据存在可复现预滑移/迟滞且收益明确时才引入动态模型。
3. 读取运行参考定义过零平滑、低速死区、模型版本、输出幅度/斜率和使能过渡；输出摩擦转矩模型给 [伺服转矩前馈](../伺服转矩前馈/GUIDE.md) 合成。
4. 比较关闭/开启的换向误差、速度纹波、实际电流与残差，区分理论拟合、离线回放和板测；未解释的周期位置误差交 [齿槽与转矩纹波补偿](../齿槽与转矩纹波补偿/GUIDE.md)。

## 按需参考

- [摩擦辨识与模型选择](references/identification_and_models_zh.md)：模型、成立条件与常用设计。
- [过零运行、转矩接口与验收](references/runtime_reversal_validation_zh.md)：运行接口、失败表现和可观察验证。

## 组合与输出边界

本技能输出摩擦转矩模型及有效范围，最终合成由转矩前馈技能完成；不接管抱闸、堵转保护、轨迹规划或把位置周期扰动全部解释成摩擦。

与其他算法组合时，读取[公共控制契约](../../references/control_contracts_zh.md)，核对单位、坐标、时间戳、总限幅、状态与证据等级。公共参考缺失时报告打包不完整，不能省略本任务的单位、时刻与限制契约。涉及C实现结合C99技能，涉及数值与滤波实现结合DSP技能。

## 可执行工程入口

读取[工程执行契约与能力映射](../../references/engineering_execution_zh.md)，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

调用 `mc_friction` 核对静态库仑/黏性/Stribeck 候选及过零符号。动态摩擦状态、温度与实机辨识残差仍需专项证据；相同 Bω 不得在机械前馈再次合成。
