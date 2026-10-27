# DSP 处理器与库的系列适配参考

本文件按已识别目标补充实现差异，不定义芯片路由，也不要求为每个系列建立 skill。先完成通用算法、数值和数据流契约，再读取匹配条目；型号、主频、寄存器值、对齐长度和库选项从当前工程与对应手册取得。

来源核读日期：2026-10-28。以下范围只表示已核读的资料，不表示整份手册、所有型号或硬件均已验证。在线 `latest` 文档用于发现约束，复现实验必须记录实际库与编译器版本。

## 所有系列共同填写的适配记录

| 项目 | 最小证据 |
|---|---|
| 编译与 ABI | 目标核心、编译器/版本、ABI、优化、浮点与 DSP 选项、链接库；确认实际参与构建的头文件和对象 |
| 数值 | 输入/输出格式、乘法及累加中间格式、舍入/饱和/溢出、状态初始化；标明硬件模式是否影响 C 或库函数 |
| 内存 | 元素个数、C byte 与外设传输单位、对齐、数据空间、缓冲区有效期与 owner、DMA/加速器访问权限 |
| 调用 | 原地/非原地、允许重叠范围、长度及尾部、可重入性、中断与特殊寄存器保存；异步完成后才能交还缓冲区 |
| 验证 | 同一输入对照标量参考，覆盖边界/溢出/尾部与状态；记录当前构建和真实运行条件下的周期、延迟、抖动 |

## TI C2000：C28x 与 CLA

### 类型与共享布局

- C28x 编译器资料中的 C byte 是 16 bit，`sizeof(char)` 仍为 1。协议 octet、DMA 传输单元与 `sizeof` 计数必须分别说明；这不是所有 32-bit DSP 的共同属性。
- 不从旧笔记图推定 `double`：核对当前编译器的 COFF/EABI 数据模型、库 ABI 及编译选项，再用 `CHAR_BIT`、`sizeof` 和编译布局证据确认。

来源：[C28x Compiler，在线 §6.4 Data Types、Table 6-1 与 Byte 注记](https://downloads.ti.com/docs/esd/SPRU514/data-types-stdz0555922.html)。此页展示的数据模型是适配参考，当前安装版本的手册与编译结果决定实际契约。

- C28x 与 CLA 对 `int` 和指针的解释不同；共享头使用双方支持的明确宽度类型，含指针的结构体尤其需要双侧检查成员偏移、大小和对齐。需要时采用经验证的地址表示或分离消息字段，不直接传递宿主布局。
- 按对应 CLA 的共享 RAM、变量定义位置、初始化和任务完成机制接线，明确单一写入 owner 与交接时机。`volatile` 不能修复布局、原子性或同步错误。

来源：[CLA Software Development Guide 1.0，FAQ §4.5～§4.6](https://software-dl.ti.com/C2000/docs/cla_software_dev_guide/faq.html)，已核读共享变量定义、初始化及指针布局示例；其他 CLA 类型与任务限制仍查当前目标手册。

### Flash/RAM 与测量

先检查 MAP 中的 load/run 地址、启动复制和 Flash 配置，再比较相同算法的执行条件。复制时间关键代码或常量到 RAM 前，确认容量、代码/数据争用与实际收益；某个示例的周期数不作为其他器件的预算。

来源：[C28x Optimization Guide v1.2，§4.1.1～§4.1.3 Memory](https://software-dl.ti.com/C2000/docs/optimization_guide/phase3/memory.html)，核读 Flash/RAM、`ramfunc`、链接与复制及物理存储块争用说明。

## TI C6000/C66x：编译器前提与流水优化

1. 使用 `restrict` 前验证所有调用的读写重叠关系；不能只凭函数内部看起来独立就声明非别名。输入范围允许原地操作时，选择满足该契约的实现。
2. 添加 `MUST_ITERATE` 或对齐保证前，证明实际最小/最大/倍数及所有尾部路径。它们向优化器提供保证，不替代运行时长度检查；不满足保证可能产生未定义行为。
3. 查看软件流水与生成汇编中的资源、调用和存取瓶颈，再比较优化内核与标量参考；记录使用的库、ABI、内存布局和编译条件。

来源：[TI Compiler Advice #30008，What it means / Risks](https://software-dl.ti.com/ccs/esd/documents/dmed/HTML/C6000/30008.html)、[#30009，参数约束与多调用示例](https://software-dl.ti.com/ccs/esd/documents/dmed/HTML/C6000/30009.html)；[SPRU187U，C6000 Compiler v7.4 User's Guide，§3.2 与 §3.14.1.15～17](https://www.ti.com/lit/ug/spru187u/spru187u.pdf)。该编译器手册为旧版机制示例，选项与支持范围须匹配实际版本。

[C66x DSPLIB 3.4.0.0 Test Report](https://software-dl.ti.com/jacinto7/esd/processor-sdk-rtos-jacinto7/11_02_00_06/exports/docs/dsplib_c66x_3_4_0_0/docs/DSPLIB_C66x_TestReport.html)的 Session Summary / Test Parameters 标注了模拟器、CGT 与对象格式。厂商 cycle 表只作为该环境的参考基线，不证明当前板的 WCET。每个函数的对齐、长度、缩放和重叠条件仍须读取实际安装库的 API 文档。

## ADI SHARC：硬件寻址与 SIMD 边界

以下是已核读 SHARC 代际的适配示例，不据此推导 Blackfin 或所有 SHARC+ 的具体行为。

1. 核对硬件环形缓冲的 base/index/length/modify、访问步长、地址空间和复位状态；迁移时重新确认是否需要启用特殊寻址，以及中断进入/退出如何保存相关状态。
2. SIMD 验证显式与隐式伴随访问，覆盖奇数长度、起始偏移、最后一组和 wrap。所读手册指出该代 SIMD 奇数长度可能让隐式访问超出环形范围；地址寄存器回绕正确不等于全部访问有效。
3. 选择 SIMD 或扩展精度前核对数据通路及存储格式，测试真实载入/存储的数值；不要将内部寄存器精度直接当成数组精度或所有 SIMD 路径的精度。

来源：[ADSP-2126x SHARC Processor Hardware Reference，Rev. 5.0](https://www.analog.com/media/en/dsp-documentation/processor-manuals/ADSP-21262_hwr_rev5.0.pdf)，核读印刷页 4-5、4-13～4-17 的 circular buffering 与 SIMD 例外，以及 5-46～5-48 的 normal-word/extended-precision 访问。此处未核读 Blackfin 的缓存/DMA章节，不补写其具体操作步骤。

## Microchip dsPIC：分数格式与特殊执行状态

1. 先识别实际系列：所读库指南区分 dsPIC30F/33F/33E/33C 的 1.15 输入输出与 40-bit 累加，以及 dsPIC33A 的 1.31 与 72-bit 累加。库名相近也不能沿用另一系列的缩放或中间格式。
2. 查实际函数的内存分配、对齐与 X/Y 数据空间要求，验证输入、状态和输出；不要以“库会检查参数”作为前提。
3. 检查 CORCON 的乘法、舍入与饱和模式、溢出/饱和状态，以及 ISR/RTOS 对循环和特殊寻址资源的保存。数值结果与周期均在真实中断条件下复测。

来源：[DSP Library User Guide for dsPIC Digital Signal Controllers，DS70005593B，2025](https://ww1.microchip.com/downloads/aemDocuments/documents/MCU16/ProductDocuments/UserGuides/DSP-Library-User-Guide-for-dsPIC-Digital-Signal-Controllers-DS70005593.pdf)，核读 §1.2.4～§1.2.8、印刷页 5～6。具体库函数的资源使用与参数仍查其 Function Profile。

## Arm：CMSIS-DSP、Helium 与 Neon 的库契约

- 从实际 API、数据类型和编译目标确定实现，不因名称相同就复用另一后端的实例结构、初始化、缓冲或表配置。Helium/Neon 的支持与函数签名以安装版本的头文件和构建结果为准。
- 复数 FFT 核对交错布局、是否原地、正逆变换缩放与 bit-reversal；实数 FFT 另查 DC/Nyquist 打包和输出长度，不能将整个输出直接当普通复数数组。
- 定点与浮点 RFFT 的输出布局、缩放和输入修改行为存在差异；先用 DC、Nyquist、单频和正逆闭环验证，再接幅值/PSD 后处理。初始化、scratch 和可覆盖范围逐函数核对。

来源：[CMSIS-DSP Complex FFT Functions，Description / Floating-point 与初始化说明](https://arm-software.github.io/CMSIS-DSP/latest/group__ComplexFFT.html)、[Real FFT Functions，Floating-point / Q15 and Q31](https://arm-software.github.io/CMSIS-DSP/latest/group__RealFFT.html)。已核读在线总说明，未将其视为所有后端的完整 ABI 或每个函数的缩放表；准确接口与格式仍读取当前版本的具体函数文档。

## 尚未核读的系列

遇到 C7x、Blackfin 或其他 DSP 时，沿共同适配记录查其官方编译器、库 API 和处理器手册；未确认的数据宽度、缓存/DMA一致性、指令或周期保留 UNKNOWN，不从相近系列补齐。新系列差异优先补进本参考，通用算法入口保持稳定。
