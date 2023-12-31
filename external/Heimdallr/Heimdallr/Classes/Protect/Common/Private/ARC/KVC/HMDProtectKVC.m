//
//  HMDProtectKVC.m
//  Heimdallr
//
//  Created by fengyadong on 2018/4/9.
//

#import <stdatomic.h>
#import "HMDProtectKVC.h"
#import "HMDProtect_Private.h"
#import "HMDProtectCapture.h"
#import "HMDSwizzle.h"
#import "HMDAppleBacktracesLog.h"

static pthread_key_t g_pthread_key;
static pthread_rwlock_t g_rwlock = PTHREAD_RWLOCK_INITIALIZER;
static HMDProtectCaptureBlock _Nullable _internal_KVC_captureBlock = nil;
static void KeyValueCoding_replaceImplementation(void);
static void HMD_Protect_KVC_handle_exception(HMDProtectCapture *capture);
static NSMutableSet<NSString *>* crashKeySet = nil;

#pragma mark - Implementation

@implementation NSObject(HMDProtectKVC)

- (id)HMDP_valueForKey:(NSString *)key {
    if (!_internal_KVC_captureBlock) {
        return [self HMDP_valueForKey:key];
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        return [self HMDP_valueForKey:key];
    }
    
    if(!(key && [key isKindOfClass:[NSString class]])) {
        if (hmd_upper_trycatch_effective(0)) {
            return nil;
        }
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *keyClassName = NSStringFromClass([key class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ valueForKey:%@]", selfClassName, key];
        NSString *reason = [NSString stringWithFormat:@"%@ attempt to retrieve a value for a %@ key", crashKey, keyClassName];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
        return nil;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        return [self HMDP_valueForKey:key];
    }
    @catch (NSException *exception) {
        if (hmd_upper_trycatch_effective(1)) {
            return nil;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ valueForKey:%@]", selfClassName, key];
        HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
        return nil;
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

- (id)HMDP_valueForKeyPath:(NSString *)keyPath {
    if (!_internal_KVC_captureBlock) {
        return [self HMDP_valueForKeyPath:keyPath];
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        return [self HMDP_valueForKeyPath:keyPath];
    }
    
    if(!(keyPath && [keyPath isKindOfClass:[NSString class]])) {
        if (hmd_upper_trycatch_effective(0)) {
            return nil;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *keyPathClassName = NSStringFromClass([keyPath class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ valueForKeyPath:%@]", selfClassName, keyPath];
        NSString *reason = [NSString stringWithFormat:@"%@ attempt to retrieve a value for a %@ keyPath", crashKey, keyPathClassName];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
        return nil;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        return [self HMDP_valueForKeyPath:keyPath];
    }
    @catch (NSException *exception) {
        if (hmd_upper_trycatch_effective(1)) {
            return nil;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ valueForKeyPath:%@]", selfClassName, keyPath];
        HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
        return nil;
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

- (id)HMDP_valueForUndefinedKey:(NSString *)key {
    if (!_internal_KVC_captureBlock) {
        return [self HMDP_valueForUndefinedKey:key];
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        return [self HMDP_valueForUndefinedKey:key];
    }
    
    if(!(key && [key isKindOfClass:[NSString class]])) {
        if (hmd_upper_trycatch_effective(0)) {
            return nil;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *keyClassName = NSStringFromClass([key class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ valueForUndefinedKey:%@]", selfClassName, key];
        NSString *reason = [NSString stringWithFormat:@"%@ attempt to retrieve a value for a %@ key", crashKey, keyClassName];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
        return nil;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        return [self HMDP_valueForUndefinedKey:key];
    }
    @catch (NSException *exception) {
        if (hmd_upper_trycatch_effective(1)) {
            return nil;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ valueForUndefinedKey:%@]", selfClassName, key];
        HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
        return nil;
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

- (void)HMDP_setValue:(id)value forKey:(NSString *)key {
    if (!_internal_KVC_captureBlock) {
        [self HMDP_setValue:value forKey:key];
        return;
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        [self HMDP_setValue:value forKey:key];
        return;
    }
    
    if(!(key && [key isKindOfClass:[NSString class]])) {
        if (hmd_upper_trycatch_effective(0)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *keyClassName = NSStringFromClass([key class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ setValue:%@ forKey:%@]", selfClassName, value, key];
        NSString *reason = [NSString stringWithFormat:@"%@ attempt to set a value for a %@ key", crashKey, keyClassName];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
        return;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        [self HMDP_setValue:value forKey:key];
    }
    @catch (NSException *exception) {
        if (hmd_upper_trycatch_effective(1)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ setValue:%@ forKey:%@]", selfClassName, value, key];
        HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

- (void)HMDP_setValue:(id)value forKeyPath:(NSString *)keyPath {
    if (!_internal_KVC_captureBlock) {
        [self HMDP_setValue:value forKeyPath:keyPath];
        return;
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        [self HMDP_setValue:value forKeyPath:keyPath];
        return;
    }
    
    if(!(keyPath && [keyPath isKindOfClass:[NSString class]])) {
        if (hmd_upper_trycatch_effective(0)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *keyPathClassName = NSStringFromClass([keyPath class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ setValue:%@ forKeyPath:%@]", selfClassName, value, keyPath];
        NSString *reason = [NSString stringWithFormat:@"%@ attempt to set a value for a %@ keyPath", crashKey, keyPathClassName];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
        return;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        [self HMDP_setValue:value forKeyPath:keyPath];
    }
    @catch (NSException *exception) {
        if (hmd_upper_trycatch_effective(1)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ setValue:%@ forKeyPath:%@]", selfClassName, value, keyPath];
        HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

- (void)HMDP_setValue:(id)value forUndefinedKey:(NSString *)key {
    if (!_internal_KVC_captureBlock) {
        [self HMDP_setValue:value forUndefinedKey:key];
        return;
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        [self HMDP_setValue:value forUndefinedKey:key];
        return;
    }
    
    if(!(key && [key isKindOfClass:[NSString class]])) {
        if (hmd_upper_trycatch_effective(0)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *keyClassName = NSStringFromClass([key class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ setValue:%@ forUndefinedKey:%@]", selfClassName, value, key];
        NSString *reason = [NSString stringWithFormat:@"%@ attempt to set a value for a %@ key", crashKey, keyClassName];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
        return;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        [self HMDP_setValue:value forUndefinedKey:key];
    }
    @catch (NSException *exception) {
        if (hmd_upper_trycatch_effective(1)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ setValue:%@ forUndefinedKey:%@]", selfClassName, value, key];
        HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

- (void)HMDP_setValuesForKeysWithDictionary:(NSDictionary<NSString *,id> *)keyedValues {
    if (!_internal_KVC_captureBlock) {
        [self HMDP_setValuesForKeysWithDictionary:keyedValues];
        return;
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        [self HMDP_setValuesForKeysWithDictionary:keyedValues];
        return;
    }
    
    if (keyedValues) {
        if (![keyedValues isKindOfClass:[NSDictionary class]]) {
            if (hmd_upper_trycatch_effective(0)) {
                return;
            }
            
            NSString *selfClassName = NSStringFromClass([self class]);
            NSString *keyClassName = NSStringFromClass([keyedValues class]);
            NSString *crashKey = [NSString stringWithFormat:@"-[%@ setValuesForKeysWithDictionary:%@]", selfClassName, keyedValues];
            NSString *reason = [NSString stringWithFormat:@"%@ attempt to set values with %@", crashKey, keyClassName];
            HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
            HMD_Protect_KVC_handle_exception(capture);
            return;
        }
    }
    else {
        // 注:keyedValues = nil时不会崩溃，此处直接返回
        return;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        [self HMDP_setValuesForKeysWithDictionary:keyedValues];
    }
    @catch (NSException *exception) {
        if (hmd_upper_trycatch_effective(1)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ setValuesForKeysWithDictionary:%@]", selfClassName, keyedValues];
        HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
        HMD_Protect_KVC_handle_exception(capture);
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

@end

#pragma mark - Foundation

void HMD_Protect_toggle_KVC_protection(HMDProtectCaptureBlock captureBlock) {
    int lock_rst = pthread_rwlock_wrlock(&g_rwlock);
    _internal_KVC_captureBlock = captureBlock;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_rwlock);
    }
    
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(captureBlock && !atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        crashKeySet = [[NSMutableSet alloc] init];
        KeyValueCoding_replaceImplementation();
    }
}

static void KeyValueCoding_replaceImplementation(void) {
    pthread_key_create(&g_pthread_key, NULL);
    Class NSObjectClass = NSObject.class;
    hmd_swizzle_instance_method(NSObjectClass, @selector(valueForKey:), @selector(HMDP_valueForKey:));
    hmd_swizzle_instance_method(NSObjectClass, @selector(valueForKeyPath:), @selector(HMDP_valueForKeyPath:));
    hmd_swizzle_instance_method(NSObjectClass, @selector(valueForUndefinedKey:), @selector(HMDP_valueForUndefinedKey:));
    hmd_swizzle_instance_method(NSObjectClass, @selector(setValue:forKey:), @selector(HMDP_setValue:forKey:));
    hmd_swizzle_instance_method(NSObjectClass, @selector(setValue:forKeyPath:), @selector(HMDP_setValue:forKeyPath:));
    hmd_swizzle_instance_method(NSObjectClass, @selector(setValue:forUndefinedKey:), @selector(HMDP_setValue:forUndefinedKey:));
    hmd_swizzle_instance_method(NSObjectClass, @selector(setValuesForKeysWithDictionary:), @selector(HMDP_setValuesForKeysWithDictionary:));
}

static void HMD_NO_OPT_ATTRIBUTE HMD_Protect_KVC_handle_exception(HMDProtectCapture *capture) {
    if (!capture) {
        return;
    }
    HMDProtect_BDALOG(capture.reason);
    HMDProtectBreakpoint();
    HMDLog(@"[Heimdallr][Protector] KVC exception");
    int lock_rst = pthread_rwlock_rdlock(&g_rwlock);
    HMDProtectCaptureBlock captureBlock = _internal_KVC_captureBlock;
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
