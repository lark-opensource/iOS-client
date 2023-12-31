//
//  hmd_stack_cursor_self_thread.h
//
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#ifndef KSStackCursor_SelfThread_h
#define KSStackCursor_SelfThread_h
#include "hmd_stack_cursor.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Initialize a stack cursor for the current thread.
 *  You may want to skip some entries to account for the trace immediately leading
 *  up to this init function.
 *
 * @param cursor The stack cursor to initialize.
 *
 * @param skipEntries The number of stack entries to skip.
 */
void hmdsc_initSelfThread(hmd_stack_cursor *cursor, int skipEntries); //same as fast backtrace

void hmdsc_init_self_thread_fast_backtrace(hmd_stack_cursor *cursor, int skipEntries);

void hmdsc_init_self_thread_sys_backtrace(hmd_stack_cursor *cursor, int skipEntries); //not async safe

void hmdsc_init_self_thread_backtrace(hmd_stack_cursor *cursor, int skipEntries);

#ifdef __cplusplus
}
#endif

#endif  // KSStackCursor_SelfThread_h
