//
//  HMDAsyncDwarfUnwind.c
//  Pods
//
//  Created by yuanzhangjing on 2020/2/4.
//

#include "HMDAsyncDwarfUnwind.h"

#if HMD_USE_DWARF_UNWIND

#include "HMDCrashSDKLog.h"
#include "HMDDwarfUnwind.h"
#include "hmd_logger.h"

__BEGIN_DECLS

hmd_error_t hmd_unwind_with_dwarf(hmd_async_mem_range eh_frame,
                                  hmd_vm_off_t dw_offset,
                                  const hmd_thread_state_t *cur_state,
                                  hmd_thread_state_t *new_state) {

    HMDLOG_TRACE("unwind with dwarf");
    
    HMDDwarfCFIRecord record;

    if (!HMDDwarfParseCFIFromFDERecordOffset(&record, (const void *)eh_frame.addr, dw_offset)) {
        HMDLOG_ERROR("parse cfi error");
      return HMD_ENOTFOUND;
    }

    *new_state = *cur_state;
    if (!HMDDwarfUnwindComputeRegisters(&record, new_state)) {
        HMDLOG_ERROR("compute register error");
      return HMD_ENOTFOUND;
    }
    
    HMDLOG_TRACE("pre fp: %p", hmd_thread_state_get_fp(new_state));
    HMDLOG_TRACE("pre sp: %p", hmd_thread_state_get_sp(new_state));
    HMDLOG_TRACE("pre pc: %p", hmd_thread_state_get_pc(new_state));

    return HMD_ESUCCESS;
}

__END_DECLS

#endif
