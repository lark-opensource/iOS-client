//
//  HMDNetTrafficMonitor+TrafficConsume.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/10/23.
//

#import "HMDNetTrafficMonitor.h"

typedef NS_ENUM(NSUInteger, HMDNetTrafficMonitorTrafficType) {
    HMDNetTrafficMonitorNetworkTraffic, /// normal traffic
    HMDNetTrafficMonitorLocalTraffic, /// the local resource that is accessed by network card, but not send request by wifi or cellular
};


@interface HMDNetTrafficMonitor (TrafficConsume)

#pragma mark --- BIZ CONSUM
- (void)startCustomTrafficSpanWithSpanName:(NSString * _Nonnull)trafficSpanName;
- (void)endCustomTrafficSpanWithSpanName:(NSString * _Nonnull)trafficSpanName completion:(void(^ _Nullable)(long long trafficUsage))completion;

/// traffic  consume inject
/// @param trafficBytes 该时间段内消费的流量(Byte) ;
/// @param sourceId  用来区分流量产生来源的标识, 下载时可能是url, 直播时可能是roomId;
/// @param business 业务模块， 比如下载器、直播、点播;
/// @param scene 场景，比如直播可能区分在详情页和feed页。可为空。当为空时，内部会自动按照栈顶,且占用屏幕比例超过百分之 60 的 ViewController 的 classname。
/// @param extraStatus 其他自定义的维度，比如是否是自动播放触发。可为空;
/// @param extraLog 其他自定义的信息，比如业务数据;
- (void)trafficConsumeWithTrafficBytes:(unsigned long long)trafficBytes
                              sourceId:(nonnull NSString *)sourceId
                              business:(nonnull NSString *)business
                                 scene:(nullable NSString *)scene
                           extraStatus:(nullable NSDictionary *)extraStatus
                              extraLog:(nullable NSDictionary *)extraLog;

/// traffic  consume inject
/// @param accumulateTrafficBytes 到当前时间该业务累积消费的流量(Byte);
/// @param sourceId  用来区分流量产生来源的标识, 下载时可能是url, 直播时可能是roomId;
/// @param business 业务模块， 比如下载器、直播、点播;
/// @param scene 场景，比如直播可能区分在详情页和feed页。可为空。当为空时，内部会自动按照栈顶,且占用屏幕比例超过百分之 60 的 ViewController 的 classname。
/// @param extraStatus 其他自定义的维度，比如是否是自动播放触发。可为空;
/// @param extraLog 其他自定义的信息，比如业务数据;
- (void)trafficConsumeWithAccumulateTrafficBytes:(unsigned long long)accumulateTrafficBytes
                                        sourceId:(nonnull NSString *)sourceId
                                        business:(nonnull NSString *)business
                                           scene:(nullable NSString *)scene
                                     extraStatus:(nullable NSDictionary *)extraStatus
                                        extraLog:(nullable NSDictionary *)extraLog;

- (void)trafficConsumeWithTrafficBytes:(unsigned long long)trafficBytes
                              sourceId:(nonnull NSString *)sourceId
                              business:(nonnull NSString *)business
                                 scene:(nullable NSString *)scene
                           extraStatus:(nullable NSDictionary *)extraStatus
                              extraLog:(nullable NSDictionary *)extraLog
                           trafficType:(HMDNetTrafficMonitorTrafficType)trafficType;

- (void)trafficConsumeWithAccumulateTrafficBytes:(unsigned long long)accumulateTrafficBytes
                                        sourceId:(nonnull NSString *)sourceId
                                        business:(nonnull NSString *)business
                                           scene:(nullable NSString *)scene
                                     extraStatus:(nullable NSDictionary *)extraStatus
                                        extraLog:(nullable NSDictionary *)extraLog
                                     trafficType:(HMDNetTrafficMonitorTrafficType)trafficType;

@end

