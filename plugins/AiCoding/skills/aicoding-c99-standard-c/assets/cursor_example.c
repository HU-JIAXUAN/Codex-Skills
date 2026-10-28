/*
    用途：实现容量游标的初始化与有界预留
    职责边界：只维护容量和偏移，不访问缓冲区，不执行硬件操作或并发同步
    相关文件：cursor_example.h定义输入、输出及失败合同
*/

#include "cursor_example.h"

/************************ 对外接口 ************************/

/* 建立游标的初始不变量，使用合同见头文件 */
CursorResult cursor_init(Cursor *cursor, size_t capacity)
{
    if (cursor == NULL) {
        return CURSOR_INVALID_ARG;
    }

    cursor->capacity = capacity;
    cursor->position = 0U;
    return CURSOR_OK;
}

/* 检查状态和剩余容量后提交预留结果，使用合同见头文件 */
CursorResult cursor_reserve(Cursor *cursor, size_t count, size_t *startOffset)
{
    if ((cursor == NULL) || (startOffset == NULL)) {
        return CURSOR_INVALID_ARG;
    }

    if (cursor->position > cursor->capacity) {
        return CURSOR_INVALID_STATE;
    }

    /* 先用剩余容量比较，避免position与count相加发生size_t回绕 */
    if (count > cursor->capacity - cursor->position) {
        return CURSOR_NO_SPACE;
    }

    /* 所有检查通过后再更新，保证失败路径不推进游标或覆盖输出 */
    *startOffset = cursor->position;
    cursor->position += count;
    return CURSOR_OK;
}
