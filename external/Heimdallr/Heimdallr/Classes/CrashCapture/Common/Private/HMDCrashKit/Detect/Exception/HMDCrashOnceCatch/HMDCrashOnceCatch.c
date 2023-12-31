//
//  HMDCrashOnceCatch.c
//  CaptainAllred
//
//  Created by sunrunwang on 2019/8/2.
//  Copyright © 2019 sunrunwang. All rights reserved.
//


#include <stdlib.h>
#include <unistd.h>
#include <stdatomic.h>
#include <mach/mach.h>
#include "HMDCrashOnceCatch.h"
#include "HMDCrashSDKLog.h"
#include "HMDCrashDeadLockMonitor.h"

static volatile atomic_bool finish;
static volatile _Atomic(thread_t) thread;

thread_t catch_thread(void) {
    return atomic_load(&thread);
}

bool once_catch(void) {
    static volatile atomic_flag once;
    if (atomic_flag_test_and_set(&once)) {
        return false;
    }

    thread_t thread_self = mach_thread_self();
    atomic_store(&thread, thread_self);
    SDKLog("catch thread:%d",thread);
    
    hmd_crash_start_detect_deadlock();
    
    return true;
}

void wait_catch(void)
{
    SDKLog_warn("crash already happened, wait");
    while(!atomic_load_explicit(&finish, memory_order_acquire)){
        usleep(10000);
    }
    SDKLog_warn("wait finished");
}

void catch_finish(void) {
    atomic_store_explicit(&finish, true, memory_order_release);
}
