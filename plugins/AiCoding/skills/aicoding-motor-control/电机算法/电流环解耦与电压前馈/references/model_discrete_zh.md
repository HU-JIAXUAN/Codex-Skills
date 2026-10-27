# dq补偿模型、离散与参数含义

## 基础模型与符号

d轴沿永磁磁链，$[d,q]^T=[\cos\theta,\sin\theta;-\sin\theta,\cos\theta][\alpha,\beta]^T$，幅值不变、峰值SI：

$$
u_d=R_si_d+L_d\dot i_d-\omega_eL_qi_q,\quad
u_q=R_si_q+L_q\dot i_q+\omega_e(L_di_d+\psi_f).
$$

补偿为：

$$
u_{d,ff}=-\hat\omega_e\hat L_qi_q,\qquad
u_{q,ff}=\hat\omega_e(\hat L_di_d+\hat\psi_f),\qquad
u^*_{dq}=u_{PI,dq}+u_{ff,dq}.
$$

反电势项不是另一轴电流耦合，通常和交叉补偿一起实现。Ld=Lq并不消除旋转速度耦合；id*=0时d轴仍需补偿−ωLqiq。

## 反馈电流、参考电流与磁链图

默认用时间对齐的实际电流；若改用给定电流，令 $e_d=i_d^*-i_d,e_q=i_q^*-i_q$，在精确参数、无延迟/饱和下仍有残余：

$$
L_d\dot i_d+R_si_d=u_{PI,d}-\omega_eL_qe_q,\quad
L_q\dot i_q+R_si_q=u_{PI,q}+\omega_eL_de_d.
$$

参考/反馈方法要以相同PI、延迟和工况比较；命名不是优劣证明。饱和时采用：

$$
u_{d,ff}=-\omega_e\psi_q(i_d,i_q),\qquad
u_{q,ff}=\omega_e\psi_d(i_d,i_q).
$$

这里ψd已含永磁磁链，不再加ωψf。动态项为磁链对电流的局部导数矩阵，不能把小信号增量电感直接替代稳态视在电感，或忽略交叉导数。固定ψf项在弱磁时并未自行失效；应与Ld id项合计评估总d磁链。

## 一拍预测的条件

基础补偿每周期重算无需对本式做“离散积分”。若PWM一拍后生效，可在可信模型及时间对齐下预估：

$$
\hat i_{d,k+1}=i_{d,k}+\frac{T_s}{L_d}(u_{d,applied,k}-R_si_{d,k}+\omega_{e,k}L_qi_{q,k}),
$$

$$
\hat i_{q,k+1}=i_{q,k}+\frac{T_s}{L_q}(u_{q,applied,k}-R_si_{q,k}-\omega_{e,k}(L_di_{d,k}+\psi_f)).
$$

使用实际生效电压和已知采样区间，不用本拍未生效命令替代。预测放大噪声或失配时，应退回已验证的延迟匹配补偿，不盲目提高预测增益。

算例：p=4、机械1000 rpm、Ld=0.3 mH、Lq=0.6 mH、ψf=0.05 Wb、id=−2 A、iq=5 A，则ωe=418.879 rad/s，ud,ff≈−1.2566 V，uq,ff≈20.6926 V。反转时速度相关项随符号变化；不能用无符号rpm。

## 来源

已核读诸自强等《永磁同步电机参数辨识》书p7（PDF28），增量/视在及饱和；[MathWorks PMSM FeedForward Control](https://www.mathworks.com/help/mcb/ref/pmsmfeedforwardcontrol.html)核对补偿符号、反馈电流输入及磁链LUT形式。参考电流残差、Euler预测与算例为本页模型推导。
