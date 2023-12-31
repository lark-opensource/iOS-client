//
//  HMDWeakRetainDeallocating.m
//  Heimdallr
//
//  Created by bytedance on 2022/11/4.
//

#include <dlfcn.h>
#import <stdatomic.h>
#import <BDFishhook/BDFishhook.h>
#import "HMDMacro.h"
#import "HMDSwizzle.h"
#import "HMDProtector.h"
#import "HMDProtectKVC.h"
#import "HMDALogProtocol.h"
#import "HMDProtectCapture.h"
#import "HeimdallrUtilities.h"
#import "HMDProtect_Private.h"
#import "HMDObjectAnalyzer.h"
#import "HMDAppleBacktracesLog.h"
#import "HMDWeakRetainDeallocating.h"
#import "HMDTaggedPointerAnalyzer.h"

#define MAX_WEAK_RETAIN_DEALLOCATING_PROTECTION_COUNT UINT64_C(5)

typedef id _Nullable (*storeWeak_t)(id _Nullable * _Nonnull location,
                                    id _Nullable obj);

static HMDProtectCaptureBlock _Nullable _internal_weakRetain_captureBlock = nil;
static pthread_rwlock_t g_rwlock = PTHREAD_RWLOCK_INITIALIZER;
static NSMutableSet<NSString*>* crashKeySet = nil;

static storeWeak_t shared_origin_objc_storeWeak = objc_storeWeak;
static storeWeak_t fishhook_origin_objc_storeWeak;

static id _Nullable objc_storeWeak_safe(id _Nullable * _Nonnull location,
                                        id _Nullable obj);

static void weakRetainDeallocating_hookImplementation(void);

@interface HMDWeakRetainDeallocating : NSObject @end
@implementation HMDWeakRetainDeallocating

+ (storeWeak_t * _Nonnull)saveOriginImp {
    return &shared_origin_objc_storeWeak;
}

+ (storeWeak_t * _Nonnull)saveFishhookImp {
    return &fishhook_origin_objc_storeWeak;
}

@end

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION
static void weakRetainDeallocating_hookImplementation(void) {
    struct bd_rebinding rebindings[1] = {
        [0] = {
            .name = "objc_storeWeak",
            .replacement = (void *)objc_storeWeak_safe,
            .replaced = (void **)&fishhook_origin_objc_storeWeak,
        }
    };
    bd_rebind_symbols(rebindings, sizeof(rebindings)/sizeof(rebindings[0]));
    bd_rebind_symbols_patch(rebindings, sizeof(rebindings)/sizeof(rebindings[0]));
}
CLANG_DIAGNOSTIC_POP

void HMD_Protect_toggle_weakRetainDeallocating_protection(HMDProtectCaptureBlock _Nullable captureBlock) {
#if __arm64__ && __LP64__
    int lock_rst = pthread_rwlock_wrlock(&g_rwlock);
    _internal_weakRetain_captureBlock = captureBlock;
    if (likely(lock_rst == 0)) pthread_rwlock_unlock(&g_rwlock);
    
    if(captureBlock) {
        
        // first time
        static atomic_flag onceToken = ATOMIC_FLAG_INIT;
        if(!atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
            crashKeySet = [[NSMutableSet alloc] init];
            HMDTaggedPointerAnalyzer_initialization();
            weakRetainDeallocating_hookImplementation();
        }
    }
#endif
}

/*!@function @p objc_storeWeak_safe
 * @abstract 当前 BDFishhook 处理之后的 hook 接口，需要校验参数后再调回原方法
 */
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_UNUSED_FUNCTION
static id _Nullable objc_storeWeak_safe(id _Nullable * _Nonnull location, id _Nullable object) {
    
    bool unsafe = false;
    
    #if __arm64__ && __LP64__
    
    COMPILE_ASSERT(!VM_ADDRESS_CONTAIN(nil));
    
    // [1] decide whether object is deallocating
    // note: object be nil is considered inside VM_ADDRESS_CONTAIN
    if(!HMDTaggedPointerAnalyzer_isTaggedPointer((__bridge void *)object)) {
        if(likely(VM_ADDRESS_CONTAIN(object)) &&
           unlikely(HMDObjectAnalyzer_objectIsDeallocating_fast_unsafe((__bridge void *)object))) unsafe = true;
    }
    
    #else   /* x86_64 or arm32 */
    
    // [1] decide whether object is deallocating
    if(likely(object != nil) && unlikely(HMDObjectAnalyzer_objectIsDeallocating_fast_unsafe((__bridge void *)object)))
        unsafe = true;
    
    #endif  /* __arm64__ && __LP64__ */
    
    // [2] obtain shared_origin_objc_storeWeak
    storeWeak_t current_origin_objc_storeWeak = shared_origin_objc_storeWeak;
    
    // [3] should not to call self unexpected
    DEBUG_ASSERT(objc_storeWeak_safe != current_origin_objc_storeWeak &&
                 VM_ADDRESS_CONTAIN(current_origin_objc_storeWeak));
    
    if(unlikely(current_origin_objc_storeWeak == objc_storeWeak_safe ||
                !VM_ADDRESS_CONTAIN(current_origin_objc_storeWeak)))
        current_origin_objc_storeWeak = NULL;
    
    // [4] try recover from unexpected status
    if(unlikely(current_origin_objc_storeWeak == NULL)) {
        void * _Nullable weakFunction = dlsym(RTLD_NEXT, "objc_storeWeak");
        if(weakFunction != NULL) {
            shared_origin_objc_storeWeak  = weakFunction;
            current_origin_objc_storeWeak = weakFunction;
        } DEBUG_ELSE
    }
    
    if(unlikely(current_origin_objc_storeWeak == NULL)) DEBUG_RETURN(nil);
    
    if(unlikely(unsafe)) {
        
        static uint64_t weak_retain_deallocating_protection_count = UINT64_C(0);
        
        if(weak_retain_deallocating_protection_count < MAX_WEAK_RETAIN_DEALLOCATING_PROTECTION_COUNT) {
            
            weak_retain_deallocating_protection_count += UINT64_C(1);
            
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"objc_storeWeak deallocating object");
            
            HMDProtectCapture *capture = [HMDProtectCapture captureException:@"weakRetainDeallocating"
                                                                      reason:@"try to weak retain of deallocated object"];
            HMDProtectBreakpoint();
            
            int lock_rst = pthread_rwlock_rdlock(&g_rwlock);
            HMDProtectCaptureBlock captureBlock = _internal_weakRetain_captureBlock;
            if (likely(lock_rst == 0)) pthread_rwlock_unlock(&g_rwlock);
            
            if(captureBlock) {
                HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread]
                                                                          symbolicate:NO
                                                                         skippedDepth:1
                                                                              suspend:NO];
                if (likely(backtrace != nil)) {
                    capture.backtraces = @[backtrace];
                    capture.crashKeySet = (NSMutableSet<id> * _Nullable)crashKeySet;
                    capture.protectType = HMDProtectionTypeNone;
                    capture.protectTypeString = @"weakRetainDeallocating";
                    captureBlock(capture);
                } DEBUG_ELSE
            }
        }
        
        return current_origin_objc_storeWeak(location, nil);
    }
    
    return current_origin_objc_storeWeak(location, object);
}
CLANG_DIAGNOSTIC_POP
