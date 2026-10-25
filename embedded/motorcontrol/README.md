# 电机控制技能套件

21个中文技能作为一个skillkit维护，工程目标是从问题选择方法、得到可移植实现、说明成立条件，再用与目标匹配的数据验证。PMSM/BLDC优先深入，模型和接口保留跨类型架构。中文目录、标题及UI用于阅读；技术ID采用运行时兼容的ASCII。

## 学科与职责

自动控制是总领域。Bode图、带宽、交越、相位/增益裕度和loop shaping共同属于经典频域方法，放在一个“频域分析与环路设计”技能中。状态空间、鲁棒控制和观测器是按需要采用的方法，不以目录的“经典/现代”划分产品档次。

系统辨识包含模型结构、激励设计、估计与验证。“电机参数辨识”是物理灰盒分支；“伺服频响辨识”获取动态数据；“激励信号设计”负责实验信息量。控制器设计消费其结果，两者不能仅凭一条拟合曲线合并。

~~~text
motorcontrol/
  SKILL.md / skillkit.json / references/ / assets/ / agents/
  系统辨识/       电机参数辨识、伺服频响辨识、激励信号设计
  自动控制/
    经典控制/     频域分析与环路设计
    控制器设计/   伺服控制器设计、伺服自动整定
    补偿与观测/   伺服振动抑制、伺服扰动观测
  电机算法/       反馈标定、无传感器、MTPA/弱磁、死区、dq解耦
  伺服算法/       速度/转矩前馈、轨迹、摩擦、纹波、双反馈
  工程应用/       伺服性能验证
~~~

## 技能入口

| 中文技能 | 入口 | 技术ID |
|---|---|---|
| 电机控制集成 | [入口](SKILL.md) | aicoding-motor-control |
| 电机参数辨识 | [入口](系统辨识/电机参数辨识/SKILL.md) | aicoding-motor-parameter-identification |
| 无传感器电机控制 | [入口](电机算法/无传感器电机控制/SKILL.md) | aicoding-motor-sensorless-control |
| 电机反馈与标定 | [入口](电机算法/电机反馈与标定/SKILL.md) | aicoding-motor-feedback-calibration |
| 伺服控制器设计 | [入口](自动控制/控制器设计/伺服控制器设计/SKILL.md) | aicoding-servo-controller-design |
| 伺服性能验证 | [入口](工程应用/伺服性能验证/SKILL.md) | aicoding-servo-validation |
| 最大转矩电流比与弱磁控制 | [入口](电机算法/最大转矩电流比与弱磁控制/SKILL.md) | aicoding-pmsm-mtpa-field-weakening |
| 逆变器死区补偿 | [入口](电机算法/逆变器死区补偿/SKILL.md) | aicoding-inverter-deadtime-compensation |
| 电流环解耦与电压前馈 | [入口](电机算法/电流环解耦与电压前馈/SKILL.md) | aicoding-pmsm-dq-decoupling |
| 伺服速度前馈 | [入口](伺服算法/伺服速度前馈/SKILL.md) | aicoding-servo-velocity-feedforward |
| 伺服转矩前馈 | [入口](伺服算法/伺服转矩前馈/SKILL.md) | aicoding-servo-torque-feedforward |
| 运动轨迹规划 | [入口](伺服算法/运动轨迹规划/SKILL.md) | aicoding-motion-trajectory-planning |
| 伺服频响辨识 | [入口](系统辨识/伺服频响辨识/SKILL.md) | aicoding-servo-frequency-response |
| 伺服自动整定 | [入口](自动控制/控制器设计/伺服自动整定/SKILL.md) | aicoding-servo-auto-tuning |
| 伺服振动抑制 | [入口](自动控制/补偿与观测/伺服振动抑制/SKILL.md) | aicoding-servo-vibration-suppression |
| 伺服扰动观测 | [入口](自动控制/补偿与观测/伺服扰动观测/SKILL.md) | aicoding-servo-disturbance-observer |
| 伺服摩擦补偿 | [入口](伺服算法/伺服摩擦补偿/SKILL.md) | aicoding-servo-friction-compensation |
| 齿槽与转矩纹波补偿 | [入口](伺服算法/齿槽与转矩纹波补偿/SKILL.md) | aicoding-servo-torque-ripple-compensation |
| 双反馈伺服控制 | [入口](伺服算法/双反馈伺服控制/SKILL.md) | aicoding-servo-dual-feedback-control |
| 频域分析与环路设计 | [入口](自动控制/经典控制/频域分析与环路设计/SKILL.md) | aicoding-control-frequency-analysis |
| 激励信号设计 | [入口](系统辨识/激励信号设计/SKILL.md) | aicoding-excitation-signal-design |

## 使用顺序与知识边界

主入口处理产品指标、控制链和跨算法约束；专项只加载当前问题所需references。一个任务可以组合多个技能，但一个前馈/补偿项只有一个求和点所有者。初始设计、模型推导、宿主测试、板测和产品验收分别陈述。

- [公共控制契约](references/control_contracts_zh.md)：单位、轴侧、时刻、增量电感、最终限幅与抗饱和。
- [系统辨识基础](references/system_identification_foundations_zh.md)：模型/实验/估计/接受/发布的分工。
- [项目参考矩阵](references/repo_reference_matrix_motor_zh.md)：按问题匹配真实调用链与官方上游。
- [理论与实践比较](references/theory_practice_comparison_zh.md)：前提、实现妥协、反例、更优候选与验证。

refs标明诸自强等专著的实际核读页码、论文DOI/原始链接和资料阅读范围；目录/摘要核对不会写成全文精读。面试题库只作覆盖检查。现成工程值得参考，其写法和成功声明仍需独立挑战。

## 代码资产与笔记

稳定代码归外部CodingKit，不复制到插件：modules/common/controller/Signal generator提供多种可重复激励；examples/servo-validation贯穿辨识→dq控制、轨迹→前馈→三环、死区→调制→抗饱和。具体API、编译命令、模型与限制以各资产README为准。

笔记库对应保存推导、来源与学习导航：系统辨识包含参数与激励；三环文件夹各有“电流环设计”“速度环设计”“位置环设计”；“算法”承载专项；具体仿真与验证附在对应笔记。保留稳定ID、旧图和用户编辑。

## 配置与发布

[skillkit.json](skillkit.json)集中记录本套件的相对源路径、中文名和打包目标；仓库总配置只选择启用这个套件。构建器将21个入口展开为平铺运行包，主入口用include清单只复制自己的资源，避免重复嵌套技能。

本轮按用户要求优先完成内容与代码，只做必要的局部编译、数学与路径检查。Hook、全库门禁、最终生成包、安装缓存与Git发布在用户提出push时继续；当前源目录内容不应冒充已安装的新版本。
