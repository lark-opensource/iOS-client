//
//  hmd_stack_cursor_machine_context.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#ifndef KSStackCursor_MachineContext_h
#define KSStackCursor_MachineContext_h

#ifdef __cplusplus
extern "C" {
#endif

#include "hmd_stack_cursor.h"

/** Initialize a stack cursor for a machine context.
 *
 * @param cursor The stack cursor to initialize.
 *
 * @param machineContext The machine context whose stack to walk.
 */
void hmdsc_initWithMachineContext(hmd_stack_cursor* cursor, const struct hmd_machine_context* machineContext);

#ifdef __cplusplus
}
#endif

#endif  // KSStackCursor_MachineContext_h
