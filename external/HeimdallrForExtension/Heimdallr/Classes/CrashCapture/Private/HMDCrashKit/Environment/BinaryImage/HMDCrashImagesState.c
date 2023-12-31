//
//  HMDCrashImagesState.c
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/8/22.
//

#include "HMDCrashImagesState.h"
#include <stdatomic.h>
#include <unistd.h>

static atomic_bool finished;

void HMDCrashMarkImagesFinish(void)
{
    atomic_store_explicit(&finished,true,memory_order_release);
    atomic_thread_fence(memory_order_release);
}

long long HMDCrashWaitForImagesSetupFinish(long long timeout)
{
    long long times = 0;
    while (!atomic_load_explicit(&finished,memory_order_acquire)) {
        usleep(1000);
        times ++;
        if (timeout > 0 && times >= timeout) {
            return -1; //time out
        }
    }
    return  times;
}
