//
//  HMDAppleBacktracesLog.m
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/3/18.
//

#import <CoreFoundation/CoreFoundation.h>

#import "HMDAppleBacktracesLog.h"
#import "HMDHeaderLog.h"
#import "HMDBacktraceLog.h"
#import "HMDImageLog.h"
#import "HMDMacro.h"
#import "hmd_thread_backtrace.h"
#import "HMDThreadBacktrace+Private.h"
#import "HMDBinaryImage.h"
#import "HMDGCD.h"

static BOOL isOpenFormatOpt = NO;

@implementation HMDAppleBacktracesLog

+(void)openFormatOpt {
    isOpenFormatOpt = YES;
}

+(void)closeFormatOpt {
    isOpenFormatOpt = NO;
}

#pragma mark - Old

+ (NSString *)getAllThreadsLogByKeyThread:(thread_t)keyThread
                             skippedDepth:(NSUInteger)skippedDepth
                                  logType:(HMDLogType)type {
    NSString *log = [self getAllThreadsLogByKeyThread:keyThread
                                       maxThreadCount:HMDBT_MAX_THREADS_COUNT
                                         skippedDepth:skippedDepth + 1
                                              logType:type
                                              suspend:NO
                                            exception:nil
                                               reason:nil];
    GCC_FORCE_NO_OPTIMIZATION return log;
}

+ (NSString *)getAllThreadsLogBySkippedDepth:(NSUInteger)skippedDepth
                                     logType:(HMDLogType)type {
    NSString *log = [self getAllThreadsLogByKeyThread:[self currentThread]
                                       maxThreadCount:HMDBT_MAX_THREADS_COUNT
                                         skippedDepth:skippedDepth + 1
                                              logType:type
                                              suspend:NO
                                            exception:nil
                                               reason:nil];
    GCC_FORCE_NO_OPTIMIZATION return log;
}

+ (NSString *)getAllThreadsLogByKeyThread:(thread_t)keyThread
                             skippedDepth:(NSUInteger)skippedDepth
                                  logType:(HMDLogType)type
                                exception:(NSString * _Nullable)exceptionField
                                   reason:(NSString * _Nullable)reasonField {
    NSString *log = [self getAllThreadsLogByKeyThread:keyThread
                                       maxThreadCount:HMDBT_MAX_THREADS_COUNT
                                         skippedDepth:skippedDepth + 1
                                              logType:type
                                              suspend:NO
                                            exception:exceptionField
                                               reason:reasonField];
    GCC_FORCE_NO_OPTIMIZATION return log;
}

+ (NSString *)getMainThreadLogBySkippedDepth:(NSUInteger)skippedDepth logType:(HMDLogType)type {
    NSString *log = [self getThreadLogByThread:[self mainThread]
                                  skippedDepth:skippedDepth+1
                                       logType:type
                                       suspend:NO
                                     exception:nil
                                        reason:nil];
    GCC_FORCE_NO_OPTIMIZATION return log;
}

+ (NSString *)getCurrentThreadLogBySkippedDepth:(NSUInteger)skippedDepth logType:(HMDLogType)type {
    NSString *log = [self getThreadLogByThread:[self currentThread]
                                  skippedDepth:skippedDepth+1
                                       logType:type
                                       suspend:NO
                                     exception:nil
                                        reason:nil];
    GCC_FORCE_NO_OPTIMIZATION return log;
}

+ (NSString *)getThreadLog:(thread_t)thread
            BySkippedDepth:(NSUInteger)skippedDepth
                   logType:(HMDLogType)type {
    NSString *log = [self getThreadLogByThread:thread
                                  skippedDepth:skippedDepth+1
                                       logType:type
                                       suspend:NO
                                     exception:nil
                                        reason:nil];
    GCC_FORCE_NO_OPTIMIZATION return log;
}

#pragma mark - New

+ (thread_t)mainThread {
    return (thread_t)hmdbt_main_thread;
}

+ (thread_t)currentThread {
    return (thread_t)hmdthread_self();
}

+ (NSString * _Nullable)getThreadLogByParameter:(HMDAppleBacktracesParameter *)parameter {
    if (parameter.needAllThreads) {
        NSArray<HMDThreadBacktrace *> *backtraces  = [HMDThreadBacktrace backtraceOfAllThreadsWithParameter:parameter];
        NSString *log = [self logWithBacktraces:backtraces type:parameter.logType exception:parameter.exception reason:parameter.reason];
        GCC_FORCE_NO_OPTIMIZATION return log;
    } else {
        HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThreadWithParameter:parameter];
        if (backtrace) {
            NSString *log = [self logWithBacktraces:@[backtrace] type:parameter.logType exception:parameter.exception reason:parameter.reason];
            GCC_FORCE_NO_OPTIMIZATION return log;
        }
        else {
            GCC_FORCE_NO_OPTIMIZATION return nil;
        }
    }
}

+ (void)getThreadLogByParameter:(HMDAppleBacktracesParameter *)parameter
                       callback:(void (^)(BOOL, NSString * _Nonnull))callback {
    if (!callback){
        return;
    }
    if (parameter.needAllThreads) {
        NSArray<HMDThreadBacktrace *> *backtraces  = [HMDThreadBacktrace backtraceOfAllThreadsWithParameter:parameter];
        hmd_safe_dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *log = nil;
            if (backtraces) {
                log = [self logWithBacktraces:backtraces
                                         type:parameter.logType
                                    exception:parameter.exception
                                       reason:parameter.reason];
            }
            
            callback((log!=nil), log);
        });
        
        GCC_FORCE_NO_OPTIMIZATION return;
    } else {
        HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThreadWithParameter:parameter];
        hmd_safe_dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *log = nil;
            if (backtrace) {
                log = [self logWithBacktraces:@[backtrace]
                                         type:parameter.logType
                                    exception:parameter.exception
                                       reason:parameter.reason];
            }
            
            callback((log!=nil), log);
        });
        
        GCC_FORCE_NO_OPTIMIZATION
    }
}
//return async times in block
+ (void)getAsyncThreadLogByParameter:(HMDAppleBacktracesParameter *)parameter
                       callback:(void (^)(BOOL, NSString * _Nonnull, int))callback {
    if (!callback){
        return;
    }
    if (parameter.needAllThreads) {
        NSArray<HMDThreadBacktrace *> *backtraces  = [HMDThreadBacktrace backtraceOfAllThreadsWithParameter:parameter];
        hmd_safe_dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *log = nil;
            __block int async_times = 0;
            if (backtraces) {
                log = [self logWithBacktraces:backtraces
                                         type:parameter.logType
                                    exception:parameter.exception
                                       reason:parameter.reason];
                [backtraces enumerateObjectsUsingBlock:^(HMDThreadBacktrace * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (obj.crashed) {
                        async_times = obj.async_times;
                        *stop = YES;
                    }
                }];
            }
            
            callback((log!=nil), log, async_times);
        });
        
        GCC_FORCE_NO_OPTIMIZATION return;
    } else {
        HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThreadWithParameter:parameter];
        hmd_safe_dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *log = nil;
            if (backtrace) {
                log = [self logWithBacktraces:@[backtrace]
                                         type:parameter.logType
                                    exception:parameter.exception
                                       reason:parameter.reason];
            }
            
            callback((log!=nil), log, backtrace.async_times);
        });
        
        GCC_FORCE_NO_OPTIMIZATION
    }
}

+ (NSString * _Nullable)getAllThreadsLogByKeyThread:(thread_t)keyThread
                                     maxThreadCount:(NSUInteger)maxThreadCount
                                       skippedDepth:(NSUInteger)skippedDepth
                                            logType:(HMDLogType)type
                                            suspend:(BOOL)suspend
                                          exception:(NSString * _Nullable)exception
                                             reason:(NSString * _Nullable)reason {
    NSArray<HMDThreadBacktrace *> *backtraces = [HMDThreadBacktrace backtraceOfAllThreadsWithKeyThread:keyThread
                                                                                           symbolicate:NO
                                                                                            skippedDepth:skippedDepth + 1
                                                                                                 suspend:suspend
                                                                                          maxThreadCount:maxThreadCount];
    NSString *log = [self logWithBacktraces:backtraces type:type exception:exception reason:reason];
    GCC_FORCE_NO_OPTIMIZATION return log;
}

+ (NSString *)getThreadLogByThread:(thread_t)keyThread
                      skippedDepth:(NSUInteger)skippedDepth
                           logType:(HMDLogType)type
                           suspend:(BOOL)suspend
                         exception:(NSString *)exception
                            reason:(NSString *)reason {
    HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThread:keyThread
                                                              symbolicate:NO
                                                             skippedDepth:skippedDepth+1
                                                                  suspend:suspend];
    if (backtrace) {
        NSString *log = [self logWithBacktraces:@[backtrace] type:type exception:exception reason:reason];
        GCC_FORCE_NO_OPTIMIZATION return log;
    }
    else {
        GCC_FORCE_NO_OPTIMIZATION return nil;
    }
}

+ (void)getAllThreadsLogByKeyThread:(thread_t)keyThread
                     maxThreadCount:(NSUInteger)maxThreadCount
                       skippedDepth:(NSUInteger)skippedDepth
                            logType:(HMDLogType)type
                            suspend:(BOOL)suspend
                          exception:(NSString *)exception
                             reason:(NSString *)reason
                           callback:(void (^)(BOOL, NSString * _Nonnull))callback {
    if (!callback) {
        return;
    }
    
    NSArray<HMDThreadBacktrace *> *backtraces = [HMDThreadBacktrace backtraceOfAllThreadsWithKeyThread:keyThread
                                                                                           symbolicate:NO
                                                                                          skippedDepth:skippedDepth + 1
                                                                                               suspend:suspend
                                                                                        maxThreadCount:maxThreadCount];
    hmd_safe_dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *log = nil;
        if (backtraces) {
            log = [self logWithBacktraces:backtraces
                                     type:type
                                exception:exception
                                   reason:reason];
        }
        
        callback((log!=nil), log);
    });
    
    GCC_FORCE_NO_OPTIMIZATION
}

+ (void)getThreadLogByThread:(thread_t)keyThread
                skippedDepth:(NSUInteger)skippedDepth
                     logType:(HMDLogType)type
                     suspend:(BOOL)suspend
                   exception:(NSString *)exception
                      reason:(NSString *)reason
                    callback:(void (^)(BOOL, NSString * _Nonnull))callback {
    if (!callback) {
        return;
    }
    
    HMDThreadBacktrace *backtrace = [HMDThreadBacktrace backtraceOfThread:keyThread
                                                              symbolicate:NO
                                                             skippedDepth:skippedDepth+1
                                                                  suspend:suspend];
    hmd_safe_dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *log = nil;
        if (backtrace) {
            log = [self logWithBacktraces:@[backtrace] type:type exception:exception reason:reason];
        }
        
        callback((log!=nil), log);
    });
    
    GCC_FORCE_NO_OPTIMIZATION
}

+ (NSString *)logWithBacktraces:(NSArray<HMDThreadBacktrace *> *)backtraces
                           type:(HMDLogType)type
                      exception:(NSString * _Nullable)exceptionField
                         reason:(NSString * _Nullable)reasonField {
    NSMutableString *logStr = [NSMutableString stringWithString:[HMDHeaderLog hmdHeaderLogString:type]];
    if (exceptionField) {
        [logStr appendFormat:@"exception %@\n", exceptionField];
    }
    
    if (reasonField) {
        [logStr appendFormat:@"reason %@\n", reasonField];
    }
    
    for (HMDThreadBacktrace *backtrace in backtraces) {
        @autoreleasepool {
            [backtrace symbolicate:false]; // 已经被符号化的会被记录，不会重复操作
            [logStr appendString:[HMDBacktraceLog backtraceLogStringWithBacktraceInfo:backtrace]];
        }
    }
    
    // 单线程堆栈中符号解析需要的 image 地址信息
    if (backtraces.count == 1 && type != HMDLogCrash) {
        NSMutableSet<NSString *> *imageSet = [[NSMutableSet alloc] init];
        HMDThreadBacktrace *bt = backtraces.firstObject;
        for (HMDThreadBacktraceFrame *frame in bt.stackFrames) {
            if (frame.imageName) {
                [imageSet addObject:frame.imageName];
            }
        }
        
        // 额外添加 jailbreak possible images
        if (isOpenFormatOpt) {
            [logStr appendString:[HMDBinaryImage binaryImagesLogStrWithMustIncludeImagesNames:imageSet includePossibleJailbreakImage:YES]];
        }else {
            [logStr appendString:[HMDImageLog binaryImagesLogStrWithMustIncludeImagesNames:imageSet includePossibleJailbreakImage:YES]];
        }
    }
    else {
        if (isOpenFormatOpt) {
            [HMDBinaryImage getSharedBinaryImagesLogStrUsingCallback:^(NSString * _Nonnull log) {
                [logStr appendString:log];
            }];
        }else {
            [logStr appendString:[HMDImageLog binaryImagesLogStr]];
        }
    }
    
    return logStr;
}

+ (NSString *)logWithBacktraceArray:(NSArray<HMDThreadBacktrace *> *)backtraceArray
                           type:(HMDLogType)type
                      exception:(NSString * _Nullable)exceptionField
                         reason:(NSString * _Nullable)reasonField
                  includeAllImages:(BOOL)includeAllImages
{
    NSMutableString *logStr = [NSMutableString stringWithString:[HMDHeaderLog hmdHeaderLogString:type]];
    if (exceptionField) {
        [logStr appendFormat:@"exception %@\n", exceptionField];
    }
    
    if (reasonField) {
        [logStr appendFormat:@"reason %@\n", reasonField];
    }
    
    for (HMDThreadBacktrace *backtrace in backtraceArray) {
        @autoreleasepool {
            [backtrace symbolicate:false]; // 已经被符号化的会被记录，不会重复操作
            [logStr appendString:[HMDBacktraceLog backtraceLogStringWithBacktraceInfo:backtrace]];
        }
    }
    
    // 单线程堆栈中符号解析需要的 image 地址信息
    if (backtraceArray.count == 1 && type != HMDLogCrash && !includeAllImages) {
        NSMutableSet<NSString *> *imageSet = [[NSMutableSet alloc] init];
        HMDThreadBacktrace *bt = backtraceArray.firstObject;
        for (HMDThreadBacktraceFrame *frame in bt.stackFrames) {
            if (frame.imageName) {
                [imageSet addObject:frame.imageName];
            }
        }
        
        // 额外添加 jailbreak possible images
        if (isOpenFormatOpt) {
            [logStr appendString:[HMDBinaryImage binaryImagesLogStrWithMustIncludeImagesNames:imageSet includePossibleJailbreakImage:YES]];
        }else {
            [logStr appendString:[HMDImageLog binaryImagesLogStrWithMustIncludeImagesNames:imageSet includePossibleJailbreakImage:YES]];
        }
    }
    else {
        if (isOpenFormatOpt) {
            [HMDBinaryImage getSharedBinaryImagesLogStrUsingCallback:^(NSString * _Nonnull log) {
                [logStr appendString:log];
            }];
        }else {
            [logStr appendString:[HMDImageLog binaryImagesLogStr]];
        }
    }
    
    return logStr;
}

+(NSString *)logHeaderWithType:(HMDLogType)type
                     exception:(NSString * _Nullable)exceptionField
                        reason:(NSString * _Nullable)reasonField
{
    NSMutableString *logStr = [NSMutableString stringWithString:[HMDHeaderLog hmdHeaderLogString:type]];
    if (exceptionField) {
        [logStr appendFormat:@"exception %@\n", exceptionField];
    }
    
    if (reasonField) {
        [logStr appendFormat:@"reason %@\n", reasonField];
    }
    return logStr;
}

+(NSString *)logBacktraceArray:(NSArray<HMDThreadBacktrace *> *)backtraceArray
{
    NSMutableString *logStr = [NSMutableString new];
    for (HMDThreadBacktrace *backtrace in backtraceArray) {
        @autoreleasepool {
            [backtrace symbolicate:false]; // 已经被符号化的会被记录，不会重复操作
            [logStr appendString:[HMDBacktraceLog backtraceLogStringWithBacktraceInfo:backtrace]];
        }
    }
    return logStr;
}

+(NSString *)logImageList {
    __block NSString *logStr = [NSString new];
    [HMDBinaryImage getSharedBinaryImagesLogStrUsingCallback:^(NSString * _Nonnull log) {
        logStr = log;
    }];
    return logStr;
}


@end
