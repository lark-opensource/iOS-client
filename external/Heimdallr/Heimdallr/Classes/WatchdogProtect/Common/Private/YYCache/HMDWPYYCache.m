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

static void hmd_wp_yycache_capture(HMDWPCapture * capture);

@interface HMDWPYYCache : NSObject
@end

@implementation HMDWPYYCache

-(id)HMDWPObjectForKey:(id)arg1 {
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
            hmd_wp_yycache_capture(capture);
        }
                       protectBlock:^{
            rst = [self HMDWPObjectForKey:arg1];
        }];
        
        return rst;
    }
    
    return [self HMDWPObjectForKey:arg1];
}

@end

void hmd_wp_toggle_yycache_protection(HMDWPExceptionCallback _Nullable callback) {
    int lock_rst = pthread_rwlock_wrlock(&lock);
    exceptionCallback = callback;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&lock);
    }
    
    if (callback) {
        static atomic_flag onceToken = ATOMIC_FLAG_INIT;
        if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
            Class class = NSClassFromString(@"YYDiskCache");
            SEL selector = NSSelectorFromString(@"objectForKey:");
            if (class && selector) {
                hmd_insert_and_swizzle_instance_method(class, selector, [HMDWPYYCache class], @selector(HMDWPObjectForKey:));
            }
        }
    }
}

static void hmd_wp_yycache_capture(HMDWPCapture * capture) {
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
