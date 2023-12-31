//
//  BDMonitorThreadManager.m
//  IESWebViewMonitor
//
//  Created by bytedance on 2020/7/27.
//

#import "BDMonitorThreadManager.h"

static const void * const SpecificKey = (const void*)&SpecificKey;
static dispatch_queue_t monitor_queue = nil;

@implementation BDMonitorThreadManager

+ (void)dispatchAsyncHandlerForceOnMainThread:(void(^)(void))handler {
    if ([NSThread isMainThread]) {
        handler();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            handler();
        });
    }
}

+ (void)dispatchSyncHandlerForceOnMainThread:(void(^)(void))handler {
    if ([NSThread isMainThread]) {
        handler();
    } else {
        dispatch_sync(dispatch_get_main_queue(), ^{
            handler();
        });
    }
}

static void checkMonitorQueue() {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor_queue = dispatch_queue_create("com.live.serial.queue", DISPATCH_QUEUE_SERIAL);
        dispatch_queue_set_specific(monitor_queue, SpecificKey, (__bridge void *)(monitor_queue), NULL);
    });
}

+ (void)dispatchAsyncHandlerForceOnMonitorThread:(void (^)(void))handler {
    if (!monitor_queue) {
        checkMonitorQueue();
    }
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(monitor_queue)) {
        handler();
    } else {
        dispatch_async(monitor_queue, ^{
            handler();
        });
    }
}

+ (BOOL)isMonitorThread {
    if (!monitor_queue) {
        checkMonitorQueue();
    }
    if (dispatch_get_specific(SpecificKey) == (__bridge void *)(monitor_queue)) {
        return YES;
    }
    return NO;
}

+ (void)dispatchForceAsyncOnMainThread:(void (^)(void))handler {
    dispatch_async(dispatch_get_main_queue(), ^{
        handler();
    });
}

@end
