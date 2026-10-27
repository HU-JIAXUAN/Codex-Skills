# 陷波器的插入点、设计和离散化

## 先确认需要滤什么

机械共振峰不等于应在同一位置放一个同频陷波。电流命令前向滤波会降低到达电机的高频能量，同时改变闭环幅相；反馈滤波也改变闭环，且不能消除已经施加到机械端的力。加速度传感器看到的结构振动与速度估算器里的噪声应分别判断。

[Kollmorgen Tuning Guide](https://webhelp.kollmorgen.com/akd2g/english/content/AKD2G_User_Manual/Tuning%20the%20Drive.htm) 的Using Anti-Resonance Filters区分前向与反馈路径；应以自己的完整框图重算，不能把其滤波器编号当作通用位置。

## 可控深度的二阶陷波

一个常用连续模板为：

$$
H(s)=\frac{s^2+2\zeta_z\omega_0s+\omega_0^2}
{s^2+2\zeta_p\omega_0s+\omega_0^2},\qquad
0<\zeta_z<\zeta_p.
$$

$\omega_0=2\pi f_0$ rad/s，$f_0$为Hz，$\zeta_z,\zeta_p$无量纲。DC与无限高频增益均为1，中心幅值为 $\zeta_z/\zeta_p$。例如 $\zeta_p=0.08$、$\zeta_z=0.02$ 时中心约−12.04 dB；此数值仅展示深度关系。宽度由两阻尼共同影响，应直接检查离散响应，不把阻尼参数误称Hz带宽。

## 预畸变双线性实现

当 $0<f_0<f_s/2$ 时令：

$$
c=\frac{\omega_0}{\tan(\omega_0T_s/2)},\qquad
s=c\frac{1-z^{-1}}{1+z^{-1}}.
$$

未归一化系数：

$$
\begin{aligned}
b_0&=c^2+2\zeta_z\omega_0c+\omega_0^2,&
b_1&=2(\omega_0^2-c^2),&
b_2&=c^2-2\zeta_z\omega_0c+\omega_0^2,\\
a_0&=c^2+2\zeta_p\omega_0c+\omega_0^2,&
a_1&=2(\omega_0^2-c^2),&
a_2&=c^2-2\zeta_p\omega_0c+\omega_0^2.
\end{aligned}
$$

全部除以 $a_0$ 后执行 $y[k]=b_0x[k]+b_1x[k-1]+b_2x[k-2]-a_1y[k-1]-a_2y[k-2]$，此式中的系数均指已归一化值。注意有些库将反馈符号吸收入系数；迁移前核对。每轴独立状态，检查量化后的极点、中心深度、DC增益和内部状态溢出。

[MathWorks Discretizing a Notch Filter](https://www.mathworks.com/help/control/ug/discretizing-a-notch-filter.html) 与 [bilinear](https://www.mathworks.com/help/signal/ref/bilinear.html) 说明频域离散误差和预畸变；上述系数由代入模板展开得到，不依赖特定工具箱。

## 失败表现与验证

模态随负载漂移时，过窄陷波会失效；过深/过宽可能影响相位、指令响应与抗扰。逐步对比原始/滤波后FRF、闭环裕度、实际电流、负载侧误差和噪声。检查多个工作点、系数量化、切换瞬态和全局限幅；切换系数时定义状态映射或受控渐变，禁止仅改寄存器而保留不相容状态。
