# 电气与机械对象上的控制器综合

## 从控制输出反推对象

电流 PI 输出相电压坐标 $v_d,v_q$；速度控制器优先输出转矩 $\tau$；位置控制器通常输出机械角速度 $\omega$。环路不同，增益量纲不能照搬。先确定同一坐标系下的正方向及峰值/RMS定义。以下为作者根据标称模型推导的候选设计，不是厂商通用整定值。

## 一阶电流对象

忽略或已补偿反电动势与交叉耦合，且电感在工作点附近可线性化时：

$$
P_i(s)=\frac{e^{-sT_d}}{Ls+R},\qquad C_i(s)=K_p+\frac{K_i}{s}.
$$

$L$ 为该工作点的增量电感 H，$R$ 为等效相电阻 Ω，$T_d$ 为采样、计算、PWM保持等效延迟 s。令 $K_p=L\omega_c$、$K_i=R\omega_c$ 可在忽略延迟时消去电气极点，使开环成为 $\omega_c/s$。$K_p$ 单位 V/A，$K_i$ 为 V/(A·s)，$\omega_c$ 为 rad/s。饱和、交叉饱和和温升会破坏准确消去。

只有纯延迟附加到这个理想模型时，候选相位裕度约为 $\pi/2-\omega_cT_d$。这不是完整裕度结论：必须把电流传感器、数字滤波、PWM保持和电压限幅纳入最终分析。

## 刚性机械速度环

若内电流环在目标频段近似单位增益，且输出是转矩：

$$
J\dot\omega+B\omega=\tau-\tau_L,\qquad
P_\omega(s)=\frac{1}{Js+B}.
$$

$J$ 为折算到同一轴的总惯量 kg·m²，$B$ 为粘性阻尼 N·m·s/rad。速度 PI 的闭环特征多项式为：

$$
Js^2+(B+K_p)s+K_i.
$$

按候选自然频率 $\omega_n$、阻尼比 $\zeta$ 匹配系数：

$$
K_p=2\zeta\omega_nJ-B,\qquad K_i=J\omega_n^2.
$$

此处 $K_p$ 为 N·m/(rad/s)，$K_i$ 为 N·m/rad。若算得负 $K_p$，不要机械采用，需重新选结构或设计目标。若输出改为电流，只有标称线性转矩常数 $K_t$ 成立时才将两增益除以 $K_t$。MTPA/弱磁时通过统一转矩映射处理。

示例：$J=2\times10^{-4}$ kg·m²、$B=10^{-4}$ N·m·s/rad、候选 $\omega_n=2\pi\times30$ rad/s、$\zeta=0.9$，得到 $K_p\approx0.06776$、$K_i\approx7.1061$，单位如上。30 Hz仅用于展示计算；实机要以电流环延迟、柔性模态和噪声重新筛选。

## 外位置环与不同性能目标

保留实际内环时，令$T_\tau$为转矩请求到实际电磁转矩的物理闭环，$P_m=1/(Js+B)$，$H_\omega$为测速通道。则$L_\omega=C_\omega T_\tau P_mH_\omega$；参考到真实速度为$C_\omega T_\tau P_m/(1+L_\omega)$。若$H_\omega\ne1$，它不等于测量量闭环$L_\omega/(1+L_\omega)$。位置环应使用真实速度闭环接运动学积分，不能把滤波后的反馈响应当真实轴响应。

真实负载转矩在电磁转矩之后进入机械对象，正阻力约定下其速度响应为$-P_m/(1+L_\omega)$，不含前级$T_\tau$。电流/转矩命令处的扰动走不同路径；抗扰公式由注入点决定。

理想速度内环下，位置 P 控制 $\omega_c=K_\theta(\theta_r-\theta)$ 给出 $\theta/\theta_r=K_\theta/(s+K_\theta)$，$K_\theta$ 为 s⁻¹。速度前馈是另一个输入，不改变上述标称反馈特征方程。实际速度闭环、负载编码器延迟和位置预滤波都需纳入。

区分指令跟踪与负载扰动抑制：提高前馈可以降低跟随误差，却不证明抗扰或稳定裕度提高。不要把固定“三环带宽比例”当作验收标准。对有多个交越或明显机械柔性的系统，检查完整 Nyquist/闭环极点、所有相关交越和负载侧响应。

## 方法边界与来源

输入应包含对象模型/频响及可信频段、惯量范围、延迟预算、执行器限制和验收定义；输出是控制器结构与参数，不替代原始频响测量。

- [Kollmorgen Tuning Guide](https://webhelp.kollmorgen.com/akd2g/english/content/AKD2G_User_Manual/Tuning%20the%20Drive.htm)，Velocity/Position Loop，提供工业级联环路和调试背景；本文公式为上述模型的独立推导，不能套用其示例超调阈值。
- [Beckhoff Resonance](https://infosys.beckhoff.com/content/1033/te5960_tc3_autotuning/16806690315.html)，区分电机侧与负载侧频响及两惯量行为。
