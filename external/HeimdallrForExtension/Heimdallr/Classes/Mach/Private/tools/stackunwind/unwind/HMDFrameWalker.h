//
//  HMDFrameStackUnwind.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#ifndef HMD_FRAMEWALKER_H
#define HMD_FRAMEWALKER_H

#include "pthread_extended.h"
#import <sys/ucontext.h>

#import <stdbool.h>
#import <stdint.h>
#import <unistd.h>

#import <mach/mach.h>

#include "HMDAsyncImageList.h"
#include "HMDAsyncThreadState.h"
#include "HMDCompactUnwindConfig.h"

/* Configure supported targets based on the host build architecture. There's currently
 * no deployed architecture on which simultaneous support for different processor families
 * is required (or supported), but -- in theory -- such cross-architecture support could be
 * enabled by modifying these defines. */
#if defined(__i386__) || defined(__x86_64__)
#define HMDFRAME_X86_SUPPORT 1
//#include <mach/i386/thread_state.h>
#endif

#if defined(__arm__) || defined(__arm64__)
#define HMDFRAME_ARM_SUPPORT 1
//#include <mach/arm/thread_state.h>
#endif

#ifdef __cplusplus
extern "C" {
#endif
/**
 * @internal
 * @defgroup hmdframe_backtrace Backtrace Frame Walker
 * @ingroup hmd_internal
 *
 * Implements a portable backtrace API. The API is fully async safe, and may be called
 * from any signal handler.
 *
 * The API is modeled on that of the libunwind library.
 *
 * @{
 */

/**
 * @internal
 * @defgroup hmd_backtrace_private Internal API
 * @ingroup hmdframe_backtrace
 *
 * API private to the frame walker implementation.
 *
 * @{
 */

/**
 * Error return codes.
 */
typedef enum {
    /** Success */
    HMDFRAME_ESUCCESS = 0,

    /** Unknown error (if found, is a bug) */
    HMDFRAME_EUNKNOWN,

    /** No more frames */
    HMDFRAME_ENOFRAME,

    /** Bad frame */
    HMDFRAME_EBADFRAME,

    /** Unsupported operation */
    HMDFRAME_ENOTSUP,

    /** Invalid argument */
    HMDFRAME_EINVAL,

    /** Internal error */
    HMDFRAME_INTERNAL,

    /** Bad register number */
    HMDFRAME_EBADREG
} hmdframe_error_t;

/**
 * @internal
 *
 * The current stack frame data
 */
typedef struct hmdframe_stackframe {
    /** Thread state */
    hmd_thread_state_t thread_state;
} hmdframe_stackframe_t;

typedef struct hmdframe_cursor {
    /** The current stack frame data */
    hmdframe_stackframe_t frame;
} hmdframe_cursor_t;

typedef hmdframe_error_t hmdframe_cursor_frame_reader_t(hmd_async_image_list_t *image_list,
                                                        const hmdframe_stackframe_t *current_frame,
                                                        hmdframe_stackframe_t *next_frame);

const char *hmdframe_strerror(hmdframe_error_t error);

hmdframe_error_t hmdframe_cursor_init(hmdframe_cursor_t *cursor,
                                      hmd_thread_state_t *thread_state);

hmd_greg_t hmdframe_cursor_get_pc(hmdframe_cursor_t *cursor);

hmd_greg_t hmdframe_cursor_get_lr(hmdframe_cursor_t *cursor);

hmd_greg_t hmdframe_cursor_get_sp(hmdframe_cursor_t *cursor);

hmd_greg_t hmdframe_cursor_get_fp(hmdframe_cursor_t *cursor);

#if HMD_USE_COMPACT_UNWIND
hmdframe_error_t hmdframe_cursor_next_with_compact_unwind(hmdframe_cursor_t *cursor,
                                                          hmd_async_image_list_t *image_list);
#endif

hmdframe_error_t hmdframe_cursor_next_with_stack_unwind(hmdframe_cursor_t *cursor,
                                                        bool use_lr);


#ifdef __cplusplus
}
#endif

#endif /* HMD_FRAMEWALKER_H */
