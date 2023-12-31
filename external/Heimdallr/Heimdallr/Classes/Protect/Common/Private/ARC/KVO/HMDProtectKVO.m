//
//  HMDProtectKVO.m
//  Heimdallr
//
//  Created by fengyadong on 2018/4/9.
//

#import <stdatomic.h>
#import "HMDProtectKVO.h"
#import "HMDProtectCapture.h"
#import "HMDProtect_Private.h"
#import "HMDSwizzle.h"
#import "HeimdallrUtilities.h"
#import "HMDProtectCapture.h"
#import "HMDProtector.h"
#import "HMDKVOPair.h"
#import "HMDAppleBacktracesLog.h"
#import "hmd_thread_backtrace.h"
#import "HMDObjectAnalyzer.h"

static pthread_key_t g_pthread_key;
static pthread_rwlock_t g_rwlock = PTHREAD_RWLOCK_INITIALIZER;
static void *kHMDKVOPairsInfoKey = &kHMDKVOPairsInfoKey;
static HMDProtectCaptureBlock _Nullable _internal_KVO_captureBlock = nil;
static void KeyValueObserving_replaceImplementation(void);
static BOOL shouldProtectKVO(NSObject * _Nonnull observee, NSObject * _Nullable observer);
static NSMutableSet<NSString*>* crashKeySet = nil;

#pragma mark - Implementation

@implementation NSObject (HMDProtectKVO)

- (HMDKVOPairsInfo *)HMDKVOInfo {
    return objc_getAssociatedObject(self, kHMDKVOPairsInfoKey);
}

- (void)setHMDKVOInfo:(HMDKVOPairsInfo *)HMDKVOInfo {
    objc_setAssociatedObject(self, kHMDKVOPairsInfoKey, HMDKVOInfo, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)HMDP_addObserver:(NSObject *)observer
              forKeyPath:(NSString *)keyPath
                 options:(NSKeyValueObservingOptions)options
                 context:(void *)context {
    if (!_internal_KVO_captureBlock) {
        [self HMDP_addObserver:observer forKeyPath:keyPath options:options context:context];
        return;
    }
    
    if (!shouldProtectKVO(self, observer)) {
        [self HMDP_addObserver:observer forKeyPath:keyPath options:options context:context];
        return;
    }
    
    if (observer == nil) {
        return;
    }
    
    if(keyPath == nil || ![keyPath isKindOfClass:[NSString class]]) {
        if (hmd_upper_trycatch_effective(0)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        NSString *observerClassName = NSStringFromClass([observer class]);
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ addObserver:%@ forKeypath:%@ options:%lu context:%p]", selfClassName, observerClassName, keyPath, (unsigned long)options, context];
        NSString *reason = [NSString stringWithFormat:@"-[%@ addObserver:%@ forKeypath:%@ options:%lu context:%p]", selfClassName, observer, keyPath, (unsigned long)options, context];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
        HMD_Protect_KVO_captureException(capture);
        return;
    }
    
    // 自己监听自己，不做代理
    // iOS 9、10上可能会因为observee释放时未移除监听而崩溃
    if(self == observer) {
        [self HMDP_addObserver:observer forKeyPath:keyPath options:options context:context];
        return;
    }
    
    HMDKVOPair *pair = [[HMDKVOPair alloc] initWithObserver:observer
                                                    keypath:keyPath
                                                    options:options
                                                    context:context];
    [pair activeWithObservee:self];
    if (pair.isActived) {
        @synchronized (self) {
            HMDKVOPairsInfo *info = self.HMDKVOInfo;
            if (info) {
                [info.pairList addObject:pair];
            }
            else {
                info = [[HMDKVOPairsInfo alloc] initWithObservee:self];
                [info.pairList addObject:pair];
                self.HMDKVOInfo = info;
            }
        }
    }
}

- (void)HMDP_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath {
    if (!_internal_KVO_captureBlock) {
        [self HMDP_removeObserver:observer forKeyPath:keyPath];
        return;
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        [self HMDP_removeObserver:observer forKeyPath:keyPath];
        return;
    }
    
    if (!shouldProtectKVO(self, observer)) {
        [self HMDP_removeObserver:observer forKeyPath:keyPath];
        return;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        // keyPath为nil会崩溃，其它为nil方法不生效
        if (observer == nil) {
            return;
        }
        
        if(keyPath == nil || ![keyPath isKindOfClass:[NSString class]]) {
            if (hmd_upper_trycatch_effective(1)) {
                return;
            }
            
            NSString *selfClassName = NSStringFromClass([self class]);
            NSString *observerClassName = NSStringFromClass([observer class]);
            NSString *crashKey = [NSString stringWithFormat:@"-[%@ removeObserver:%@ forKeypath:%@]", selfClassName, observerClassName, keyPath];
            NSString *reason = [NSString stringWithFormat:@"[%@ removeObserver:%@ forKeyPath:%@]", self, observer, keyPath];
            HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
            HMD_Protect_KVO_captureException(capture);
            return;
        }
        
        if(self == observer) {
            [self HMDP_removeObserver:observer forKeyPath:keyPath];
            return;
        }
        
        BOOL rst = NO;
        // 对数组操作，需要加锁
        @synchronized (self) {
            rst = [self _HMDTryRemoveObserver:observer keyPath:keyPath];
        }
                
        // 无法找到代理
        // 可能是在安全气垫开启前增加的监听，继续调用系统默认实现
        if(!rst) {
            [self HMDP_removeObserver:observer forKeyPath:keyPath];
        }
    }
    @catch (NSException *exception) {
        if (self.HMDKVOInfo == nil) {
            // HMDKVOInfo == nil 可能是 observee 已经进入 dealloc 阶段
            // 如果 observee 处于 deallocating 中，则认为是误判
            if (HMDObjectAnalyzer_objectIsDeallocating(self)) {
                return;
            }
        }
        
        if (hmd_upper_trycatch_effective(1)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        
        NSString * _Nullable observerClassName = @"unknownClass";
        if(HMDObjectAnalyzer_isInitialized()) {
            
            #define HMDKVO_MAX_CLASS_NAME_LENGTH 256
            uint8_t tempStorage[HMDKVO_MAX_CLASS_NAME_LENGTH];
            if(HMDObjectAnalyzer_unsafeObjectGetClassName((__bridge HMDUnsafeObject)observer, tempStorage, HMDKVO_MAX_CLASS_NAME_LENGTH)) {
                tempStorage[HMDKVO_MAX_CLASS_NAME_LENGTH - 1] = '\0';
                if((observerClassName = [NSString stringWithCString:(const char * _Nonnull)tempStorage encoding:NSUTF8StringEncoding]) == nil) {
                    observerClassName = @"observerSmashed";
                }
            } else  observerClassName = @"observerSmashed";
        }
        
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ removeObserver:%@ forKeypath:%@]", selfClassName, observerClassName, keyPath];
        HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
        HMD_Protect_KVO_captureException(capture);
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

- (void)HMDP_removeObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath context:(void *)context {
    
    if (!_internal_KVO_captureBlock) {
        [self HMDP_removeObserver:observer forKeyPath:keyPath context:context];
        return;
    }
    
    if (hmd_check_thread_specific_flag(g_pthread_key)) {
        [self HMDP_removeObserver:observer forKeyPath:keyPath context:context];
        return;
    }
    
    if (!shouldProtectKVO(self, observer)) {
        [self HMDP_removeObserver:observer forKeyPath:keyPath context:context];
        return;
    }
    
    @try {
        hmd_thread_specific_set_flag(g_pthread_key);
        
        // keyPath为nil会崩溃，其它为nil方法不生效
        if (observer == nil) {
            return;
        }
        
        if(keyPath == nil || ![keyPath isKindOfClass:[NSString class]]) {
            if (hmd_upper_trycatch_effective(1)) {
                return;
            }
            
            NSString *selfClassName = NSStringFromClass([self class]);
            NSString *observerClassName = NSStringFromClass([observer class]);
            NSString *crashKey = [NSString stringWithFormat:@"-[%@ removeObserver:%@ forKeypath:%@ context:%p]", selfClassName, observerClassName, keyPath, context];
            NSString *reason = [NSString stringWithFormat:@"[%@ removeObserver:%@ forKeyPath:%@ context:%p]", self, observer, keyPath, context];
            HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
            HMD_Protect_KVO_captureException(capture);
            return;
        }
        
        if(self == observer) {
            [self HMDP_removeObserver:observer forKeyPath:keyPath context:context];
            return;
        }
        
        BOOL rst = NO;
        // 对数组操作，需要加锁
        @synchronized (self) {
            rst = [self _HMDTryRemoveObserver:observer keyPath:keyPath context:context];
        }
                
        // 无法找到代理
        // 可能是在安全气垫开启前增加的监听，继续调用系统默认实现
        if(!rst) {
            [self HMDP_removeObserver:observer forKeyPath:keyPath context:context];
        }
    }
    @catch (NSException *exception) {
        
        if (self.HMDKVOInfo == nil) {
            // HMDKVOInfo == nil 可能是 observee 已经进入 dealloc 阶段
            // 如果 observee 处于 deallocating 中，则认为是误判
            if (HMDObjectAnalyzer_objectIsDeallocating(self)) {
                return;
            }
        }
        
        if (hmd_upper_trycatch_effective(1)) {
            return;
        }
        
        NSString *selfClassName = NSStringFromClass([self class]);
        
        NSString * _Nullable observerClassName = @"unknownClass";
        if(HMDObjectAnalyzer_isInitialized()) {
            
            #define HMDKVO_MAX_CLASS_NAME_LENGTH 256
            uint8_t tempStorage[HMDKVO_MAX_CLASS_NAME_LENGTH];
            if(HMDObjectAnalyzer_unsafeObjectGetClassName((__bridge HMDUnsafeObject)observer, tempStorage, HMDKVO_MAX_CLASS_NAME_LENGTH)) {
                tempStorage[HMDKVO_MAX_CLASS_NAME_LENGTH - 1] = '\0';
                if((observerClassName = [NSString stringWithCString:(const char * _Nonnull)tempStorage encoding:NSUTF8StringEncoding]) == nil) {
                    observerClassName = @"observerSmashed";
                }
            } else  observerClassName = @"observerSmashed";
        }
        
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ removeObserver:%@ forKeypath:%@ context:%p]", selfClassName, observerClassName, keyPath, context];
        HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:crashKey];
        if (capture) {
            HMD_Protect_KVO_captureException(capture);
        }
    }
    @finally {
        hmd_thread_specific_clear_flag(g_pthread_key);
    }
}

- (BOOL)_HMDTryRemoveObserver:(NSObject *)observer keyPath:(NSString *)keyPath {
    // 只删除一个匹配的Observer，倒序遍历(系统API逻辑)
    __block NSInteger index = -1;
    void *observerPtr = (__bridge void *)(observer);
    NSMutableArray *list = self.HMDKVOInfo.pairList;
    [list enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HMDKVOPair * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 因为weak引用，对象地址可能为nil，所以要同时对比指针地址
        if (obj.HMDObserver != observer && obj.HMDObserverPtr != observerPtr) {
            return;
        }
        
        if (![obj.HMDKeyPath isEqualToString:keyPath]) {
            return;
        }
        
        [obj deactiveWithObservee:self];
        index = idx;
        *stop = YES;
    }];
    
    if (index >= 0) {
        [list removeObjectAtIndex:index];
        return YES;
    }
    
    return NO;
}

- (BOOL)_HMDTryRemoveObserver:(NSObject *)observer keyPath:(NSString *)keyPath context:(void *)context {
    // 只删除一个匹配的Observer，倒序遍历(系统API逻辑)
    __block NSInteger index = -1;
    void *observerPtr = (__bridge void *)(observer);
    NSMutableArray *list = self.HMDKVOInfo.pairList;
    [list enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(HMDKVOPair * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        // 因为weak引用，对象地址可能为nil，所以要同时对比指针地址
        if (obj.HMDObserver != observer && obj.HMDObserverPtr != observerPtr) {
            return;
        }
        
        if (obj.HMDContext != context) {
            return;
        }
        
        if (![obj.HMDKeyPath isEqualToString:keyPath]) {
            return;
        }
        
        [obj deactiveWithObservee:self];
        index = idx;
        *stop = YES;
    }];
    
    if (index >= 0) {
        [list removeObjectAtIndex:index];
        return YES;
    }
    
    return NO;
}

@end

#pragma mark - Foundation

void HMD_Protect_toggle_KVO_protection(HMDProtectCaptureBlock _Nullable captureBlock) {
    int lock_rst = pthread_rwlock_wrlock(&g_rwlock);
    _internal_KVO_captureBlock = captureBlock;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_rwlock);
    }
    
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        crashKeySet = [[NSMutableSet alloc] init];
        KeyValueObserving_replaceImplementation();
        HMDObjectAnalyzer_initialization();
    }
}

static void KeyValueObserving_replaceImplementation(void) {
    pthread_key_create(&g_pthread_key, NULL);
    Class NSObjectClass = NSObject.class;
    hmd_swizzle_instance_method(NSObjectClass,
                                @selector(removeObserver:forKeyPath:context:),
                                @selector(HMDP_removeObserver:forKeyPath:context:));
    hmd_swizzle_instance_method(NSObjectClass,
                                @selector(removeObserver:forKeyPath:),
                                @selector(HMDP_removeObserver:forKeyPath:));
    // 注意：add方法一定要放在最后，如果add先生效，通过代理添加了KVO，此时remove不通过代理就会崩溃
    hmd_swizzle_instance_method(NSObjectClass,
                                @selector(addObserver:forKeyPath:options:context:),
                                @selector(HMDP_addObserver:forKeyPath:options:context:));
}

void HMD_NO_OPT_ATTRIBUTE HMD_Protect_KVO_captureException(HMDProtectCapture * _Nonnull capture) {
    if (!capture) {
        return;
    }
    
    HMDProtect_BDALOG(capture.reason);
    HMDProtectBreakpoint();
    HMDLog(@"[Heimdallr][Protector] KVO exception");
    int lock_rst = pthread_rwlock_rdlock(&g_rwlock);
    HMDProtectCaptureBlock captureBlock = _internal_KVO_captureBlock;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_rwlock);
    }
    
    if(captureBlock) {
        HMDThreadBacktrace *bt = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:NO skippedDepth:2 suspend:NO];
        if (bt) {
            capture.backtraces = @[bt];
            capture.crashKeySet = (NSMutableSet<id> * _Nullable)crashKeySet;
            captureBlock(capture);
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION
}

static BOOL ignoreObserverForClass(Class _Nonnull clazz) {
    if (!clazz) {
        return NO;
    }
    
    NSArray<NSString *> *ignoreClassPrefix = [HMDProtector sharedProtector].ignoreKVOObserverPrefix;
    NSString *className = NSStringFromClass(clazz);
    BOOL isIgnored = NO;
    
    for (NSString *prefix in ignoreClassPrefix) {
        if ([className hasPrefix:prefix]) {
            isIgnored = YES;
            break;
        }
    }
    
    return isIgnored;
}

static BOOL shouldProtectKVO(NSObject * observee, NSObject * observer) {
    // observer == nil会崩溃
    if(observee == nil || observer == nil) {
        return YES;
    }
    
    if([observer isKindOfClass:HMDKVOPair.class]) {
        return NO;
    }
    
    Class observerClass = [observer class];
    return ((!ignoreObserverForClass(observerClass)) && [HeimdallrUtilities isClassFromApp:observerClass]);
}
