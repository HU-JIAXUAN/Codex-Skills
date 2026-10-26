# 在线限压、电流分配与标定表

## 电压反馈弱磁的一种离散实现

定义滤波后的电压需求幅值 $U_{req}=\sqrt{u_{d,raw}^2+u_{q,raw}^2}$，必须取最终矢量限幅前且口径一致的总指令。令 $e_U=U_{avail}-U_{req}$，负误差表示需要更负id：

$$
x_{k+1}=\operatorname{clip}(x_k+K_{i,fw}T_{fw}e_U,\ i_{d,min},0),\quad
i_{d,fw}=\operatorname{clip}(x_{k+1}+K_{p,fw}e_U,\ i_{d,min},0).
$$

在已声明分配规则下与MTPA候选协调，例如采用更负的id候选，再由转矩模型重算iq并检查电流圆。不能在任何电机/目标下无条件取min；MTPV段应由可行域求解或LUT接管。弱磁外环比内电流环慢，增益由闭环电压对id灵敏度/延迟设计；不是固定增益配方。

电压瞬间下降时使用母线前馈/可行域降额限制转矩，慢积分弱磁不能独自保证不饱和。退出弱磁采用滞环和状态跟踪，避免id突跳。最终输出还受 $|i_q|\le\sqrt{\max(0,I_{max}^2-i_d^2)}$ 约束，超限须降低可达转矩并反馈外环抗饱和。

## C99插入点

下列 `current_ref_update` 是完整转矩分配/动态弱磁的方法设计草图，仓库没有该正式函数。已存在的 `mc_mtpa` 只解常参数固定电流幅值MTPA，`mc_torque` 计算模型转矩，`mc_check_limits` 检查稳态约束；三者不能冒充完整FW/MTPV控制器。先复用当前工程/原始SDK中匹配器件与磁模型的正式分配器，没有时明确实现缺口并单独验收。

```c
#include <stdbool.h>
#include <stdint.h>
typedef struct {
    float torqueNm;
    float omegaERadS;
    float busV;
    float maxCurrentA;
    float maxVoltageV;
    float minIdA;
    float voltageDemandV;
} CurrentRequest;
typedef struct {
    float idA;
    float iqA;
    float achievableNm;
    bool currentLimited;
    bool voltageLimited;
    bool valid;
} CurrentReference;
typedef struct {
    float weakIdA;
    float previousIdA;
    float previousIqA;
} CurrentRefState;
typedef struct {
    float ldH;
    float lqH;
    float fluxWb;
    uint16_t polePairs;
    float weakKp;
    float weakKi;
    float updatePeriodS;
} CurrentRefParams;
typedef enum { CURRENT_REF_OK, CURRENT_REF_LIMITED, CURRENT_REF_BAD_INPUT } CurrentRefStatus;
/** 用固定大小状态发布参考；受限时out有效，输入错误时不修改状态和out。 */
CurrentRefStatus current_ref_update(CurrentRefState *state,
                                   const CurrentRefParams *params,
                                   const CurrentRequest *request, CurrentReference *out);
```

`current_ref_update`运行在已定义的参考更新率，只输出dq电流给定；输入参数图/配置只读并带版本，实例状态独立；积分器、退出跟踪和斜率保存在上下文。轨迹/前馈/速度环先形成总转矩请求，再经此唯一分配入口；不直接写PWM或隐藏地改速度环积分状态。

`voltageDemandV`来自最近完整控制周期的未限幅总需求，附属快照应提供周期/年龄和有效性；弱磁外环消费该反馈时需计入一周期及滤波延迟，不能把尚未完成的本周期量读成同步反馈。

## 标定与查表

在电流平面扫描并记录电磁或轴转矩、实际电压、母线、速度、温度、损耗与测量误差。生成以转矩/速度/母线等为自变量的表时保留可行性掩码，不能用邻点复制掩盖不可达区。采用有界双线性插值，边缘夹紧自变量后仍须重新检查约束；跨无效单元改用有效边界或返回受限状态。

系统效率目标需包括采用的电机/逆变器/传动损耗与动态余量；不能把简化损耗模型中的某个相等条件写成普遍最优。参数/温度改变后重新检查表覆盖，不静默外推到未标定工况。

## 调参与验证

观察id/iq请求与反馈、总电压/施加电压、Vdc、限制原因、可达转矩、弱磁积分和外环饱和。覆盖母线阶跃、高速负载阶跃、区域切换、回馈、负id边界、SPMSM极限及LUT边缘。验收转矩误差、峰值电流、饱和恢复、状态连续性和CPU耗时；阈值来自项目规格。

来源：李贵、童维勇书p25–28、34–35已核读；在线限压PI与接口是模型驱动的实施示例，未核对该书后续全部标定步骤。仿真和板测结果需要另附工况与数据，本文不提供虚构通过记录。
