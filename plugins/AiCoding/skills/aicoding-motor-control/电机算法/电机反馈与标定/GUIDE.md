---
capability_id: aicoding-motor-feedback-calibration
description: 设计与诊断PMSM和BLDC的位置反馈、电角度零偏、极对数、相序方向、编码器与旋变标定及反馈时序。用于有传感器FOC首次运行、角度不一致和高速延迟问题；纯传感器less观测器或通信协议栈实现不触发。
---

# 电机反馈与标定

本文件是[电机控制与伺服总入口](../../SKILL.md)调度的内部专题指南，不独立注册。`aicoding-motor-feedback-calibration` 是内部能力键；其他专题通过[skillkit.json](../../skillkit.json)的 `target → source/entrypoint` 定位并读取对应 `GUIDE.md`，不调用同名独立 skill。
共同约束读取[公共控制契约](../../references/control_contracts_zh.md)，执行与证据读取[工程执行契约](../../references/engineering_execution_zh.md)。

## Skill 类型

属于 `reusable-domain-knowledge` 与 `team-expertise`。默认中文。以上描述的触发和排除边界决定是否使用，不因只出现PMSM关键词就加载全部算法。

## 共同输入与边界

先从项目读取电机/功率级、坐标与单位、采样/生效时间、参数来源、运行目标和已有证据。跨算法契约读取[公共控制契约](../../references/control_contracts_zh.md)；不可用时在当前输出显式定义等价单位、方向、时间、有效性和限制状态，不依赖个人路径或相邻目录。涉及C实现同时使用 `aicoding-c99-standard-c`，滤波/定点细节使用 `aicoding-dsp`。

## 方法与实施

1. 分别确认ADC电流方向、U/V/W相序、机械反馈方向、极对数、单多圈与减速比；读[角度与标定](references/angle_calibration_zh.md)，不要把所有错误折算成一个offset。
2. 从数据手册和采样事件确定编码器/旋变的取样时刻；读[时序与诊断](references/timing_diagnostics_zh.md)，区分分辨率、准确度、传输延迟、采样年龄和滤波相移。
3. 电气零偏必须附机械还是电气单位、参考轴和变换约定；保留原始计数，在单一换算处应用方向、比例和零点。
4. 标定输出带版本、可信度和适用硬件；写入候选记录，确认后再由控制周期一致发布，不能边采集边改活动坐标。
5. 用多位置/双方向及时间对齐验证；输出C99接口、异常策略与板测项目，不能把CRC正确或静止角度不变等同反馈可靠。

## 完成标准

方法适用于声明工况；公式与离散实现、单位/时间基准、C99模块状态与插入点可检查；给出调参依据、失败诊断和与目标对应的验证结果。分别标记资料结论、模型推导、仿真和板测；没有证据不得宣称调试成功。仅执行用户已授权的代码或设备动作。

## 可执行工程入口

读取[工程执行契约与能力映射](../../references/engineering_execution_zh.md)，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

通过 `mc_align_angle` 和 Go `analyze` 检查物理锁存到使用时刻的有界预测与年龄。方向、零偏和极对数标定状态机及协议采集仍属项目接口；接收时间不得替代位置采样时间。
