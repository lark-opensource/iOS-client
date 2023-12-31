//
//  HMDWPYYCache.m
//  AWECloudCommand
//
//  Created by 曾凯 on 2020/6/4.
//

#import "HMDWPYYCache.h"
#import "HMDSwizzle.h"
#import "HMDWatchdogProtectManager.h"
#import "pthread_extended.h"
#import "NSString+HDMUtility.h"
#import "HMDWPUtility.h"
#import <UIKit/UIKit.h>

static pthread_rwlock_t lock = PTHREAD_RWLOCK_INITIALIZER;
static HMDWPExceptionCallback exceptionCallback;

static void hmd_wp_nsuserdefault_capture(HMDWPCapture * capture);

@implementation NSUserDefaults (HMDWatchdogProtect)

- (id)HMDWPObjectForKey:(NSString *)defaultName {
    if ([NSThread isMainThread] && exceptionCallback) {
        __block id rst = nil;
        static atomic_flag waitFlag = ATOMIC_FLAG_INIT;
        [HMDWPUtility protectObject:self
                            slector:_cmd
                       skippedDepth:1
                           waitFlag:&waitFlag
                       syncWaitTime:[HMDWatchdogProtectManager sharedInstance].timeoutInterval
                   exceptionTimeout:HMDWPExceptionMaxWaitTime
                  exceptionCallback:^(HMDWPCapture *capture) {
            hmd_wp_nsuserdefault_capture(capture);
        }
                       protectBlock:^{
            rst = [self HMDWPObjectForKey:defaultName];
        }];
        
        return rst;
    }
    
    return [self HMDWPObjectForKey:defaultName];
}

- (void)HMDWPSetObject:(id)value forKey:(NSString *)defaultName {
    if ([NSThread isMainThread] && exceptionCallback) {
        static atomic_flag waitFlag = ATOMIC_FLAG_INIT;
        [HMDWPUtility protectObject:self
                            slector:_cmd
                       skippedDepth:1
                           waitFlag:&waitFlag
                       syncWaitTime:[HMDWatchdogProtectManager sharedInstance].timeoutInterval
                   exceptionTimeout:HMDWPExceptionMaxWaitTime
                  exceptionCallback:^(HMDWPCapture *capture) {
            hmd_wp_nsuserdefault_capture(capture);
        }
                       protectBlock:^{
            [self HMDWPSetObject:value forKey:defaultName];
        }];
    }
    else {
        [self HMDWPSetObject:value forKey:defaultName];
    }
}

@end

void hmd_wp_toggle_nsuserdefault_protection(HMDWPExceptionCallback _Nullable callback) {
    int lock_rst = pthread_rwlock_wrlock(&lock);
    exceptionCallback = callback;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&lock);
    }
    
    if (callback) {
        static atomic_flag onceToken = ATOMIC_FLAG_INIT;
        if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
            hmd_swizzle_instance_method([NSUserDefaults class], @selector(objectForKey:), @selector(HMDWPObjectForKey:));
            hmd_swizzle_instance_method([NSUserDefaults class], @selector(setObject:forKey:), @selector(HMDWPSetObject:forKey:));
        }
    }
}

static void hmd_wp_nsuserdefault_capture(HMDWPCapture * capture) {
    if (!capture) {
        return;
    }
    
    int lock_rst = pthread_rwlock_rdlock(&lock);
    HMDWPExceptionCallback callback = exceptionCallback;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&lock);
    }
    
    if (callback) {
        callback(capture);
    }
}
