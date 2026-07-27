---
name: embedded
description: 嵌入式系统一级入口 skill，覆盖 C99、DSP、ARM、EtherCAT、RTOS/裸机 OS、电机控制、系统架构、Git-Skill 发布治理和代码评审。用户请求嵌入式固件设计、实现、调试、重构、架构、Git 分支/提交/PR/Tag/Release/README/CHANGELOG 或评审时使用，并按主问题路由到更具体的二级 skill。默认使用中文输出。
---

# 嵌入式系统 Skill 路由

默认使用中文回答。先识别主问题，再加载最匹配的二级 skill；领域交叉时只补充确有必要的辅助 skill。

## 路由

- `c99`：C99 模块、`.c/.h`、内存安全、可移植性、文件编码和底层 C 重构。
- `review`：代码评审、风险分级、变更记录和回归建议。
- `dsp`：滤波、FFT、定点、量化、饱和和数值稳定性。
- `arm`：Cortex 启动、CMSIS、NVIC、Fault、MPU/cache、链接脚本和寄存器。
- `ethercat`：PDO/SDO/CoE/FoE、DC、ESI、对象字典、ESC/PDI 和状态机。
- `os`：RTOS 任务、调度、中断交接、队列、互斥锁、定时器和裸机 superloop。
- `motorcontrol`：FOC、SVPWM、控制环、PWM/ADC/Encoder 同步、保护和多轴控制算法。
- `architecture`：架构分层检查、语义角色归一、依赖方向与公共头纯度、解耦但不过度抽象的边界设计、平台抽象、Bootloader、OTA、量产交付及发布门禁。
- `aicoding-git-governance`（路径 `platform/aicoding-git-governance/`）：嵌入式优先、可通用的 Git、GitHub、分支、提交、PR、合并、Tag、Release、README、CHANGELOG、版本文件、固件制品、测试基线、生产基线和客户交付治理。

## 组合规则

- 任何 C 编码任务必须同时使用 `c99`。
- 电机控制中的定点、滤波或数值问题补充 `dsp`。
- 架构任务包含控制算法时，按用户主问题选择架构或电机控制为主 skill，另一项只作为辅助。
- 代码评审任务以 `review` 为主，并补充一个具体领域 skill。
- Git、GitHub、发布、版本、README 或 CHANGELOG 治理任务以 `aicoding-git-governance` 为主；如果同时修改 C 代码，再按实现/评审需要补充 `c99` 或 `review`。

保持现有项目风格和已验证代码。只修改需求、缺陷、安全风险或测试失败直接涉及的内容，并给出可执行验证步骤。
