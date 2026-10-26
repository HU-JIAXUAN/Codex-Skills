---
name: embedded-c99
description: "嵌入式 C99 编程参考 Skill，适用于裸机、RTOS、BSP、驱动、控制算法、通信协议栈和功能安全相关 C 代码的生成、审查、重构与维护。默认源文件编码为 GBK；更改编码格式前必须先询问用户。"
license: Project internal reference
---

# 嵌入式 C99 编程 Skill

> 适用对象：裸机、RTOS、驱动、BSP、控制算法、通信协议栈、安全相关嵌入式软件。
> 基准语言：ISO/IEC 9899:1999（C99）。
> 目标：清晰、简洁、可维护、可测试、可靠、安全、可移植，并在满足这些前提后优化效率。

---

> 注释写法以当前SKILL.md和c-coding-rules-zh.md为准：普通说明使用简易中文块注释，分区或重点可用星号标记，不恢复历史文档标签和函数历史表模板

## Quick Reference

| 任务 | 默认做法 | 必须确认/验证 |
|---|---|---|
| 新建 `.h/.c` 模块 | 头文件声明接口，源文件实现；私有函数/变量使用 `static` | 头文件自包含、无变量定义、无循环依赖 |
| 修改既有代码 | 先保持原有架构、命名和格式；最小改动 | 不因个人偏好重构已稳定代码 |
| 修复缺陷 | 只改动与缺陷直接相关的最小闭环 | 回归影响面、错误码、边界条件 |
| 编码格式 | 默认 GBK | 变更为 UTF-8、GBK 或其他编码前必须询问用户 |
| ISR/并发代码 | 共享变量 `volatile`，临界区显式保护 | 中断延迟、竞态、可重入性 |
| 寄存器/硬件访问 | 使用明确位掩码、读改写封装、禁止魔法数 | 位宽、时序、清标志顺序、副作用 |
| 质量检查 | 编译告警清零，静态检查，单元/集成测试 | 不以“能编过”代替“可维护、可验证” |

## Skill 使用流程

1. **先识别上下文**：新建模块、修改遗留代码、驱动适配、算法实现、ISR、协议栈或安全相关代码。
2. **先读接口再改实现**：确认 `.h` 暴露内容、调用关系、全局状态、并发访问点和硬件副作用。
3. **优先最小改动**：除非存在明确缺陷、测试失败、安全风险或用户要求，不主动重排稳定代码。
4. **按已定版设计输出实现**：新增功能、模块或公共契约变化先按主 Skill 完成流程、函数职责与接口审核；优先复用已有实现，只创建或修改实际缺口需要的文件，类型、生命周期接口和状态按真实职责提供。
5. **补充验证点**：列出编译选项、静态检查、边界测试、ISR/并发测试、硬件在环验证点。

## Critical Rules

- **代码能用就不改**：已验证稳定、无明确缺陷、无需求变更、无安全隐患的代码，不因风格偏好、抽象洁癖或“看起来更好”而改动。
- **必要修改必须最小化**：修改范围应限于需求或缺陷闭环；避免顺手重构、顺手改名、顺手调整格式。
- **格式一致优先于个人风格**：新文件遵循本 Skill；旧文件优先保持局部一致性。
- **编码格式默认 GBK**：创建、读取、写回 C/H/MD 参考文件时默认按 GBK 处理；更改编码格式前必须先询问用户。
- **公共头文件不得放实现和变量定义**。
- **所有外部接口必须有错误返回或明确的失败处理策略**。
- **嵌入式实时路径禁止引入不可控资源消耗**：递归、VLA、默认动态内存、不可界定循环、阻塞等待。
- **寄存器、DMA、ISR、共享内存访问必须显式表达副作用和同步边界**。

---

## 1. 总体原则

### 1.1 清晰优先

代码首先面向维护者，其次才是编译器。除已量化证明为瓶颈的路径外，不得以“效率”为理由牺牲可读性、边界检查和模块隔离。

**要求：**

- 代码意图应能通过命名、结构和接口表达，而不是依赖大量解释性注释。
- 优先使用简单直接的控制流。
- 避免隐式依赖、隐式状态、隐式类型转换。
- 对硬件寄存器、DMA、ISR、并发共享数据等隐含副作用必须显式标注。

### 1.2 简洁为美

- 一个模块只承担一类职责。
- 一个函数只完成一件事情。
- 重复代码出现两次应考虑抽取；出现三次应立即重构。
- 废弃函数、废弃变量、废弃宏应及时删除，不保留“可能以后会用”的代码。

### 1.3 风格一致

- 新项目采用本文风格。
- 修改既有代码时，优先保持所在文件或模块原有风格。
- 驱动厂商 SDK、芯片头文件、第三方协议栈适配层可保持原风格，但新增业务封装层应遵循本文。

### 1.4 代码能用就不改

该原则用于约束维护行为，不用于掩盖缺陷。

**适用条件：**

- 代码已在目标硬件、目标编译器和目标工况下验证稳定。
- 当前需求未要求改变该逻辑。
- 未发现明确缺陷、安全隐患、可移植性问题或测试失败。
- 修改收益无法覆盖重新验证成本。

**执行要求：**

- 不因命名偏好、排版偏好、抽象偏好而修改稳定代码。
- 不在缺陷修复中夹带无关重构。
- 不为“统一风格”大面积改动历史文件，除非用户明确要求并接受回归测试成本。
- 如必须修改，应记录修改原因、影响范围、回归项和验证结果。

**例外：**

- 明确 bug、越界、未初始化、竞态、死锁、ISR 时序风险。
- 编译器升级、芯片平台迁移、功能安全审查、MISRA/静态检查要求。
- 用户明确要求重构、格式化、改编码或统一风格。

### 1.5 Skill 编写与输出规范

本 Skill 的规则描述采用“任务 → 做法 → 验证 → 常见陷阱”的结构，便于直接执行。

- 对关键约束使用 **CRITICAL** 或 **禁止** 标识。
- 对生成文件给出完整框架，而不是零散片段。
- 对嵌入式专有风险单独列出：寄存器副作用、ISR、DMA、缓存一致性、字节序、对齐、栈占用。
- 对工具链差异保持显式：IAR/GCC/Clang、C99 支持程度、警告等级、链接脚本。
- 对不确定项先询问用户，尤其是编码格式、编译器、芯片、RTOS、命名风格和是否允许重构。

---

## 2. C99 使用边界

### 2.1 允许使用的 C99 特性

- `stdint.h` / `stdbool.h` / `stddef.h` / `stdint.h` 中的标准类型。
- `inline`，但仅用于短小、无副作用、性能敏感函数。
- `for (uint32_t i = 0U; ...)` 形式的局部循环变量。
- 指定初始化器，例如 `.baudrate = 115200U`。
- 复合字面量仅限局部、短生命周期配置对象，不用于复杂表达式。

### 2.2 限制或禁止的 C99 特性

| 特性 | 规则 | 原因 |
|---|---|---|
| VLA 可变长数组 | 禁止 | 栈占用不可控，嵌入式风险高 |
| `restrict` | 谨慎使用 | 误用会破坏别名语义，导致优化错误 |
| 复杂宏表达式 | 限制 | 可读性差，副作用风险高 |
| 递归 | 禁止，除非经专项评审 | 栈深不可控 |
| 动态内存 | 默认禁止，允许范围见第 12 节 | 碎片、泄漏、实时性不可控 |
| 浮点 | 控制算法可用，但需评估 FPU、确定性和耗时 | 资源和实时性风险 |
| `long double` | 禁止 | 平台差异大，收益低 |

---

## 3. 编码格式与文件写回

### 3.1 默认编码

- 源码、头文件、Markdown 参考文件默认编码格式为 **GBK**。
- 在未得到用户确认前，不得主动改为 UTF-8、GBK、UTF-8 with BOM、Shift-JIS 或其他编码。
- 如果工具链或编辑器无法识别 GBK，应先说明风险并询问用户是否改用其他编码。

### 3.2 写回规则

- 修改既有文件时，应保持原文件换行符、缩进风格和编码格式。
- 只在用户明确要求时执行全文件格式化。
- 批量替换、全局重命名、编码转换、换行符转换属于高风险操作，执行前必须征得用户确认。

### 3.3 中文注释

- 注释允许中文，但必须确保目标编译器、静态检查工具、版本管理系统和发布流程能稳定处理默认编码。
- 面向第三方交付或跨国团队的公共接口，建议使用英文注释；改变注释语言前同样应先确认。
- 函数具体实现的关键代码或者核心代码必须添加注释以增强代码可读性。

---

## 4. 文件与模块组织

### 3.1 文件职责

- 公共接口使用职责明确的头文件；私有实现、测试和启动文件不机械增加同名 `.h`，保留合理的既有组织。
- 仅同一 `.c` 内使用的函数声明为 `static`；模块内部跨 `.c` 使用的接口仅在确有需要时放入内部头文件，并限制其构建可见范围。
- 头文件只放接口：类型、宏、枚举、函数声明。实现代码、私有宏、私有结构不得放入公共头文件。
- 文件命名统一小写，单词用下划线分隔。

**示例：**

```text
motor_control/
  motor_control.h
  motor_control.c
  motor_current_loop.c
  motor_speed_loop.c
  motor_position_loop.c
  motor_private.h   // 仅模块内部使用，不对外暴露
```

### 3.2 头文件规则

- 头文件必须自包含：任意 `.h` 单独被 `.c` 包含时应能编译通过。
- 禁止头文件循环依赖。
- 禁止包含用不到的头文件。
- 禁止在头文件中定义变量。
- 禁止在 `.c` 中手写 `extern` 使用其他模块函数；必须包含其头文件。
- 头文件必须使用 include guard，不使用以下划线开头的保护符。

**推荐模板：**

```c
#ifndef PROJECT_MODULE_FILE_H
#define PROJECT_MODULE_FILE_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void motor_control_init(void);
bool motor_control_is_ready(void);

#ifdef __cplusplus
}
#endif

#endif /* PROJECT_MODULE_FILE_H */
```

### 3.3 include 顺序

推荐统一为：

```c
#include "current_module.h"

#include "project_dependency.h"
#include "platform_dependency.h"

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
```

项目也可采用字母序，但同一仓库内必须一致。

---

## 4. 命名规范

### 4.1 通用规则

- 标识符应清晰表达含义。
- 不使用汉语拼音。
- 不使用生僻缩写。
- 不使用匈牙利命名法。
- 局部循环变量允许使用 `i`、`j`、`k`。
- 变量名使用名词或形容词 + 名词。
- 函数名使用动词或动词 + 名词。

### 4.2 推荐缩写

| 全称 | 缩写 |
|---|---|
| command | cmd |
| configuration | cfg |
| buffer | buf / buff |
| error | err |
| initialize | init |
| previous | prev |
| message | msg |
| parameter | param |
| register | reg |
| synchronize | sync |
| temporary | tmp |

### 4.3 变量前缀

| 类型 | 前缀 | 示例 |
|---|---|---|
| 全局变量 | `g_` | `g_system_state` |
| 文件内静态变量 | `s_` | `s_adc_offset` |
| 常量宏 | 全大写 | `PWM_PERIOD_TICKS` |
| 枚举常量 | 全大写或模块前缀 | `MOTOR_STATE_READY` |

**要求：** 全局变量应尽量少用；使用时必须注释说明所有者、初始化时机、访问并发策略。

---

## 5. 类型与数据模型

### 5.1 基本类型

- 固定位宽数据必须使用 `stdint.h`：`uint8_t`、`int16_t`、`uint32_t`、`int64_t`。
- 布尔值使用 `bool`，取值只用 `true` / `false`。
- 数组长度、内存大小使用 `size_t`。
- 寄存器地址、指针整数转换使用 `uintptr_t`。
- 不直接使用 `char` 表示有符号数值；需要有符号 8 位数时使用 `int8_t`。

### 5.2 字面量后缀

```c
#define ADC_MAX_COUNTS       (4095U)
#define CTRL_Q15_ONE         (32768L)
#define TIMEOUT_US_DEFAULT   (1000UL)
#define POSITION_SCALE_Q32   (4294967296ULL)
```

### 5.3 枚举

枚举用于状态、事件、模式；不得依赖枚举底层宽度进行通信或存储。

```c
typedef enum
{
    MOTOR_STATE_INIT = 0,
    MOTOR_STATE_READY,
    MOTOR_STATE_RUNNING,
    MOTOR_STATE_FAULT
} motor_state_t;
```

跨 MCU、通信报文、Flash 参数存储时，应使用显式宽度整数，而不是裸枚举。

---

## 6. 函数设计

### 6.1 函数长度与复杂度

- 新增函数非空非注释行建议不超过 50 行。
- 嵌套深度不超过 4 层。
- 参数个数超过 5 个时审查职责与参数内聚性；只有语义、生命周期和校验规则一致的数据才聚合为结构体，不按数量机械打包。
- 函数扇出通常控制在 3~5，调度函数除外。

### 6.2 函数职责

每个函数只完成一个明确动作。

**不推荐：**

```c
void motor_update_and_check_fault_and_send_log(void);
```

**推荐：**

```c
void motor_update_control(void);
bool motor_check_fault(void);
void motor_report_status(void);
```

### 6.3 参数与返回值

- 输入指针参数尽量使用 `const`。
- 输出参数必须显式检查空指针。
- 所有有错误语义的返回值必须被调用者检查。
- 模块内统一约定：参数合法性由调用者检查还是被调用者检查。默认公共接口由被调用者检查，内部静态函数可由调用者保证。

```c
typedef enum
{
    RESULT_OK = 0,
    RESULT_ERR_NULL,
    RESULT_ERR_RANGE,
    RESULT_ERR_BUSY,
    RESULT_ERR_TIMEOUT
} result_t;

result_t adc_read_channel(uint8_t channel, uint16_t *value)
{
    if (value == NULL)
    {
        return RESULT_ERR_NULL;
    }

    if (channel >= ADC_CHANNEL_COUNT)
    {
        return RESULT_ERR_RANGE;
    }

    *value = adc_get_raw(channel);
    return RESULT_OK;
}
```

### 6.4 静态函数

仅在当前 `.c` 文件内使用的函数必须声明为 `static`。

```c
static void current_loop_update(motor_ctrl_t *ctrl);
```

---

## 7. 变量与作用域

### 7.1 作用域最小化

- 变量定义应靠近首次使用位置。
- 变量必须在首次作为右值前初始化。
- 一个变量只表示一种含义，不得复用变量承载不同语义。
- 防止局部变量与全局变量同名。

### 7.2 全局变量

全局变量默认禁止作为模块接口。确需使用时：

- 必须有 `g_` 前缀。
- 必须在单一 `.c` 文件中定义。
- 只允许一个模块拥有写权限。
- 并发访问必须说明保护机制：关中断、临界区、互斥锁、原子操作或双缓冲。
- ISR 与主循环共享变量必须使用 `volatile`，但 `volatile` 不等于原子和互斥。

```c
static volatile uint32_t s_adc_done_flag;

void ADC_IRQHandler(void)
{
    s_adc_done_flag = 1U;
}
```

### 7.3 `volatile` 使用

仅在以下场景使用：

- 硬件寄存器映射。
- ISR 与非 ISR 共享变量。
- 多核共享内存中的轮询标志。
- DMA 或外设异步更新的内存标志。

不得为“避免优化”滥用 `volatile`。

---

## 8. 宏、常量与内联函数

### 8.1 宏使用规则

- 常量宏全大写，单词以下划线分隔。
- 宏参数和宏整体必须加括号。
- 宏不得产生隐藏副作用。
- 多语句宏必须使用 `do { ... } while (0)`。
- 能用 `static inline` 的地方优先不用函数式宏。

```c
#define ARRAY_SIZE(arr)    (sizeof(arr) / sizeof((arr)[0]))
#define CLAMP_U16(x, min_value, max_value) \
    (((x) < (min_value)) ? (min_value) : (((x) > (max_value)) ? (max_value) : (x)))
```

### 8.2 禁止示例

```c
#define SQUARE(x) x * x          /* 错误 */
#define INC_AND_CHECK(x) (++x > 10U)  /* 隐藏副作用 */
```

### 8.3 推荐替代

```c
static inline int32_t square_i32(int32_t value)
{
    return value * value;
}
```

---

## 9. 表达式与控制流

### 9.1 表达式

- 复杂表达式应拆分为中间变量。
- 不在同一表达式中多次修改同一变量。
- 避免隐式有符号/无符号混合运算。
- 位运算对象必须使用无符号整数。
- 移位位数必须小于对象位宽。

```c
uint32_t mask = (uint32_t)1U << bit_index;
reg_value |= mask;
```

### 9.2 if / else

- 必须使用花括号，即使只有一行。
- 优先处理异常分支并提前返回，以降低嵌套。

```c
if (ptr == NULL)
{
    return RESULT_ERR_NULL;
}

if (!module_is_ready())
{
    return RESULT_ERR_BUSY;
}

return do_work(ptr);
```

### 9.3 switch

- 每个 `case` 必须有 `break`、`return` 或明确的 `fall through` 注释。
- 必须有 `default`，即使只是错误处理。

```c
switch (state)
{
case MOTOR_STATE_READY:
    motor_start();
    break;

case MOTOR_STATE_RUNNING:
    motor_update();
    break;

case MOTOR_STATE_FAULT:
    motor_stop();
    break;

/* fall through intended */
default:
    fault_report(FAULT_INVALID_STATE);
    break;
}
```

---

## 10. 嵌入式并发与实时性

### 10.1 ISR 规则

- ISR 中只做必要工作：清中断、采样、置标志、推入无锁队列。
- ISR 中禁止阻塞、等待锁、动态内存分配、复杂日志输出。
- ISR 与任务共享数据必须有明确同步策略。
- 中断优先级和最坏执行时间必须可追踪。

### 10.2 临界区

- 临界区必须短小。
- 临界区内不得调用不可控耗时函数。
- 嵌套临界区必须有统一封装。

```c
uint32_t irq_state = irq_save();
shared_value = new_value;
irq_restore(irq_state);
```

### 10.3 多核与共享内存

多核共享变量必须定义：

- 内存归属方。
- 读写方向。
- 更新周期。
- 缓存一致性策略。
- 内存屏障位置。
- 数据有效标志或版本号。

推荐共享数据结构：

```c
typedef struct
{
    volatile uint32_t sequence;
    volatile int32_t position_q16;
    volatile int32_t velocity_q16;
    volatile uint16_t status_word;
    volatile uint16_t control_word;
} axis_shared_t;
```

---

## 11. 硬件寄存器与驱动

### 11.1 寄存器访问

- 寄存器结构体成员必须使用 `volatile`。
- 禁止通过魔法地址直接散落访问。
- 寄存器位定义必须集中管理。
- 读改写寄存器前必须确认写 1 清零、保留位、只读位语义。

```c
#define GPIO_BASE_ADDR    (0x40020000UL)

#define GPIO_REG          ((gpio_reg_t *)GPIO_BASE_ADDR)

typedef struct
{
    volatile uint32_t DIR;
    volatile uint32_t OUT;
    volatile uint32_t IN;
} gpio_reg_t;
```

### 11.2 魔法数

禁止在业务代码中直接写硬件常数。

```c
#define MOTOR_PWM_FREQ_HZ        (20000U)
#define MOTOR_PWM_PERIOD_TICKS   (10000U)
#define BRAKE_DUTY_PERCENT       (25U)
```

### 11.3 延时

- 禁止无边界空循环延时。
- 短延时使用平台封装。
- 长延时使用定时器、RTOS tick 或状态机。

---

## 12. 内存管理

### 12.1 动态内存

默认禁止使用 `malloc`、`calloc`、`realloc`、`free`。

允许例外：

- 仅在系统初始化阶段一次性分配。
- 不在实时路径、ISR、安全路径中使用。
- 有失败处理和内存统计。
- 经项目评审批准。

### 12.2 栈使用

- 禁止大数组作为局部变量。
- 栈占用应通过 map 文件、静态分析或运行时水位检测评估。
- 深调用链、递归、复杂格式化输出会增加栈风险。

### 12.3 缓冲区

- 所有缓冲区操作必须携带容量。
- 禁止无长度限制的字符串函数。
- 接收通信数据时必须先验证长度，再解析内容。

---

## 13. 安全性

### 13.1 字符串安全

禁止使用：

```c
gets();
strcpy();
strcat();
sprintf();
```

推荐使用带长度参数的封装函数，并统一返回错误码。

```c
result_t string_copy(char *dst, size_t dst_size, const char *src);
```

### 13.2 整数安全

- 注意上溢、下溢、符号扩展、截断。
- 无符号循环变量递减时必须谨慎。
- 乘法、左移、定点数缩放前必须确认范围。

**禁止：**

```c
uint8_t size = 10U;
while (size-- >= 0U)
{
    process(size);
}
```

**推荐：**

```c
for (uint8_t i = size; i > 0U; i--)
{
    process((uint8_t)(i - 1U));
}
```

### 13.3 格式化输出

- 格式化输出必须限制长度。
- 格式字符串不得来自外部输入。
- `printf` 类函数不得出现在高频实时路径和 ISR 中。

```c
(void)snprintf(log_buf, sizeof(log_buf), "fault=%u", fault_code);
```

### 13.4 通信与协议解析

- 所有外部输入默认不可信。
- 先验证帧头、长度、版本、CRC，再访问字段。
- 多字节字段必须明确大小端。
- 不直接将通信报文字节流强转为结构体指针。

```c
uint16_t read_u16_be(const uint8_t *buf)
{
    return (uint16_t)(((uint16_t)buf[0] << 8U) | (uint16_t)buf[1]);
}
```

---

## 14. 可移植性

- 不假设 `int`、`long`、指针宽度。
- 不假设大小端。
- 不假设结构体填充方式。
- 不依赖位域跨编译器布局。
- 与硬件或编译器相关的实现必须集中在平台适配层。
- 嵌入式汇编默认禁止；确需使用时必须隔离封装并提供 C 语言等价说明。

---

## 15. 注释

### 15.1 注释原则

- 普通说明使用简体中文 `/* 注释内容 */`，句末不加句号，不带多余星号或Doxygen标签
- 分区标题、重要代码段允许星号分割线或大块星号，不把它们当作参数含义说明
- 参数与字段说明用途、单位/范围以及必要的填写例子
- 简单函数一句用途说明即可，不强制另加内部注释；复杂计算说明关键步骤和依据
- 删除代码交给版本管理，不通过注释保留旧代码；修改代码时同步有效说明

### 15.2 文件头模板

```c
/*
    motor_control.c
    电机状态与控制环调度
    motor_control_update_isr由PWM中断调用
*/
```

文件头只写当前模块需要的信息；作者、版权和版本不从示例照抄。

### 15.3 函数注释模板

```c
/*
    设置目标转速
    axis 电机运行数据，不能为NULL
    velocityRpmQ16 目标转速，单位rpm，使用Q16表示
    返回RESULT_OK表示成功，其余值表示设置失败
    只能从任务调用
*/
Result axis_set_velocity(Axis *axis, int32_t velocityRpmQ16);
```

详细例子和判断方式见[c-coding-rules-zh.md](c-coding-rules-zh.md#注释与修改记录)。

---

## 16. 排版与格式

- 缩进使用 4 个空格，不使用 Tab。
- 每行不超过 120 字符。
- 运算符两侧留空格。
- 关键控制语句后留空格：`if (...)`、`for (...)`。
- 左花括号单独成行或同行均可，但项目必须统一。本文推荐单独成行。
- 指针星号靠近变量名或类型名均可，但项目必须统一。本文推荐靠近变量名：`uint8_t *buf`。

```c
if (current > limit)
{
    current = limit;
}
```

---

## 17. 编译与静态检查

### 17.1 编译选项

建议开启：

```text
-std=c99
-Wall
-Wextra
-Werror
-Wshadow
-Wconversion
-Wsign-conversion
-Wstrict-prototypes
-Wmissing-prototypes
-Wundef
-Wformat=2
```

嵌入式交叉编译器不完全兼容 GCC 选项时，应使用等价告警等级。

### 17.2 零告警原则

- 新增代码必须零编译告警。
- 不允许通过无意义类型转换掩盖告警。
- 第三方代码告警应隔离，不污染项目自身告警基线。

### 17.3 静态分析

推荐检查项：

- 空指针解引用。
- 数组越界。
- 未初始化变量。
- 死代码。
- 整数溢出。
- 资源泄漏。
- 不可达分支。
- MISRA-C 关键规则偏离。

---

## 18. 可测性与单元测试

### 18.1 可测性设计

- 硬件访问通过接口封装，便于 mock。
- 控制算法与寄存器访问分离。
- 状态机输入输出显式化。
- 避免函数内部直接读写全局状态。
- 时间、随机数、外设状态通过依赖注入或平台抽象获取。

### 18.2 单元测试范围

至少覆盖：

- 正常路径。
- 边界值。
- 错误参数。
- 超时路径。
- 状态机非法迁移。
- 整数饱和与定点数缩放。
- 通信帧 CRC、长度异常和大小端解析。

### 18.3 嵌入式测试分层

| 层级 | 目标 |
|---|---|
| PC 单元测试 | 算法、协议、状态机 |
| HAL mock 测试 | 驱动上层逻辑 |
| HIL 测试 | 真实外设、时序、故障注入 |
| 长稳测试 | 内存、栈、实时性、通信稳定性 |

---

## 19. 程序效率

### 19.1 优化原则

优化顺序：

1. 保证正确性。
2. 保证清晰性和可维护性。
3. 通过测量确认瓶颈。
4. 局部优化瓶颈路径。
5. 记录优化依据和副作用。

### 19.2 嵌入式性能关注点

- ISR 最坏执行时间。
- 控制环周期裕量。
- 栈峰值。
- DMA 与 CPU 竞争。
- Cache 一致性。
- Flash wait-state。
- 浮点与定点转换成本。
- 除法、取模、64 位运算成本。

### 19.3 高频路径规则

- 避免动态分配。
- 避免复杂格式化输出。
- 避免不必要的除法和取模。
- 查表、定点化、预计算必须有精度分析。
- 优化后必须保留等价性测试。

---

## 20. 嵌入式 C99 检查清单

### 20.1 提交前自检

- [ ] 所有 `.h` 文件自包含。
- [ ] 无头文件循环依赖。
- [ ] 无未使用 include。
- [ ] 无头文件变量定义。
- [ ] 新增函数不超过 50 行或有合理说明。
- [ ] 嵌套深度不超过 4 层。
- [ ] 所有错误返回码已处理。
- [ ] 指针参数已做必要空指针检查。
- [ ] 变量首次使用前已初始化。
- [ ] 无局部变量遮蔽全局变量。
- [ ] 无无界字符串操作。
- [ ] 无无保护共享变量访问。
- [ ] ISR 中无阻塞、无动态内存、无复杂日志。
- [ ] 通信字段已处理大小端和长度边界。
- [ ] 编译零告警。
- [ ] 单元测试覆盖边界和错误路径。

### 20.2 评审重点

- 模块接口是否稳定、清晰。
- 是否直接暴露全局变量。
- 是否存在隐含硬件时序依赖。
- 是否存在实时性风险。
- 是否存在整数溢出风险。
- 是否存在并发竞争。
- 是否存在平台不可移植假设。

---

## 21. 推荐代码骨架

### 21.1 模块头文件

```c
#ifndef PROJECT_AXIS_AXIS_H
#define PROJECT_AXIS_AXIS_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct axis axis_t;

typedef enum
{
    AXIS_RESULT_OK = 0,
    AXIS_RESULT_ERR_NULL,
    AXIS_RESULT_ERR_RANGE,
    AXIS_RESULT_ERR_STATE
} axis_result_t;

axis_result_t axis_init(axis_t *axis);
axis_result_t axis_enable(axis_t *axis);
axis_result_t axis_disable(axis_t *axis);
axis_result_t axis_set_target_position(axis_t *axis, int64_t position_q16);
bool axis_is_enabled(const axis_t *axis);

#ifdef __cplusplus
}
#endif

#endif /* PROJECT_AXIS_AXIS_H */
```

### 21.2 模块源文件

```c
#include "axis.h"

#include "platform_irq.h"
#include "platform_time.h"

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>

struct axis
{
    int64_t target_position_q16;
    int64_t actual_position_q16;
    bool enabled;
};

static bool axis_position_is_valid(int64_t position_q16)
{
    return (position_q16 >= AXIS_POSITION_MIN_Q16) &&
           (position_q16 <= AXIS_POSITION_MAX_Q16);
}

axis_result_t axis_set_target_position(axis_t *axis, int64_t position_q16)
{
    if (axis == NULL)
    {
        return AXIS_RESULT_ERR_NULL;
    }

    if (!axis_position_is_valid(position_q16))
    {
        return AXIS_RESULT_ERR_RANGE;
    }

    axis->target_position_q16 = position_q16;
    return AXIS_RESULT_OK;
}
```

---

## 22. 项目落地建议

1. 将本文作为仓库 `docs/c_coding_skill.md`。
2. 在 CI 中加入编译告警、格式检查、静态分析、单元测试。
3. 对历史代码建立豁免清单，新代码不允许新增豁免。
4. 对 ISR、多核共享内存、安全状态机、通信协议解析建立专项评审模板。
5. 每次缺陷复盘后，将可复用规则补充到本 Skill。

---

## 23. 规则优先级

当规则冲突时，按以下顺序决策：

1. 功能安全和人身安全。
2. 正确性。
3. 可测试性和可诊断性。
4. 清晰性和可维护性。
5. 可移植性。
6. 性能和资源占用。

性能优化必须建立在测量数据基础上；安全性和正确性问题不得以性能为由豁免。

---

## 附录 A：常见陷阱清单

- 把变量定义放进头文件，导致重复定义。
- 为了修一个小 bug 顺手格式化整个文件，导致代码审查和回归范围扩大。
- 未确认编码格式就把历史 C 文件从 GBK 转成 UTF-8，导致中文注释、编译脚本或老工具链异常。
- 在 ISR 中调用阻塞函数、动态内存、printf 或复杂协议处理。
- 对 `volatile` 误解为“线程安全”，但没有临界区或内存屏障。
- 对寄存器执行读改写时未考虑 W1C、只读位、清标志顺序和硬件副作用。
- 通信结构体直接映射到报文，未处理字节序、对齐和填充。
- 错误返回码未处理，或者失败路径没有释放资源/恢复安全状态。

## 附录 B：生成 `.h/.c` 参考文件时的最低框架

生成嵌入式 C99 模块时，至少包含：

1. 文件头说明：模块职责、适用范围、依赖、注意事项。
2. 头文件保护符：`PROJECT_PATH_FILE_H` 风格，禁止以下划线开头。
3. `extern "C"`：只包声明，不包 `#include`。
4. 必要标准头：`stdint.h`、`stdbool.h`、`stddef.h`，按需包含。
5. 公共类型：只定义实际需要的错误码、配置、状态或回调，不添加空状态、空回调等无用途类型。
6. 公共接口：按真实职责与生命周期提供；纯计算功能不机械增加 `init/reset/deinit`，已有稳定 API 保持兼容。
7. 私有实现：同文件私有函数使用 `static`；可变状态按单实例、多实例及并发需求明确所有权，避免隐藏共享状态。
8. 参数检查：按明确责任检查空指针、范围及实际状态前提，失败后的输出与状态遵守接口契约。
9. 并发边界：有共享访问时落实目标上可执行的同步方案；条件不足则说明缺口，不生成无效临界区宏或锁接口占位。
10. 验证注释：可单元测试项、硬件依赖项、异常路径。




# 24. Firmware Documentation & Change Tracking Skill（固件文档与变更追踪规范）

## 24.1 目标

让维护者看懂参数、单位、计算和重要限制。注释按需要写清楚，不以格式标签、字数和历史表数量评价完整性。

## 24.2 文件头注释规范

采用第15.2节的普通块说明。可以用星号横幅标记模块分区或重点，不能因此给普通单行说明添加多余符号。

## 24.3 函数头注释规范

采用第15.3节的简单中文说明；参数和返回值不直观时再展开，不要求每个函数重复作者、日期和版本。

## 24.4 代码块注释规范

```c
/************************ 写入参数 ************************/
/* 全部校验通过后再更新，避免错误参数覆盖当前设置 */
```

## 24.5 修改历史

修改历史默认保存在Git、CHANGELOG或项目已有记录中，不自动生成代码内Modification History表。

## 24.6 函数修改说明

影响后续维护的原因可以在对应代码上方用一句中文说明；不要只重复修改日期、作者或实现步骤。

## 24.7 缺陷记录

现象、根因和修复方案记录到项目已有问题或提交记录；代码里只保留理解当前实现所需的原因与限制，不默认添加Bug Fix块。

## 24.8 Agent执行要求

1. 普通说明使用简易中文块注释，分区或重点可用星号标记
2. 字段说明用途、单位/范围、填写或维护方式，容易混淆时给例子
3. 不自动生成Doxygen标签、函数历史表、占位作者或版本
4. 不为了满足注释数量而补逐行翻译
5. 保留有用的原注释，修改过期说明，遵循用户当前要求

## 24.9 评审要点

- 参数、单位、计算依据和重要限制是否看得懂
- 普通说明是否简洁，分区或重点标记是否合理
- 简单函数是否避免重复说明，复杂逻辑是否交代关键步骤
- 说明是否与当前实现一致，变更是否能从项目已有记录追溯

## 24.10 优先级

用户当前要求和主技能规则优先于历史模板。项目明确要求Doxygen时才使用专用格式；第三方或生成代码不为统一注释而批量改写。
