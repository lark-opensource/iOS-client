//
//  HMDUserException.h
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/4/1.
//

#import "HMDTracker.h"
#import "HMDAddressUnit.h"
#import "HMDAppleBacktracesLog.h"
#import <mach/mach_types.h>
#import "HMDUserExceptionParameter.h"


typedef void (^ _Nullable HMDUserExceptionCallback)(NSError * _Nullable error);
extern NSErrorDomain const _Nonnull HMDUserExceptionErrorDomain;

typedef NS_ENUM(NSInteger, HMDUserExceptionFailType) {
    HMDUserExceptionFailTypeNotWorking  = 1,  // user exception模块没有开启工作
    HMDUserExceptionFailTypeMissingType = 2,  //类型缺失
    HMDUserExceptionFailTypeExceedsLimiting = 3,  //超出客户端限流，1min内同一种类型的自定义异常不可以超过1条
    HMDUserExceptionFailTypeInsertFail = 4,  //写入数据库失败
    HMDUserExceptionFailTypeParamsMissing = 5, // 参数缺失
    HMDUserExceptionFailTypeBlockList = 6, // hitting blockList 
    HMDUserExceptionFailTypeLog = 7, // 日志生成失败
    HMDUserExceptionFailTypeDropData = 8, // 容灾
};

@interface HMDUserExceptionTracker : HMDTracker

+ (instancetype _Nonnull)sharedTracker;

/**
 检查当前类型异常是否可以上报。返回值为nil时，可以上报
 */
- (NSError * _Nullable)checkIfAvailableForType:(NSString * _Nullable)type;

#pragma mark - recommend API
/**
 记录一条自定义异常事件并且上报, 按照参数获取取线程调用栈
 @param parameter 自定义异常上报参数，可使用HMDUserExceptionParameter.h中的初始化方法构建，参数说明：
 *  -exceptionType NSString 异常类型，不可为空
 *  -customParams NSDictionary<NSString *, id> 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 *  -filters NSDictionary<NSString *, id> 自定义的筛选项，可在平台列表页中筛选
 *  --keyThread BOOL 指定需要获取调用栈的线程id,获取所有线程时无需指定
 *  --isGetMainThread BOOL 指定获取主线程的调用栈，为YES时，keyThread无效，默认值：NO
 *  --maxThreadCount NSUInteger 获取所有线程调用栈时，最大线程数量，默认值：500
 *  --skippedDepth NSUInteger 指定需要忽略的栈顶栈帧数量，默认值：0
 *  --suspend BOOL 获取调用栈时是否挂起线程，不挂起时调用栈可能不准确，默认值：NO
 *  --needDebugSymbol BOOL Debug环境是否进行符号化，只在Debug时生效，默认值：NO
 *  --needAllThreads BOOL 是否获取所有线程，当为YES时，isGetMainThread失效，默认值：NO
 @param callback 日志是否记录失败的回调，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackThreadLogWithParameter:(HMDUserExceptionParameter * _Nonnull)parameter
                           callback:(HMDUserExceptionCallback _Nullable)callback;

/**
按照参数获取取线程调用栈，返回各个线程的栈帧
 @param parameter 自定义异常上报参数，可使用HMDUserExceptionParameter.h中的初始化方法构建，参数说明：
 *  -exceptionType NSString 异常类型，不可为空
 *  --keyThread BOOL 指定需要获取调用栈的线程id,获取所有线程时无需指定
 *  --isGetMainThread BOOL 指定获取主线程的调用栈，为YES时，keyThread无效，默认值：NO
 *  --maxThreadCount NSUInteger 获取所有线程调用栈时，最大线程数量，默认值：500
 *  --skippedDepth NSUInteger 指定需要忽略的栈顶栈帧数量，默认值：0
 *  --suspend BOOL 获取调用栈时是否挂起线程，不挂起时调用栈可能不准确，默认值：NO
 *  --needDebugSymbol BOOL Debug环境是否进行符号化，只在Debug时生效，默认值：NO
 *  --needAllThreads BOOL 是否获取所有线程，当为YES时，isGetMainThread失效，默认值：NO
 */
- (NSArray<HMDThreadBacktrace *> * _Nullable)getBacktracesWithParameter:(HMDUserExceptionParameter * _Nonnull)parameter;

/**
 记录一条自定义异常事件并且上报，通过已有栈帧生成记录
 @param parameter 自定义异常上报参数，可使用HMDUserExceptionParameter.h中的初始化方法构建，参数说明：
 *  -exceptionType NSString 异常类型，不可为空
 *  -customParams NSDictionary<NSString *, id> 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 *  -filters NSDictionary<NSString *, id> 自定义的筛选项，可在平台列表页中筛选
 *  -backtraces NSArray<HMDThreadBacktrace *> 线程调用栈信息
 @param callback 日志是否记录失败的回调，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackThreadLogWithBacktraceParameter:(HMDUserExceptionParameter * _Nonnull)parameter
                                    callback:(HMDUserExceptionCallback _Nullable)callback;

/**
 记录一条自定义异常事件并且上报，不携带栈帧
 @param parameter 自定义异常上报参数，可使用HMDUserExceptionParameter.h中的初始化方法构建，参数说明：
 *  -exceptionType NSString 异常类型，不可为空
 *  -title 自定义异常标题（用于聚合）
 *  -subTitle 自定义异常子标题（用于聚合）
 *  -addressList NSArray<HMDAddressUnit *> 需要解析的地址
 *  -customParams NSDictionary<NSString *, id> 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 *  -filters NSDictionary<NSString *, id> 自定义的筛选项，可在平台列表页中筛选
 @param callback 日志是否记录失败的回调，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackBaseExceptionWithBacktraceParameter:(HMDUserExceptionParameter * _Nonnull)parameter
                                        callback:(HMDUserExceptionCallback _Nullable)callback;

#pragma mark - unrecommend API (Not easy to expand)
/**
 记录一条自定义异常事件并且上报所有线程的调用栈，指定当前线程作为关键线程

 @param exceptionType 异常类型，不可为空
 @param skippedDepth 忽略的frame数量，取决你想忽略掉多少个你调用链顶部的frame
 @param customParams 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 @param filters 自定义的筛选项，可在平台列表页中筛选
 @param callback 日志是否记录成功的回调，如果失败的话NSError非空，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackAllThreadsLogExceptionType:(NSString * _Nonnull)exceptionType
                           skippedDepth:(NSUInteger)skippedDepth
                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                filters:(NSDictionary<NSString *, id> * _Nullable)filters
                               callback:(HMDUserExceptionCallback _Nullable)callback;

/**
 记录一条自定义异常事件并且上报所有线程的调用栈，可以指定某个线程作为关键线程

 @param exceptionType 异常类型，不可为空
 @param keyThread 关键线程
 @param skippedDepth 忽略的frame数量，取决你想忽略掉多少个你调用链顶部的frame
 @param customParams 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 @param filters 自定义的筛选项，可在平台列表页中筛选
 @param callback 日志是否记录成功的回调，如果失败的话NSError非空，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackAllThreadsLogExceptionType:(NSString * _Nonnull)exceptionType
                              keyThread:(thread_t)keyThread
                           skippedDepth:(NSUInteger)skippedDepth
                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                filters:(NSDictionary<NSString *, id> * _Nullable)filters
                               callback:(HMDUserExceptionCallback _Nullable)callback;

/**
 * skippedDepth 忽略的frame数量，取决你想忽略掉多少个你调用链顶部的frame
 */

/**
 记录一条自定义异常事件并且上报当前线程的调用栈

 @param exceptionType 异常类型，不可为空
 @param skippedDepth 忽略的frame数量，取决你想忽略掉多少个你调用链顶部的frame
 @param customParams 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 @param filters 自定义的筛选项，可在平台列表页中筛选
 @param callback 日志是否记录成功的回调，如果失败的话NSError非空，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackCurrentThreadLogExceptionType:(NSString * _Nonnull)exceptionType
                              skippedDepth:(NSUInteger)skippedDepth
                              customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                   filters:(NSDictionary<NSString *, id> * _Nullable)filters
                                  callback:(HMDUserExceptionCallback _Nullable)callback;

/**
 记录一条自定义异常事件并且上报主线程的调用栈

 @param exceptionType 异常类型，不可为空
 @param skippedDepth 忽略的frame数量，取决你想忽略掉多少个你调用链顶部的frame
 @param customParams 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 @param filters 自定义的筛选项，可在平台列表页中筛选
 @param callback 日志是否记录成功的回调，如果失败的话NSError非空，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackMainThreadLogExceptionType:(NSString * _Nonnull)exceptionType
                           skippedDepth:(NSUInteger)skippedDepth
                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                filters:(NSDictionary<NSString *, id> * _Nullable)filters
                               callback:(HMDUserExceptionCallback _Nullable)callback;

/**
 记录一条自定义异常事件并且上报指定线程的调用栈

 @param exceptionType 异常类型，不可为空
 @param thread 指定线程
 @param skippedDepth 忽略的frame数量，取决你想忽略掉多少个你调用链顶部的frame
 @param customParams 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 @param filters 自定义的筛选项，可在平台列表页中筛选
 @param callback 日志是否记录成功的回调，如果失败的话NSError非空，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackThreadLogExceptionType:(NSString * _Nonnull)exceptionType
                             thread:(thread_t)thread
                       skippedDepth:(NSUInteger)skippedDepth
                       customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                            filters:(NSDictionary<NSString *, id> * _Nullable)filters
                           callback:(HMDUserExceptionCallback _Nullable)callback;

/**
 * 获取 调用栈异常日志（耗时方法，不推荐使用，请使用
 * getBacktracesWithKeyThread:maxThreadCount:skippedDepth:needAllThreads:suspend）替代
 */
- (NSString * _Nullable)getUserExceptionLogWithType:(NSString * _Nonnull)exceptionType
                             skippedDepth:(NSUInteger)skippedDepth
                                keyThread:(thread_t)keyThread
                           needAllThreads:(BOOL)needAllThreads
                                 callback:(HMDUserExceptionCallback _Nullable)callback __attribute__((deprecated("deprecated. Use getBacktracesWithKeyThread:skippedDepth:needAllThreads: instead")));

/**
 * 通过 调用栈异常日志 生成自定义异常
 */
- (void)trackUserExceptionWithType:(NSString * _Nonnull)exceptionType
                               Log:(NSString * _Nonnull)log
                      CustomParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                           filters:(NSDictionary<NSString *, id> * _Nullable)filters
                          callback:(HMDUserExceptionCallback _Nullable)callback __attribute__((deprecated("deprecated. Use trackUserExceptionWithType:exceptionType:keyThread:backtracesArray:filters:callback: instead")));

/**
 * 参数说明：
 * @param keyThread 目标线程，Slardar平台根据该线程堆栈进行聚合
 *                  - 主线程：[HMDAppleBacktracesLog mainThread]
 *                  - 当前线程：[HMDAppleBacktracesLog currentThread]
 * @param skippedDepth 当前调用的线程索要忽略的调用栈深度
 * @param needAllThreads 是否获取全线程堆栈，NO：只获keyThread线程堆栈
 */
- (NSArray<HMDThreadBacktrace *> * _Nullable)getBacktracesWithKeyThread:(thread_t)keyThread
                                                          skippedDepth:(NSUInteger)skippedDepth
                                                        needAllThreads:(BOOL)needAllThreads;
/**
 * 通过 backtrace 生成自定义异常并上报
 * @param exceptionType 异常类型
 * @param backtraces 通过(getBacktracesWithKeyThread:skippedDepth:needAllThreads:)获取的堆栈信息
 * @param customParams 自定义参数，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 * @param filters 自定义过滤参数
 * @param callback 执行回调
 */
- (void)trackUserExceptionWithType:(NSString * _Nonnull)exceptionType
                   backtracesArray:(NSArray<HMDThreadBacktrace *>* _Nonnull)backtraces
                      customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                           filters:(NSDictionary<NSString *, id> * _Nullable)filters
                          callback:(HMDUserExceptionCallback _Nullable)callback;

/**
 记录一条自定义异常事件，不抓取调用栈

 @param exceptionType 异常类型，不可为空
 @param title 自定义异常标题（用于聚合）
 @param subTitle 自定义异常子标题（用于聚合）
 @param customParams 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 @param filters 自定义的筛选项，可在平台列表页中筛选
 @param callback 日志是否记录成功的回调，如果失败的话NSError非空，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackUserExceptionWithExceptionType:(NSString * _Nonnull)exceptionType
                                      title:(NSString * _Nonnull)title
                                   subTitle:(NSString * _Nonnull)subTitle
                               customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                    filters:(NSDictionary<NSString *, id> * _Nullable)filters
                                   callback:(HMDUserExceptionCallback _Nullable)callback;

/**
 记录一条自定义异常事件，不抓取调用栈，同时传入

 @param exceptionType 异常类型，不可为空
 @param title 自定义异常标题（用于聚合）
 @param subTitle 自定义异常子标题（用于聚合）
 @param addressList 传入的需要被解析的地址
 @param customParams 自定义的现场信息，可在平台详情页中展示，字典必须可转化为json（参考：https://developer.apple.com/documentation/foundation/nsjsonserialization）
 @param filters 自定义的筛选项，可在平台列表页中筛选
 @param callback 日志是否记录成功的回调，如果失败的话NSError非空，errcode的定义见HMDUserExceptionFailType枚举
 */
- (void)trackUserExceptionWithExceptionType:(NSString * _Nonnull)exceptionType
                                      title:(NSString * _Nonnull)title
                                   subTitle:(NSString * _Nonnull)subTitle
                                addressList:(NSArray<HMDAddressUnit *> * _Nullable)addressList
                               customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                    filters:(NSDictionary<NSString *, id> * _Nullable)filters
                                   callback:(HMDUserExceptionCallback _Nullable)callback;

@end

