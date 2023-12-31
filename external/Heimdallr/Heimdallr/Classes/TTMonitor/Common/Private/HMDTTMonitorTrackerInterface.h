//
//  HMDTTMonitorTrackerInterface.h
//  Pods
//
//  Created by 崔晓兵 on 16/3/2022.
//

#ifndef HMDTTMonitorTrackerInterface_h
#define HMDTTMonitorTrackerInterface_h

typedef NS_ENUM(NSInteger, HMDTTMonitorTrackerType);

typedef NS_ENUM(NSInteger, TTMonitorMetricItemType){
    TTMonitorMetricItemTypeTimeNotAssign = 0,
    TTMonitorMetricItemTypeTime = 1,
    TTMonitorMetricItemTypeCount = 2,
};

typedef NS_ENUM(NSUInteger, HMDTTMonitorStoreActionType) {
    HMDTTmonitorStoreActionNormal = 0, // 正常策略的事件处理 monitor->memory->database->upload
    HMDTTmonitorStoreActionStoreImmediately = 1, // 事件立刻写入数据库中 monitor->database->upload
    HMDTTmonitorStoreActionUploadImmediately = 2, // 事件发生后立即上传 monitor->upload
    HMDTTmonitorStoreActionUploadImmediatelyIfNeed = 3, // 事件发生后，如果命中采样则立即上传 monitor->upload
    HMDTTmonitorHighPriotityIgnoreSampling = 4,  //高保事件，全采样写入，monitor->memory->database->upload
};

@protocol HMDTTMonitorOfflineCheckPointProtocol <NSObject>
@optional

- (void)recordDataGeneratedCheckPointWithServiceName:(NSString *)serviceName logType:(NSString *)logTypeStr data:(NSDictionary *)data;
- (void)recordCachedCheckPointWithServiceName:(NSString *)serviceName data:(NSDictionary *)data;
- (void)recordSavedCheckPointWithServiceName:(NSString *)serviceName data:(NSDictionary *)data;
- (void)recordsFetchedCheckPointWithReporter:(NSString *)reporter datas:(NSArray *)dataArr;

@end

@protocol HMDTTMonitorTraceProtocol <NSObject>
@optional

- (void)recordGeneratedCheckPointWithlogType:(NSString *)logTypeStr
                                 serviceType:(NSString*)serviceType
                                       appID:(NSString *)appID
                                  actionType:(HMDTTMonitorStoreActionType)actionType
                                  uniqueCode:(int64_t)uniqueCode;

- (void)recordSavedCheckPointWithRecords:(NSArray *)records
                                 success:(BOOL)success
                                memoryDB:(BOOL)memoryDB
                                   appID:(NSString *)appID;

- (void)recordFetchedCheckPointWithRecords:(NSArray<NSDictionary *> *)records
                                     appID:(NSString *)appID;

@end

@class HMDTTMonitorInterceptorParam;
@protocol HMDTTMonitorTracker <NSObject>
@required
@property (nonatomic, assign) BOOL ignoreLogType;   // Fixme: Just For MT

- (void)trackDataWithParam:(HMDTTMonitorInterceptorParam *)params;

// https: //android%byted%org/ios/monitor/help%html
// 处理 metric 数据，需要考虑是否聚合
- (void)countEvent:(NSString *)type label:(NSString *)label value:(float)value needAggregate:(BOOL)needAggr appID:(NSString *)appID;

- (void)timerEvent:(NSString *)type label:(NSString *)label value:(float)value needAggregate:(BOOL)needAggr appID:(NSString *)appID;

- (BOOL)needUploadWithlogTypeStr:(NSString *)logTypeStr serviceType:(NSString *)serviceType;

- (BOOL)needUploadWithLogTypeStr:(NSString *)logTypeStr serviceType:(NSString *)serviceType data:(NSDictionary *)data;

- (BOOL)isHighPriorityWithLogType:(NSString *)logTypeStr serviceType:(NSString *)serviceType;

- (BOOL)ttmonitorConfigurationAvailable;

- (BOOL)logTypeEnabled:(NSString *)logType;

- (BOOL)serviceTypeEnabled:(NSString *)serviceType;

@end


#endif /* HMDTTMonitorTrackerInterface_h */
