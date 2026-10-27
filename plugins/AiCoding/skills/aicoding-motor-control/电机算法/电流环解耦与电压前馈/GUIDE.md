---
capability_id: aicoding-pmsm-dq-decoupling
description: 设计与审查PMSM电流环的dq交叉耦合补偿、反电势电压前馈、磁链表补偿及数字延迟处理。用于高速轴间串扰、前馈符号、参数失配和补偿后饱和；速度或转矩机械前馈、死区补偿及纯PI整定不触发。
---

# 电流环解耦与电压前馈

本文件是[电机控制与伺服总入口](../../SKILL.md)调度的内部专题指南，不独立注册。`aicoding-pmsm-dq-decoupling` 是内部能力键；其他专题通过[skillkit.json](../../skillkit.json)的 `target → source/entrypoint` 定位并读取对应 `GUIDE.md`，不调用同名独立 skill。
共同约束读取[公共控制契约](../../references/control_contracts_zh.md)，执行与证据读取[工程执行契约](../../references/engineering_execution_zh.md)。

## Skill 类型

属于 `reusable-domain-knowledge` 与 `team-expertise`。默认中文。以上描述的触发和排除边界决定是否使用，不因只出现PMSM关键词就加载全部算法。

## 共同输入与边界

先从项目读取电机/功率级、坐标与单位、采样/生效时间、参数来源、运行目标和已有证据。跨算法契约读取[公共控制契约](../../references/control_contracts_zh.md)；不可用时在当前输出显式定义等价单位、方向、时间、有效性和限制状态，不依赖个人路径或相邻目录。涉及C实现同时使用 `aicoding-c99-standard-c`，滤波/定点细节使用 `aicoding-dsp`。

## 方法与实施

1. 从项目Park变换和dq方程确定补偿符号，明确使用反馈还是参考电流；先读[模型与计算](references/model_discrete_zh.md)，不靠“前馈/反馈解耦”名称判断信号来源。
2. 区分旋转坐标速度耦合、永磁反电势和磁路交叉饱和；有饱和时选择磁链图而非含义不明的电感表。
3. 对齐电流/角度/速度与PWM生效时刻，再计算补偿；仅在有需求和足够模型证据时加入一拍预测或复矢量控制。
4. 读[实现与交叉轴验证](references/integration_diagnostics_zh.md)，在总电压限幅前叠加补偿，最终施加残差用于抗饱和；不在两个层重复增加永磁项。
5. 输出公式、离散式、C99接口和同工况交叉轴阶跃结果；理想代数抵消不等于离散/饱和系统完全解耦。

## 完成标准

方法适用于声明工况；公式与离散实现、单位/时间基准、C99模块状态与插入点可检查；给出调参依据、失败诊断和与目标对应的验证结果。分别标记资料结论、模型推导、仿真和板测；没有证据不得宣称调试成功。仅执行用户已授权的代码或设备动作。

## 可执行工程入口

读取[工程执行契约与能力映射](../../references/engineering_execution_zh.md)，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

用 `mc_dq_ff` 及 `motor/run_tests.py` 检查正反转符号、单位、参数与限压组合；运行只使用正式 FOC/PI/SVPWM。高速串扰还要区分电角速度/参数、角度年龄、饱和、死区与 ADC 错拍，不能只重调 PI。
