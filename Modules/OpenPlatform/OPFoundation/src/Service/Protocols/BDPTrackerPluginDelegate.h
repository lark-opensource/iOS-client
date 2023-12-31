//
//  BDPTrackerPluginDelegate.h
//  Pods
//
//  Created by 维旭光 on 2019/3/22.
//

#ifndef BDPTrackerPluginDelegate_h
#define BDPTrackerPluginDelegate_h

#import "BDPBasePluginDelegate.h"

NS_ASSUME_NONNULL_BEGIN

/**
 * 宿主定制埋点接口
 */
@protocol BDPTrackerPluginDelegate <BDPBasePluginDelegate>
@optional

/**
 * 埋点上报 , 使用 Tracker.post 上报，默认打 TEA，若 eventId 为性能相关埋点会同步打 Slardar
 * @param eventId 事件名
 * @param params 埋点参数
 */
- (void)bdp_event:(NSString *)eventId params:(NSDictionary *)params;

/**
 端监控上报

 @param service 服务名称
 @param metric Slardar 的 metric
 @param category Slardar 的 category
 @param extra 额外信息，方便追查问题使用，Slardar 平台不会进行展示，hive 中可以查询
 */
- (void)bdp_monitorService:(NSString *)service
                    metric:(nullable NSDictionary <NSString *, NSNumber *> *)metric
                  category:(nullable NSDictionary *)category
                     extra:(NSDictionary *)extra;

@end

NS_ASSUME_NONNULL_END

#endif /* BDPTrackerPluginDelegate_h */
