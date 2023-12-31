//
//  HMDFrameStackUnwind.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#ifndef HMD_FRAME_STACKUNWIND_H
#define HMD_FRAME_STACKUNWIND_H

#ifdef __cplusplus
extern "C" {
#endif

#include "HMDFrameWalker.h"

hmdframe_error_t hmdframe_cursor_read_frame_ptr(const hmdframe_stackframe_t *current_frame,
                                                hmdframe_stackframe_t *next_frame,
                                                bool use_lr);

#ifdef __cplusplus
}
#endif

#endif /* HMD_FRAME_STACKUNWIND_H */
