//
//  HMDFrameStackUnwind.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#include "HMDFrameWalker.h"
#include "hmd_types.h"

#include "HMDFrameCompactUnwind.h"
#include "HMDFrameStackUnwind.h"

#include "hmd_logger.h"

#pragma mark Error Handling

/**
 * Return an error description for the given hmdframe_error_t.
 */
const char *hmdframe_strerror(hmdframe_error_t error) {
    switch (error) {
        case HMDFRAME_ESUCCESS:
            return "No error";
        case HMDFRAME_EUNKNOWN:
            return "Unknown error";
        case HMDFRAME_ENOFRAME:
            return "No frames are available";
        case HMDFRAME_EBADFRAME:
            return "Corrupted frame";
        case HMDFRAME_ENOTSUP:
            return "Operation not supported";
        case HMDFRAME_EINVAL:
            return "Invalid argument";
        case HMDFRAME_INTERNAL:
            return "Internal error";
        case HMDFRAME_EBADREG:
            return "Invalid register";
    }

    /* Should be unreachable */
    return "Unhandled error code";
}

#pragma mark Frame Walking

hmdframe_error_t hmdframe_cursor_init(hmdframe_cursor_t *cursor, hmd_thread_state_t *thread_state) {
    hmd_async_memcpy(&cursor->frame.thread_state, thread_state, sizeof(cursor->frame.thread_state));
    return HMDFRAME_ESUCCESS;
}

#if HMD_USE_COMPACT_UNWIND

hmdframe_error_t hmdframe_cursor_next_with_compact_unwind(hmdframe_cursor_t *cursor,
                                                          hmd_async_image_list_t *image_list) {
    /* Read in the next frame using the first successful frame reader. */
    hmdframe_stackframe_t next_frame;
    
    hmdframe_error_t ferr = HMDFRAME_EINVAL;  // default return value if reader_count is 0.
    
    ferr = hmdframe_cursor_read_compact_unwind(image_list, &cursor->frame, &next_frame);
    if (ferr != HMDFRAME_ESUCCESS) {
       return ferr;
    }

    /* A pc within the NULL page is a terminating frame */
    hmd_greg_t pc = hmd_thread_state_get_pc(&next_frame.thread_state);
    if (!HMD_IS_VALID_PTR(pc)) {
        return HMDFRAME_ENOFRAME;
    }
    
    cursor->frame = next_frame;

    return HMDFRAME_ESUCCESS;
}

#endif

hmdframe_error_t hmdframe_cursor_next_with_stack_unwind(hmdframe_cursor_t *cursor, bool use_lr) {
    /* Read in the next frame using the first successful frame reader. */
    hmdframe_stackframe_t next_frame;

    hmdframe_error_t ferr = HMDFRAME_EINVAL;  // default return value if reader_count is 0.
    
    ferr = hmdframe_cursor_read_frame_ptr(&cursor->frame, &next_frame, use_lr);
    if (ferr != HMDFRAME_ESUCCESS) {
       return ferr;
    }

    /* A pc within the NULL page is a terminating frame */
    hmd_greg_t pc = hmd_thread_state_get_pc(&next_frame.thread_state);
    if (!HMD_IS_VALID_PTR(pc)) {
        return HMDFRAME_ENOFRAME;
    }

    cursor->frame = next_frame;

    return HMDFRAME_ESUCCESS;
}

hmd_greg_t hmdframe_cursor_get_pc(hmdframe_cursor_t *cursor) {
    if (cursor) {
        return hmd_thread_state_get_pc(&cursor->frame.thread_state);
    }
    return 0;
}

hmd_greg_t hmdframe_cursor_get_lr(hmdframe_cursor_t *cursor) {
    if (cursor) {
        return hmd_thread_state_get_lr(&cursor->frame.thread_state);
    }
    return 0;
}

hmd_greg_t hmdframe_cursor_get_sp(hmdframe_cursor_t *cursor) {
    if (cursor) {
        return hmd_thread_state_get_sp(&cursor->frame.thread_state);
    }
    return 0;
}

hmd_greg_t hmdframe_cursor_get_fp(hmdframe_cursor_t *cursor) {
    if (cursor) {
        return hmd_thread_state_get_fp(&cursor->frame.thread_state);
    }
    return 0;
}
