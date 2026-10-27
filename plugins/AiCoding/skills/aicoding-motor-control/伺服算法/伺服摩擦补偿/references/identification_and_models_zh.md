# 摩擦辨识与模型选择

## 先将不属于摩擦的转矩分开

同一机械轴上 $\tau_m=J\alpha+\tau_f(\omega)+\tau_g(q)+\tau_L+\tau_{cog}(\theta)$。恒速测量时 $J\alpha$接近零，但速度纹波、重力、齿槽、电流offset和转矩映射误差仍会污染结果。记录机械角、速度、加速度、实际电流/转矩、温度和所有已启用补偿；不要只记录速度环请求。

相同位置和负载条件、方向对称的近似下：

$$
\hat\tau_f(v)=\frac{\tau_m(+v)-\tau_m(-v)}{2},\qquad
\hat\tau_{bias}=\frac{\tau_m(+v)+\tau_m(-v)}{2}.
$$

它利用摩擦的近似奇对称性和偏置的近似方向无关性。若传动、预载或润滑明显不对称，使用正反向两条曲线，不能为了拟合对称模型而丢掉真实差异。跨位置测量时重力变化可能破坏上述分离。

## 常用静态模型

从库仑加粘性起步：$\tau_f=F_c\operatorname{sgn}(\omega)+B_v\omega$。需要描述低速下降段时采用平滑Stribeck候选：

$$
\tau_f(\omega)=\left[F_c+(F_s-F_c)e^{-(|\omega|/\omega_s)^\delta}\right]
\tanh(\omega/\omega_\epsilon)+B_v\omega.
$$

$F_c,F_s$为N·m，$B_v$为N·m·s/rad，$\omega_s,\omega_\epsilon$为rad/s，$\delta>0$无量纲；一般约束 $F_s\ge F_c\ge0$、$B_v\ge0$，但是否对称要由数据决定。静摩擦在零速本质上具有集合值/预滑移特性，平滑式在零速为零，不代表真实保持转矩为零。

按多个稳定速度平台拟合，低速增加密度，剔除加减速、饱和和未稳态段；每速度重复、跨位置平均或显式分离周期分量。保留独立验证数据、残差和参数置信区间。温度、润滑、预载变化明显时采用可追溯调度表而非持续无界自适应。

## 动态模型何时值得

LuGre模型可表达预滑移和迟滞：

$$
\dot z=\omega-\frac{|\omega|}{g(\omega)}z,\qquad
\tau_f=\sigma_0z+\sigma_1\dot z+\sigma_2\omega,
$$

其中 $z$为等效接触变形rad，$g(\omega)=[F_c+(F_s-F_c)e^{-(\omega/\omega_s)^2}]/\sigma_0$也为rad；$\sigma_0$为N·m/rad，$\sigma_1,\sigma_2$为N·m·s/rad。参数较多、状态与离散化敏感，不能仅凭几条恒速数据完成动态参数辨识。

来源：[Lund原始LuGre论文](https://lup.lub.lu.se/search/ws/files/6363840/8498924.pdf)，模型与摩擦控制背景；[Beckhoff速度相关附加电流](https://infosys.beckhoff.com/content/1033/tf5200_axis_compensation/352383115.html)说明实际电流对标定和验证的重要性。上述平滑模型是工程候选，不将任何厂商表值作为本轴参数。
