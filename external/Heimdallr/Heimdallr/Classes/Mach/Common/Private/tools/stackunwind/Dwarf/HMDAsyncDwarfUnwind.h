//
//  HMDAsyncDwarfUnwind.h
//  Pods
//
//  Created by yuanzhangjing on 2020/2/4.
//

#ifndef HMDAsyncDwarfUnwind_h
#define HMDAsyncDwarfUnwind_h

#import "HMDDwarfConfig.h"

#if HMD_USE_DWARF_UNWIND

#include <stdio.h>
#include "HMDAsyncImageList.h"
#include "HMDFrameWalker.h"

#ifdef __cplusplus
extern "C" {
#endif

 hmd_error_t hmd_unwind_with_dwarf(hmd_async_mem_range eh_frame,
                                   hmd_vm_off_t dw_offset,
                                   const hmd_thread_state_t *cur_state,
                                   hmd_thread_state_t *new_state);

#ifdef __cplusplus
} // extern "C"
#endif

#endif

#endif /* HMDAsyncDwarfUnwind_h */
