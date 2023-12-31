//
//  HMDProtectUnrecognizedSelector.m
//  Heimdallr
//
//  Created by fengyadong on 2018/4/9.
//

#import "HMDMacro.h"
#include <dlfcn.h>
#import <stdatomic.h>
#import "HMDProtectUnrecognizedSelector.h"
#import "HMDSwizzle.h"
#import "HMDProtect_Private.h"
#import "pthread_extended.h"
#import "HMDAppleBacktracesLog.h"
#import "hmd_thread_backtrace.h"
#import "HMDUSELForwarder.h"
#import "HMDCrashKit.h"
#import "hmd_mach.h"
#import "HMDCrashKit+Internal.h"

#if TARGET_OS_OSX && __x86_64__
    // 64-bit Mac - tag bit is LSB
#   define HMD_PROTECT_OBJC_MSB_TAGGED_POINTERS 0
#else
    // Everything else - tag bit is MSB
#   define HMD_PROTECT_OBJC_MSB_TAGGED_POINTERS 1
#endif

#if HMD_PROTECT_OBJC_MSB_TAGGED_POINTERS
#   define HMD_PROTECT_OBJC_TAG_MASK (1ULL<<63)
#else
#   define HMD_PROTECT_OBJC_TAG_MASK 1
#endif

static pthread_rwlock_t g_rwlock = PTHREAD_RWLOCK_INITIALIZER;
static HMDProtectCaptureBlock _Nullable _internal_USEL_captureBlock = nil;
static void USEL_replaceImplementation(void);
static void HMD_Protect_USEL_captureException(HMDProtectCapture * _Nonnull capture);
static bool HMD_Protect_check_invalid_address(id _Nonnull objc, SEL _Nonnull aSelector);
static NSMutableSet<NSString *>* crashKeySet = nil;

#pragma mark - Implementation

@implementation NSObject (HMDProtectUnrecognizedSelector)

// [为什么要 HOOK doesNotRecognizeSelector:]
// 返回了methodSignature但在forwardInvocation时无法实现，会走到这里
// 兜底方法，防止其他hook方案直接调用doesNotRecognizeSelector方法抛出异常
- (void)HMDP_doesNotRecognizeSelector:(SEL)aSelector {
    if (_internal_USEL_captureBlock) {
        
        // [判断是原有 objc_msgSend doesNotRecognizeSelector:逻辑时 不兜底]
        // 拿到寄存器返回地址 => 反推上一个函数是个啥玩意 => CoreFoundation.___forwarding___ => 不兜底
        void *where_should_it_return =
        __builtin_extract_return_addr(__builtin_return_address(0));
        Dl_info info;
        if(dladdr(where_should_it_return, &info) != 0) {
            if(info.dli_fname != NULL && info.dli_sname != NULL) {
                if(strstr(info.dli_fname, "/System/Library/Frameworks/CoreFoundation.framework/CoreFoundation") != NULL) {
                    if(strcmp(info.dli_sname, "___forwarding___") == 0) {
                        // 比较成功，该处来自于 objc_msgSend 最后的兜底 doesNotRecognizeSelector:
                        [self HMDP_doesNotRecognizeSelector:aSelector];
                        return;
                    }
                }
            } DEBUG_ELSE
        } DEBUG_ELSE
        
        if (hmd_upper_trycatch_effective(0)) {
            return;
        }

        // Check address of 'self' and 'aSelector' are valid
        if (!HMD_Protect_check_invalid_address(self, aSelector)) {
            [[HMDCrashKit sharedInstance] syncDynamicValue:@"1" key:@"protect_invalid_address"];
            [self HMDP_doesNotRecognizeSelector:aSelector];
            return;
        }

        NSString *selfClassName = NSStringFromClass([self class]);
        const char *selectorCName = sel_getName(aSelector);
        NSString *selectorName = [NSString stringWithCString:selectorCName encoding:NSUTF8StringEncoding];
        NSString *reasonString = [NSString stringWithFormat:@"-[%@ %@]: unrecognized selector sent to instance %p", selfClassName, selectorName, self];
        NSString *crashKey = [NSString stringWithFormat:@"-[%@ %@]", selfClassName, selectorName];
        HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reasonString crashKey:crashKey];
        HMD_Protect_USEL_captureException(capture);
    }
    else {
        [self HMDP_doesNotRecognizeSelector:aSelector];
    }
}

- (id)HMDP_forwardingTargetForSelector:(SEL)aSelector {
    if (!_internal_USEL_captureBlock) {
        return [self HMDP_forwardingTargetForSelector:aSelector];
    }
    
    id forwardObject = [self HMDP_forwardingTargetForSelector:aSelector];
    if (forwardObject) {
        return forwardObject;
    }
    
    if ([self methodSignatureForSelector:aSelector]) {
        return forwardObject;
    }
    
    if (hmd_upper_trycatch_effective(0)) {
        return HMDUSELForwarder.class;
    }
    
    // Check address of 'self' and 'aSelector' are valid
    if (!HMD_Protect_check_invalid_address(self, aSelector)) {
        [[HMDCrashKit sharedInstance] syncDynamicValue:@"1" key:@"protect_invalid_address"];
        return nil;
    }
    
    Class cls = [self class];
    NSString *selfClassName = NSStringFromClass(cls);
    const char *selectorCName = sel_getName(aSelector);
    NSString *selectorName = [NSString stringWithCString:selectorCName encoding:NSUTF8StringEncoding];
    NSString *reason = [NSString stringWithFormat:@"-[%@ %@]: unrecognized selector sent to instance %p", selfClassName, selectorName, self];
    NSString *crashKey = [NSString stringWithFormat:@"-[%@ %@]", selfClassName, selectorName];
    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
    HMD_Protect_USEL_captureException(capture);
    return HMDUSELForwarder.class;
}

+ (id)HMDP_forwardingTargetForSelector:(SEL)aSelector {
    if (!_internal_USEL_captureBlock) {
        return [self HMDP_forwardingTargetForSelector:aSelector];
    }
    
    id forwardObject = [self HMDP_forwardingTargetForSelector:aSelector];
    if (forwardObject) {
        return forwardObject;
    }
    
    if ([self methodSignatureForSelector:aSelector]) {
        return forwardObject;
    }
    
    if (hmd_upper_trycatch_effective(0)) {
        return HMDUSELForwarder.class;
    }
    
    Class cls = [self class];
    NSString *selfClassName = NSStringFromClass(cls);
    NSString *selectorName = NSStringFromSelector(aSelector);
    NSString *reason = [NSString stringWithFormat:@"+[%@ %@]: unrecognized selector sent to class %@", selfClassName, selectorName, selfClassName];
    NSString *crashKey = [NSString stringWithFormat:@"+[%@ %@]", selfClassName, selectorName];
    HMDProtectCapture *capture = [HMDProtectCapture captureException:@"NSInvalidArgumentException" reason:reason crashKey:crashKey];
    HMD_Protect_USEL_captureException(capture);
    return HMDUSELForwarder.class;
}

@end

#pragma mark - Foundation

void HMD_Protect_toggle_USEL_protection(HMDProtectCaptureBlock captureBlock) {
    int lock_rst = pthread_rwlock_wrlock(&g_rwlock);
    _internal_USEL_captureBlock = captureBlock;
    if (lock_rst == 0) {
        pthread_rwlock_unlock(&g_rwlock);
    }
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    // 开启, Swizzle只进行一次，通过_internal_USEL_captureBlock = nil进行功能关闭
    if(captureBlock && !atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        crashKeySet = [[NSMutableSet alloc] init];
        USEL_replaceImplementation();
    }
}

static void USEL_replaceImplementation(void) {
    Class NSObjectClass = NSObject.class;
    hmd_swizzle_instance_method(NSObjectClass, @selector(doesNotRecognizeSelector:), @selector(HMDP_doesNotRecognizeSelector:));
    hmd_swizzle_instance_method(NSObjectClass, @selector(forwardingTargetForSelector:), @selector(HMDP_forwardingTargetForSelector:));
    hmd_swizzle_class_method(NSObjectClass, @selector(forwardingTargetForSelector:), @selector(HMDP_forwardingTargetForSelector:));
}

static void HMD_NO_OPT_ATTRIBUTE HMD_Protect_USEL_captureException(HMDProtectCapture * _Nonnull capture) {
    if (!capture) {
        return;
    }
    HMDProtect_BDALOG(capture.reason);
    HMDProtectBreakpoint();
    HMDLog(@"[Heimdallr][Protector] Unrecognize Selector exception");
    int lock_rst = pthread_rwlock_rdlock(&g_rwlock);
    HMDProtectCaptureBlock captureBlock = _internal_USEL_captureBlock;
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

static inline bool hmd_protect_objc_isTaggedPointer(const void *ptr) {
    bool result =  ((intptr_t)ptr & HMD_PROTECT_OBJC_TAG_MASK) == HMD_PROTECT_OBJC_TAG_MASK;
    return result;
}

static bool HMD_Protect_check_invalid_address(id __unsafe_unretained _Nonnull objc, SEL _Nonnull aSelector) {
    /*! 给后续维护代码的备注 @p objc 属性标记为 @b __unsafe_unretained 意味着不遵守 ARC 管理，
        也就是对于这个对象可以理解为 void * 数据类型，但是你也得同样记得这个指针指向的对象不够安全
        任何 OC 方法不应当对其调用 */

    void *queryAddress = aSelector;
    hmd_vm_region_basic_info info;
    
    // 如果查询 vm_region 该处内存读写状态失败，则 hmd_vm_region_query_basic_info 会返回 false
    // 如果查询结果中 protection，没有可读权限，那么也会失败
    if(!hmd_vm_region_query_basic_info(&queryAddress, NULL, &info) || !(info.protection & VM_PROT_READ)) {
        HMDLog(@"[Heimdallr][Protect] Unrecognize Selector : Address of aSelector is invalid.");
        return false;
    }
    
    uintptr_t objectAddress = (uintptr_t)objc;
    
    //reference to https://blog.timac.org/2016/1124-testing-if-an-arbitrary-pointer-is-a-valid-objective-c-object/
    //vm_read for TaggedPointers return KERN_INVALID_ADDRESS
#if defined(__LP64__)
    if (hmd_protect_objc_isTaggedPointer((const void *)objectAddress)) {
        return true;
    }
#endif
    
    // 一个 OC 地址有效的条件至少需要指针对齐
#ifdef __LP64__
    if(objectAddress & UINT64_C(0x7)) return false; // 64位对齐，64/8 = 8 字节，8 - 1 = 7
#else
    if(objectAddress & UINT32_C(0x3)) return false; // 32位对齐，32/8 = 4 字节，4 - 1 = 3
#endif
    
    queryAddress = (void *)objectAddress;
    if(!hmd_vm_region_query_basic_info(&queryAddress, NULL, &info) || !(info.protection & VM_PROT_READ)) {
        HMDLog(@"[Heimdallr][Protect] Unrecognize Selector : Address of objc is invalid.");
        return false;
    }
    
    return true;
}

