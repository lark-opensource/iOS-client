//
//  HMDCrashDetectShared.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/11.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashDetectShared_h
#define HMDCrashDetectShared_h

#include <stdbool.h>
#include <sys/_types.h>
#include <mach/vm_types.h>
#include <mach/mach_types.h>
#include <mach/exception_types.h>

#include "hmd_machine_context.h"
#include "HMDCrashDetect_Private.h"

EXTERN_C

typedef struct hmdcrash_detector_context {
    
    /** crash time since 1970 in sec */
    double crash_time;
    
    /** Address that caused the fault. */
    uintptr_t fault_address;
    
    /** The type of crash that occurred.
     * This determines which other fields are valid. */
    HMDCrashType crash_type;
    
    struct {
        /** The mach exception type. */
        exception_type_t type;
        
        /** The mach exception code. */
        mach_exception_code_t code;
        
        /** The mach exception subcode. */
        mach_exception_subcode_t subcode;
    } mach;
    
    struct {
        /** The exception name. */
        const char *name;
        
        const char *reason;
        
        /** The exception userInfo. */
        const char *user_info;
    } ns_exception;
    
    struct {
        /** The exception name. */
        const char *name;
        const char *description;
    } cpp_exception;
    
    struct {
        /** User context information. */
        const void *user_context;
        int signum;
        int sigcode;
    } signal;
    
    bool asan_detected;
    
} hmdcrash_detector_context_t;

extern void hmd_crash_handler(struct hmd_crash_env_context *envContextPointer, struct hmdcrash_detector_context *crash_detector_context);

EXTERN_C_END

#endif /* HMDCrashDetectShared_h */
