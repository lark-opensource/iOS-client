//
//  hmd_symbolicator.h
//
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#ifndef KSSymbolicator_h
#define KSSymbolicator_h

/** Remove any pointer tagging from an instruction address
 * On armv7 the least significant bit of the pointer distinguishes
 * between thumb mode (2-byte instructions) and normal mode (4-byte instructions).
 * On arm64 all instructions are 4-bytes wide so the two least significant
 * bytes should always be 0.
 * On x86_64 and i386, instructions are variable length so all bits are
 * signficant.
 */
#if defined(__arm__)
#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(1UL))
#elif defined(__arm64__)
#define DETAG_INSTRUCTION_ADDRESS(A) ((A) & ~(3UL))
#else
#define DETAG_INSTRUCTION_ADDRESS(A) (A)
#endif

/** Step backwards by one instruction.
 * The backtrace of an objective-C program is expected to contain return
 * addresses not call instructions, as that is what can easily be read from
 * the stack. This is not a problem except for a few cases where the return
 * address is inside a different symbol than the call address.
 */
#define CALL_INSTRUCTION_FROM_RETURN_ADDRESS(A) (DETAG_INSTRUCTION_ADDRESS((A)) - 1)

#include <stdbool.h>
#include "hmd_stack_cursor.h"
#include "HMDAsyncSymbolicator.h"

#ifdef __cplusplus
extern "C" {
#endif

/** Symbolicate a stack cursor.
 *
 * @param cursor The cursor to symbolicate.
 *
 * @return True if successful.
 */
bool hmdsymbolicator_symbolicate(hmd_stack_cursor *cursor);
    
// CALL_INSTRUCTION_FROM_RETURN_ADDRESS(address)
bool hmd_symbolicate(uintptr_t address, hmd_dl_info *info, bool need_symbol);

#ifdef __cplusplus
}
#endif

#endif  // KSSymbolicator_h
