//
//  HMDCrashAppExitReasonMark.c
//  Pods
//
//  Created by yuanzhangjing on 2019/12/30.
//

#include <mach/mach.h>
#include <stdatomic.h>

#include "HMDMacro.h"
#include "HMDCrashAppExitReasonMark.h"

static atomic_uintptr_t sharedFlagAddress;

static bool read_memory(void * _Nonnull from, void * _Nonnull to, vm_size_t size);

void HMDCrashKit_registerAppExitReasonMark(bool * _Nullable flag) {
    atomic_store_explicit(&sharedFlagAddress, (uintptr_t)flag, memory_order_release);
}

void HMDCrashKit_markAppExitReasonCrash(void) {
    uintptr_t address_raw = atomic_load_explicit(&sharedFlagAddress, memory_order_acquire);
    if(address_raw == 0x0) return;
    if(!VM_ADDRESS_CONTAIN(address_raw)) DEBUG_RETURN_NONE;
    
    bool * _Nonnull address = (bool *)address_raw;
    
    bool markTrue = true;
    read_memory(&markTrue, address, sizeof(bool));
}

static bool read_memory(void * _Nonnull from, void * _Nonnull to, vm_size_t size) {
    if(from == NULL || to == NULL) DEBUG_RETURN(false);
    // safe memory access
    vm_size_t storage_size = size;
    if(vm_read_overwrite(mach_task_self(), (vm_address_t)from, size, (vm_address_t)to, &storage_size) == KERN_SUCCESS)
        return true;
    ELSE_DEBUG_RETURN(false);
}
