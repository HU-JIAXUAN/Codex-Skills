---
name: aicoding-servo-controller-design
description: 设计和审查伺服电流、速度、位置控制器的连续与离散结构、PI参数、延迟裕度、限幅和抗饱和。用于从对象模型综合环路、解释参数单位或审查离散实现；频响采集、自动整定、专用前馈和机械抑振由对应技能处理。
---

# 伺服控制器设计

默认使用中文。先读取任务相关资料，按需加载参考；不将未实测候选写成产品已验证能力。

## Skill 类型

`reusable-domain-knowledge`、`team-expertise`。本技能保存可复用模型、设计判断与验证方法。

## 使用方式

1. 确认各环输出是电压、转矩、电流还是速度；记录机械/电角度、峰值/RMS、采样周期、测量与执行延迟。
2. 按对象和问题读取模型综合或离散实现参考。先建立可解释的标称控制器，再评估实际延迟、滤波、柔性传动与参数变化。
3. 给出带单位的连续增益、实际离散式、总限幅与积分状态接口。需要重整定时调用 aicoding-servo-auto-tuning，需要原始频响时调用 aicoding-servo-frequency-response。
4. 输出候选参数和成立范围、线性频域证据、饱和与切换时域检验；将理论计算、主机仿真、板测分别标明。

## 按需参考

- [电气与机械对象上的控制器综合](references/models_and_synthesis_zh.md)：模型、成立条件与常用设计。
- [离散控制、总限幅与验证](references/discrete_saturation_validation_zh.md)：运行接口、失败表现和可观察验证。

## 组合与输出边界

本技能输出控制器结构、带单位的增益和离散状态约定；FRF技能提供测量数据，自动整定技能搜索候选参数，抑振技能设计专用滤波。前馈和补偿按技能名定位后组合，禁止在此重复维护其实现。

与其他算法组合时，按名称定位 `aicoding-motor-control` 的 `references/control_contracts_zh.md`，核对单位、坐标、时间戳、总限幅、状态与证据等级。当前环境缺该参考时，先显式写清本任务对应契约，不依赖跨技能相对路径。涉及C实现结合C99技能，涉及数值与滤波实现结合DSP技能。

## 可执行工程入口

按技能名定位 `aicoding-motor-control` 的 `references/engineering_execution_zh.md`，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

增益基线调用 `mc_pi_design`，参数无扰更新用 `mc_pi_cfg`，运行复用正式 `pid_pi.c` 的先积分顺序；以真实 Ts、延迟和离散方法检查准入。柔性/高阶对象与最终限幅闭环仍须各自验证，禁止复制第二个 PI。
