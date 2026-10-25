# PWM / ADC / Encoder 同步时序

## 1. 按硬件事件选择采样/更新策略

从当前配置和测量直接给推荐与成立条件；只对确实影响决策的缺失事实提问。位置反馈可异步、多速率采集，须明确采样所属时刻、有效性、年龄和预测误差，不能要求每个ADC周期都有新帧。

```text
波谷采样
波峰采样
双采单更
双采双更
```

选择时必须检查：

```text
PWM 频率和中心对齐/边沿对齐模式
ADC 采样保持时间和转换时间
DMA/SDFM/ADCINT 延迟
FOC 计算时间
PWM shadow load 点
编码器读取延迟
电流采样窗口是否避开开关噪声
```

## 2. 参考项目思路

### VESC

- `motor/mcpwm_foc.c` 中体现了围绕 PWM/ADC/DMA 完成点执行 FOC 的强实时路径。
- `motor/foc_math.c` 中 `foc_svm()` 体现 SVPWM 数学平台化。
- 可吸收：采样时序、SVPWM、补偿和调试变量。

### ODrive

- `Firmware/MotorControl` 中将 Axis/Motor/Encoder/Controller/FOC 分开。
- 可吸收：控制周期中先采集 timing critical input，再更新控制和 PWM timing 的思想。

### moteus

- 查当前版本README和目标源码确认控制率、PWM频率、主控与通信能力，第三方历史频率不能作为当前产品的时序证明。
- 可吸收：高动态伺服控制周期、紧凑一体化执行器设计、诊断工具。

### TI SDK / ODRI

- TI C2000 / AM R5F + PRU 方向应优先利用 ePWM/ADC/SDFM/CLA/PRU-ICSS 的硬件同步能力。
- 不要按 STM32 TIM/ADC 名称照搬。

## 3. 输出模板

```text
推荐采样点：波谷 / 波峰 / 双采单更 / 双采双更
理由：
计算窗口：
ADC 完成点：
编码器锁存点：
PWM shadow load 点：
overrun 检测：
用户需确认：
```
