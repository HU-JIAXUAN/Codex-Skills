---
name: aicoding-motor-parameter-identification
description: 设计与审查永磁同步电机的离线或在线电气及机械参数辨识，处理欠秩、激励、病态、饱和和逆变器误差。用于参数测量、RLS辨识及结果验收；纯角度零偏校准使用电机反馈与标定，纯环路调参使用伺服自动整定。
---

# 电机参数辨识

## Skill 类型

属于 `reusable-domain-knowledge` 与 `team-expertise`。默认中文。以上描述的触发和排除边界决定是否使用，不因只出现PMSM关键词就加载全部算法。

## 共同输入与边界

先从项目读取电机/功率级、坐标与单位、采样/生效时间、参数来源、运行目标和已有证据。跨算法契约按技能名定位 `aicoding-motor-control` 的 `references/control_contracts_zh.md`；不可用时在当前输出显式定义等价单位、方向、时间、有效性和限制状态，不依赖个人路径或相邻目录。涉及C实现同时使用 `aicoding-c99-standard-c`，滤波/定点细节使用 `aicoding-dsp`。

## 学科位置

本技能属于系统辨识的物理灰盒分支；模型结构与实验先于估计器。激励设计使用aicoding-excitation-signal-design，非参数FRF获取使用aicoding-servo-frequency-response，频域指标与控制器综合使用aicoding-control-frequency-analysis。

## 方法与实施

1. 明确结果用于电流环、转矩、弱磁、无传感器还是机械环；先定义相电阻、峰值磁链、增量或视在电感、轴侧及温度。
2. 对静止电阻/电感与旋转磁链/惯量选择不同实验；辨识前读[实验与可辨识性](references/experiments_zh.md)，不要先选RLS或EKF再寻找数据。
3. 依据实际采样与电压生效时刻构造回归，检查窗口秩、归一化条件数、激励与参数相关性。固定参数的误差必须进入结果不确定度。
4. 在线更新时读[递推辨识与发布](references/recursive_estimation_zh.md)。估计、接受、发布分离；采样无效或持续饱和时冻结辨识，不将零残差等同正确参数。
5. 输出公式、离散更新、C99输入输出与插入点，以及可复现数据/初值/单位；参数仅在独立残差和留出工况合格后供控制器平滑消费。

## 完成标准

方法适用于声明工况；公式与离散实现、单位/时间基准、C99模块状态与插入点可检查；给出调参依据、失败诊断和与目标对应的验证结果。分别标记资料结论、模型推导、仿真和板测；没有证据不得宣称调试成功。仅执行用户已授权的代码或设备动作。

## 可执行工程入口

按技能名定位 `aicoding-motor-control` 的 `references/engineering_execution_zh.md`，只加载本专项映射和 L1—L7 验收条件；通过批准的资产发现协议定位 CodingKit，命令与覆盖范围以唯一资产的 README、头文件和实际测试输出为准。

使用 `mc_rl_init/add/fit` 的固定 Ts、精确 ZOH RL 子集及独立真值。核对秩/激励、实际施加电压和留出工况；全参数在线辨识、磁链图与机械联合估计不因该测试通过而成立。
