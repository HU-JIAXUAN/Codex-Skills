# 补偿集成、总限幅与交叉轴验证

## C99接口与插入点

```c
#include <stdint.h>
#include <stdbool.h>
typedef struct {
    float idA;
    float iqA;
    float omegaERadS;
    uint32_t cycleId;
    bool valid;
} DqSample;
typedef struct {
    float udV;
    float uqV;
    bool valid;
} DqVoltage;
typedef struct {
    float ldH;
    float lqH;
    float fluxWb;
} DqFfParams;
typedef enum { DQFF_OK, DQFF_BAD_INPUT } DqFfStatus;
/** 根据同一时刻的反馈计算电压；失败不覆盖out，不访问硬件。 */
DqFfStatus dqff_update(const DqFfParams *params, const DqSample *sample,
                      DqVoltage *out);
```

`dqff_update`接收同一时间基准的快照及只读参数版本，输出纯补偿；不读取速度PI全局、不写PWM、不修改电流PI积分。若使用LUT，接口同时校验坐标、范围与版本，显式报告越界；不默认外推。

推荐链：有效采样 → Park → 电流PI → 叠加dq前馈 → 限压/调制 → 实际电压估计 → 下拍模型/抗饱和。死区补偿也会消耗电压，要在最终调制层统一统计。限幅策略可以圆形等比或轴优先，但应匹配弱磁目标，不能按轴独立夹紧后宣称满足圆约束。

一种归一化回算抗饱和形式：

$$
x_{I,k+1}=x_{I,k}+K_iT_se_k+K_{aw}T_s(u_{applied,est,k}-u_{raw,k}).
$$

误差项必须对应同一生效周期、同一dq角度和总电压路径。若当前周期生效值尚不可知，用可实现命令残差并明确剩余模型误差，不把未知实际电压冒充可测。Kaw单位s⁻¹，不能不看采样周期抄离散系数。

## 参数误差与诊断

假设速度精确且使用反馈电流，$\Delta L=\hat L-L$、$\Delta\psi=\hat\psi-\psi$，残余为：

$$
L_d\dot i_d+R_si_d=u_{PI,d}-\omega_e\Delta L_qi_q,\quad
L_q\dot i_q+R_si_q=u_{PI,q}+\omega_e\Delta L_di_d+\omega_e\Delta\psi_f.
$$

速度越高残余可能越大，但不能由此把所有高速畸变归咎参数。也检查反馈年龄、ωm/ωe换算、角度预测重复、补偿符号、母线与PWM限幅、采样窗和逆变器误差。低速时补偿量小，改善不明显不能证明公式错误。

## 调参与工程验证

先保留可稳定的PI基线，仅开交叉项，再开永磁项/磁链图，必要时才加预测。测试时PI、母线、速度、负载和采样完全相同；记录补偿量、PI量、raw/applied电压、积分、时间戳和限幅状态。

固定id*对iq*阶跃，测非激励id峰值、积分绝对误差及恢复时间；反向试验同理。定义有单位的指标，如 $C_{dq}=\max|\Delta i_d|/|\Delta i_q^*|$。测试正反转、多转速、参数变化、弱磁限压、回馈与噪声；超限时不能用“完全解耦”描述结果。

源码/主机测试证明符号、单位、边界与时序算法；离散闭环仿真证明所用模型下性能；板上需测真实采样与生效时刻及交叉响应。没有后两层证据时报告为设计/仿真结果。

来源：本页为已声明dq模型的工程推导；诸自强等书p7、27、32、41用于参数、逆变器和辨识误差边界，[MathWorks官方补偿模型](https://www.mathworks.com/help/mcb/ref/pmsmfeedforwardcontrol.html)用于符号交叉核对。
