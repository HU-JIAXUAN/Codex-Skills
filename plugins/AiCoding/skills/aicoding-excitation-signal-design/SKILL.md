---
name: aicoding-excitation-signal-design
description: 为电机参数、机械模型与伺服频响辨识选择和实现阶跃、正弦、扫频、PRBS、多正弦及噪声激励，设计频段、幅值、时间、注入点和数据契约。用于提高可辨识性与实验信息量；运动目标规划使用运动轨迹规划，频响估计使用伺服频响辨识。
---

# 激励信号设计

## Skill 类型

`reusable-domain-knowledge`、`team-expertise`。默认中文。属于系统辨识的实验设计部分。目标是用受约束、可重复的输入区分候选模型和参数，波形发生器只是执行工具。

## 方法

1. 从待辨识模型、未知量和预期使用场景出发，明确哪一轴、哪一个求和点、哪些状态/参数需要被激励；先看[实验选择与信息量](references/experiment_design_zh.md)。
2. 依据最慢动态、可信采样频段、共振、负载行程、温升和噪声选波形/频带/幅值/时长；写明非线性、闭环相关性和测点带来的限制。
3. 按[发生器与采集契约](references/generator_integration_zh.md)实现可复位、每实例独立的离散波形，记录实际施加输入和停机/饱和状态。不要把请求波形直接当辨识输入。
4. 检查有效数据窗内的频谱、秩/条件数、削顶、信噪比与重复性，再决定是否估计；用新工况/新随机相位/新噪声实现做独立验证。
5. 交付实验表、波形配置、生成代码/调用点、采集定义、拒绝条件、参数/模型可信范围与下一轮调整依据。

参数估计交给`aicoding-motor-parameter-identification`，FRF估计交给`aicoding-servo-frequency-response`，已获FRF的环路设计交给`aicoding-control-frequency-analysis`。调参时幅值、带宽、模型阶次与数据长度联动考虑，不以“换成EKF/RLS”代替激励不足。

跨模块按技能名定位`aicoding-motor-control`的公共控制契约；C实现结合C99，滤波/定点结合DSP。没有板上数据只标记设计或宿主验证，禁止把重复同一波形后的低残差称为产品辨识完成。

## 可执行工程入口

按技能名定位 `aicoding-motor-control` 的 `references/engineering_execution_zh.md`，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

运行正式 `Signal generator/run_tests.py` 验证波形、复位和多实例；与 `mc_rl_init/add/fit` 的秩/激励拒绝组合。实际电压、温升、行程和信噪比仍需采集证据，禁止把请求激励直接当施加输入。
