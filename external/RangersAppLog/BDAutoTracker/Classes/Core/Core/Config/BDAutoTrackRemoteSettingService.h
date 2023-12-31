//
//  BDAutoTrackRemoteSettingService.h
//  RangersAppLog
//
//  Created by bob on 2019/9/12.
//

#import "BDAutoTrackService.h"

NS_ASSUME_NONNULL_BEGIN



/// 通过logsetting 请求拉回来的settings，优先级高于初始化设置
@interface BDAutoTrackRemoteSettingService : BDAutoTrackService

@property (nonatomic, assign, readonly) NSTimeInterval batchInterval;     /// batch_event_interval
@property (nonatomic, assign, readonly) NSUInteger batchBulkSize;
@property (nonatomic, assign, readonly) NSTimeInterval abFetchInterval;   /// abtest_fetch_interval 目前后台没有下发，取值默认 600
@property (nonatomic, assign) BOOL abTestEnabled;               /// bav_ab_config
@property (nonatomic, assign) BOOL autoTrackEnabled;                      /// bav_log_collect
@property (nonatomic, assign, readonly) BOOL skipLaunch;       /// send_launch_timely 取反
@property (atomic, copy, readonly) NSArray *realTimeEvents;               /// real_time_events 支持 since 6.15.0
@property (nonatomic, assign) NSInteger fetchInterval;

@property (atomic, copy, readonly ) NSArray *sensitiveFields;  //过滤敏感通参 header.{...}

- (instancetype)initWithAppID:(NSString *)appID;
- (void)updateRemoteWithResponse:(NSDictionary *)responseDict;

- (NSDictionary *)devtools_toDictionary;

@end

FOUNDATION_EXTERN BDAutoTrackRemoteSettingService *_Nullable bd_remoteSettingsForAppID(NSString *appID);


NS_ASSUME_NONNULL_END
