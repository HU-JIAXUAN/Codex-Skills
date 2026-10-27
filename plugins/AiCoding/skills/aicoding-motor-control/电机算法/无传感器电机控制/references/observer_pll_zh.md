# 基波观测器与PLL

## 方法与可观测边界

中高速反电势信噪比足够时，可先用SPMSM电流模型SMO或反电势观测器；IPMSM必须使用含凸极性的扩展反电势/磁链模型，不能直接套单一L。低速时Rs、压降、ADC偏置可能大于反电势；零速下仅凭无激励基波反电势不能确定静止角度。

采用幅值不变αβ、峰值SI，SPMSM模型：

$$
\dot i_{\alpha\beta}=\frac{u_{applied,\alpha\beta}-R_si_{\alpha\beta}-e_{\alpha\beta}}{L},\qquad
e_{\alpha\beta}=\omega_e\psi_f[-\sin\theta_e,\cos\theta_e]^T.
$$

一种可实现的边界层SMO：

$$
z_k=K\operatorname{sat}((\hat i_k-i_k)/\epsilon),\quad
\hat i_{k+1}=\hat i_k+\frac{T_s}{L}(u_{applied,k}-R_s\hat i_k-z_k),
$$

$$
\hat e_{k+1}=a\hat e_k+(1-a)z_k,\quad a=e^{-2\pi f_cT_s}.
$$

K单位V，$\epsilon$单位A；这是连续模型前向Euler示例，须检查 $T_sR_s/L$ 和闭环离散极点，必要时精确离散。不能凭K大于某一个标称反电势就宣称全域稳定。滤波相移及实际电压误差须纳入评估。

## 双向PLL与低幅值失效

对带符号速度的原始反电势，直接 `atan2(-eAlpha,eBeta)` 在反转时会相差π；需用经过验证的方向状态/模型处理符号，不能在零速由噪声决定方向。若方向锁存 $s_\omega$ 已可信，定义 $\tilde e=s_\omega\hat e$、$E=\|\tilde e\|$，可构造：

$$
\varepsilon_k=-\frac{\tilde e_{\alpha,k}\cos\hat\theta_k+\tilde e_{\beta,k}\sin\hat\theta_k}{\max(E_k,E_{min})},
$$

$$
\hat\omega_{k+1}=\operatorname{clip}(\hat\omega_k+K_iT_s\varepsilon_k),\quad
\hat\theta_{k+1}=\operatorname{wrap}(\hat\theta_k+T_s(\hat\omega_{k+1}+K_p\varepsilon_k)).
$$

这里归一化相位检测器小误差增益为1，可从 $K_p=2\zeta\omega_n,K_i=\omega_n^2$ 起步，再纳入LPF、采样延迟与噪声验证。E低于有效门限时应冻结捕获/宣布无效；分母下限只防数值问题，不提供可观测性。反转经过零速需由切换状态机接管。

例：R=0.5 Ω、L=0.3 mH、$T_s=50\ \mu s$，仅电流模型衰减项Euler系数为0.9167；若$\omega_n=2\pi50$ rad/s、ζ=0.707，PLL初值约Kp=444.2 s⁻¹、Ki=98696 s⁻²。该数值是归一化检测器算例，不是任何电机的推荐带宽。

## C99快照与验证

以下 `observer_update` 是完整观测器的方法设计草图，仓库没有该正式实现。现有 `mc_pll_init/update` 仅跟踪输入相位，并不从电压/电流生成可观测角度；已有I-f启动也不等于无传感器闭环。需要SMO/磁链/HFI时先查当前项目或原始SDK的已验证模块，明确缺口后再实现并做独立真值，不从本页C声明生成空stub当成完成。

快照至少含 `uAppliedAlphaV/uAppliedBetaV/iAlphaA/iBetaA/sampleTimeS/valid`，`cycleId/sampleId`可选用于追踪；输出 `thetaERad/omegaERadS/confidence/ageS/valid`。观测器自有状态、可复位；不隐式读取编码器或电机全局变量。`observer_update`只估计，状态机决定是否消费；无效样本不得静默置角度0。下例展示带可选追踪字段的一种布局，不要求每个工程使用相同字段。

```c
#include <stdbool.h>
#include <stdint.h>
typedef struct {
    float uAlphaV;
    float uBetaV;
    float iAlphaA;
    float iBetaA;
    float sampleTimeS;
    uint32_t cycleId;
    bool valid;
} ObserverSample;
typedef struct {
    float thetaERad;
    float omegaERadS;
    float confidence;
    float ageS;
    uint32_t sampleId;
    bool valid;
} ObserverResult;
typedef struct {
    float rsOhm;
    float inductanceH;
    float samplePeriodS;
    float slidingGainV;
    float boundaryA;
    float filterA;
    float pllKp;
    float pllKi;
    float minEmfV;
} ObserverParams;
typedef struct {
    float currentAlphaA;
    float currentBetaA;
    float emfAlphaV;
    float emfBetaV;
    float pllIntegralRadS;
    ObserverParams params;
    ObserverResult estimate;
} ObserverState;
typedef enum { OBSERVER_OK, OBSERVER_UNOBSERVABLE, OBSERVER_BAD_INPUT } ObserverStatus;
/** 模型/周期配置由实例初始化；不访问硬件，失败标记结果无效。 */
ObserverStatus observer_update(ObserverState *state, const ObserverSample *sample,
                               ObserverResult *out);
```

配置含Rs、L、Ts、K、ε、滤波/PLL增益和有效性门限，初始化时与实例绑定；上述结构仅展示状态与样本分离。若使用正式相位PLL，成功更新后的 `angleRad` 属于k+1；不能把它当k时刻角度再补同一拍。生产观测器还须明确配置生命周期、时间戳与丢样恢复，不能偷偷读取全局参数。

先影子运行，以时间对齐的临时编码器比较包角误差；再做速度/负载/温度/正反转/母线变化，注入电流偏置、Rs偏差、电压饱和和丢样。指标包含角误差分位数、失锁率、重新捕获时间、CPU最坏耗时，不能只看速度均值。

## 来源

模型与符号核对：[MathWorks SMO文档](https://www.mathworks.com/help/mcb/ref/slidingmodesensorlessobserver.html)；该官方页面中的块位于Archive，引用其模型不意味着推荐新项目使用该归档块。PLL工程背景：[Microchip AN1292](https://www.microchip.com/en-us/application-notes/an1292)。上述PLL及算例是按所声明检测器增益推导，不能照搬厂商增益。

诸自强、吴溪蒙《永磁同步电机无位置传感器控制》第2–3章仅核目录；滤波、参数与数字延迟章节需实施时精读。未声称完成整书公式校核。
