//
//  HMDProtectUserDefaults.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/7.
//

#import <stdatomic.h>
#import "HMDMacro.h"
#import "HMDProtectUserDefaults.h"
#import "HMDSwizzle.h"
#import "HMDAppleBacktracesLog.h"

static pthread_rwlock_t g_rwlock = PTHREAD_RWLOCK_INITIALIZER;
static HMDProtectCaptureBlock _Nullable _internal_UserDefaults_captureBlock = nil;
static void HMD_Protect_UserDefaults_handle_exception(HMDProtectCapture *capture);
static NSMutableSet<NSString *>* crashKeySet = nil;

#pragma mark - UserDefaults

@interface NSUserDefaults (HMDProtect)

- (void)HMDSetObject:(id)value forKey:(NSString *)defaultName;

@end

@implementation NSUserDefaults (HMDProtect)

#if !HMD_APPSTORE_REVIEW_FIXUP

// protect method that series of objectForKey:
- (id)HMDCopyAppValueForKey:(NSString *)key
                 identifier:(id)identifier
                  container:(id)container
           configurationURL:(id)url {
    if (!key) {
        key = @"";
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"MACH_Exception" reason:@"MACH_Exception EXC_BREAKPOINT EXC_ARM_BREAKPOINT [NSUserDefault] : key is nil"];
        HMD_Protect_UserDefaults_handle_exception(capture);
    }
    
    return [self HMDCopyAppValueForKey:key identifier:identifier container:container configurationURL:url];
}

#endif

- (void)HMDSetObject:(id)value forKey:(NSString *)defaultName {
    if (_internal_UserDefaults_captureBlock) {
        // Don't crash after iOS 13.0
        if (@available(iOS 13.0, *)) {
            // do nothing...
        }
        else {
            if (!defaultName) {
                defaultName = @"";
                NSString *selfClassName = NSStringFromClass([self class]);
                NSString *crashKey = [NSString stringWithFormat:@"MACH_Exception EXC_BREAKPOINT EXC_ARM_BREAKPOINT -[%@ setObject:forKey:] : key is nil", selfClassName];
                HMDProtectCapture *capture = [HMDProtectCapture captureException:@"MACH_Exception" reason:crashKey];
                HMD_Protect_UserDefaults_handle_exception(capture);
            }
        }
        
        @try {
            [self HMDSetObject:value forKey:defaultName];
        }
        @catch (NSException *exception) {
            if (!hmd_upper_trycatch_effective(1)) {
                NSString *selfClassName = NSStringFromClass([self class]);
                NSString *objectClassName = NSStringFromClass([value class]);
                NSString *crashKey = [NSString stringWithFormat:@"[%@ setObject:%@ forKey:%@]", selfClassName, objectClassName, defaultName];
                HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
                HMD_Protect_UserDefaults_handle_exception(capture);
            }
        }
    }
    else {
        [self HMDSetObject:value forKey:defaultName];
    }
}

@end

#pragma mark - Foundation

void HMD_Protect_toggle_UserDefaults_protection(HMDProtectCaptureBlock captureBlock) {
    int lock_rst = pthread_rwlock_wrlock(&g_rwlock);
    _internal_UserDefaults_captureBlock = captureBlock;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_rwlock);
    }
    
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(captureBlock && !atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        crashKeySet = [[NSMutableSet alloc] init];
        hmd_swizzle_instance_method([NSUserDefaults class], @selector(setObject:forKey:), @selector(HMDSetObject:forKey:));
        
        #if !HMD_APPSTORE_REVIEW_FIXUP
        
        // Don't crash after iOS 13.0
        if (@available(iOS 13.0, *)) return;
        
        Class originClass = objc_getClass("_CFXPreferences");
        SEL originSel = NSSelectorFromString(@"copyAppValueForKey:identifier:container:configurationURL:");
        hmd_insert_and_swizzle_instance_method(originClass, originSel, [NSUserDefaults class], @selector(HMDCopyAppValueForKey:identifier:container:configurationURL:));
        
        #endif
    }
}

static void HMD_NO_OPT_ATTRIBUTE HMD_Protect_UserDefaults_handle_exception(HMDProtectCapture *capture) {
    if (!capture) {
        return;
    }
    HMDProtect_BDALOG(capture.reason);
    HMDProtectBreakpoint();
    HMDLog(@"[Heimdallr][Protector] UserDefaults exception");
    int lock_rst = pthread_rwlock_rdlock(&g_rwlock);
    HMDProtectCaptureBlock captureBlock = _internal_UserDefaults_captureBlock;
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
