//
//  ACCMacrosTool.m
//  CreativeKit-Pods-Aweme
//
//  Created by lixingdong on 2021/1/10.
//

#import "ACCMacrosTool.h"

extern void acc_dispatch_queue_async_safe(dispatch_queue_t queue, dispatch_block_t block)
{
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {
        block();
    } else {
        dispatch_async(queue, block);
    }
}

extern void acc_dispatch_main_async_safe(dispatch_block_t block)
{
    acc_dispatch_queue_async_safe(dispatch_get_main_queue(), block);
}

extern void acc_dispatch_main_thread_async_safe(dispatch_block_t block)
{
    if ([NSThread isMainThread]) {
        block();
    } else {
        dispatch_async(dispatch_get_main_queue(), block);
    }
}

BOOL ACC_isEmptyString(NSString *param)
{
    return ( !(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO) );
}

BOOL ACC_isEmptyArray(NSArray *param)
{
    return ( !(param) ? YES : ([(param) isKindOfClass:[NSArray class]] ? (param).count == 0 : NO) );
}

BOOL ACC_isEmptyDictionary(NSDictionary *param)
{
    return ( !(param) ? YES : ([(param) isKindOfClass:[NSDictionary class]] ? (param).count == 0 : NO) );
}
