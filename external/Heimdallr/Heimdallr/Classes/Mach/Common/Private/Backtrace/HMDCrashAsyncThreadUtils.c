//
//  HMDCrashAsyncThreadUtils.c
//  Pods
//
//  Created by yuanzhangjing on 2019/12/26.
//

#include "HMDCrashAsyncThreadUtils.h"
#include <dispatch/dispatch.h>
#include <pthread.h>

void hmd_perform_on_mainthread(void(^block)(void)) {
    if (pthread_main_np() != 0) {
        if (block) {
            block();
        }
    }else{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (block) {
                block();
            }
        });
    }
}
