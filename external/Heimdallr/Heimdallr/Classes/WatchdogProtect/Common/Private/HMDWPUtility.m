//
//  HMDWPUtility.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/13.
//

#import "HMDWPUtility.h"
#import "HMDWPCapture.h"
#import "HMDTimeSepc.h"
#import "HMDALogProtocol.h"
#import "HMDGCD.h"

extern bool HMDWPDispatchWorkItemEnabled;

static NSUInteger HMDWPSyncWaitTimes = 4;
static NSTimeInterval HMDWPExceptionWaitInterval = 1.0;
NSTimeInterval const HMDWPExceptionMaxWaitTime = 10.0;

NSErrorDomain const HMDWatchdogProtectErrorDomain = @"HMDWatchdogProtectErrorDomain";

/*!
 * @file @p queue_private.h
 * @enum @p dispatch_queue_flags_t
 *
 * @constant @p DISPATCH_QUEUE_OVERCOMMIT
 * The queue will create a new thread for invoking blocks, regardless of how
 * busy the computer is.
 */
enum {
    DISPATCH_QUEUE_OVERCOMMIT = 0x2ull,
};

@implementation HMDWPUtility

#pragma mark  - Public

+ (void)protectClass:(Class)cls
             slector:(SEL)selector
        skippedDepth:(NSUInteger)skippedDepth
            waitFlag:(atomic_flag * _Nullable)waitFlag
        syncWaitTime:(NSTimeInterval)syncWaitTime
    exceptionTimeout:(NSTimeInterval)exceptionTimeout
   exceptionCallback:(HMDWPExceptionCallback)exceptionCallback
        protectBlock:(dispatch_block_t)block
{
    [self protectSyncWaitTime:syncWaitTime
             exceptionTimeout:exceptionTimeout
            exceptionCallback:exceptionCallback
                 protectBlock:block
                 skippedDepth:skippedDepth+1
                     waitFlag:waitFlag
         protectSelectorBlock:^NSString *{
        return [NSString stringWithFormat:@"+[%@ %@]", cls, NSStringFromSelector(selector)];
    }];
}
    
    

+ (void)protectObject:(id)object
              slector:(SEL)selector
         skippedDepth:(NSUInteger)skippedDepth
             waitFlag:(atomic_flag * _Nullable)waitFlag
         syncWaitTime:(NSTimeInterval)syncWaitTime
     exceptionTimeout:(NSTimeInterval)exceptionTimeout
    exceptionCallback:(HMDWPExceptionCallback)exceptionCallback
         protectBlock:(dispatch_block_t)block
{
    [self protectSyncWaitTime:syncWaitTime
             exceptionTimeout:exceptionTimeout
            exceptionCallback:exceptionCallback
                 protectBlock:block
                 skippedDepth:skippedDepth+1
                     waitFlag:waitFlag
         protectSelectorBlock:^NSString *{
        return [NSString stringWithFormat:@"-[%@ %@]", [object class], NSStringFromSelector(selector)];
    }];
}

#pragma mark - Private

+ (void)protectSyncWaitTime:(NSTimeInterval)syncWaitTime
           exceptionTimeout:(NSTimeInterval)exceptionTimeout
          exceptionCallback:(HMDWPExceptionCallback)exceptionCallback
               protectBlock:(dispatch_block_t)block
               skippedDepth:(NSUInteger)skippedDepth
                   waitFlag:(atomic_flag * _Nullable)waitFlag
       protectSelectorBlock:(NSString*(^)(void))protectSelectorBlock
{
    if (!block) {
        return;
    }
    
    // 检测是否存在当前API阻塞
    if(waitFlag != NULL) {
        if (atomic_flag_test_and_set_explicit(waitFlag, memory_order_relaxed)) {
            DEBUG_OC_LOG(@"Synchronous waiting for blocking, return the default value directly!");
            return;
        }
    }
    
    NSTimeInterval startTS = HMD_XNUSystemCall_timeSince1970();
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    
    if (HMDWPDispatchWorkItemEnabled) {
        dispatch_block_t dispatch_block = dispatch_block_create(0, ^{
            block();
            // waitFlag == NULL 意味着在任意线程防护
            if(waitFlag != NULL) atomic_flag_clear_explicit(waitFlag, memory_order_release);
            dispatch_semaphore_signal(semaphore);
        });
        
        NSString *queueName = @"com.heimdallr.watchdog_protect.wait ";
        if (protectSelectorBlock) {
            queueName = [queueName stringByAppendingString:protectSelectorBlock()];
        }
        dispatch_queue_t protectQueue = dispatch_queue_create(queueName.UTF8String, dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, qos_class_self(), 0));
        dispatch_async(protectQueue, dispatch_block);
        if (dispatch_block_wait(dispatch_block, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(syncWaitTime * NSEC_PER_SEC))) == 0) {
            DEBUG_OC_LOG(@"Synchronous waiting for return");
            return;
        }
    }
    else {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, DISPATCH_QUEUE_OVERCOMMIT), ^{
            block();
            // waitFlag == NULL 意味着在任意线程防护
            if(waitFlag != NULL) atomic_flag_clear_explicit(waitFlag, memory_order_release);
            dispatch_semaphore_signal(semaphore);
        });
        
        for (NSUInteger index = 0; index < HMDWPSyncWaitTimes; index++) {
            if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(syncWaitTime * NSEC_PER_SEC / HMDWPSyncWaitTimes))) == 0) {
                // 在超时时间内得到返回结果，正常返回
                DEBUG_OC_LOG(@"Synchronous waiting for return");
                return;
            }
            DEBUG_OC_LOG(@"Synchronous waiting[%lu]", index);
        }
    }

    
    // 超时时间内未得到返回结果
    HMDWPCapture *capture = [HMDWPCapture captureCurrentBacktraceWithSkippedDepth:skippedDepth+1];
    capture.timeoutInterval = syncWaitTime;
    if (protectSelectorBlock) {
        capture.protectSelector = protectSelectorBlock();
    }
    
    BOOL isMainThread = NSThread.isMainThread;
    capture.mainThread = isMainThread;
    
    NSString *queueName = @"com.heimdallr.watchdog_protect ";
    if (capture.protectSelector) {
        queueName = [queueName stringByAppendingString:capture.protectSelector];
    }
    
    HMDALOG_PROTOCOL_WARN(@"[Heimdallr][HMDWP]%@Synchronization waiting timeout. duration=%.3f", capture.protectSelector, syncWaitTime);
    DEBUG_OC_LOG(@"Synchronization waiting timeout. duration=%.3f", syncWaitTime);
    
    dispatch_queue_t waitQueue = dispatch_queue_create(queueName.UTF8String, DISPATCH_QUEUE_SERIAL);
    hmd_safe_dispatch_async(waitQueue, ^{
        NSTimeInterval blockTime = syncWaitTime;
        NSTimeInterval waitTime = 0;
        while (blockTime + 0.001 < exceptionTimeout) {
            if (exceptionTimeout - blockTime >= HMDWPExceptionWaitInterval) {
                waitTime = HMDWPExceptionWaitInterval;
            }
            else {
                waitTime = exceptionTimeout - blockTime;
            }
            
            if (dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(waitTime * NSEC_PER_SEC))) == 0) {
                // 因为超时所以调用方没有获取同步返回，但是也没有卡死，只是等待时间超过了同步等待阈值
                blockTime += waitTime;
                NSTimeInterval interval = HMD_XNUSystemCall_timeSince1970() - startTS;
                if (blockTime > interval) {
                    blockTime = interval;
                }
                
                capture.type = HMDWPCaptureExceptionTypeWarning;
                capture.blockTimeInterval = blockTime;
                if (exceptionCallback) {
                    exceptionCallback(capture);
                }
                
                HMDALOG_PROTOCOL_WARN(@"[Heimdallr][HMDWP] %@ asynchronous waiting on %s ends. duration: %.3f",
                                      capture.protectSelector,
                                      isMainThread ? "main thread" : "child thread",
                                      capture.blockTimeInterval);
                
                DEBUG_OC_LOG(@"Asynchronous waiting ends.[Warning][%.3f s]", blockTime);
                return;
            }
            else {
                blockTime += waitTime;
                DEBUG_OC_LOG(@"Asynchronous waiting for [%.3f s]", blockTime);
            }
        }
        
        capture.type = HMDWPCaptureExceptionTypeError;
        capture.blockTimeInterval = exceptionTimeout;
        if (exceptionCallback) {
            exceptionCallback(capture);
        }
        
        HMDALOG_PROTOCOL_ERROR(@"[Heimdallr][HMDWP] %@ asynchronous waiting %s timeout, duration: %.3f",
                               capture.protectSelector,
                               isMainThread ? "main thread" : "child thread",
                               capture.blockTimeInterval);
        
        DEBUG_OC_LOG(@"Asynchronous waiting timeout.[Error][%.3f s]", capture.blockTimeInterval);
    });
}

@end
