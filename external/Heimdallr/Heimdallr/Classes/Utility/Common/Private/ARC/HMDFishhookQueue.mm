//
//  HMDFishhookQueue.m
//  Pods
//
//  Created by xushuangqing on 2022/5/25.
//

#import "HMDFishhookQueue.h"
#import <atomic>

extern "C" dispatch_queue_t hmd_fishhook_queue(void) {
    static dispatch_queue_t fishhookQueue;
    static std::atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, std::memory_order_acq_rel)) {
        fishhookQueue = dispatch_queue_create("com.Heimdallr.fishhookQueue", dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INITIATED, 0));
    }
    return fishhookQueue;
}
