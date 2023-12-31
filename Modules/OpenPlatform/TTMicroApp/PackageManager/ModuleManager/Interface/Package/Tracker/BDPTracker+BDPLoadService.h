//
//  BDPTracker+BDPLoadService.h
//  Timor
//
//  Created by 傅翔 on 2019/7/24.
//

#import <OPFoundation/BDPTracker.h>

#define BDPMonitorLoadTimeline(name, aExtra, aUniqueId) [[BDPTracker sharedInstance] monitorLoadTimelineWithName:name extra:aExtra uniqueId:aUniqueId]
#define BDPMonitorLoadTimelineDate(name, aExtra, aDate, aUniqueId) [[BDPTracker sharedInstance] monitorLoadTimelineWithName:name extra:aExtra date:aDate uniqueId:aUniqueId]
#define BDPMonitorLoadTimelineDateTime(name, aExtra, aDate, cTime, aUniqueId) [[BDPTracker sharedInstance] monitorLoadTimelineWithName:name extra:aExtra date:aDate cpuTime:cTime uniqueId:aUniqueId]

NS_ASSUME_NONNULL_BEGIN



/**
 加载相关监控业务方法
 */
@interface BDPTracker (BDPLoadService)

/** 端监控mp_load_timeline事件上报 */
- (void)monitorLoadTimelineWithName:(NSString *)name
                              extra:(nullable NSDictionary *)extra
                           uniqueId:(nullable BDPUniqueID *)uniqueId;

/** 端监控mp_load_timeline事件上报, 可指定date(若有则会设置/覆盖timestamp字段) */
- (void)monitorLoadTimelineWithName:(NSString *)name
                              extra:(nullable NSDictionary *)extra
                               date:(nullable NSDate *)date
                           uniqueId:(nullable BDPUniqueID *)uniqueId;

- (void)monitorLoadTimelineWithName:(NSString *)name
                              extra:(nullable NSDictionary *)extra
                               date:(nullable NSDate *)date
                            cpuTime:(int64_t)cpuTime
                           uniqueId:(nullable BDPUniqueID *)uniqueId;

/** 一组points直接丢, 主要给前端reportTimelinePoints使用 */
- (void)monitorLoadTimelineWithJSONPoints:(NSString *)jsonPoints uniqueId:(BDPUniqueID *)uniqueId;

/** 立马"上报"端监控. 其实就只是传给HMDMonitor */
- (void)flushLoadTimelineWithUniqueId:(BDPUniqueID *)uniqueId;

#pragma mark - 生命周期Id设置
- (void)generateLifecycleIdIfNeededForUniqueId:(BDPUniqueID *)uniqueId;
- (void)removeLifecycleIdWithUniqueId:(BDPUniqueID *)uniqueId;

@end

NS_ASSUME_NONNULL_END
