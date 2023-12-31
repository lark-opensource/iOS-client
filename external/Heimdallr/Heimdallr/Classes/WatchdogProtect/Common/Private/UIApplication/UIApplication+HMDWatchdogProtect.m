//
//  UIApplication+HMDWatchdogProtect.m
//
//  Created by 白昆仑 on 2020/4/9.
//

#import "UIApplication+HMDWatchdogProtect.h"
#import "HMDSwizzle.h"
#import "HMDWatchdogProtectManager.h"
#import "HMDUserExceptionTracker.h"
#import "pthread_extended.h"
#import "HMDThreadBacktrace.h"
#import "HMDWPUtility.h"
#import "NSString+HDMUtility.h"
#import <UserNotifications/UNUserNotificationCenter.h>
#import "HMDMacro.h"

#if HMD_APPSTORE_REVIEW_FIXUP

void hmd_wp_toggle_application_protection(HMDWPExceptionCallback _Nullable callback) {
    // empty imp
}

#else /* HMD_APPSTORE_REVIEW_FIXUP */

static pthread_rwlock_t lock = PTHREAD_RWLOCK_INITIALIZER;
static HMDWPExceptionCallback exceptionCallback;

static void hmd_wp_application_capture(HMDWPCapture * capture);

@interface HMDWPUIApplication : NSObject
@end

@implementation HMDWPUIApplication

- (BOOL)HMDWPAllowsRemoteNotifications {
     if ([NSThread isMainThread] && exceptionCallback) {
         __block BOOL rst = YES;
         static atomic_flag waitFlag = ATOMIC_FLAG_INIT;
         [HMDWPUtility protectObject:self
                             slector:_cmd
                        skippedDepth:1
                            waitFlag:&waitFlag
                        syncWaitTime:[HMDWatchdogProtectManager sharedInstance].timeoutInterval
                    exceptionTimeout:HMDWPExceptionMaxWaitTime
                   exceptionCallback:^(HMDWPCapture *capture) {
             hmd_wp_application_capture(capture);
         }
                        protectBlock:^{
             rst = [self HMDWPAllowsRemoteNotifications];
         }];
         
         return rst;
     }
     
     return [self HMDWPAllowsRemoteNotifications];
}

@end


@interface UIApplication (HMDWatchdogProtect)
@end @implementation UIApplication (HMDWatchdogProtect)

- (BOOL)HMDWPOpenURL:(NSURL *)url {
    if ([NSThread isMainThread] && exceptionCallback) {
        __block BOOL rst = NO;
        static atomic_flag waitFlag = ATOMIC_FLAG_INIT;
        [HMDWPUtility protectObject:self
                            slector:_cmd
                       skippedDepth:1
                           waitFlag:&waitFlag
                       syncWaitTime:[HMDWatchdogProtectManager sharedInstance].timeoutInterval
                   exceptionTimeout:HMDWPExceptionMaxWaitTime
                  exceptionCallback:^(HMDWPCapture *capture) {
            hmd_wp_application_capture(capture);
        }
                       protectBlock:^{
            rst = [self HMDWPOpenURL:url];
        }];
        
        return rst;
    }
    
    return [self HMDWPOpenURL:url];
}

@end

@implementation UNUserNotificationCenter (HMDWatchdogProtect)

- (id)HMDWPBadgeNumber {
    if ([NSThread isMainThread] && exceptionCallback) {
        // 若BadgeNumbaer == 0, 系统返回nil，此处默认设置为@(0)
        __block id rst = @(0);
        static atomic_flag waitFlag = ATOMIC_FLAG_INIT;
        [HMDWPUtility protectObject:self
                            slector:_cmd
                       skippedDepth:1
                           waitFlag:&waitFlag
                       syncWaitTime:[HMDWatchdogProtectManager sharedInstance].timeoutInterval
                   exceptionTimeout:HMDWPExceptionMaxWaitTime
                  exceptionCallback:^(HMDWPCapture *capture) {
            hmd_wp_application_capture(capture);
        }
                       protectBlock:^{
            rst = [self HMDWPBadgeNumber];
        }];
        
        return rst;
    }
    
    return [self HMDWPBadgeNumber];
}

@end

void hmd_wp_toggle_application_protection(HMDWPExceptionCallback _Nullable callback) {
    int lock_rst = pthread_rwlock_wrlock(&lock);
    exceptionCallback = callback;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&lock);
    }
    
    if (callback) {
        static atomic_flag onceToken = ATOMIC_FLAG_INIT;
        if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
            hmd_swizzle_instance_method([UIApplication class], @selector(openURL:), @selector(HMDWPOpenURL:));
            
            if (@available(iOS 12.0, *)) {
                SEL sel = NSSelectorFromString(@"badgeNumber");
                hmd_swizzle_instance_method([UNUserNotificationCenter class], sel, @selector(HMDWPBadgeNumber));
            }
            
            {
                /*@"PKUserNotificationsRemoteNotificationServiceConnection"*/
                Class class = NSClassFromString([@"UEtVc2VyTm90aWZpY2F0aW9uc1JlbW90ZU5vdGlmaWNhdGlvblNlcnZpY2VDb25uZWN0aW9u" hmd_base64Decode]);
                /*@"allowsRemoteNotifications"*/
                SEL selector = NSSelectorFromString([@"YWxsb3dzUmVtb3RlTm90aWZpY2F0aW9ucw==" hmd_base64Decode]);
                if (class && selector) {
                    hmd_insert_and_swizzle_instance_method(class, selector, [HMDWPUIApplication class], @selector(HMDWPAllowsRemoteNotifications));
                }
            }
        }
    }
}

static void hmd_wp_application_capture(HMDWPCapture * capture) {
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

#endif /* HMD_APPSTORE_REVIEW_FIXUP */
