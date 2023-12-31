//
//  HMDFrameCompactUnwind.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#include "HMDFrameCompactUnwind.h"

#if HMD_USE_COMPACT_UNWIND

#include "HMDAsyncCompactUnwindEncoding.h"
#define HMDLogger_LocalLevel INFO
#include <inttypes.h>
#import "hmd_logger.h"

hmdframe_error_t hmdframe_cursor_read_compact_unwind(hmd_async_image_list_t *image_list,
                                                     const hmdframe_stackframe_t *current_frame,
                                                     hmdframe_stackframe_t *next_frame) {
    HMDLOG_TRACE("use compact_unwind");
    hmdframe_error_t result;
    hmd_error_t err;
   
    hmd_greg_t fp = hmd_thread_state_get_fp(&current_frame->thread_state);
    HMDLOG_TRACE("cur fp: %p", fp);
    if (!HMD_IS_VALID_PTR(fp)) {
       HMDLOG_ERROR("fp is invalid %p",fp);
       return HMDFRAME_EBADFRAME;
    }
    hmd_greg_t sp = hmd_thread_state_get_sp(&current_frame->thread_state);
    HMDLOG_TRACE("cur sp: %p", sp);
    if (!HMD_IS_VALID_PTR(sp)) {
        HMDLOG_ERROR("sp is invalid %p",sp);
        return HMDFRAME_EBADFRAME;
    }
    
    if (fp < sp) { //有些情况下fp与sp相等，如 libc++abi.dylib`std::terminate，没有自己的frame
        HMDLOG_ERROR("fp is smaller than sp, wrong direction fp:%p sp:%p, ending",fp,sp);
        return HMDFRAME_ENOFRAME;
    }
    hmd_greg_t pc = hmd_thread_state_get_pc(&current_frame->thread_state);
    HMDLOG_TRACE("cur pc: %p", pc);
    if (!HMD_IS_VALID_PTR(pc)) {
        HMDLOG_ERROR("pc is invalid %p",pc);
        return HMDFRAME_EBADFRAME;
    }
    
    /* Find the corresponding image */
    hmd_async_image_list_set_reading(image_list, true);
    hmd_async_image_t *image = hmd_async_image_containing_address(image_list, (hmd_vm_address_t)pc);
    if (image == NULL) {
        HMDLOG_ERROR("Could not find a loaded image for the current frame pc: %p", pc);
        result = HMDFRAME_ENOTSUP;
        goto cleanup;
    }

    hmd_async_mem_range unwind_info = image->macho_image.unwind_info;
    if (unwind_info.size <= 0) {
        result = HMDFRAME_EINVAL;
        HMDLOG_ERROR("image:%s don't have unwind info", image->macho_image.name);
        goto cleanup;
    }

    /* Initialize the CFE reader. */    
    err = hmd_async_cfe_lookup_and_compute(image, &current_frame->thread_state, &next_frame->thread_state);
    if (err != HMD_ESUCCESS) {
        HMDLOG_ERROR("cfe lookup failed");
        result = HMDFRAME_EINVAL;
        goto cleanup;
    }
    
    HMDLOG_TRACE("cfe lookup success");
    result = HMDFRAME_ESUCCESS;
    
cleanup:
    hmd_async_image_list_set_reading(image_list, false);
    return result;
}

#endif
