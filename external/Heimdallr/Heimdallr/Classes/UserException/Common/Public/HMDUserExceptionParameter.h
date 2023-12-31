//
//  HMDUserExceptionParameter.h
//  Pods
//
//  Created by wangyinhui on 2021/9/6.
//

#import <Foundation/Foundation.h>
#import "HMDAppleBacktracesParameter.h"
#import "HMDAddressUnit.h"
#import "HMDThreadBacktrace.h"



@interface HMDUserExceptionParameter : HMDAppleBacktracesParameter

@property(nonatomic, strong, nonnull)NSString *exceptionType; //异常类型，不可为空

@property(nonatomic, strong, nullable)NSString *title;

@property(nonatomic, strong, nullable)NSString *subTitle;

@property(nonatomic, strong, nullable)NSDictionary<NSString *, id> *customParams;

@property(nonatomic, strong, nullable)NSDictionary<NSString *, id> *filters;

@property(nonatomic, strong, nullable)NSArray<HMDAddressUnit *> *addressList;

@property(nonatomic, strong, nullable)NSArray<HMDThreadBacktrace *> *backtraces;

@property(nonatomic, strong, nullable)NSDictionary *viewHierarchy;

//A short string used for aggregation.
@property(nonatomic, strong, nullable)NSString *aggregationKey;

/**参数说明，推荐使用以下init方法初始化
 *  -exceptionType NSString 异常类型，不可为空
 *  -title 自定义异常标题（用于聚合）
 *  -subTitle 自定义异常子标题（用于聚合）
 *  -customParams NSDictionary<NSString *, id> 自定义的现场信息，可在平台详情页中展示
 *  -filters NSDictionary<NSString *, id> 自定义的筛选项，可在平台列表页中筛选
 *  -addressList NSArray<HMDAddressUnit *> 需要解析的地址
 *  -backtraces NSArray<HMDThreadBacktrace *> 线程调用栈信息
 *  --keyThread BOOL 指定需要获取调用栈的线程id,获取所有线程时无需指定
 *  --isGetMainThread BOOL 指定获取主线程的调用栈，为YES时，keyThread无效，默认值：NO
 *  --maxThreadCount NSUInteger 获取所有线程调用栈时，最大线程数量，默认值：500
 *  --skippedDepth NSUInteger 指定需要忽略的栈顶栈帧数量，默认值：0
 *  --suspend BOOL 获取调用栈时是否挂起线程，不挂起时调用栈可能不准确，默认值：NO
 *  --needDebugSymbol BOOL Debug环境是否进行符号化，只在Debug是生效，默认值：NO
 *  --needAllThreads BOOL 是否获取所有线程，当为YES时，isGetMainThread失效，默认值：NO
 */
//获取所有线程调用栈，并指定当前线程为关键线程
+ (instancetype _Nonnull)initAllThreadParameterWithExceptionType:( NSString * _Nonnull )exceptionType
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> * _Nullable)filters;

//获取所有线程调用栈，keyThread为关键线程
+ (instancetype _Nonnull)initAllThreadParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                              keyThread:(thread_t)keyThread
                                            debugSymbol:(BOOL)needDebugSymbol
                                           skippedDepth:(NSUInteger)skippedDepth
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> * _Nullable)filters;

//获取当前线程调用栈
+ (instancetype _Nonnull)initCurrentThreadParameterWithExceptionType:( NSString * _Nonnull )exceptionType
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                                   filters:(NSDictionary<NSString *, id> * _Nullable)filters;

//获取当前线程调用栈
+ (instancetype _Nonnull)initCurrentThreadParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                            debugSymbol:(BOOL)needDebugSymbol
                                           skippedDepth:(NSUInteger)skippedDepth
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                                   filters:(NSDictionary<NSString *, id> * _Nullable)filters;

//获取主线程调用栈
+ (instancetype _Nonnull)initMainThreadParameterWithExceptionType:( NSString * _Nonnull )exceptionType
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                                 filters:(NSDictionary<NSString *, id> * _Nullable)filters;

//获取主线程调用栈
+ (instancetype _Nonnull)initMainThreadParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                            debugSymbol:(BOOL)needDebugSymbol
                                           skippedDepth:(NSUInteger)skippedDepth
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                                 filters:(NSDictionary<NSString *, id> * _Nullable)filters;

//获取指定线程调用栈
+ (instancetype _Nonnull)initThreadParameterWithExceptionType:( NSString * _Nonnull )exceptionType
                                              keyThread:(thread_t)keyThread
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                             filters:(NSDictionary<NSString *, id> * _Nullable)filters;

//获取指定线程调用栈
+ (instancetype _Nonnull)initThreadParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                              keyThread:(thread_t)keyThread
                                            debugSymbol:(BOOL)needDebugSymbol
                                           skippedDepth:(NSUInteger)skippedDepth
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                             filters:(NSDictionary<NSString *, id> * _Nullable)filters;

//上传已有的调用栈信息
+ (instancetype _Nonnull)initBacktraceParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                        backtracesArray:(NSArray<HMDThreadBacktrace *> * _Nullable)backtraces
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> * _Nullable)filters;


//基础自定义异常，不携带调用栈信息
+ (instancetype _Nonnull)initBaseParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                             title:(NSString * _Nullable)title
                                          subTitle:(NSString * _Nullable)subTitle
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                           filters:(NSDictionary<NSString *, id> * _Nullable)filters;

//基础自定义异常，不携带调用栈信息,addressList需要符号化的地址
+ (instancetype _Nonnull)initBaseParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                             title:(NSString * _Nullable)title
                                          subTitle:(NSString * _Nullable)subTitle
                                       addressList:(NSArray<HMDAddressUnit *> * _Nullable)addressList
                                           customParams:(NSDictionary<NSString *, id> * _Nullable)customParams
                                           filters:(NSDictionary<NSString *, id> * _Nullable)filters;

@end


