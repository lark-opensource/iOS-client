//
//  HMDProtectNSNotification.m
//  Heimdallr
//
//  Created by fengyadong on 2018/4/10.
//

#import <stdatomic.h>
#import "HMDSwizzle.h"
#import "HeimdallrUtilities.h"
#import "HMDProtectNSNotification.h"
#import "HMDNotificationCenter.h"
#import "HMDNotificationConnection.h"
#import "HMDAppleBacktracesLog.h"
#import "hmd_thread_backtrace.h"

static pthread_key_t g_pthread_key;
static pthread_rwlock_t g_rwlock = PTHREAD_RWLOCK_INITIALIZER;
static HMDProtectCaptureBlock _Nullable _internal_Notification_captureBlock = nil;
static void NSNotificationCenter_replaceImplementation(void);
static BOOL shouldProtectNotificationForObserver(NSNotificationCenter * _Nonnull thisSelf, NSObject *_Nullable observer);
static NSMutableSet<NSString*>* crashKeySet = nil;

#pragma mark - Implementation

@implementation NSNotificationCenter (HMDProtectNSNotification)

- (void)HMDP_addObserver:(id)observer selector:(SEL)aSelector name:(NSNotificationName)aName object:(id)anObject {
    if (!_internal_Notification_captureBlock) {
        [self HMDP_addObserver:observer selector:aSelector name:aName object:anObject];
        return;
    }
    
    if (!shouldProtectNotificationForObserver(self, observer)) {
        [self HMDP_addObserver:observer selector:aSelector name:aName object:anObject];
        return;
    }
    
    HMDProtectCapture *capture = [HMDNotificationCenter.sharedInstance addObserver:observer selector:aSelector name:aName object:anObject];
    if (capture) {
        HMD_Protect_Notification_captureException(capture);
    }
}

- (void)HMDP_removeObserver:(id)observer {
    if (!_internal_Notification_captureBlock) {
        [self HMDP_removeObserver:observer];
        return;
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        [self HMDP_removeObserver:observer];
        return;
    }
    
    if (!shouldProtectNotificationForObserver(self, observer)) {
        [self HMDP_removeObserver:observer];
        return;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        HMDProtectCapture *capture = [HMDNotificationCenter.sharedInstance removeObserver:observer];
        if (capture) {
            HMD_Protect_Notification_captureException(capture);
        }
    }
    @catch (NSException *exception) {
        HMDProtectCapture *systemCapture = [HMDProtectCapture captureWithNSException:exception];
        HMD_Protect_Notification_captureException(systemCapture);
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

- (void)HMDP_removeObserver:(id)observer name:(NSNotificationName)aName object:(id)anObject {
    if (!_internal_Notification_captureBlock) {
        [self HMDP_removeObserver:observer name:aName object:anObject];
        return;
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        [self HMDP_removeObserver:observer name:aName object:anObject];
        return;
    }
    
    if (!shouldProtectNotificationForObserver(self, observer)) {
        [self HMDP_removeObserver:observer name:aName object:anObject];
        return;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        HMDProtectCapture *capture = [HMDNotificationCenter.sharedInstance removeObserver:observer name:aName object:anObject];
        if (capture) {
            HMD_Protect_Notification_captureException(capture);
        }
        
        
    }
    @catch (NSException *exception) {
        HMDProtectCapture *systemCapture = [HMDProtectCapture captureWithNSException:exception];
        HMD_Protect_Notification_captureException(systemCapture);
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

@end

#pragma mark - Foundation

void HMD_Protect_toggle_Notification_protection(HMDProtectCaptureBlock captureBlock) {
    if(@available(iOS 9.0, *)) {
        return;
    }
    
    int lock_rst = pthread_rwlock_wrlock(&g_rwlock);
    _internal_Notification_captureBlock = captureBlock;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_rwlock);
    }
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        crashKeySet = [[NSMutableSet alloc] init];
        NSNotificationCenter_replaceImplementation();
    }
}

static void NSNotificationCenter_replaceImplementation(void) {
    pthread_key_create(&g_pthread_key, NULL);
    Class NotificationClass = NSNotificationCenter.class;
    hmd_swizzle_instance_method(NotificationClass, @selector(removeObserver:), @selector(HMDP_removeObserver:));
    hmd_swizzle_instance_method(NotificationClass, @selector(removeObserver:name:object:), @selector(HMDP_removeObserver:name:object:));
    // 注意：add方法一定要放在最后，如果add先生效，通过代理添加了Notification，此时remove不通过代理就会崩溃
    hmd_swizzle_instance_method(NotificationClass, @selector(addObserver:selector:name:object:), @selector(HMDP_addObserver:selector:name:object:));
}

void HMD_NO_OPT_ATTRIBUTE HMD_Protect_Notification_captureException(HMDProtectCapture * _Nonnull capture) {
    if (!capture) {
        return;
    }
    HMDProtect_BDALOG(capture.reason);
    HMDProtectBreakpoint();
    HMDLog(@"[Heimdallr][Protector] Notification exception");
    int lock_rst = pthread_rwlock_rdlock(&g_rwlock);
    HMDProtectCaptureBlock captureBlock = _internal_Notification_captureBlock;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_rwlock);
    }
    
    if(captureBlock) {
        HMDThreadBacktrace *bt = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:NO skippedDepth:2 suspend:NO];
        if (bt) {
            capture.backtraces = @[bt];
            capture.crashKeySet = (NSMutableSet<id>*)crashKeySet;
            captureBlock(capture);
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION
}

static BOOL shouldProtectNotificationForObserver(NSNotificationCenter * _Nonnull thisSelf, NSObject *_Nullable observer) {
    if(observer == nil) {
        return YES;
    }
    
    if([observer isKindOfClass:HMDNotificationConnection.class]) {
        return NO;
    }
    
    if(![HeimdallrUtilities isClassFromApp:[observer class]]) {
        return NO;
    }
    
    return YES;
}
