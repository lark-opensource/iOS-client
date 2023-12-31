//
//  hmd_stack_cursor.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/2/19.
//

#include "hmd_stack_cursor.h"
#include <stdlib.h>
#include "hmd_symbolicator.h"
#include "HMDCompactUnwind.hpp"
//#define HMDLogger_LocalLevel TRACE
#include "hmd_logger.h"
#include "HMDCompactUnwind.hpp"

static bool g_advanceCursor(__unused hmd_stack_cursor *cursor) {
    HMDLOG_WARN(
        "No stack cursor has been set. For C++, this means that hooking __cxa_throw() failed for some reason. Embedded "
        "frameworks can cause this: ");
    return false;
}

void hmdsc_resetCursor(hmd_stack_cursor *cursor) {
    cursor->state.currentDepth = 0;
    cursor->stackEntry.address = 0;
    cursor->stackEntry.imageAddress = 0;
    cursor->stackEntry.imageName[0] = 0;
    cursor->stackEntry.symbolAddress = 0;
    cursor->stackEntry.symbolName[0] = 0;
    cursor->fast_unwind = false;
}

void hmdsc_initCursor(hmd_stack_cursor *cursor, void (*resetCursor)(hmd_stack_cursor *),
                      bool (*advanceCursor)(hmd_stack_cursor *)) {
    cursor->symbolicate = hmdsymbolicator_symbolicate;
    cursor->advanceCursor = advanceCursor != NULL ? advanceCursor : g_advanceCursor;
    cursor->resetCursor = resetCursor != NULL ? resetCursor : hmdsc_resetCursor;
    cursor->resetCursor(cursor);
}

bool hmdsc_setup_frame_cursor(hmd_stack_cursor *cursor, const hmd_thread_state_t *state) {
    if (cursor && state) {
        hmd_thread_state_mcontext_init(&cursor->frame_cursor.frame.thread_state, state);
        return true;
    }
    return false;
}
