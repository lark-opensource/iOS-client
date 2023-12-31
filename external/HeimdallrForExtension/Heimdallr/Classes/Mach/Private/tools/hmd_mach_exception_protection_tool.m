//
//  hmd_mach_exception_protection_tool.m
//  Heimdallr
//
//  Created by bytedance on 2022/9/6.
//

#include <stddef.h>
#import "HMDMacro.h"
#include "hmd_mach_exception_protection_tool.h"

static HMDMachExceptionFunction_t shared_mach_exception_function = NULL;

bool HMDCrashPreventMachExceptionProtect_internal(const char * _Nonnull scope,
                                                  HMDMachRecoverOption option,
                                                  HMDMachRecoverContextRef _Nullable context,
                                                  void(^ _Nonnull block)(void)) {
    DEBUG_ASSERT(scope != NULL);
    DEBUG_ASSERT(block != nil);
    
    HMDMachExceptionFunction_t _Nullable exception_function;
    if((exception_function = __atomic_load_n(&shared_mach_exception_function, __ATOMIC_ACQUIRE)) != NULL) {
        if(VM_ADDRESS_CONTAIN(exception_function)) {
            return exception_function(scope, option, context, block);
        } DEBUG_ELSE
    }
    if(block != nil) block();
    return false;
}

void HMDCrashPreventMachExceptionProtect_internal_register(HMDMachExceptionFunction_t _Nonnull exception_function) {
    DEBUG_ASSERT(exception_function != NULL);
    __atomic_store_n(&shared_mach_exception_function, exception_function, __ATOMIC_RELEASE);
}
