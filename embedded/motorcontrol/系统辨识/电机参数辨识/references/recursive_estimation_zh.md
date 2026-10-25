# 递推辨识、结果可信度与控制消费

## 选择方法

线性回归、低算力优先从带遗忘因子的RLS开始；模型非线性或状态不可测时再评估EKF/MRAS。更复杂的估计器不能修复不可辨识实验。独立辨识某参数前说明其余参数如何取得，不能把标称值当精确常数。

单输出RLS的离散更新为：

$$
K_k=\frac{P_{k-1}\phi_k}{\lambda+\phi_k^TP_{k-1}\phi_k},\qquad
\hat\vartheta_k=\hat\vartheta_{k-1}+K_k(y_k-\phi_k^T\hat\vartheta_{k-1}),
$$

$$
P_k=\frac{P_{k-1}-K_k\phi_k^TP_{k-1}}{\lambda}.
$$

$\lambda\in(0,1]$；P为归一化参数协方差量。多输出按所建噪声模型更新，不能机械逐轴重复使用同一观测。分母非正/非有限、P失去正定性或激励不足时不发布；需要时使用平方根/QR实现。对称化只能减轻舍入误差，不能证明正定。

例：静止已补偿电压，取 $y=u$、$\phi=i$，即估计R；多级正负电流排除常量压降影响。若器件电压偏差随电流符号变化，应增加合理的压降项或先单独标定；简单增广不保证满秩。

## C99边界

下面是接口形状，不是完整库：状态由调用者持有，各轴/电机独立，无硬件读写和动态内存。

```c
#include <stdbool.h>
#include <stdint.h>
typedef struct {
    float rsOhm;
    float ldH;
    float lqH;
    float fluxWb;
    uint32_t version;
} MotorParams;
typedef struct {
    float udV;
    float uqV;
    float idA;
    float iqA;
    float omegaERadS;
    uint32_t cycleId;
    bool voltageValid;
    bool currentValid;
} IdSample;
typedef struct {
    float value[4];
    float covariance[4][4];
    MotorParams accepted;
    uint32_t acceptedSampleId;
} IdState;
typedef enum { ID_OK, ID_NO_EXCITATION, ID_BAD_INPUT } IdStatus;
/** 推进本轴实例估计；有效性失败时冻结，不改活动控制参数。 */
IdStatus id_update(IdState *state, const IdSample *sample);
```

实际实现补充显式错误枚举和带限维数的上下文；`id_update`只消费配对样本，`id_get_result`同时返回可信度、工况和参数版本。返回失败时不部分覆盖活动参数。

插入点：FOC采样快照/实际电压估计 → 降频辨识 → 独立接受判据 → 版本化影子参数 → 控制周期边界原子切换。RLS不应抢占硬实时控制链；参数更新不得同时改变电流标度、角度零点等无关契约。

## 调参与诊断

遗忘过快导致噪声跟踪，过慢导致温漂跟不上；通过预期漂移时间和采样率设置有效窗口。初始P过大使噪声引起突跳，过小造成不信新数据；按参数先验和归一化单位选择。冻结时保留最后可信结果和数据年龄，不能将冻结值报告成新估计。

验收同时看：激励/秩、归一化条件数、留出残差、物理范围、初值敏感性、参数变化率和独立测量。参数投影只防越界，不证明正确。控制消费可用 $x_{use,k}=x_{use,k-1}+\operatorname{clip}(x_{new}-x_{use,k-1},\pm r_xT_s)$ 做斜率限制，限值按闭环容许变化确定。

## 来源与证据

欠秩/病态和逆变器依赖来自已核读的《永磁同步电机参数辨识》书p21–22、27、32、41。RLS更新为标准线性回归推导，本次未核读该书第10章算法正文；不得把这里的接口与算例标成作者原代码或板测结果。
