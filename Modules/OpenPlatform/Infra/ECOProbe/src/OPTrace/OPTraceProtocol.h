//
//  ECOTraceProtocol.h
//  ECOProbe
//
//  Created by qsc on 2021/3/12.
//

#ifndef ECOTraceProtocol_h
#define ECOTraceProtocol_h

#import "OPMonitorServiceProtocol.h"

typedef NS_ENUM(NSUInteger, OPTraceLogLevel) {
    OPTraceLogLevelDebug = 1,
    OPTraceLogLevelInfo  = 2,
    OPTraceLogLevelWarn  = 3,
    OPTraceLogLevelError = 4,
    OPTraceLogLevelFatal = 5
};

NS_ASSUME_NONNULL_BEGIN

@protocol OPTraceProtocol <NSObject, OPMonitorServiceProtocol>

@required

/// traceId
@property (readonly) NSString *traceId;

/// 批量上报时使用的埋点，外部可在此埋点上添加额外的公共参数等数据
@property (nonatomic, strong, readonly, nullable) OPMonitorEvent * batchReportMonitor;
/// 是否允许批量埋点上报
@property (nonatomic, assign, readonly) BOOL batchEnabled;

/// 派生 subTrace
- (instancetype) subTrace;

#pragma mark monitor service protocol, cache monitor data

/// OPMonitorServiceProtocol: 接收一个 monitor flush
///  *注意：需要在 trace 结束时调用 finish 方法触发数据上报！*
/// @param monitor monitor
/// @param platform 打点平台,实时不处理，OPTrace 上报使用 OPMonitor 默认上报平台
- (void)flush:(OPMonitorEvent *)monitor platform:(OPMonitorReportPlatform)platform;

/// OPMonitorServiceProtocol: monitor 打印能力
/// @param monitor 被打印的 monitor
- (void)log:(OPMonitorEvent *)monitor;

#pragma mark monitor batch report


/// Trace finish时，将缓存的 monitor 打包上报
/// **注意** ： 可能会对 monitor 进行规则过滤，monitor 必须符合 OPMonitor 数据定义，包含 domain、code 信息
- (void)finish;

#pragma mark serialize

/// 序列化，用于 Native 与 JS 互传
- (NSString * _Nullable) serialize;
/// 反序列化，用于 Native 与 JS 互传
+ (instancetype  _Nullable) deserializeFrom:(NSString *) json;

@end

NS_ASSUME_NONNULL_END

#endif /* ECOTraceProtocol_h */
