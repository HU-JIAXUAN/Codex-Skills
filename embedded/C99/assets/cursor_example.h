/*
    用途：维护容量游标，为调用者预留连续区域
    职责边界：只计算偏移，不分配或访问实际缓冲区，不提供并发同步
    使用条件：字节指C的sizeof单位；目标协议的8位octet需另行换算
*/

#ifndef C99_CURSOR_EXAMPLE_H
#define C99_CURSOR_EXAMPLE_H

#include <stddef.h>

/* 游标操作结果 */
typedef enum {
    CURSOR_OK = 0,        /* 操作成功 */
    CURSOR_INVALID_ARG,   /* 必需的实例或输出指针为空 */
    CURSOR_INVALID_STATE, /* 当前偏移已经超出容量 */
    CURSOR_NO_SPACE       /* 剩余容量不足，本次未预留 */
} CursorResult;

/* 容量与当前偏移，由游标接口维护，调用者负责串行访问 */
typedef struct {
    size_t capacity; /* 可预留的总容量，单位字节 */
    size_t position; /* 已预留容量，单位字节，始终不超过capacity */
} Cursor;

/*
    初始化容量游标
    输入：cursor指向调用者持有的实例；capacity为总字节容量，允许为0
    输出：成功后cursor的当前偏移为0
    返回：CURSOR_OK成功；CURSOR_INVALID_ARG表示cursor为空
    约束：初始化不分配缓冲区；不能与同一实例的其他操作并发调用
*/
CursorResult cursor_init(Cursor *cursor, size_t capacity);

/*
    预留连续区域并返回起始偏移
    输入：cursor为已初始化游标；count为预留字节数，允许为0
    输出：startOffset接收预留前偏移；失败时输出和cursor都保持原值
    返回：CURSOR_OK成功；INVALID_ARG/INVALID_STATE/NO_SPACE含义见CursorResult
    约束：startOffset不能指向cursor内部；同一实例由调用者串行访问
*/
CursorResult cursor_reserve(Cursor *cursor, size_t count, size_t *startOffset);

#endif
