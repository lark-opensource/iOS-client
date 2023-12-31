//
//  HMDOTSpan.h
//  Pods
//
//  Created by fengyadong on 2019/12/11.
//

#import <Foundation/Foundation.h>
#import "HMDOTSpanConfig.h"

@class HMDOTTrace;

@interface HMDOTSpan : NSObject

#ifdef DEBUG
@property (nonatomic, assign, readwrite) BOOL isReporting;
#endif
@property (atomic, copy, readwrite, nullable) NSString *latestChildSpanID;
@property (atomic, weak, readwrite, nullable) HMDOTSpan *parentSpan;
@property (nonatomic, copy, readonly, nullable) NSString *traceID;//一次完整场景的id，在所有span之间共享
@property (nonatomic, copy, readonly, nullable) NSString *spanID;//唯一的id，随机数
@property (nonatomic, weak, readonly, nullable) HMDOTTrace *trace;
@property (nonatomic, assign, readonly) NSUInteger isFinished;

+ (NSString *_Nullable)tableName;

/// 初始化一个trace的span
/// @param trace span归属的trace
/// @param operationName span的名字 (默认使用当前时间为 span 开始时间)
+ (nullable instancetype)startSpanOfTrace:(nullable HMDOTTrace *)trace
                            operationName:(nonnull NSString*)operationName;

/// 初始化一个trace的span
/// @param trace span归属的span
/// @param operationName span的名字
/// @param startDate  span 开始的时间，传nil的话取当前的时间
+ (nullable instancetype)startSpanOfTrace:(nullable HMDOTTrace *)trace
                            operationName:(nonnull NSString*)operationName
                            spanStartDate:(nullable NSDate *)startDate;

/// 初始化一个span的子span
/// @param operationName span的名字
/// @param parent span的父span  (默认使用当前时间为 span 开始时间)
+ (nullable instancetype)startSpan:(nonnull NSString *)operationName
                           childOf:(nullable HMDOTSpan *)parent;

/// 初始化一个span的子span
/// @param operationName span的名字
/// @param parent span的父span
/// @param startDate  span 开始的时间，传nil的话取当前的时间
+ (nullable instancetype)startSpan:(nonnull NSString *)operationName
                            childOf:(nullable HMDOTSpan *)parent
                      spanStartDate:(nullable NSDate *)startDate;

/// 初始化一个span的兄弟span
/// @param operationName  span的名字
/// @param reference 该span的前继兄弟span
+ (nullable instancetype)startSpan:(nonnull NSString *)operationName
                       referenceOf:(nullable HMDOTSpan *)reference;

/// 在span中记录一些关键的信息和对排查问题有意义的上下文信息
/// @param message 关键的信息，只支持string类型
/// @param fields 对排查问题有意义的上下文信息，fields的key和value必须都是string，否则fields整体会被忽略
- (void)logMessage:(nullable NSString *)message fields:(nullable NSDictionary<NSString*, NSString*>*)fields;

/// 记录本次span发生了错误
/// @param error 一个NSError对象
- (void)logError:(nullable NSError *)error;

/// 记录一次错误的信息
/// @param message 错误信息
- (void)logErrorWithMessage:(nullable NSString *)message;

/// 向一次span中记录筛选信息，可以在平台上筛选分析
/// @param key tag的名字，只支持string
/// @param value 值，只支持string
- (void)setTag:(nullable NSString *)key value:(nullable NSString *)value;

/// 重置开始时间
/// @param startDate  开始时间;
- (void)resetSpanStartDate:(nullable NSDate *)startDate;

///  一次span完成的标志，必须手动调用
- (void)finish;

/// 一次span完成的标志，必须手动调用
/// @param endDate 结束时间;
- (void)finishWithEndDate:(nullable NSDate *)endDate;

/// 因为错误导致span中断的一次完成
/// @param error 一个NSError对象
- (void)finishWithError:(nullable NSError *)error;

/// 因为错误导致span中断的一次完成
/// @param message 错误信息，只支持string
- (void)finishWithErrorMsg:(nullable NSString *)message;

/// 创建一个span
///  @param spanConfig 创建span时的配置，各项配置信息参考HMDOTSpanConfig类的注释
+ (nullable instancetype)createSpanWithConfig:(nullable HMDOTSpanConfig *)spanConfig;

/// 启动一个trace的span
/// @param trace span归属的trace
/// @param config 启动span时的配置，各项配置信息参考HMDOTSpanConfig类的注释
+ (nullable instancetype)startSpanOfTrace:(nullable HMDOTTrace *)trace WithConfig:(nullable HMDOTSpanConfig *)config;

/// 启动一个trace的span
/// @param parent span的父级span
/// @param config 启动span时的配置，各项配置信息参考HMDOTSpanConfig类的注释
+ (nullable instancetype)startSpanOfParentSpan:(nullable HMDOTSpan *)parent WithConfig:(nullable HMDOTSpanConfig *)config;

/// 启动一个trace的span
/// @param reference span的前继兄弟span
/// @param config 启动span时的配置，各项配置信息参考HMDOTSpanConfig类的注释
+ (nullable instancetype)startSpanOfReferance:(nullable HMDOTSpan *)reference SpanWithConfig:(nullable HMDOTSpanConfig *)config;

/// 向一个动线span添加关键日志
/// @param category 日志类别
/// @param type 日志具体类型
/// @param data 符合动线协议的关键数据或者原始数据，传递空不生效
/// @param endDate span结束时间，传递空不生效
- (void)setMovingLineCategory:(NSUInteger) category type:(NSUInteger)type data:(nullable id<HMDOTSpanMovinglineDataProtocol>)data  extra:(nullable NSDictionary*)extra AndEndDate:(nullable NSDate *)endDate;

/// 获取该span对应的traceParent，traceparent规则：{version}-{trace_id}-{parent_id}-{flags}
- (nullable NSString *)getTraceParent;

@end
