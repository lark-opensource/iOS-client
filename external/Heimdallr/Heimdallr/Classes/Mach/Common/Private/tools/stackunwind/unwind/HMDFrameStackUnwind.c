//
//  HMDFrameStackUnwind.c
//
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/6/4.
//
#include "HMDFrameStackUnwind.h"
#define HMDLogger_LocalLevel INFO
#include "hmd_logger.h"
#include "hmd_types.h"

hmdframe_error_t hmdframe_unwind_with_lr(const hmdframe_stackframe_t *current_frame, hmdframe_stackframe_t *next_frame) {
    hmd_greg_t lr = hmd_thread_state_get_lr(&current_frame->thread_state);
    HMDLOG_TRACE("cur lr: %p",lr);
    if (!HMD_IS_VALID_PTR(lr)) {
        HMDLOG_ERROR("cur lr: %p",lr);
        return HMDFRAME_EINVAL;
    }
    
    *next_frame = *current_frame;

    hmd_thread_state_set_pc(&next_frame->thread_state, lr);
    
    HMDLOG_TRACE("pre pc: %p", hmd_thread_state_get_pc(&next_frame->thread_state));
    HMDLOG_INFO("unwind with lr : %p", lr);
    return HMDFRAME_ESUCCESS;
}

hmdframe_error_t hmdframe_cursor_read_frame_ptr(const hmdframe_stackframe_t *current_frame,
                                                hmdframe_stackframe_t *next_frame,
                                                bool use_lr) {
    if (!current_frame || !next_frame) {
        return HMDFRAME_EINVAL;
    }
    
    HMDLOG_TRACE("use stack_unwind");
    if (use_lr) {
        if (hmdframe_unwind_with_lr(current_frame, next_frame) == HMDFRAME_ESUCCESS) {
            return HMDFRAME_ESUCCESS;
        }
    }
    
    HMDLOG_TRACE("unwind with fp");

    hmd_greg_t fp = hmd_thread_state_get_fp(&current_frame->thread_state);
    HMDLOG_TRACE("cur fp: %p", fp);
    if (!HMD_IS_VALID_PTR(fp)) {
        HMDLOG_ERROR("fp is invalid %p, ending",fp);
        return HMDFRAME_ENOFRAME;
    }
    
    hmd_greg_t sp = hmd_thread_state_get_sp(&current_frame->thread_state);
    HMDLOG_TRACE("cur sp: %p", sp);
    if (!HMD_IS_VALID_PTR(sp)) {
        HMDLOG_ERROR("sp is invalid %p, ending",sp);
        return HMDFRAME_ENOFRAME;
    }
    
    if (fp < sp) {
        HMDLOG_ERROR("fp is smaller than sp, wrong direction fp:%x sp:%x, ending",fp,sp);
        return HMDFRAME_ENOFRAME;
    }
    
    hmd_greg_t pc = hmd_thread_state_get_pc(&current_frame->thread_state);
    HMDLOG_TRACE("cur pc: %p", pc);
    if (!HMD_IS_VALID_PTR(pc)) {
        HMDLOG_ERROR("pc is invalid %p, ending",pc);
        return HMDFRAME_ENOFRAME;
    }
    
    uintptr_t dest[2];
    size_t len = sizeof(dest);

    /* Read the registers off the stack via the frame pointer */
    hmd_error_t err = hmd_async_read_memory((hmd_vm_address_t)fp, dest, len);
    if (err != HMD_ESUCCESS) {
        HMDLOG_ERROR("Failed to read frame");
        return HMDFRAME_EBADFRAME;
    }

    next_frame->thread_state = current_frame->thread_state;

    hmd_thread_state_set_fp(&next_frame->thread_state, dest[0]);
    hmd_thread_state_set_pc(&next_frame->thread_state, dest[1]);
    hmd_thread_state_set_sp(&next_frame->thread_state, fp + len);
        
    hmd_greg_t pre_pc = hmd_thread_state_get_pc(&next_frame->thread_state);
    
    HMDLOG_TRACE("pre fp: %p", hmd_thread_state_get_fp(&next_frame->thread_state));
    HMDLOG_TRACE("pre sp: %p", hmd_thread_state_get_sp(&next_frame->thread_state));
    HMDLOG_TRACE("pre pc: %p", pre_pc);

    //check if the terminal frame
    if (!HMD_IS_VALID_PTR(pre_pc)) {
        HMDLOG_ERROR("pre_pc is invalid %p, ending",pre_pc);
        return HMDFRAME_ENOFRAME;
    }
    
    return HMDFRAME_ESUCCESS;
}
