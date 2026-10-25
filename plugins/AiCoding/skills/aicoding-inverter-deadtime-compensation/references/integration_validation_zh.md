# 补偿插入点、限幅与效果验证

## 唯一插入点

推荐先明确一条实现链：电流PI与dq模型前馈合计 → 逆Park → 相电压补偿/共模处理 → 调制与最小脉冲 → PWM生效。若在dq或占空比层补偿，需要证明与该链等价并记录哪个层拥有补偿。驱动已有硬件/固件补偿时，不再叠加同一项。

定义 `uRaw/uComp/uCommand/uAppliedEst`。前者是控制期望，补偿后形成命令；施加估计按补偿后调制、实际母线及逆变器误差模型得到。辨识不得把补偿命令直接视为已精确施加电压。

## 限幅与抗饱和

补偿也消耗可用电压/脉宽。最终调制限幅后，把其引起的电压残差返回电流PI/集成层；不能只在补偿前夹紧PI而忽略最后裁剪。补偿模块报告请求与使用值，限幅政策由集成层统一拥有。采样窗被破坏时优先保证可测量性，并返回饱和/采样无效状态。

```c
#include <stdint.h>
#include <stdbool.h>
typedef struct {
    float iaA;
    float ibA;
    float icA;
    float busV;
    float tempC;
    uint32_t sampleId;
    bool currentValid;
} DeadtimeInput;
typedef struct {
    float uaV;
    float ubV;
    float ucV;
    bool valid;
} DeadtimeVoltage;
typedef struct {
    float pwmPeriodS;
    float effectiveTimeS;
    float deviceDropV;
    float zeroBandA;
} DeadtimeParams;
typedef enum { DEADTIME_OK, DEADTIME_BAD_INPUT } DeadtimeStatus;
/** 计算三相补偿电压；所有指针必需，失败不覆盖out，不写PWM。 */
DeadtimeStatus deadtime_update(const DeadtimeParams *params,
                              const DeadtimeInput *input, DeadtimeVoltage *out);
```

`deadtime_update`只算补偿，不写PWM、不读取全局电流；配置含周期、等效时间、压降模型和过零带。无效输入默认输出显式无效/由集成策略禁用补偿，不能保持一个旧符号无限补偿。相电压单位V，若API输出归一化占空比要明确基值和饱和。

## 诊断顺序

先区分电流offset/gain、采样盲区、磁链谐波、转速抖动和PWM误差。时间域比较相电流过零与dq残差，再按电角阶次比较6次及其相关分量；FFT必须注明采样率、抽取率、记录长度和转速。固定频率峰可能来自记录节拍，不等同电机阶次。

常见失败：补偿方向相反导致THD增大；I0太小导致过零抖动；I0太大导致欠补偿；母线/温度未建模导致仅单工况有效；补偿后截断使积分恢复恶化；电压模型重复相减使辨识Rs漂移。

## 通过标准

以同工况开启/关闭对比相电流THD、dq6次幅值、转矩纹波、低速稳态误差、限幅比例和温升。还需测正反转、回馈、低母线、大电流、零附近与温度变化；任何改善不得牺牲最大电流、采样有效窗和稳定性。数值容差来自项目目标，不以“波形更圆”验收。

来源：已核读诸自强等书p27、32；其p41的病态分析用于解释补偿残差为什么会放大辨识偏差。接口及集成链为工程设计，没有声称完成特定逆变器的标定或板测。
