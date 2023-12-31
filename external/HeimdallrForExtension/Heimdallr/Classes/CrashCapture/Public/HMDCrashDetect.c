//
//  HMDCrashDetect.m
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/11.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#import "HMDCrashDetect.h"
#import "HMDCrashDetect_Private.h"
#include "HMDCrashDetectMach.h"
#include "HMDCrashDetectCPP.h"
#include "HMDCrashDetectFatalSignal.h"
#include "HMDCrashSDKLog.h"
#include <stdlib.h>
#include "hmd_debug.h"

#include <pthread.h>
#include <mach/mach_init.h>
#include <stdatomic.h>
#include <dispatch/dispatch.h>
#include "HMDCrashOnceCatch.h"
#include "HMDCrashDeadLockMonitor.h"
#include "HMDCrashKitSwitch.h"

#define SIZE(array) (sizeof(array) / sizeof((array)[0]))

static hmd_detector_t all_detects[] = {
    {
        .type  = HMDCrashTypeMachException                                      ,
        .start = HMDCrashDetect_mach_start                                      ,
        .end   = HMDCrashDetect_mach_end                                        ,
        .check = HMDCrashDetect_mach_check                                      ,
    },
    {
        .type  = HMDCrashTypeCPlusPlus                                          ,
        .start = HMDCrashDetect_cpp_start                                       ,
        .end   = HMDCrashDetect_cpp_end                                         ,
        .check = HMDCrashDetect_cpp_check,
    },
    {
        .type  = HMDCrashTypeFatalSignal                                        ,
        .start = HMDCrashDetect_signal_start                                    ,
        .end   = HMDCrashDetect_signal_end                                      ,
        .check = HMDCrashDetect_signal_check,
    },
};

static void hmdcrash_exit_callback()
{
    SDKLog_warn("exit called!!!");
    if (hmd_crash_switch_state(HMDCrashSwitchIgnoreExitByUser)) {
        HMDCrashStopDetect();
    }
    
    pthread_t p_th = pthread_self(); //async safe
    const char *queue_name = dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL);
    char thread_name[128];
    thread_name[0] = 0;
    pthread_getname_np(p_th, thread_name, sizeof(thread_name));
    thread_name[127] = 0;//just for safe
    
    thread_t current_thread = mach_thread_self();
    SDKLog_warn("[%d][%s][%s] calling exit()",current_thread,queue_name,thread_name);

    thread_t capture_thread = catch_thread();
    if (capture_thread > 0 && capture_thread != current_thread) {
        SDKLog_warn("[%d]wait first crash capture finish",capture_thread);
        wait_catch();
        SDKLog_warn("wait finished");
    }
    SDKLog_warn("process exiting");
}

void HMDCrashStartDetect(void)
{
    static atomic_flag setup;
    if (atomic_flag_test_and_set_explicit(&setup, memory_order_relaxed)) {
        return;
    }

#if !(defined(DEBUG))
    if (hmddebug_isBeingTraced()) {
        return;
    }
#endif
    
    atexit(hmdcrash_exit_callback);
    
    for(size_t index = 0; index < SIZE(all_detects); index++)
        all_detects[index].start();
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SDKLog("check crash handler in 100ms");
        HMDCrashCheckHandler();
    });
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SDKLog("check crash handler in 3000ms");
        HMDCrashCheckHandler();
    });
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (!hmd_crash_init_detect_deadlock()) {
            SDKLog_error("init detect deadlock failed");
        }
    });
}

void HMDCrashStopDetect(void) {
    for(size_t index = 0; index < SIZE(all_detects); index++)
        all_detects[index].end();
    
    hmd_crash_stop_detect_deadlock();
}

void HMDCrashStopDetectPortion(HMDCrashType except_type) {
    for (size_t index = 0; index < SIZE(all_detects); index++) {
        if (all_detects[index].type != except_type) {
            all_detects[index].end();
        }
    }
}

void HMDCrashCheckHandler(void)
{
    for(size_t index = 0; index < SIZE(all_detects); index++)
        all_detects[index].check();
}
