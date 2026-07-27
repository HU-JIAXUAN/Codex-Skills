# embedded skill 分流说明

默认使用中文。此文件用于选择 `embedded` 下的二级 skill，避免重复、冗余调用。

## 分流原则

- 只选择能直接解决当前任务的最小 skill 集合。
- 不因为任务涉及 C 代码就同时调用所有 C 相关 skill。
- 实现、评审、领域知识分开：实现优先 `c99-standard-c`，评审优先 `review`，领域问题优先对应领域 skill。
- 需要组合时明确主 skill 和辅助 skill，辅助 skill 只读取必要参考。

## 推荐路由

| 用户意图 | 主 skill | 辅助 skill | 不要重复调用 |
|---|---|---|---|
| 生成或修改 `.c/.h` 模块 | `c99-standard-c` | 具体领域 skill，如 `arm`、`ethercat`、`motorcontrol` | 不要同时调用 `review`，除非用户要求评审 |
| 审查 C 代码、PR、patch、缺陷风险 | `review` | 必要时读取 `c99-standard-c` 的规则 | 不要把 `c99-standard-c` 当成主 skill 重复输出实现规范 |
| 代码风格、Doxygen、命名、格式化评审 | `review` | `review/references/majerle-c-code-style-review-cn.md` | 不要用 MaJerle 规则替代 `c99-standard-c` |
| ARM Cortex 启动、中断、Fault、MPU/cache | `arm` | 实现时加 `c99-standard-c`，评审时加 `review` | 不要默认调用 `dsp`、`ethercat`、`motorcontrol` |
| EtherCAT、PDO/SDO、CoE、FoE、ESI、ESC | `ethercat` | 实现时加 `c99-standard-c`，评审时加 `review` | 不要默认调用 `os`，除非涉及调度/任务 |
| RTOS、裸机 superloop、任务、队列、互斥锁 | `os` | 实现时加 `c99-standard-c`，评审时加 `review` | 不要默认调用 `arm`，除非涉及 NVIC/平台 |
| FOC、PID、SVPWM、电流/速度/位置环 | `motorcontrol` | 数值细节加 `dsp`，实现加 `c99-standard-c` | 不要默认调用 `ethercat`，除非 setpoint/现场总线相关 |
| 滤波器、FFT、定点、采样、数值稳定性 | `dsp` | 实现加 `c99-standard-c`，评审加 `review` | 不要默认调用 `motorcontrol`，除非任务属于电机控制 |
| 检查架构分层、依赖方向、公共头泄漏、是否过度抽象、目录/边界重构、平台化、OTA/量产门禁 | `architecture` | 落到 C 实现时加 `c99-standard-c`；涉及启动/中断/cache 加 `arm` | 不要用 `review` 代替架构检查；控制算法归 `motorcontrol` |
| 嵌入式优先的 Git 分支、提交、PR、Tag、Release、README、CHANGELOG、版本文件、固件制品、测试/生产基线 | `aicoding-git-governance`（路径 `platform/aicoding-git-governance/`） | 修改 C 代码时加 `c99-standard-c`；评审代码风险时加 `review` | 不要用通用 GitHub plugin skill 替代 AiCoding 发布治理；PR 元数据/评论/CI 可交给 GitHub plugin/MCP |

## 优先级

1. 用户明确点名的 skill。
2. 当前任务类型：实现、评审、调试、架构、格式化。
3. 领域：ARM、EtherCAT、OS、DSP、电机控制、Git/发布治理。
4. 项目既有规范和周围代码风格。
5. `c99-standard-c` 的 C99、安全、实时性、可移植性和编码规则。
6. `aicoding-git-governance` 中的分支、提交、PR、Tag、Release、README、CHANGELOG 和固件制品治理规则。
7. `review` 中的 MaJerle 风格参考，仅用于风格/可维护性评审。

## MaJerle 参考的使用方式

- MaJerle/c-code-style 已作为中文摘要放入 `review/references/majerle-c-code-style-review-cn.md`。
- 它只在 review 场景中使用，尤其是代码风格、命名、格式化、Doxygen 和头/源文件组织。
- 它与 `c99-standard-c` 不重复：`c99-standard-c` 负责如何实现 C99 嵌入式代码，MaJerle 参考负责如何审查代码风格和可维护性。
- 如果 MaJerle 与 `c99-standard-c` 或项目现有规范冲突，按“项目规范 > c99-standard-c > MaJerle 参考”处理。
