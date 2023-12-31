//
//  HMDProtectNSAssert.m
//  Heimdallr
//
//  Created by sunruwang on whatever
//

#import "HeimdallrUtilities.h"
#import <stdatomic.h>
#import "HMDMacro.h"
#import "HMDProtector.h"
#import "HMDProtectKVC.h"
#import "HMDProtect_Private.h"
#import "HMDProtectCapture.h"
#import "HMDSwizzle.h"
#import "HMDAppleBacktracesLog.h"
#import "HMDALogProtocol.h"

static HMDProtectCaptureBlock _Nullable _internal_NSAssert_captureBlock = nil;
static pthread_rwlock_t g_rwlock = PTHREAD_RWLOCK_INITIALIZER;
static NSMutableSet<NSString*>* crashKeySet = nil;

static void NSAssert_replaceImplementation(void);
static void HMD_NO_OPT_ATTRIBUTE HMD_Protect_NSAssert_handle_exception(HMDProtectCapture *capture);
static NSString * _Nullable HMDP_FullMethodName(id objectOrClass, SEL selector);



#pragma mark - NSAssertionHandler Hooked implementation

@interface NSAssertionHandler (HMDProtectNSAssert) @end
@implementation NSAssertionHandler (HMDProtectNSAssert)
- (void)HMDP_handleFailureInMethod:(SEL)selector object:(id)object file:(NSString *)fileName lineNumber:(NSInteger)line description:(nullable NSString *)format,...  {
    
    /*  关于这里的直接访问 _internal_NSAssert_captureBlock 不加锁是否会有多线程风险
        
        [汇编原码示意]
        adrp        x8, __internal_NSAssert_captureBlock@PAGE
        ldr    x8, [x8, __internal_NSAssert_captureBlock@PAGEOFF]
        cbz    x8, <LABLE: if ended location>
     
        [解释]
        就是简单读取了 __internal_NSAssert_captureBlock 的内存,
        然后简单的判断了是否为 0, 没有其他操作, 没有 retain relase 之类的多线程风险
     
        所以看起来直接访问没啥问题，再者关于 arm64 其实每一次对齐内存的 p2align = 3
        的访问都是原子类型的 (不是原子类型读取也不会崩溃，也不会代码逻辑错误) */
    
    if(_internal_NSAssert_captureBlock) {
        if(unlikely(![HeimdallrUtilities canFindDebuggerAttached])) {
            /* 该处参考的原 NSAssert 输出格式 */
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"*** Assertion failure in %@, %@:%ld",
                                      HMDP_FullMethodName(object, selector), fileName, line);
            va_list ap;
            va_start(ap, format);
            NSString *formattedExceptionReason = [[NSString alloc] initWithFormat:format arguments:ap];
            va_end(ap);
            NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException reason:formattedExceptionReason userInfo:nil];
            HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:nil];
            HMD_Protect_NSAssert_handle_exception(capture);
            
            GCC_FORCE_NO_OPTIMIZATION return;
        }
    }
    
    va_list ap;             // 这里是不会有重复代码的，说到底大部分 va_list 相关宏都是空值
    va_start(ap, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    
    /*  这一步替换所有"%"=>"%%", 是为了防止回调原函数之后的进行再进行格式化输出;
        是的, 我们没法做到完全无损swizzle(不使用汇编语言的话), 但至少我们避免崩溃  */
    description = [description stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
    [self HMDP_handleFailureInMethod:selector object:object file:fileName lineNumber:line description:description];
    
    GCC_FORCE_NO_OPTIMIZATION
}

- (void)HMDP_handleFailureInFunction:(NSString *)functionName file:(NSString *)fileName lineNumber:(NSInteger)line description:(nullable NSString *)format,...  {
    if(_internal_NSAssert_captureBlock) {
        if(unlikely(![HeimdallrUtilities canFindDebuggerAttached])) {
            /* 该处参考的原 NSAssert 输出格式 */
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"*** Assertion failure in %@(), %@:%ld", functionName, fileName, line);
            
            va_list ap;
            va_start(ap, format);
            NSString *formattedExceptionReason = [[NSString alloc] initWithFormat:format arguments:ap];
            va_end(ap);
            
            NSException *exception = [NSException exceptionWithName:NSInternalInconsistencyException
                                                             reason:formattedExceptionReason
                                                           userInfo:nil];
            
            HMDProtectCapture *capture = [HMDProtectCapture captureWithNSException:exception crashKey:nil];
            HMD_Protect_NSAssert_handle_exception(capture);
            
            GCC_FORCE_NO_OPTIMIZATION return;
        }
    }
    
    va_list ap;             // 这里是不会有重复代码的，说到底大部分 va_list 相关宏都是空值
    va_start(ap, format);
    NSString *description = [[NSString alloc] initWithFormat:format arguments:ap];
    va_end(ap);
    
    /*  这一步替换所有"%"=>"%%", 是为了防止回调原函数之后的进行再进行格式化输出;
        是的, 我们没法做到完全无损swizzle(不使用汇编语言的话), 但至少我们避免崩溃  */
    description = [description stringByReplacingOccurrencesOfString:@"%" withString:@"%%"];
    [self HMDP_handleFailureInFunction:functionName file:fileName lineNumber:line description:description];
    
    GCC_FORCE_NO_OPTIMIZATION
}

@end

void HMD_Protect_toggle_NSAssert_protection(HMDProtectCaptureBlock captureBlock) {
    int lock_rst = pthread_rwlock_wrlock(&g_rwlock);
    _internal_NSAssert_captureBlock = captureBlock;
    if (likely(lock_rst == 0)) pthread_rwlock_unlock(&g_rwlock);
    
    static atomic_flag onceToken = ATOMIC_FLAG_INIT;
    if(captureBlock && !atomic_flag_test_and_set_explicit(&onceToken, memory_order_relaxed)) {
        crashKeySet = [[NSMutableSet alloc] init];
        NSAssert_replaceImplementation();
    }
}

static void NSAssert_replaceImplementation(void) {
    Class NSAssertionHandlerClass = NSAssertionHandler.class;
    hmd_swizzle_instance_method(NSAssertionHandlerClass,
                                @selector(handleFailureInMethod:object:file:lineNumber:description:),
                                @selector(HMDP_handleFailureInMethod:object:file:lineNumber:description:));
    hmd_swizzle_instance_method(NSAssertionHandlerClass,
                                @selector(handleFailureInFunction:file:lineNumber:description:),
                                @selector(HMDP_handleFailureInFunction:file:lineNumber:description:));
}

static void HMD_NO_OPT_ATTRIBUTE HMD_Protect_NSAssert_handle_exception(HMDProtectCapture *capture) {
    if (unlikely(capture == nil)) return;
    
    HMDProtect_BDALOG(capture.reason);
    HMDProtectBreakpoint();
    HMDLog(@"[Heimdallr][Protector] NSAssert exception");
   
    int lock_rst = pthread_rwlock_rdlock(&g_rwlock);
    HMDProtectCaptureBlock captureBlock = _internal_NSAssert_captureBlock;
    if (likely(lock_rst == 0)) pthread_rwlock_unlock(&g_rwlock);
    
    if(captureBlock) {
        HMDThreadBacktrace *bt = [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread] symbolicate:NO skippedDepth:2 suspend:NO];
        if (likely(bt)) {
            capture.backtraces = @[bt];
            capture.crashKeySet = (NSMutableSet<id>*)crashKeySet;
            capture.protectType = HMDProtectionTypeNone;
            capture.protectTypeString = @"Assert";
            captureBlock(capture);
        }
    }
    
    GCC_FORCE_NO_OPTIMIZATION
}

static NSString * _Nullable HMDP_FullMethodName(id objectOrClass, SEL selector) {
    if(unlikely(objectOrClass == nil || selector == nil)) return nil;
    Class aClass = object_getClass(objectOrClass);
    
    bool is_metalClass = class_isMetaClass(aClass);
    if(unlikely(is_metalClass)) aClass = objectOrClass;
    
    const char *selectorString = sel_getName(selector);
    if(unlikely(selector == nil)) return nil;
    
    char headCharacter;
    if(is_metalClass) headCharacter = '+';
    else headCharacter = '-';
    
    const char *className = class_getName(aClass);
    if(unlikely(className == nil)) return nil;
    
    return [NSString stringWithFormat:@"%c[%s %s]", headCharacter, className, selectorString];
}

