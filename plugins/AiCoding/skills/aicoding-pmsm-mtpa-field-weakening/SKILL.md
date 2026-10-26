---
name: aicoding-pmsm-mtpa-field-weakening
description: 设计与审查PMSM的MTPA、限压弱磁、MTPV和转矩到电流分配，处理饱和磁链图、母线变化及四象限限制。用于电流轨迹、最大可达转矩和高速限压问题；纯dq电压解耦、六步换相或电机电磁结构设计不触发。
---

# 最大转矩电流比与弱磁控制

## Skill 类型

属于 `reusable-domain-knowledge` 与 `team-expertise`。默认中文。以上描述的触发和排除边界决定是否使用，不因只出现PMSM关键词就加载全部算法。

## 共同输入与边界

先从项目读取电机/功率级、坐标与单位、采样/生效时间、参数来源、运行目标和已有证据。跨算法契约按技能名定位 `aicoding-motor-control` 的 `references/control_contracts_zh.md`；不可用时在当前输出显式定义等价单位、方向、时间、有效性和限制状态，不依赖个人路径或相邻目录。涉及C实现同时使用 `aicoding-c99-standard-c`，滤波/定点细节使用 `aicoding-dsp`。

## 方法与实施

1. 明确峰值dq和转矩定义、SPMSM/IPMSM、参数/磁链图、母线与调制约束、电流和退磁边界；先读[轨迹与约束](references/trajectories_zh.md)。
2. 按最小电流、总效率或动态性能选择目标；MTPA不等于最高系统效率，MTPV不意味着所有电机可达到深弱磁。
3. 在请求转矩下先求MTPA候选，再检查实时可行域；超限时限压分配/弱磁，仍不可达则输出受限转矩。不能独立夹紧id/iq破坏矢量约束。
4. 在线限压与查表读[限压实现与标定](references/limits_calibration_zh.md)，与总电压饱和及电流PI抗饱和协调；不重复实现电压层限幅。
5. 输出求解/离散策略、C99电流参考接口、不可达原因和边界验证。为正反转/回馈分别验证，而非只镜像一张第一象限图。

## 完成标准

方法适用于声明工况；公式与离散实现、单位/时间基准、C99模块状态与插入点可检查；给出调参依据、失败诊断和与目标对应的验证结果。分别标记资料结论、模型推导、仿真和板测；没有证据不得宣称调试成功。仅执行用户已授权的代码或设备动作。

## 可执行工程入口

按技能名定位 `aicoding-motor-control` 的 `references/engineering_execution_zh.md`，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

调用 `mc_mtpa`、`mc_torque`、`mc_check_limits` 验证常参数正凸极 IPMSM 固定电流幅值与稳态约束。非线性磁链图、MTPV 和动态弱磁调节器尚需专项实现，不把稳态可行性判断称为完整弱磁控制。
