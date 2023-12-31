//
//  BTDDispatch.m
//  ByteDanceKit
//
//  Created by zengkai on 2019/10/21.
//

#import "BTDDispatch.h"

long
bd_dispatch_block_sync_global_queue_wait(NSTimeInterval timeout_seconds, dispatch_block_t block) {
    if (block == nil) return 0;
    
    if ([NSThread isMainThread]) {
        if (timeout_seconds <= 0) {
            timeout_seconds = 0.01;
        }
        dispatch_block_t task_block = dispatch_block_create_with_qos_class(DISPATCH_BLOCK_INHERIT_QOS_CLASS, QOS_CLASS_USER_INITIATED, -8, block);
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), task_block);
        return dispatch_block_wait(task_block, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout_seconds * NSEC_PER_SEC)));
    } else {
        block();
        return 0;
    }
}
