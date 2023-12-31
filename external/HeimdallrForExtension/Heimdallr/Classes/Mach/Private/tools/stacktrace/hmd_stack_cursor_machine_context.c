//
//  hmd_stack_cursor_machine_context.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include "hmd_stack_cursor_machine_context.h"
#include "hmd_memory.h"
#define HMDLogger_LocalLevel INFO
#include "HMDFrameWalker.h"
#include "hmd_logger.h"
#include "HMDCompactUnwind.hpp"
#include <stdlib.h>

/** Represents an entry in a frame list.
 * This is modeled after the various i386/x64 frame walkers in the xnu source,
 * and seems to work fine in ARM as well. I haven't included the args pointer
 * since it's not needed in this context.
 */
typedef struct FrameEntry {
    /** The previous frame in the list. */
    struct FrameEntry* previous;

    /** The instruction address. */
    uintptr_t return_address;
} FrameEntry;

typedef struct {
    const struct hmd_machine_context* machineContext;
    FrameEntry currentFrame;
} MachineContextCursor;

/**
 - Make a new machine context structure (_STRUCT_MCONTEXT)
 - Fill in its stack state using thread_get_state()
 - Get the program counter (first stack trace entry) and frame pointer (all the rest)
 - Step through the stack frame pointed to by the frame pointer and store all instruction addresses in a buffer for
 later use.
 - Note that you should pause the thread before doing this or else you can get unpredictable results.

 The stack frame is filled with structures containing two pointers:

 Pointer to the next level up on the stack
 instruction address

 So you need to take that into account when walking the frame to fill out your stack trace. There's also the possibility
 of a corrupted stack, leading to a bad pointer, which will crash your program. You can get around this by copying
 memory using vm_read_overwrite(), which first asks the kernel if it has access to the memory, so it doesn't crash.
 https://stackoverflow.com/questions/4765158/printing-a-stack-trace-from-another-thread
 */
static bool advanceCursor(hmd_stack_cursor* cursor) {
    //check pc fp lr if valid
    if (cursor->state.currentDepth == 0) {
        MachineContextCursor* context = (MachineContextCursor*)cursor->context;
        uintptr_t pc = hmdmc_get_pc(context->machineContext);
        uintptr_t lr = hmdmc_get_lr(context->machineContext);
        uintptr_t fp = hmdmc_get_fp(context->machineContext);
        if (pc == 0 && lr == 0 && fp == 0) {
            HMDLOG_ERROR("pc lr fp are empty, backtrace failure");
            return false;
        }
        cursor->stackEntry.address = (uintptr_t)pc;
        cursor->state.currentDepth++;
        return true;
    }
    
    hmdframe_error_t ferr = HMDFRAME_EUNKNOWN;
    
#if HMD_USE_COMPACT_UNWIND
    if (!cursor->fast_unwind) {
        if (hmd_async_share_image_list_has_setup()) {
            ferr = hmdframe_cursor_next_with_compact_unwind(&cursor->frame_cursor, &shared_image_list);
        }
    }
#endif
    
    if (ferr != HMDFRAME_ESUCCESS) {
        ferr = hmdframe_cursor_next_with_stack_unwind(&cursor->frame_cursor, cursor->state.currentDepth==1);
        if (ferr != HMDFRAME_ESUCCESS) {
            return false;
        }
    }
    hmd_greg_t pc = hmdframe_cursor_get_pc(&cursor->frame_cursor);
    cursor->stackEntry.address = (uintptr_t)pc;
    cursor->state.currentDepth++;
    return true;
}

static void resetCursor(hmd_stack_cursor* cursor) {
    hmdsc_resetCursor(cursor);
    MachineContextCursor* context = (MachineContextCursor*)cursor->context;
    context->currentFrame.previous = 0;
    context->currentFrame.return_address = 0;
}

void hmdsc_initWithMachineContext(hmd_stack_cursor* cursor, const struct hmd_machine_context* machineContext) {
    hmdsc_initCursor(cursor, resetCursor, advanceCursor);
    MachineContextCursor* context = (MachineContextCursor*)cursor->context;
    context->machineContext = machineContext;
    hmdsc_setup_frame_cursor(cursor, &machineContext->state);
}
