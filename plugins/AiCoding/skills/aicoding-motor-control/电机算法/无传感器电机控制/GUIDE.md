---
capability_id: aicoding-motor-sensorless-control
description: 设计与诊断PMSM无位置传感器控制，覆盖反电势或磁链观测、PLL、高频注入、I-f启动和闭环切换。用于零低速可观测性、估计发散、启动及切换问题；纯编码器校准使用电机反馈与标定，纯速度环整定不触发。
---

# 无传感器电机控制

本文件是[电机控制与伺服总入口](../../SKILL.md)调度的内部专题指南，不独立注册。`aicoding-motor-sensorless-control` 是内部能力键；其他专题通过[skillkit.json](../../skillkit.json)的 `target → source/entrypoint` 定位并读取对应 `GUIDE.md`，不调用同名独立 skill。
共同约束读取[公共控制契约](../../references/control_contracts_zh.md)，执行与证据读取[工程执行契约](../../references/engineering_execution_zh.md)。

## Skill 类型

属于 `reusable-domain-knowledge` 与 `team-expertise`。默认中文。以上描述的触发和排除边界决定是否使用，不因只出现PMSM关键词就加载全部算法。

## 共同输入与边界

先从项目读取电机/功率级、坐标与单位、采样/生效时间、参数来源、运行目标和已有证据。跨算法契约读取[公共控制契约](../../references/control_contracts_zh.md)；不可用时在当前输出显式定义等价单位、方向、时间、有效性和限制状态，不依赖个人路径或相邻目录。涉及C实现同时使用 `aicoding-c99-standard-c`，滤波/定点细节使用 `aicoding-dsp`。

## 方法与实施

1. 先确定SPMSM/IPMSM、最低承载转速、反转/回馈、可用注入和噪声要求；无传感器角度与有传感器反馈使用同一单位、方向、时间戳和有效性契约。
2. 基波模型观测读[反电势观测与锁相](references/observer_pll_zh.md)；零低速或启动问题读[凸极注入与切换](references/startup_handover_zh.md)。不要将“有SMO”当作零速可观测。
3. 按模型推导符号，匹配实际施加电压和电流样本，处理参数误差、滤波相移和数字延迟；先在不参与控制的影子模式比较角度。
4. 定义估计有效/失效、启动、极性判断、捕获、混合和退出状态；切换需要幅相、转速、残差和持续时间判据，不能只用转速门限。
5. 输出可执行离散更新、C99快照/状态接口和测试矩阵；必须区分仿真角度真值、临时编码器对照与最终传感器less运行证据。

## 完成标准

方法适用于声明工况；公式与离散实现、单位/时间基准、C99模块状态与插入点可检查；给出调参依据、失败诊断和与目标对应的验证结果。分别标记资料结论、模型推导、仿真和板测；没有证据不得宣称调试成功。仅执行用户已授权的代码或设备动作。

## 可执行工程入口

读取[工程执行契约与能力映射](../../references/engineering_execution_zh.md)，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

启动复用正式 `IF` 资产；`mc_pll_init/update` 仅验证基础相位跟踪。完整反电势/磁链观测、HFI 与闭环切换仍须专项实现和验证，不能将 PLL 或 I-f 测试当作无传感器闭环通过。
