//
//  hmd_stack_cursor_backtrace.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include "hmd_stack_cursor_backtrace.h"
#include <os/base.h>

static bool advanceCursor(hmd_stack_cursor* cursor) {
    hmd_stack_cursor_backtrace_context* context = (hmd_stack_cursor_backtrace_context*)cursor->context;
    int endDepth = context->backtraceLength - context->skippedEntries;
    if (cursor->state.currentDepth < endDepth) {
        int currentIndex = cursor->state.currentDepth + context->skippedEntries;
        uintptr_t nextAddress = context->backtrace[currentIndex];
        // Bug: The system sometimes gives a backtrace with an extra 0x00000001 at the end.
        if (nextAddress > 1) {
            cursor->stackEntry.address = HMD_POINTER_STRIP(nextAddress);
            cursor->state.currentDepth++;
            return true;
        }
    }
    return false;
}

void OS_NOINLINE OS_NOT_TAIL_CALLED hmdsc_initWithBacktrace(hmd_stack_cursor* cursor, const uintptr_t* backtrace, int backtraceLength, int skipEntries) {
    hmdsc_initCursor(cursor, hmdsc_resetCursor, advanceCursor);
    hmd_stack_cursor_backtrace_context* context = (hmd_stack_cursor_backtrace_context*)cursor->context;
    context->skippedEntries = skipEntries;
    context->backtraceLength = backtraceLength;
    context->backtrace = backtrace;
}
