/*
    用途：验证游标边界和失败时状态、输出保持的公开行为
    职责边界：仅验证主机示例，不证明目标设备的时序或并发
*/

#include "cursor_example.h"

#include <assert.h>
#include <stdint.h>

/* 覆盖零容量、最大容量、非法状态和失败输出 */
int main(void)
{
    Cursor cursor;
    size_t startOffset = 99U;

    assert(cursor_init(NULL, 8U) == CURSOR_INVALID_ARG);
    assert(cursor_init(&cursor, 8U) == CURSOR_OK);
    assert(cursor_reserve(&cursor, 3U, &startOffset) == CURSOR_OK);
    assert(startOffset == 0U);
    assert(cursor.position == 3U);

    startOffset = 99U;
    assert(cursor_reserve(&cursor, 6U, &startOffset) == CURSOR_NO_SPACE);
    assert(startOffset == 99U);
    assert(cursor.position == 3U);
    assert(cursor_reserve(&cursor, 5U, &startOffset) == CURSOR_OK);
    assert(startOffset == 3U);
    assert(cursor.position == 8U);
    assert(cursor_reserve(&cursor, 1U, NULL) == CURSOR_INVALID_ARG);
    assert(cursor.position == 8U);

    assert(cursor_init(&cursor, 0U) == CURSOR_OK);
    assert(cursor_reserve(&cursor, 0U, &startOffset) == CURSOR_OK);
    assert(startOffset == 0U);
    assert(cursor_reserve(&cursor, 1U, &startOffset) == CURSOR_NO_SPACE);

    /* 最大size_t容量验证预检查，不能靠相加后的回绕来判定边界 */
    assert(cursor_init(&cursor, SIZE_MAX) == CURSOR_OK);
    assert(cursor_reserve(&cursor, SIZE_MAX, &startOffset) == CURSOR_OK);
    assert(startOffset == 0U);
    assert(cursor.position == SIZE_MAX);
    assert(cursor_reserve(&cursor, 1U, &startOffset) == CURSOR_NO_SPACE);
    assert(cursor.position == SIZE_MAX);

    /* 被外部破坏的实例必须失败，且不能覆盖调用者原输出 */
    cursor.capacity = 1U;
    cursor.position = 2U;
    startOffset = 99U;
    assert(cursor_reserve(&cursor, 1U, &startOffset) == CURSOR_INVALID_STATE);
    assert(cursor.position == 2U);
    assert(startOffset == 99U);
    return 0;
}
