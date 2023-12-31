//
//  HMDCrashDetectMach.h
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/11.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#ifndef HMDCrashDetectMach_h
#define HMDCrashDetectMach_h

#include <stdbool.h>
#include "HMDCrashDetect_Private.h"
#include <mach/mach.h>
#include <mach/exc.h>

EXTERN_C

#pragma pack(4)
typedef struct {
    mach_msg_header_t Head;
    /* start of the kernel processed data */
    mach_msg_body_t msgh_body;
    mach_msg_port_descriptor_t thread;
    mach_msg_port_descriptor_t task;
    /* end of the kernel processed data */
    NDR_record_t NDR;
    exception_type_t exception;
    mach_msg_type_number_t codeCnt;
    mach_exception_data_type_t code[0];
    /* some times RCV_TO_LARGE probs */
    char pad[512];
} hmd_exc_msg;
#pragma pack()

#pragma pack(4)
typedef struct {
    mach_msg_header_t Head;
    NDR_record_t NDR;
    kern_return_t RetCode;
} hmd_reply_msg;
#pragma pack()

void HMDCrashDetect_mach_start(void);
void HMDCrashDetect_mach_end(void);
bool HMDCrashDetect_mach_check(void);

#pragma mark - Mach Exception Recover

// return true if protection success
typedef bool (*hmd_mach_recover_function_t)(task_t task,
                                            thread_t thread,
                                            NDR_record_t record,
                                            exception_type_t exception_type,
                                            mach_msg_type_number_t exception_code);

// require atomic access
extern hmd_mach_recover_function_t hmd_mach_recover_handle;

EXTERN_C_END

#endif /* HMDCrashDetectMach_h */
