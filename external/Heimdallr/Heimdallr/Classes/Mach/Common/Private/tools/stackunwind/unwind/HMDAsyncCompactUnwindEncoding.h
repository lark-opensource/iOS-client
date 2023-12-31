//
//  HMDAsyncCompactUnwindEncoding.h
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#ifndef HMD_ASYNC_COMPACT_UNWIND_ENCODING_H
#define HMD_ASYNC_COMPACT_UNWIND_ENCODING_H 1

#include "HMDCompactUnwindConfig.h"

#if HMD_USE_COMPACT_UNWIND

#include "HMDAsyncImageList.h"
#include "HMDAsyncThreadState.h"
#include "hmd_types.h"
#include <mach-o/compact_unwind_encoding.h>

/**
 * @internal
 * @ingroup hmd_async_cfe
 * @{
 */


hmd_error_t hmd_async_cfe_lookup_and_compute(hmd_async_image_t *image,
                                             const hmd_thread_state_t *cur_state,
                                             hmd_thread_state_t *new_state);

/**
 * @} hmd_async_cfe
 */

#endif

#endif /* HMD_ASYNC_COMPACT_UNWIND_ENCODING_H */
