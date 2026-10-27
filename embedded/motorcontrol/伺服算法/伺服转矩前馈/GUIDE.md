---
capability_id: aicoding-servo-torque-feedforward
description: 设计和实现伺服惯量、阻尼、重力及已知负载转矩前馈。用于加减速跟随、轴侧换算、转矩到电流映射、限流与观测器组合；输出机械转矩请求。速度指令前馈与dq电压前馈由各专项处理。
---

# 伺服转矩前馈

本文件是[电机控制与伺服总入口](../../SKILL.md)调度的内部专题指南，不独立注册。`aicoding-servo-torque-feedforward` 是内部能力键；其他专题通过[skillkit.json](../../skillkit.json)的 `target → source/entrypoint` 定位并读取对应 `GUIDE.md`，不调用同名独立 skill。
共同约束读取[公共控制契约](../../references/control_contracts_zh.md)，执行与证据读取[工程执行契约](../../references/engineering_execution_zh.md)。

## Skill Type

`reusable-domain-knowledge`、`team-expertise`。

## 输入与方法选择

确定转矩定义、轴侧、有符号传动比、惯量/摩擦/重力来源、参考加速度/速度、执行延迟、可达转矩与电流约束。先用可信的等效惯量乘轨迹加速度；按负载与残差证据逐项增加阻尼、重力和已知负载。

读取[机械模型与选择](references/mechanical_models_zh.md)。摩擦模型和齿槽图由各自技能提供，转矩前馈负责合成；DOB/ESO的估计对象必须说明，防止同一补偿项重复相加。

## 实现与组合

输出统一轴侧的N·m，叠加到速度控制器转矩输出后统一限制。交由唯一的转矩到电流分配器处理；IPMSM/弱磁/饱和时调用MTPA/磁链模型，不让各前馈自行除同一个未定义Kt。

读取[实现与验证](references/implementation_validation_zh.md)，定义配置、状态、限幅残差和切换语义。C99实现优先纯计算，传动/平台量纲转换留在适配边界，参数与运行状态分离。

## 输出与验收

给出力学模型、辨识/标定依据、计算顺序、接口与可达性判断。固定轨迹与控制器比较启停前馈的跟随误差、加减速电流、转矩预测残差和停稳；覆盖负载、方向、母线及限制恢复。外部CodingKit案例2可作宿主纵向基线，实际产品通过阈值由工况决定。

## 可执行工程入口

读取[工程执行契约与能力映射](../../references/engineering_execution_zh.md)，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

调用 `mc_mech_ff` 核对同轴侧惯量、黏性和已知负载转矩合成，并与 `servo-validation` 链组合。重力/弹性模型及最终可实现转矩须由当前对象提供，避免与摩擦/DOB 重复补偿。
