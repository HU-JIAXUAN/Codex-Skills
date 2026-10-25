# 电角度、极对数与零偏标定

## 单一换算入口

设转子机械角 $\theta_m$（rad）、极对数p、反馈方向 $s=\pm1$、电零偏 $\theta_0$（rad）：

$$
\theta_e=\operatorname{wrap}(p s\theta_m+\theta_0),\qquad \omega_e=p s\omega_m.
$$

正负号、零偏加减由此定义固定。外部编码器输出轴角不能直接当转子角；减速比、弹性、回差和双反馈用途要分清。绝对多圈用于机械坐标，FOC通常消费包裹的电角度，两者不可共用重置逻辑。

例：14位单圈计数N=16384、计数4096、p=7、s=1、$\theta_0=0.1$，机械角π/2，电角为 `wrap(7π/2+0.1)=4.81239 rad`。回零改变负载坐标时不应改变该电磁关系。

## 分步识别

1. 功率输出禁止时检查电流零点、ADC量程和原始计数；人工/外拖双向转动确认解包与方向。
2. 小电流限速旋转定子磁场，只有转子确实同步跟随后才可由 $p\simeq|\Delta\theta_e/\Delta\theta_m|$ 推估极对数。角度必须解包，多圈回归；失步、减速器或轴错认会使比值错误。
3. 在已知静止定向电角度 $\theta_{align}$ 下，候选零偏为 $\theta_{0,j}=\operatorname{wrap}(\theta_{align,j}-p s\theta_{m,j})$。多角度、正反向采样，用圆均值：

$$
\bar\theta_0=\operatorname{atan2}\left(\sum_j\sin\theta_{0,j},\sum_j\cos\theta_{0,j}\right).
$$

检查圆集中度及方向差；静摩擦/齿槽可能导致定向偏移，单点标定不能发现周期误差。转子d轴对齐和极性须通过实际转矩/反电势确认，不能只因电流稳定就认定。
4. 有索引编码器区分索引参考与上电计数；绝对式区分内部绝对零与磁极零。Hall六扇区可做换相，不能默认其原始角度具有高精度伺服所需分辨率。

## 旋变

先处理励磁参考、sin/cos偏置/增益/正交误差与同步解调，再 `atan2` 或PLL。旋变电气周期数与电机极对数不同，需独立记录；跟踪环带宽和激励/解调延迟进入反馈年龄。不能把两路ADC瞬时值直接当无延迟正交位置。

## C99契约

```c
#include <stdint.h>
#include <stdbool.h>
typedef struct {
    uint32_t countsPerTurn;
    uint16_t polePairs;
    int8_t direction;
    float zeroElecRad;
    uint32_t version;
} AngleCal;
typedef struct {
    float thetaMechRad;
    float thetaElecRad;
    uint32_t sampleId;
    bool valid;
} AngleResult;
typedef struct {
    uint32_t count;
    uint32_t sampleId;
    bool valid;
} AngleRaw;
typedef enum { ANGLE_OK, ANGLE_BAD_INPUT, ANGLE_UNCALIBRATED } AngleStatus;
/** 仅换算角度，速度由独立估计器生成；失败不覆盖out。 */
AngleStatus angle_update(const AngleCal *cal, const AngleRaw *raw,
                         AngleResult *out);
```

换算函数不重置硬件计数、不写PWM；错误枚举区分配置、帧无效、年龄、范围与未标定。候选与活动标定记录分离，CRC只证明记录传输/存储完整性，不能证明零偏正确。

## 来源与验证

核对官方[位置传感器校准](https://www.mathworks.com/help/mcb/gs/current-sensor-adc-pos-sensor-calib.html)：不同例程的Hall偏置为电气量、QEP偏置为机械量，不能混用。李贵、童维勇书旋变第4.5节仅核目录，本页公式与例子为坐标模型推导。验证多角度、双方向、断电重启、索引缺失、速度变化和数据丢帧，保留原计数及包角误差。
