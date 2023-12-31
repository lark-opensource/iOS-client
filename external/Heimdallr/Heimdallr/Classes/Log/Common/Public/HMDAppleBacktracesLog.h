//
//  HMDAppleBacktracesLog.h
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/3/18.
//

#import <Foundation/Foundation.h>
#import "HMDThreadBacktrace.h"
#import "HMDLog.h"
#import "HMDAppleBacktracesParameter.h"

@interface HMDAppleBacktracesLog : NSObject

+(void)openFormatOpt;

+(void)closeFormatOpt;

#pragma mark - deprecated API

+ (NSString *_Nullable)getAllThreadsLogByKeyThread:(thread_t)keyThread
                             skippedDepth:(NSUInteger)skippedDepth
                                  logType:(HMDLogType)type __attribute__((deprecated("Please use APIgetAllThreadsLogByKeyThread: maxThreadCount: skippedDepth: logType: suspend: exception: reason:")));

+ (NSString *_Nullable)getAllThreadsLogBySkippedDepth:(NSUInteger)skippedDepth
                                     logType:(HMDLogType)type __attribute__((deprecated("Please use APIgetAllThreadsLogByKeyThread: maxThreadCount: skippedDepth: logType: suspend: exception: reason:")));

+ (NSString *_Nullable)getAllThreadsLogByKeyThread:(thread_t)keyThread
                             skippedDepth:(NSUInteger)skippedDepth
                                  logType:(HMDLogType)type
                                exception:(NSString * _Nullable)exceptionField
                                   reason:(NSString * _Nullable)reasonField __attribute__((deprecated("Please use APIgetAllThreadsLogByKeyThread: maxThreadCount: skippedDepth: logType: suspend: exception: reason:")));

+ (NSString *_Nullable)getMainThreadLogBySkippedDepth:(NSUInteger)skippedDepth
                                     logType:(HMDLogType)type __attribute__((deprecated("Please use getThreadLogByThread: skippedDepth: logType: suspend: exception: reason:")));

+ (NSString *_Nullable)getCurrentThreadLogBySkippedDepth:(NSUInteger)skippedDepth
                                        logType:(HMDLogType)type __attribute__((deprecated("Please use getThreadLogByThread: skippedDepth: logType: suspend: exception: reason:")));

+ (NSString *_Nullable)getThreadLog:(thread_t)thread
            BySkippedDepth:(NSUInteger)skippedDepth
                   logType:(HMDLogType)type __attribute__((deprecated("Please use getThreadLogByThread: skippedDepth: logType: suspend: exception: reason:")));


#pragma mark - New API

+ (thread_t)mainThread;
+ (thread_t)currentThread;

#pragma mark - recommend API

/**
 * 获取线程调用栈,  并格式化为String，调用栈获取及格式化耗时较高，主线程调用时需要考虑耗时
 * @param parameter 获取调用栈的参数
 *  -keyThread BOOL 指定需要获取调用栈的线程id,获取所有线程时无需指定
 *  -isGetMainThread BOOL 指定获取主线程的调用栈，为YES时，keyThread无效，默认值：NO
 *  -maxThreadCount NSUInteger 获取所有线程调用栈时，最大线程数量，默认值：500
 *  -skippedDepth NSUInteger 指定需要忽略的栈顶栈帧数量，默认值：0
 *  -suspend BOOL 获取调用栈时是否挂起线程，不挂起时调用栈可能不准确，默认值：NO
 *  -needDebugSymbol BOOL Debug环境是否进行符号化，只在Debug是生效，默认值：NO
 *  -needAllThreads BOOL 是否获取所有线程，当为YES时，isGetMainThread失效，默认值：NO
 */
+ (NSString * _Nullable)getThreadLogByParameter:(HMDAppleBacktracesParameter *_Nonnull)parameter;

/**
 * 获取线程调用栈, 并格式化为String，格式过程异步执行，减少耗时，推荐使用
 * @param parameter 获取调用栈的参数
 *  -keyThread BOOL 指定需要获取调用栈的线程id,获取所有线程时无需指定
 *  -isGetMainThread BOOL 指定获取主线程的调用栈，为YES时，keyThread无效，默认值：NO
 *  -maxThreadCount NSUInteger 获取所有线程调用栈时，最大线程数量，默认值：500
 *  -skippedDepth NSUInteger 指定需要忽略的栈顶栈帧数量，默认值：0
 *  -suspend BOOL 获取调用栈时是否挂起线程，不挂起时调用栈可能不准确，默认值：NO
 *  -needDebugSymbol BOOL Debug环境是否进行符号化，只在Debug是生效，默认值：NO
 *  -needAllThreads BOOL 是否获取所有线程，当为YES时，isGetMainThread失效，默认值：NO
 * @param callback 处理生成log的回调
 */
+ (void)getThreadLogByParameter:(HMDAppleBacktracesParameter *_Nonnull)parameter callback:(void (^_Nullable)(BOOL, NSString * _Nonnull))callback;

//return async times in callback
+ (void)getAsyncThreadLogByParameter:(HMDAppleBacktracesParameter *_Nonnull)parameter callback:(void (^_Nullable)(BOOL, NSString * _Nonnull, int))callback;

#pragma mark - unrecommend API

/**
 * 参数说明：
 * @param keyThread 标注为崩溃的线程，Slardar平台根据该线程堆栈进行聚合。
 *                  - 主线程：[HMDAppleBacktracesLog mainThread]
 *                  - 当前线程：[HMDAppleBacktracesLog currentThread]
 * @param skippedDepth 当前调用的线程索要忽略的调用栈深度
 * @param maxThreadCount 限制生成日志的最大线程数
 *                      - 0表示不做限制
 *                      - 若当前线程数大于设置最大线程数，取线程队列的前N个生成堆栈信息
 * @param suspend 获取线程堆栈时是否对线程进行挂起
 *                - 挂起线程获取的堆栈准确无误，但会损失部分性能
 *                - 不进行挂起可能会造成堆栈信息失真
 */

// 以下为同步获取log方法，堆栈获取为较耗操作，在主线程时调用，请使用下面的异步方法
+ (NSString * _Nullable)getAllThreadsLogByKeyThread:(thread_t)keyThread
                                     maxThreadCount:(NSUInteger)maxThreadCount
                                       skippedDepth:(NSUInteger)skippedDepth
                                            logType:(HMDLogType)type
                                            suspend:(BOOL)suspend
                                          exception:(NSString * _Nullable)exception
                                             reason:(NSString * _Nullable)reason;

+ (NSString * _Nullable)getThreadLogByThread:(thread_t)keyThread
                                skippedDepth:(NSUInteger)skippedDepth
                                     logType:(HMDLogType)type
                                     suspend:(BOOL)suspend
                                   exception:(NSString * _Nullable)exception
                                      reason:(NSString * _Nullable)reason;

// 以下为异步方法，在主线程调用推荐使用异步方法避免耗时而卡死
+ (void)getAllThreadsLogByKeyThread:(thread_t)keyThread
                     maxThreadCount:(NSUInteger)maxThreadCount
                       skippedDepth:(NSUInteger)skippedDepth
                            logType:(HMDLogType)type
                            suspend:(BOOL)suspend
                          exception:(NSString * _Nullable)exception
                             reason:(NSString * _Nullable)reason
                           callback:(void(^_Nullable)(BOOL success, NSString * _Nullable log))callback;

+ (void)getThreadLogByThread:(thread_t)keyThread
                skippedDepth:(NSUInteger)skippedDepth
                     logType:(HMDLogType)type
                     suspend:(BOOL)suspend
                   exception:(NSString * _Nullable)exception
                      reason:(NSString * _Nullable)reason
                    callback:(void(^_Nullable)(BOOL success, NSString * _Nullable log))callback;

+ (NSString *_Nullable)logWithBacktraces:(NSArray <HMDThreadBacktrace *>*_Nullable)backtraces
                                    type:(HMDLogType)type
                               exception:(NSString * _Nullable)exceptionField
                                  reason:(NSString * _Nullable)reasonField;

/**
 @param backtraceArray   the backtraces need format
 @param type the type of log
 @param exceptionField the exception type of backtraces
 @param reasonField the exception reason of backtraces
 @param includeAllImages If YES, your log length will increase when there is only one thread in the stack, but the advantage is that execution will be faster.

 */
+ (NSString *_Nullable)logWithBacktraceArray:(NSArray<HMDThreadBacktrace *> *_Nullable)backtraceArray
                           type:(HMDLogType)type
                      exception:(NSString * _Nullable)exceptionField
                         reason:(NSString * _Nullable)reasonField
                        includeAllImages:(BOOL)includeAllImages;

+(NSString *_Nullable)logHeaderWithType:(HMDLogType)type
                     exception:(NSString * _Nullable)exceptionField
                        reason:(NSString * _Nullable)reasonField;

+(NSString *_Nullable)logBacktraceArray:(NSArray<HMDThreadBacktrace *> *_Nullable)backtraceArray;

+(NSString *_Nullable)logImageList;


@end
