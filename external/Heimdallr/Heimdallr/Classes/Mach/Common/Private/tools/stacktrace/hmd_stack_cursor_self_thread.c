//
//  hmd_stack_cursor_self_thread.c
//
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include "hmd_stack_cursor_self_thread.h"
#include <execinfo.h>
#include "hmd_stack_cursor_backtrace.h"
#include "HMDMacro.h"
#include "hmd_crash_safe_tool.h"
//#define HMDLogger_LocalLevel TRACE

#define MAX_BACKTRACE_LENGTH (KSSC_CONTEXT_SIZE - sizeof(hmd_stack_cursor_backtrace_context) / sizeof(void*) - 1)

typedef struct {
    hmd_stack_cursor_backtrace_context SelfThreadContextSpacer;
    uintptr_t backtrace[0];
} SelfThreadContext;

void HMD_NO_OPT_ATTRIBUTE hmdsc_initSelfThread(hmd_stack_cursor* cursor, int skipEntries) {
    hmdsc_init_self_thread_fast_backtrace(cursor, skipEntries + 1);
    GCC_FORCE_NO_OPTIMIZATION
}

void HMD_NO_OPT_ATTRIBUTE hmdsc_init_self_thread_fast_backtrace(hmd_stack_cursor *cursor, int skipEntries) {
    SelfThreadContext* context = (SelfThreadContext*)cursor->context;
    int backtraceLength = hmd_reliable_fast_backtrace((void**)context->backtrace, MAX_BACKTRACE_LENGTH);
    hmdsc_initWithBacktrace(cursor, context->backtrace, backtraceLength, skipEntries + 1);
    GCC_FORCE_NO_OPTIMIZATION
}

void HMD_NO_OPT_ATTRIBUTE hmdsc_init_self_thread_sys_backtrace(hmd_stack_cursor *cursor, int skipEntries) {
    SelfThreadContext* context = (SelfThreadContext*)cursor->context;
    int backtraceLength = backtrace((void**)context->backtrace, MAX_BACKTRACE_LENGTH);
    hmdsc_initWithBacktrace(cursor, context->backtrace, backtraceLength, skipEntries + 1);
    GCC_FORCE_NO_OPTIMIZATION
}

void HMD_NO_OPT_ATTRIBUTE hmdsc_init_self_thread_backtrace(hmd_stack_cursor *cursor, int skipEntries) {
    SelfThreadContext* context = (SelfThreadContext*)cursor->context;
    int backtraceLength = hmd_reliable_backtrace((void**)context->backtrace, MAX_BACKTRACE_LENGTH);
    hmdsc_initWithBacktrace(cursor, context->backtrace, backtraceLength, skipEntries + 1);
    GCC_FORCE_NO_OPTIMIZATION
}
