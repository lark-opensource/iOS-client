//
//  HMDFrameCompactUnwind.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#ifndef HMD_FRAME_COMPACTUNWIND_H
#define HMD_FRAME_COMPACTUNWIND_H

#include "HMDFrameWalker.h"

#if HMD_USE_COMPACT_UNWIND

#ifdef __cplusplus
extern "C" {
#endif

hmdframe_error_t hmdframe_cursor_read_compact_unwind(hmd_async_image_list_t *image_list,
                                                     const hmdframe_stackframe_t *current_frame,
                                                     hmdframe_stackframe_t *next_frame);

#ifdef __cplusplus
}
#endif

#endif

#endif /* HMD_FRAME_COMPACTUNWIND_H */
