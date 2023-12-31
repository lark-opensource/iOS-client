//
//  HMDOTTrace.h
//  Pods
//
//  Created by fengyadong on 2019/12/11.
//

#import <Foundation/Foundation.h>
#import "HMDOTTraceDefine.h"
#import "HMDRecordStoreObject.h"

@class HMDOTTraceConfig;
@class HMDOTSpan;


extern NSUInteger hmd_hit_rules_all;
extern NSUInteger hmd_hit_rules_error;

@interface HMDOTTrace : NSObject <HMDRecordStoreObject>

#ifdef DEBUG
@property (nonatomic, assign, readwrite) BOOL isReporting;
#endif

@property (nonatomic, copy, readonly, nullable) NSString *serviceName;
@property (nonatomic, copy, readonly, nullable) NSString *traceID;
@property (nonatomic, copy, readonly, nullable) NSString *appVersion;
@property (nonatomic, copy, readonly, nullable) NSString *updateVersionCode;
@property (nonatomic, copy, readonly, nullable) NSString *osVersion;
@property (nonatomic, copy, readonly, nullable) NSString *sessionID;
@property (nonatomic, assign, readonly) NSUInteger isFinished;
@property (nonatomic, assign, readwrite) NSUInteger hasError;
@property (nonatomic, assign, readonly) NSUInteger hitRules;
@property (nonatomic, strong, readonly, nullable) NSNumber *sampleRate;
@property (atomic, assign, readonly) BOOL isForcedUpload; /*当前trace是否是强制命中采样并上报*/
@property (atomic, copy, readwrite, nullable) NSString *latestSpanID;
@property (atomic, assign, readonly) BOOL needCache;/*是否发生在HMDOTManager启动之前*/
@property (atomic, assign, readonly) BOOL isAbandoned; /*当前的 Trace 是否无效了*/
@property (nonatomic, assign, readonly) HMDOTTraceInsertMode insertMode;/*写入模式*/
@property (nonatomic, assign, readonly) BOOL isMovingLine;/*是否为动线日志*/

/// 初始化一次trace
/// @param serviceName trace的名字 (默认使用当前时间为 trace 开始时间)
+ (nullable instancetype)startTrace:(nonnull NSString *)serviceName;

/// 初始化一次trace
/// @param serviceName trace的名字
/// @param startDate  trace 开始的时间，传空默认是当前时间
+ (nullable instancetype)startTrace:(nonnull NSString *)serviceName startDate:(nullable NSDate *)startDate;

/// 初始化一次trace
/// @param serviceName trace的名字
/// @param startDate trace 开始的时间，传空默认是当前时间
/// @param insertMode span写入模式，具体可以查看HMDOTTraceInsertMode枚举的定义
+ (nullable instancetype)startTrace:(nonnull NSString *)serviceName
                          startDate:(nullable NSDate *)startDate
                         insertMode:(HMDOTTraceInsertMode)insertMode;

/// 创建一个trace
/// @param traceConfig 创建trace时的配置，各项配置信息参考HMDOTTraceConfig类的注释
+ (nullable instancetype)startTraceWithConfig:(nullable HMDOTTraceConfig *)traceConfig;

/// 重置开始时间
/// @param startDate  开始的时间;
- (void)resetTraceStartDate:(nullable NSDate *)startDate;

/// 一次trace结束的标志，必须手动调用; (默认使用当前时间为结束时间)
- (void)finish;

/// 一次trace结束的标志，必须手动调用
/// @param finishDate  trace 结束的时间
- (void)finishWithDate:(nullable NSDate *)finishDate;

/// 一次trace结束的标志，必须手动调用
/// @param delay  延迟结束finish，单位为s
- (void)finishAfterDelay:(NSTimeInterval)delay;

/// 向一次trace中记录筛选信息，可以在平台上筛选分析，trace中的tag最终将作用于当次trace中的每个span上
/// @param key tag的名字，只支持string
/// @param value 值，只支持string
- (void)setTag:(nullable NSString *)key value:(nullable NSString *)value;

/// 废弃当前的 trace; 三种insert model均支持
- (void)abandonCurrentTrace;

/// 禁用[trace启动后 120s不结束断言]
+ (void)ignoreUnfinishedTraceAssert;

/// 启动Debug模式上报
+ (void)enableDebugUpload;

/// 上报cache数据
+ (void)uploadCache;

@end

