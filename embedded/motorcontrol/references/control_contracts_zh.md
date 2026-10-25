# 公共控制契约：量纲、模型、时基与约束

## 默认坐标与量纲

本族示例默认SI、相电流/相电压峰值、幅值不变Clarke、d轴对齐永磁磁链。其他约定先显式换算，尤其教材中的峰值/RMS转矩系数。

$$
i_d=i_\alpha\cos\theta_e+i_\beta\sin\theta_e,\qquad
i_q=-i_\alpha\sin\theta_e+i_\beta\cos\theta_e
$$

$$
\theta_m=s_{enc}\theta_{enc},\quad\omega_m=s_{enc}\omega_{enc},\qquad
\theta_e=\operatorname{wrap}(p\theta_m+\theta_0),\quad\omega_e=p\omega_m
$$

电流A，角度rad，速度rad/s，极对数$p$无量纲。$s_{enc}\in\{-1,1\}$只把原始编码器坐标转换为与相序/转矩一致的机械正转坐标；下文机械功率和转矩均在此统一坐标中定义，不再次乘方向。若直接对原始编码器坐标定义转矩，则也必须转换转矩符号以保持功率一致。rpm先转rad/s；电机轴与输出轴通过明确定义的传动比连接。

本约定下

$$
P_e=\frac32(u_di_d+u_qi_q),\qquad
T_e=\frac32p(\psi_di_q-\psi_qi_d)
$$

在端口功率核对中计入电阻、储能和机械损耗；电磁转矩与负载轴传感器转矩有不同含义。$K_t$必须注明轴侧与峰值/RMS定义。

## 参数与模型

线性PMSM电压模型为

$$
u_d=R_si_d+L_d\dot i_d-\omega_eL_qi_q
$$

$$
u_q=R_si_q+L_q\dot i_q+\omega_e(L_di_d+\psi_f)
$$

$R_s$为每相Ω，$L_d,L_q$为H，磁链为Wb。线间测量转换依赖星/三角接法。每份参数记录辨识方法、温度、偏置电流、激励频率与有效范围。

非线性模型使用磁链图和局部导数：

$$
\begin{bmatrix}u_d\\u_q\end{bmatrix}
=R_s\begin{bmatrix}i_d\\i_q\end{bmatrix}
+\underbrace{\begin{bmatrix}
\partial\psi_d/\partial i_d&\partial\psi_d/\partial i_q\\
\partial\psi_q/\partial i_d&\partial\psi_q/\partial i_q
\end{bmatrix}}_{L_{\mathrm{inc}}}
\begin{bmatrix}\dot i_d\\\dot i_q\end{bmatrix}
+\omega_e\begin{bmatrix}-\psi_q\\\psi_d\end{bmatrix}
$$

动态增量电感与稳态磁链/电流比对应的视在电感不同，不能将含义不明的一个`L`无条件用于辨识、MTPA、解耦和高频注入。交叉饱和、温度和插值范围进入模型接口。

## 时基与数据年龄

明确每项反馈的采样时刻、接收时刻、有效标志、数据年龄及输出实际生效时刻。允许异步与多速率；锁存/外推由最大年龄、角速度、误差预算和测量延迟决定。

PWM载波、控制更新频率与带宽分别记录。滤波、ADC、传输、计算和PWM保持延迟进入模型。`cycle_id`是可选手段；不变量是时间关系可解释、过期可识别、最坏计算不越过装载点。

## 唯一求和点

| 模块 | 输出与组合责任 |
|---|---|
| 轨迹 | 同时刻$q_r,v_r,a_r$与v/a/j约束、改目标/停止语义 |
| 位置反馈+速度前馈 | 速度请求，求和后统一限速 |
| 速度反馈+机械前馈 | 转矩请求，求和后统一转矩/电流/热约束 |
| MTPA/弱磁 | 可行$id^*,iq^*$与可达转矩/限制原因 |
| 电流PI+dq前馈 | 电压请求，包括动态调节余量 |
| 逆变器补偿/调制 | 门极请求、最终duty、有效端电压估计；这些量分别记录 |

同一摩擦、重力或齿槽补偿项只有一个所有者。摩擦模块如已包含黏性项，机械前馈不能再叠加相同的Bω。DOB/ESO需说明估计总扰动还是已补偿后的剩余扰动；已有前馈并不自动使总扰动估计变为残差，必须在估计方程中扣除同一时基/滤波的已知项，详见伺服扰动观测技能。

## 可实现性与抗饱和

按本幅值不变且$u_{\alpha\beta}/V_{dc}$归一化，理想线性SVPWM的全角度圆上限为$1/\sqrt3$。真实能力还受母线、最小脉宽、采样窗口与动态余量限制。若API使用其他归一化，先推导映射再给数值。

检查最终三相duty和装载，不能只检查dq圆。记录`requested/applied/residual`和限制原因。

若PI只评价$u_{PI}$，外部前馈为$u_{FF}$，且已转换到同一物理电压评价点，则

$$
r=u_{\mathrm{applied}}-(u_{PI}+u_{FF}),\qquad
u_{PI,\mathrm{track}}=u_{PI}+r
$$

把一致残差送回PI，不能直接把含外部前馈的最终总电压当PI独自产生的输出。死区门极补偿和有效端电压不同，求残差前先统一评价点；正常补偿本身不应凭空触发回算。各外环也要知道其求和点的最终限制。模式切换采用积分跟踪与无扰衔接。

## 产品与证据

每项功能记录指标、基线、参数/版本、工况、启停状态、算力与标定成本。区分独立数值真值、对象模型、目标构建/时序、真实机械对象四类证据。

基础：诸自强、刘侃、梁大为《永磁同步电机参数辨识》，ISBN 9787111793960，书页7、21–22、27、32、41；李贵、童维勇《电机控制算法实战》第1–2章。列举页已核对，其他章节按具体任务读取。

公开交叉参考：[磁链与dq前馈](https://www.mathworks.com/help/mcb/ref/pmsmfeedforwardcontrol.html)、[MTPA/弱磁约束](https://www.mathworks.com/help/mcb/gs/field-weakening-control-mtpa-pmsm.html)、[前馈尺度与延迟](https://infosys.beckhoff.com/content/1033/tf5200_feedforward_control/308354059.html)。
