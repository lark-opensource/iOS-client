//
//  HMDMainRunloopMonitorV2.m
//  Heimdallr
//
//  Created by ByteDance on 2023/9/6.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CFRunLoop.h>

#import "HMDMainRunloopMonitorV2.h"

#import <CoreFoundation/CFRunLoop.h>
#import <atomic>
#import "NSString+HDMUtility.h"

#import "HMDSwizzle.h"

#import "pthread_extended.h"

static const char *g_UITrackingRunloopMode = NULL;

#pragma mark - UIWindowScreen

@implementation UIWindowScene(HMDMainRunloopMonitorV2)

- (void)hmd_mainRunloopPrepareForSuspendV2 {
    HMDMainRunloopMonitorV2::getInstance()->setRunloopRunning(NO);
    
    [self hmd_mainRunloopPrepareForSuspendV2]; // Prepare期间认为是休眠状态
    
    HMDMainRunloopMonitorV2::getInstance()->setRunloopRunning(YES);
    
    HMDMainRunloopMonitorV2::getInstance()->runloopCount++;
    
}

@end


#pragma mark - HMDMainRunloopMonitorV2


bool HMDMainRunloopMonitorV2::isUITrackingRunloopMode() {
    bool rst = false;
    int lock_rst = pthread_rwlock_rdlock(&this->runloopModeRwLock);
    if (this->runloopMode != NULL && g_UITrackingRunloopMode != NULL && (strcmp(this->runloopMode, g_UITrackingRunloopMode) == 0)) {
        rst = true;
    }
    
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&this->runloopModeRwLock);
    }
    
    return rst;
}

HMDMainRunloopMonitorV2::HMDMainRunloopMonitorV2() : HMDRunloopMonitor(CFRunLoopGetMain(), "com.heimdallr.runloop.observer_v2", 0) {
    
    g_UITrackingRunloopMode = UITrackingRunLoopMode.UTF8String;
    
    if (@available(iOS 13.0, *)) {
        /* -(void)_prepareForSuspend; */
        SEL windowSceneOriginSel = NSSelectorFromString(@"_prepareForSuspend");
        hmd_swizzle_instance_method([UIWindowScene class], windowSceneOriginSel, @selector(hmd_mainRunloopPrepareForSuspendV2));
    }
    
}


