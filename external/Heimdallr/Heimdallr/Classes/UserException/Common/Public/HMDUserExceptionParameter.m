//
//  HMDUserExceptionParameter.m
//  Heimdallr
//
//  Created by wangyinhui on 2021/9/6.
//

#import "HMDUserExceptionParameter.h"
#import "HMDAsyncThread.h"
#if RANGERSAPM
#import "HMDUserExceptionParameter_RangersAPM.h"
#endif

@implementation HMDUserExceptionParameter

+ (instancetype)initAllThreadParameterWithExceptionType:( NSString * _Nonnull )exceptionType
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.needAllThreads = YES;
    parameter.keyThread = (thread_t)hmdthread_self();
    parameter.exceptionType = exceptionType;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initAllThreadParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                              keyThread:(thread_t)keyThread
                                            debugSymbol:(BOOL)needDebugSymbol
                                           skippedDepth:(NSUInteger)skippedDepth
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.needAllThreads = YES;
    parameter.exceptionType = exceptionType;
    parameter.keyThread = keyThread;
    parameter.needDebugSymbol = needDebugSymbol;
    parameter.skippedDepth = skippedDepth;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initCurrentThreadParameterWithExceptionType:( NSString * _Nonnull )exceptionType
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.needAllThreads = NO;
    parameter.keyThread = (thread_t)hmdthread_self();
    parameter.exceptionType = exceptionType;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initCurrentThreadParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                            debugSymbol:(BOOL)needDebugSymbol
                                           skippedDepth:(NSUInteger)skippedDepth
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.needAllThreads = NO;
    parameter.exceptionType = exceptionType;
    parameter.keyThread = (thread_t)hmdthread_self();
    parameter.needDebugSymbol = needDebugSymbol;
    parameter.skippedDepth = skippedDepth;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initMainThreadParameterWithExceptionType:( NSString * _Nonnull )exceptionType
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.needAllThreads = NO;
    parameter.keyThread = [HMDThreadBacktrace mainThread];
    parameter.exceptionType = exceptionType;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initMainThreadParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                            debugSymbol:(BOOL)needDebugSymbol
                                           skippedDepth:(NSUInteger)skippedDepth
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.needAllThreads = NO;
    parameter.exceptionType = exceptionType;
    parameter.keyThread = [HMDThreadBacktrace mainThread];
    parameter.needDebugSymbol = needDebugSymbol;
    parameter.skippedDepth = skippedDepth;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initThreadParameterWithExceptionType:( NSString * _Nonnull )exceptionType
                                              keyThread:(thread_t)keyThread
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.needAllThreads = NO;
    parameter.keyThread = keyThread;
    parameter.exceptionType = exceptionType;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initThreadParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                              keyThread:(thread_t)keyThread
                                            debugSymbol:(BOOL)needDebugSymbol
                                           skippedDepth:(NSUInteger)skippedDepth
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.needAllThreads = NO;
    parameter.exceptionType = exceptionType;
    parameter.keyThread = keyThread;
    parameter.needDebugSymbol = needDebugSymbol;
    parameter.skippedDepth = skippedDepth;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initBacktraceParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                        backtracesArray:(NSArray<HMDThreadBacktrace *> *)backtraces
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.exceptionType = exceptionType;
    parameter.backtraces = backtraces;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initBaseParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                             title:(NSString *)title
                                          subTitle:(NSString *)subTitle
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.exceptionType = exceptionType;
    parameter.title = title;
    parameter.subTitle = subTitle;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

+ (instancetype)initBaseParameterWithExceptionType:(NSString * _Nonnull)exceptionType
                                             title:(NSString *)title
                                          subTitle:(NSString *)subTitle
                                       addressList:(NSArray<HMDAddressUnit *> *)addressList
                                           customParams:(NSDictionary<NSString *, id> *_Nullable)customParams
                                                filters:(NSDictionary<NSString *, id> *_Nullable)filters
{
    HMDUserExceptionParameter *parameter = [[HMDUserExceptionParameter alloc] init];
    parameter.exceptionType = exceptionType;
    parameter.title = title;
    parameter.subTitle = subTitle;
    parameter.addressList = addressList;
    parameter.customParams = customParams;
    parameter.filters = filters;
    return parameter;
}

@end
