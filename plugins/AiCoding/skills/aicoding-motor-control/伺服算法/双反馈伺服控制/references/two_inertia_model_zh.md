# 两惯量模型与反馈测点

## 坐标统一后再建模

设减速比 $n=\omega_m/\omega_l>0$，负载惯量折算到电机侧为 $J_l'=J_l/n^2$，负载角折算为 $\theta_l'=n\theta_l$，理想负载转矩为 $\tau_l'=\tau_l/n$。实际方向通过独立符号映射；比值的平方不能代替方向标定。以下省略撇号，所有量均已折算到同一轴侧。

两惯量无各自对地阻尼的简化模型为：

$$
\begin{aligned}
J_m\dot\omega_m&=\tau_m-K(\theta_m-\theta_l)-D(\omega_m-\omega_l),\\
J_l\dot\omega_l&=K(\theta_m-\theta_l)+D(\omega_m-\omega_l)-\tau_L.
\end{aligned}
$$

$J_m,J_l$为kg·m²，$K$为N·m/rad，$D$为N·m·s/rad，角度rad、速度rad/s。摩擦、间隙、齿隙碰撞和非线性刚度尚未包括。

## 同一输入，不同测点的频响

令 $\tau_L=0$，由上述方程可推得：

$$
\frac{\omega_m}{\tau_m}=
\frac{J_ls^2+Ds+K}
{s[J_mJ_ls^2+D(J_m+J_l)s+K(J_m+J_l)]},
$$

$$
\frac{\omega_l}{\tau_m}=
\frac{Ds+K}
{s[J_mJ_ls^2+D(J_m+J_l)s+K(J_m+J_l)]}.
$$

小阻尼近似下，电机侧反共振频率与扭振模态为：

$$
\omega_{ar}\approx\sqrt{K/J_l},\qquad
\omega_r\approx\sqrt{K(1/J_m+1/J_l)}.
$$

两者为rad/s，换Hz要除 $2\pi$。例如 $J_m=2\times10^{-4}$、$J_l=8\times10^{-4}$ kg·m²、$K=20$ N·m/rad，得到约25.2 Hz与56.3 Hz；这是示例对象，不是控制带宽推荐。负载侧和电机侧不能共用同一条FRF而不声明测点。

## 常用结构与适用条件

常见基线让电机编码器负责换相与内速度环，负载编码器负责外位置环。它利用电机侧快速可观察量稳定执行器，同时修正传动后的静态/低频位置误差；并不自动允许把外环带宽提高到扭振模态之上。

组合两侧速度、估算轴扭矩或加入主动阻尼可改善动态，但需模型、延迟与噪声分析，不能简单平均两编码器。内环测点不同会改变零点结构，非共置控制更应检查完整闭环稳定性。

来源：[Beckhoff Resonance](https://infosys.beckhoff.com/content/1033/te5960_tc3_autotuning/16806690315.html)，电机/负载侧不同传递行为；[Kollmorgen Dual-Loop](https://webhelp.kollmorgen.com/kas3.04/content/AKD2G%20User%20Manual/Feedback.htm)，不同环独立反馈源。公式为所列简化力矩平衡模型的推导，不将产品的默认结构当作唯一可用结构。
