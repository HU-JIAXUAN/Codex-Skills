---
name: aicoding-control-frequency-analysis
description: 用频率响应、Bode图、带宽、交越频率、稳定裕度和灵敏度设计与审查电机三环及补偿器。用于解释频域指标、把连续设计落到离散控制、评估延迟与模型不确定性；实验采集与FRF估计使用伺服频响辨识。
---

# 频域分析与环路设计

## Skill 类型

`reusable-domain-knowledge`、`team-expertise`。默认中文。位于自动控制的经典控制分支；状态空间、H∞和多变量分析按实际耦合程度引入，不把“现代”当性能等级。

把Bode图、带宽与相位/增益裕度放在同一技能，因为它们使用同一个带有注入点、反馈符号和延迟的环路模型。先读[频域对象与指标](references/frequency_models_metrics_zh.md)，再按任务读[环路设计与离散实现](references/loop_design_implementation_zh.md)。

## 实施

1. 定义输入输出及单位、负反馈符号、环路断点、采样/更新率和已闭合的内环。实测曲线先确认是对象、环路增益还是闭环，不能对任意曲线求“相位裕度”。
2. 明确目标：跟踪误差、扰动抑制、噪声、电流峰值、停稳、参数变化。分别检查`L`、`S`、`T`和控制输出；不把采样率、开环交越与闭环带宽混用。
3. 按模型/FRF选择PI、超前滞后、陷波或降低带宽，写出选择依据和能推翻方案的工况。只在基准模型成立时用极零消去，柔性模态和非最小相位零点不做精确抵消。
4. 使用真实离散式、保持器、计算/通信与反馈延迟复算所有交越及裕度。连续模型估算只作起点；多质量、多轴或dq强耦合时补Nyquist、极点或多变量鲁棒性分析。
5. 输出控制器系数/单位/状态、调用时刻、总限幅和抗饱和插入点；给出标称与变化工况下的频域证据及同对象时域对照。无实测数据时交付可执行测量方案，不宣称已获得实物带宽。

## 组合

实验激励交给`aicoding-excitation-signal-design`；FRF获取与偏差交给`aicoding-servo-frequency-response`；三环结构与饱和交给`aicoding-servo-controller-design`；批量参数搜索交给`aicoding-servo-auto-tuning`。

跨模块按名称定位`aicoding-motor-control`的`references/control_contracts_zh.md`；缺少该资源时显式定义本任务的坐标、量纲和时刻。C实现结合C99，滤波及定点结合DSP。最终交付应能从公式、系数和对象数据复算，而非只有一张好看的Bode图。
