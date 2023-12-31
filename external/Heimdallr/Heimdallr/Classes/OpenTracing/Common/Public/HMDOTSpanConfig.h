//
//  HMDOTSpanConfig.h
//  Pods
//
//  Created by liuhan on 2022/6/7.
//

#import <Foundation/Foundation.h>
#import "HMDOTTrace.h"

@protocol HMDOTSpanMovinglineDataProtocol <NSObject>

@required
- (NSDictionary *_Nullable)generateMovinglineData;

@end


@interface HMDOTSpanApiAllData : NSObject <HMDOTSpanMovinglineDataProtocol>

@property (nonatomic, copy, nullable) NSString *url;

@property (nonatomic, assign) NSUInteger duration;

@property (nonatomic, assign) NSUInteger status;

- (NSDictionary *_Nullable)generateMovinglineData;

@end


@interface HMDOTSpanTTMonitorData : NSObject <HMDOTSpanMovinglineDataProtocol>

@property (nonatomic, copy, nullable) NSString *logType;
@property (nonatomic, copy, nullable) NSString *serviceName;

- (NSDictionary *_Nullable)generateMovinglineData;

@end


@interface HMDOTSpanViewData : NSObject <HMDOTSpanMovinglineDataProtocol>

@property (nonatomic, copy, nullable) NSString *btm;

@property (nonatomic, assign) NSUInteger status;

- (NSDictionary *_Nullable)generateMovinglineData;

@end

@interface HMDOTSpanCustomEventData : NSObject <HMDOTSpanMovinglineDataProtocol>

@property (nonatomic, copy, nullable) NSString *event;

@property (nonatomic, assign) NSUInteger threadID; // 线程ID

@property (nonatomic, copy, nullable) NSString *threadName; // 线程名称

- (NSDictionary *_Nullable)generateMovinglineData;

@end

@interface HMDOTSpanConfig : NSObject

@property (nonatomic, copy, readonly, nullable) NSString *operationName; /*一次span的名称*/

@property (nonatomic, weak, nullable) HMDOTTrace *trace; /*span的父级trace*/

@property (nonatomic, strong, nullable) NSDate *startDate; /*span开始时间*/

@property (nonatomic, copy, nullable) NSDictionary<NSString*, NSString*> *tags; /*为span记录筛选信息，可以在平台上筛选分析；字典key tag的名字，只支持string；value为tag值，只支持string*/

@property (nonatomic, strong, nullable)NSError *error; /*为span记录错误tag*/

@property (nonatomic, copy, nullable)NSString *errMsg; /*为span记录错误tag*/

@property (atomic, copy, readonly, nullable) NSArray<NSDictionary *> *logs;


#pragma mark - property for movingline
/*仅当trace为movingLine类型时，才生效*/

//日志类别，不同的类别是具备不同的协议的日志格式。
//- 0：原始日志数据 -> 待定，目前不需要
//- 1：applog 日志数据 -> 串联 applog 日志，log_data 中会构造 applog 的关键数据
//- 2：Slardar 网络指标数据 -> 串联网络请求日志，log_data 中会构造网络的关键数据
//- 3：Slardar 事件指标数据 -> 串联性能日志，log_data 中会构造性能日志的关键数据
//- 4~9：预留
//- 10：Alog 日志数据 ->  前端展示
@property (nonatomic, assign)NSUInteger category;

//日志的具体类型，如下定义：
//- 行为交互日志类（1~100）：
//  - 1：页面日志，解析 log_data 中 btm 字段得到页面信息，status 1 表示打开页面，status 2 退出页面
//  - 2：事件日志，解析 log_data 中 event 字段得到事件名信息
//  - 4~99：预留
//- 网络日志类（101~200）：
//  - 101：网络 API 请求日志，解析  log_data 字段中的 url、duration、status
//  - 102~199：预留
@property (nonatomic, assign)NSUInteger type;

// 日志数据：关键数据或者原始数据
@property (nonatomic, strong, nullable) id<HMDOTSpanMovinglineDataProtocol> data;

// 额外信息
@property (nonatomic, strong, nullable)NSDictionary *extra;

// span创建后立即结束。默认为NO，设置为YES后，无需业务再次调用[span finish]手动结束
@property (nonatomic, assign)BOOL isInstant;

// 该Span是否需要关联其他类型日志，默认为true，需要关联其他类型log(事件埋点/网络日志等)
@property (nonatomic, assign)BOOL needReferenceOtherLog;


/// 初始化一条spanConfig
/// @param operationName span的名称
- (nonnull instancetype)initWithOperationName:(nonnull NSString *)operationName;

/// 在span中记录一些关键的信息和对排查问题有意义的上下文信息
/// @param message 关键的信息，只支持string类型
/// @param fields 对排查问题有意义的上下文信息，fields的key和value必须都是string，否则fields整体会被忽略
- (void)logMessage:(nullable NSString *)message fields:(nullable NSDictionary<NSString*, NSString*>*)fields;


- (nonnull id)init __attribute__((unavailable("please use initWithOperationName:")));
+ (nonnull instancetype)new __attribute__((unavailable("please use initWithOperationName:")));

@end
