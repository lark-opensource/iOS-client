/*!@header HMDMainThreadDispatch.m
 * @discussion HOOK 框架，将子线程调用 UI 方法 dispatch 到主线程执行
 */

#import <stdatomic.h>
#import <Stinger/Stinger.h>
#import <Foundation/Foundation.h>
#import "HMDMacro.h"
#import "HMDOCMethod.h"
#import "HMDALogProtocol.h"
#import "pthread_extended.h"
#import "HMDThreadBacktrace.h"
#import "HMDKStingerHookPool.h"
#import "HMDMainThreadDispatch.h"
#import "HMDUserExceptionTracker.h"
#import "HMDWPDynamicSafeData+ThreadSynchronize.h"

#define HMD_MAIN_THREAD_DISPATCH_TIMEOUT 3.0

typedef enum : NSUInteger {
    HMDMainThreadDispatchHookStatusDisable,
    HMDMainThreadDispatchHookStatusEnable,
    
    HMDMainThreadDispatchHookStatusImpossible
} HMDMainThreadDispatchHookStatus;

static inline void prepareForAsyncInvocationIfPossible(id<StingerParams> params);

static NSMutableArray<HMDOCMethod *> *shared_methods;
static pthread_mutex_t shared_mutex = PTHREAD_MUTEX_INITIALIZER;

@implementation HMDMainThreadDispatch: NSObject

@dynamic enable;

+ (instancetype)sharedInstance {
    static HMDMainThreadDispatch *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = HMDMainThreadDispatch.new;
    });
    return shared;
}

static atomic_bool shared_enable = NO;

- (void)setEnable:(BOOL)enable {
    shared_enable = enable;
}

- (BOOL)enable {
    return shared_enable;
}

- (void)dispatchMainThreadMethods:(NSArray<NSString *> *)methods {
    
    NSMutableArray<HMDOCMethod *> *methodArray =
        [NSMutableArray arrayWithCapacity:methods.count];
    
    for(NSString *eachString in methods) {
        DEBUG_ASSERT([eachString isKindOfClass:NSString.class]);
        if(![eachString isKindOfClass:NSString.class]) continue;
        
        HMDOCMethod *method = [HMDOCMethod methodWithString:eachString];
        method.status = HMDMainThreadDispatchHookStatusEnable;
        
        if(method != nil) [methodArray addObject:method];
    }
    
    [HMDMainThreadDispatch updateMethods:methodArray];
}

#pragma mark - Private Method

+ (void)updateMethods:(NSMutableArray<HMDOCMethod *> *)methodArray {
    
#ifdef DEBUG
    NSArray *copiedMethodArray = methodArray.copy;
    for(HMDOCMethod * eachMethod in methodArray) {
        DEBUG_ASSERT(eachMethod.status == HMDMainThreadDispatchHookStatusEnable);
    }
#endif
    
    NSUInteger methodArrayCount = methodArray.count;
    
    pthread_mutex_lock(&shared_mutex);
    
    if(shared_methods == nil) shared_methods = [NSMutableArray arrayWithCapacity:methodArrayCount];
    
    [shared_methods enumerateObjectsUsingBlock:^(HMDOCMethod * _Nonnull alreadyHookedMethod, NSUInteger idx, BOOL * _Nonnull stop) {
        if([methodArray containsObject:alreadyHookedMethod]) {
            alreadyHookedMethod.status = HMDMainThreadDispatchHookStatusEnable;
            [methodArray removeObject:alreadyHookedMethod];
        }
        else alreadyHookedMethod.status = HMDMainThreadDispatchHookStatusDisable;
    }];
    
    [shared_methods addObjectsFromArray:methodArray];
    
#ifdef DEBUG
    for(HMDOCMethod * eachMethod in shared_methods) {
        if([copiedMethodArray containsObject:eachMethod]) {
            DEBUG_ASSERT(eachMethod.status == HMDMainThreadDispatchHookStatusEnable);
        } else {
            DEBUG_ASSERT(eachMethod.status == HMDMainThreadDispatchHookStatusDisable);
        }
    }
#endif
    
    pthread_mutex_unlock(&shared_mutex);
    
    if(methodArray.count > 0)
        for(HMDOCMethod *eachMethod in methodArray)
            [HMDMainThreadDispatch hookMethod:eachMethod];
}

+ (void)hookMethod:(HMDOCMethod *)method {
    [HMDKStingerHookPool hookOCMethod:method block:^(id<StingerParams>  _Nonnull params, HMDWPDynamicSafeData * _Nonnull returnStore, size_t returnSize) {
        // 如果模块启动, 并且不在主线程
        if(shared_enable && pthread_main_np() == 0 && method.status == HMDMainThreadDispatchHookStatusEnable) {
            
            prepareForAsyncInvocationIfPossible(params);
            
            [HMDMainThreadDispatch dispatchMainThreadTimeout:HMD_MAIN_THREAD_DISPATCH_TIMEOUT operation:^{
                DEBUG_ASSERT(returnStore != nil);
                HMDWPCallerStatus callerStatus = returnStore.atomicInfo;
                DEBUG_ASSERT(callerStatus < HMDWPCallerStatusImpossible);
                if(callerStatus != HMDWPCallerStatusWaiting) return;
                
                void *temp = NULL;
                if(returnSize > 0) temp = __builtin_alloca(returnSize);
                
                [params invokeAndGetOriginalRetValue:temp];
                
                if(returnSize > 0) [returnStore storeData:temp];
            }];
            
            GCC_FORCE_NO_OPTIMIZATION return;
        }
        
        DEBUG_ASSERT(returnStore.atomicInfo == HMDWPCallerStatusWaiting);
        
        void *temp = NULL;
        if(returnSize > 0) temp = __builtin_alloca(returnSize);
        
        [params invokeAndGetOriginalRetValue:temp];
        
        if(returnSize > 0) [returnStore storeData:temp];
    }];
}

#pragma mark - Dispatch Main Thread

+ (void)dispatchMainThreadTimeout:(NSTimeInterval)timeout operation:(dispatch_block_t)block {
    if(block == nil) DEBUG_RETURN_NONE;
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        block();
        dispatch_semaphore_signal(semaphore);
    });
    
    BOOL wait_timeout = YES;
    if(dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeout * NSEC_PER_SEC))) == 0)
         wait_timeout = NO;      // 没有超时标记
    
    HMDThreadBacktrace *backtrace =
    [HMDThreadBacktrace backtraceOfThread:[HMDThreadBacktrace currentThread]
                              symbolicate:NO
                             skippedDepth:3
                                  suspend:NO];
    
    backtrace.crashed = YES;
    [[HMDUserExceptionTracker sharedTracker] trackUserExceptionWithType:@"HMDDispatchMain"
                                                        backtracesArray:@[backtrace]
                                                           customParams:nil
                                                                filters:@{@"dispatch_main_timeout": wait_timeout ? @"1":@"0"}
                                                               callback:^(NSError * _Nullable error) {
        if (error != nil)
            HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[HMDDispatchMain] upload user exception failed with error %@", error);
    }];
}

@end

/*!@protocol HMDStingerUpdate
  @discussion 因为在 Stinger 1.1.0 版本，支持 -[id<StingerParams> preGenerateInvocationIfNeed] 方法
   我又没有办法把每个小业务给说动同步升级 Heimdallr + Stinger 版本；出此下策，望大家谅解
 */
@protocol HMDStingerUpdate <NSObject>

- (void)preGenerateInvocationIfNeed;

@end

static inline void prepareForAsyncInvocationIfPossible(id<StingerParams> params) {
    static BOOL globalDecided = NO;       // 全局：是否已经查询 -[id<StingerParams> preGenerateInvocationIfNeed] 方法存在
    static BOOL globalRespondToSEL;       // 全局查询结果：是否 -[id<StingerParams> preGenerateInvocationIfNeed] 方法存在

    // 当前全局是否已经判断完成
    BOOL currentDecided = __atomic_load_n(&globalDecided, __ATOMIC_ACQUIRE);

    // 如果全局已经判断完成，无论如何都会返回
    if(likely(currentDecided)) {
        BOOL respondToSEL = __atomic_load_n(&globalRespondToSEL, __ATOMIC_ACQUIRE);
        if(respondToSEL) [(id<HMDStingerUpdate>)params preGenerateInvocationIfNeed];
        return; //       无论如何都会返回
    }
    
    // 当前查询结果: 是否已经升级 Stinger 版本
    BOOL currentRespondToSEL = NO;
    
    id<NSObject> convertObject = (id<NSObject>)params;
    if([convertObject respondsToSelector:@selector(preGenerateInvocationIfNeed)])
        currentRespondToSEL = YES;

    // 写入全局判断结果
    if(currentRespondToSEL)
         __atomic_store_n(&globalRespondToSEL, YES, __ATOMIC_RELEASE);
    else __atomic_store_n(&globalRespondToSEL, NO,  __ATOMIC_RELEASE);

    // 写入全局是否判断
    __atomic_store_n(&globalDecided, YES, __ATOMIC_RELEASE);
    
    // 如果当前存在相应方法，那么调用一下
    if(currentRespondToSEL) [(id<HMDStingerUpdate>)params preGenerateInvocationIfNeed];
}
