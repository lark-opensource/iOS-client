//
//  hmd_stack_cursor.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#ifndef KSStackCursor_h
#define KSStackCursor_h
#include "HMDFrameWalker.h"

#ifdef __cplusplus
extern "C" {
#endif

#include "hmd_machine_context.h"

#include <stdbool.h>
#include <sys/types.h>

#define KSSC_CONTEXT_SIZE 100

/** Point at which to give up walking a stack and consider it a stack overflow. */
#define KSSC_STACK_OVERFLOW_THRESHOLD 150

typedef struct hmd_stack_cursor {
    struct {
        /** Current address in the stack trace. */
        uintptr_t address;

        /** The name (if any) of the binary image the current address falls inside. */
        char imageName[512];

        /** The starting address of the binary image the current address falls inside. */
        uintptr_t imageAddress;

        /** The name (if any) of the closest symbol to the current address. */
        char symbolName[512];

        /** The address of the closest symbol to the current address. */
        uintptr_t symbolAddress;
    } stackEntry;
    struct {
        /** Current depth as we walk the stack (1-based). */
        int currentDepth;
    } state;

    /** real frame walker cursor for compact unwind and stack unwind*/
    /** Reset the cursor back to the beginning. */
    void (*resetCursor)(struct hmd_stack_cursor*);
    hmdframe_cursor_t frame_cursor;
    
    bool fast_unwind;

    /** Advance the cursor to the next stack entry. */
    bool (*advanceCursor)(struct hmd_stack_cursor*);

    /** Attempt to symbolicate the current address, filling in the fields in stackEntry. */
    bool (*symbolicate)(struct hmd_stack_cursor*);

    /** Internal context-specific information. */
    void* context[KSSC_CONTEXT_SIZE];
} hmd_stack_cursor;

/** Common initialization routine for a stack cursor.
 *  Note: This is intended primarily for other cursors to call.
 *
 * @param cursor The cursor to initialize.
 *
 * @param resetCursor Function that will reset the cursor (NULL = default: Do nothing).
 *
 * @param advanceCursor Function to advance the cursor (NULL = default: Do nothing and return false).
 */
void hmdsc_initCursor(hmd_stack_cursor* cursor, void (*resetCursor)(hmd_stack_cursor*),
                      bool (*advanceCursor)(hmd_stack_cursor*));

void hmdsc_resetCursor(hmd_stack_cursor* cursor);
bool hmdsc_setup_frame_cursor(hmd_stack_cursor *cursor, const hmd_thread_state_t *mcontext);
#ifdef __cplusplus
}
#endif

#endif  // KSStackCursor_h
