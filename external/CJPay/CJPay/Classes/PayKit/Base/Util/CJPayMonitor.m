//
//  CJPayMonitor.m
//  CJPay
//
//  Created by 王新华 on 8/25/19.
//

#import "CJPayMonitor.h"
#import "CJPaySDKMacro.h"
#import <Heimdallr/HMDTTMonitorUserInfo.h>
#import <Heimdallr/HMDTTMonitor.h>
#import "CJPayRequestParam.h"
#import <BDTrackerProtocol/BDTrackerProtocol.h>
#import <ByteDanceKit/UIApplication+BTDAdditions.h>
#import <Heimdallr/HMDLogUploader.h>
#import "CJPaySettingsManager.h"

@interface CJPayMonitor()

@property (nonatomic, strong) HMDTTMonitor *monitor;
@property (nonatomic, assign) NSTimeInterval lastReportTime;

@end

@implementation CJPayMonitor

+ (instancetype)shared {
    static CJPayMonitor *monitor;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        monitor = [CJPayMonitor new];
    });
    return monitor;
}

- (instancetype)init {
    self = [super init];
    return self;
}

- (HMDTTMonitor *)monitor {
    if (!_monitor) {
        CJPayAppInfoConfig *appInfo = [CJPayRequestParam gAppInfoConfig];
        if (appInfo) {
            static dispatch_once_t onceToken;
            dispatch_once(&onceToken, ^{
                HMDTTMonitorUserInfo *injectedInfo = [[HMDTTMonitorUserInfo alloc] initWithAppID:@"1792"];
                injectedInfo.hostAppID = appInfo.appId;
                injectedInfo.sdkVersion = [CJSDKParamConfig defaultConfig].version;
                injectedInfo.channel = [UIApplication btd_currentChannel];
                injectedInfo.deviceID = appInfo.deviceIDBlock ? appInfo.deviceIDBlock() : [BDTrackerProtocol deviceID];
                _monitor = [[HMDTTMonitor alloc] initMonitorWithAppID:@"1792" injectedInfo:injectedInfo];
            });
        }
    }
    return _monitor;
}

- (void)trackService:(NSString *)name value:(id)value extra:(NSDictionary *)extra {
    [self.monitor hmdTrackService:name metric:@{} category:@{} extra:extra];
    CJPayLogInfo(@"Monitor: name=%@,  extra=%@", name, extra);
}

- (NSDictionary *)p_buildCommonCategoryParams {
    NSMutableDictionary *params = [NSMutableDictionary new];
    [params cj_setObject:[CJSDKParamConfig defaultConfig].version forKey:@"sdk_version"];
    [params cj_setObject:CJString([UIApplication btd_currentChannel]) forKey:@"channel"];
    [params cj_setObject:[CJPayRequestParam gAppInfoConfig].appId forKey:@"aid"];
    NSString *deviceId = [CJPayRequestParam gAppInfoConfig].deviceIDBlock ? [CJPayRequestParam gAppInfoConfig].deviceIDBlock() : [BDTrackerProtocol deviceID];
    [params cj_setObject:CJString(deviceId) forKey:@"device_id"];

    CJPaySettings *currentSettings = [CJPaySettingsManager shared].remoteSettings ?: [CJPaySettingsManager shared].localSettings;
    [params cj_setObject:@(currentSettings.isVIP).stringValue forKey:@"is_vip"];
    return [params copy];
}

#pragma mark - 埋点方法
- (void)trackServiceAllInOne:(NSString *)name
                      metric:(NSDictionary *)metric
                    category:(NSDictionary *)category
                       extra:(NSDictionary *)extra {
    NSMutableDictionary *categoryParams = [NSMutableDictionary dictionaryWithDictionary:[self p_buildCommonCategoryParams]];
    [categoryParams addEntriesFromDictionary:category];
    [categoryParams cj_setObject:CJString(name) forKey:@"event_name"];
    [self.monitor hmdTrackService:@"wallet_rd_exception_all_in_one"
                           metric:metric
                         category:categoryParams
                            extra:extra];
    [self p_uploadAlogWithEventName:name];
    CJPayLogInfo(@"Monitor all in one: name=%@, metric=%@, category=%@, extra=%@", name, metric, category, extra);
}

- (void)trackService:(NSString *)name metric:(NSDictionary *)metric category:(NSDictionary *)category extra:(NSDictionary *)extra {
    NSMutableDictionary *categoryParams = [NSMutableDictionary dictionaryWithDictionary:[self p_buildCommonCategoryParams]];
    [categoryParams addEntriesFromDictionary:category];
    [self.monitor hmdTrackService:name metric:metric category:categoryParams extra:extra];
    [self p_uploadAlogWithEventName:name];
    CJPayLogInfo(@"Monitor: name=%@, metric=%@, category=%@, extra=%@", name, metric, category, extra);
}

- (void)trackService:(NSString *)name category:(NSDictionary *)category extra:(NSDictionary *)extra {
    [self trackService:name metric:@{} category:category extra:extra];
}

- (void)trackService:(NSString *)name extra:(NSDictionary *)extra {
    [self trackService:name metric:@{} category:extra extra:@{}];
}

- (void)p_uploadAlogWithEventName:(NSString *)eventName {
    CJPaySettings *currentSettings = [CJPaySettingsManager shared].remoteSettings ?: [CJPaySettingsManager shared].localSettings;
    CJPayAlogReportConfigModel *reportConfigModel = currentSettings.alogReportConfigModel;
    NSInteger reportTimeInterval = reportConfigModel.reportTimeInterval > 0 ? reportConfigModel.reportTimeInterval : 600;
    NSInteger reportEnableInterval = reportConfigModel.reportEnableInterval > 0 ?  reportConfigModel.reportEnableInterval: 3600;
    NSArray<NSString *> *eventWhiteList = reportConfigModel.eventWhiteList;
    
    // 开关未打开不自动上报
    if (!reportConfigModel.reportEnable) {
        return;
    }
    
    // 非vip不自动上报
    if (!currentSettings.isVIP) {
        return;
    }
    
    // 不在事件白名单不自动上报
    if (![eventWhiteList containsObject:CJString(eventName)]) {
        return;
    }

    NSTimeInterval nowTime = [NSDate date].timeIntervalSince1970;
    NSTimeInterval intervalSinceLastReport = nowTime - self.lastReportTime;
    // 距离上次上报间隔较短不自动上报
    if (intervalSinceLastReport < reportEnableInterval) {
        return;
    }
    
    self.lastReportTime = nowTime;
    NSTimeInterval startTime = nowTime - reportTimeInterval;
    [CJPayTracker event:@"wallet_rd_alog_report"
                 params:@{@"event": CJString(eventName)}];
    [self p_uploadAlogWithStartTime:startTime
                            endTime:nowTime];
}

- (void)p_uploadAlogWithStartTime:(NSTimeInterval)startTime
                          endTime:(NSTimeInterval)endTime {
    CJPayLogInfo(@"start report alog, start_time:%@ end_time:%@", @(startTime), @(endTime));
    [[HMDLogUploader sharedInstance] reportALogWithFetchStartTime:startTime
                                                     fetchEndTime:endTime
                                                            scene:@"cjpay_exception"
                                               reportALogCallback:^(BOOL isSuccess, NSInteger fileCount) {
        
        
        
    }];
}

@end
