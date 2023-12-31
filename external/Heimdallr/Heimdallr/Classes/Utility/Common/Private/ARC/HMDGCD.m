//
//  HMDGCD.m
//  Pods
//
//  Created by 白昆仑 on 2020/5/29.
//

#import "HMDGCD.h"

void hmd_safe_dispatch_async(dispatch_queue_t queue, dispatch_block_t block) {
    if (!block || !queue) {
        return;
    }
    
    dispatch_async(queue, ^{
        @autoreleasepool {
            block();
        }
    });
}

void hmd_safe_dispatch_after(dispatch_time_t when, dispatch_queue_t queue, dispatch_block_t block) {
    if (!block || !queue) {
        return;
    }
    
    dispatch_after(when, queue, ^{
        @autoreleasepool {
            block();
        }
    });
}
