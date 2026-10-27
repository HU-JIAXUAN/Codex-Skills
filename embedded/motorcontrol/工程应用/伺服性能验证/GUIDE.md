---
capability_id: aicoding-servo-validation
description: 设计并执行伺服算法与产品性能验证。用于定义指标/工况、对照实验、数值与闭环模型、目标时序及实测证据，输出可复现结果。具体控制算法由对应技能设计，仿真与测试记录归对应算法主题。
---

# 伺服性能验证

本文件是[电机控制与伺服总入口](../../SKILL.md)调度的内部专题指南，不独立注册。`aicoding-servo-validation` 是内部能力键；其他专题通过[skillkit.json](../../skillkit.json)的 `target → source/entrypoint` 定位并读取对应 `GUIDE.md`，不调用同名独立 skill。
共同约束读取[公共控制契约](../../references/control_contracts_zh.md)，执行与证据读取[工程执行契约](../../references/engineering_execution_zh.md)。

## Skill Type

`reusable-domain-knowledge`、`team-expertise`。

## 输入与评价范围

取得具体产品目标、工况、算法/参数/代码版本、基线、测量通道与时间戳。将“高端”写成可测量的跟随/停稳/纹波/抗扰/效率/整定时间与一致性要求。读取[指标与试验](references/metrics_experiments_zh.md)。

## 执行

1. 选择与变化直接相关的数值真值、宿主对象、目标构建/时序、实物层级；说明当前证据边界。
2. 固定初态、轨迹、控制器、采样与负载，对算法启停做A/B；把参数失配、噪声、延迟和约束加入独立对象。
3. 预先写指标、阈值、计算窗口、数据有效性和失败退出规则；不能在结果不佳后降低阈值掩盖失败。
4. 运行并保存命令、原始数据和机器可读结果；生成必要图表，检查限幅、失效与恢复。
5. 按[三条纵向链](references/vertical_cases_zh.md)验证可组合性，记录未覆盖工况与目标板待测项。

## 工具与输出

`scripts/metrics.py`是小型CSV后处理器，输入`time_s,reference_rad,position_rad`及可选`current_a`，计算误差与电流指标；它不连接设备。停稳需显式指定起始时刻、误差带与保持时间，目标在此段必须恒定。用`--self-test`验证后处理边界。

输出工况/指标表、可复现命令、原始数据位置、数值结果和证据等级。数据不满足单调时刻、有限值或稳定参考时给错误，不输出虚假停稳。C99案例优先复用已检查的PI/数学/SVPWM原语；实际调用链应独立核对。

## 可执行工程入口

读取[工程执行契约与能力映射](../../references/engineering_execution_zh.md)，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

运行当前 `scripts/metrics.py --self-test` 和正式 `servo-validation/run_validation.py`；数值核心另跑 `motor/run_tests.py`。原始日志、产品阈值和硬件故障恢复由实际项目提供，宿主案例不能替代板测。
