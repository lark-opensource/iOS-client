//
//  hmd_stack_cursor_backtrace.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#ifndef KSStackCursor_Backtrace_h
#define KSStackCursor_Backtrace_h

#ifdef __cplusplus
extern "C" {
#endif

#include "hmd_stack_cursor.h"

/** Exposed for other internal systems to use.
 */
typedef struct {
    int skippedEntries;
    int backtraceLength;
    const uintptr_t* backtrace;
} hmd_stack_cursor_backtrace_context;

/** Initialize a stack cursor for an existing backtrace (array of addresses).
 *
 * @param cursor The stack cursor to initialize.
 *
 * @param backtrace The existing backtrace to walk.
 *
 * @param backtraceLength The length of the backtrace.
 *
 * @param skipEntries The number of stack entries to skip.
 */
void hmdsc_initWithBacktrace(hmd_stack_cursor* cursor, const uintptr_t* backtrace, int backtraceLength,
                             int skipEntries);

#ifdef __cplusplus
}
#endif

#endif  // KSStackCursor_Backtrace_h
