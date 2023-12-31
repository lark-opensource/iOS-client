//
//  HMDNetTrafficMonitor+TrafficConsume.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/10/23.
//

#import "HMDNetTrafficMonitor+TrafficConsume.h"
#import "HMDNetworkTraffic.h"
#import "HMDNetTrafficMonitorRecord.h"
#import "HMDNetTrafficUsageStatistics.h"
#import "HMDNetworkHelper.h"
#import "NSArray+HMDSafe.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDNetTrafficSourceUsageModel.h"
#import "HMDNetTrafficUsageModel+Report.h"
#import "HMDNetTrafficMonitor+Privated.h"
#import "HMDGCD.h"
#import <TTReachability/TTReachability.h>
#import "NSDictionary+HMDSafe.h"
#import "HMDNetTrafficDefinedKey.h"
// PrivateServices
#import "HMDMonitorService.h"

#define kHMDTrafficMonitorIntervalDuration  (600)
static hmd_IOBytes intervalTrafficBeforeUsage;
static hmd_IOBytes intervalTrafficBeforeAppStateUsage;
static long long intervalTrafficWiFiBackUsage;
static long long intervalTrafficWiFiFrontUsage;
static long long intervalTrafficCellularBackUsage;
static long long intervalTrafficCellularFrontUsage;

@interface HMDNetTrafficMonitor ()
- (void)processRecordUniformly:(HMDNetTrafficMonitorRecord *)record;
@end

@implementation HMDNetTrafficMonitor (TrafficConsume)

#pragma mark
#pragma mark --- traffic consume public method
- (void)trafficConsumeWithTrafficBytes:(unsigned long long)trafficBytes
                              sourceId:(NSString *)sourceId
                              business:(NSString *)business
                                 scene:(NSString *)scene
                           extraStatus:(NSDictionary *)extraStatus
                              extraLog:(NSDictionary *)extraLog {
    [self.statisticsTool hmdBizConsumeWithTrafficBytes:trafficBytes
                                              sourceId:sourceId
                                              business:business
                                                 scene:scene
                                           extraStatus:extraStatus
                                              extraLog:extraLog
                                   isCurrentTotalUsage:NO
                                           trafficType:HMDNetTrafficMonitorNetworkTraffic];
}

- (void)trafficConsumeWithAccumulateTrafficBytes:(unsigned long long)accumulateTrafficBytes
                                        sourceId:(NSString *)sourceId
                                        business:(NSString *)business
                                           scene:(NSString *)scene
                                     extraStatus:(NSDictionary *)extraStatus
                                        extraLog:(NSDictionary *)extraLog {
    [self.statisticsTool hmdBizConsumeWithTrafficBytes:accumulateTrafficBytes
                                              sourceId:sourceId
                                              business:business
                                                 scene:scene
                                           extraStatus:extraStatus
                                              extraLog:extraLog
                                   isCurrentTotalUsage:YES
                                           trafficType:HMDNetTrafficMonitorNetworkTraffic];
}

- (void)trafficConsumeWithTrafficBytes:(unsigned long long)trafficBytes
                              sourceId:(NSString *)sourceId
                              business:(NSString *)business
                                 scene:(NSString *)scene
                           extraStatus:(NSDictionary *)extraStatus
                              extraLog:(NSDictionary *)extraLog
                           trafficType:(HMDNetTrafficMonitorTrafficType)trafficType {
    [self.statisticsTool hmdBizConsumeWithTrafficBytes:trafficBytes
                                              sourceId:sourceId
                                              business:business
                                                 scene:scene
                                           extraStatus:extraStatus
                                              extraLog:extraLog
                                   isCurrentTotalUsage:NO
                                           trafficType:trafficType];
}

- (void)trafficConsumeWithAccumulateTrafficBytes:(unsigned long long)accumulateTrafficBytes
                                        sourceId:(NSString *)sourceId
                                        business:(NSString *)business
                                           scene:(NSString *)scene
                                     extraStatus:(NSDictionary *)extraStatus
                                        extraLog:(NSDictionary *)extraLog
                                     trafficType:(HMDNetTrafficMonitorTrafficType)trafficType {
    [self.statisticsTool hmdBizConsumeWithTrafficBytes:accumulateTrafficBytes
                                              sourceId:sourceId
                                              business:business
                                                 scene:scene
                                           extraStatus:extraStatus
                                              extraLog:extraLog
                                   isCurrentTotalUsage:YES
                                           trafficType:trafficType];
}

- (void)networkTrafficUsageWithURL:(NSString *)url
                         sendBytes:(unsigned long long)sendBytes
                         recvBytes:(unsigned long long)recvBytes
                        clientType:(nonnull NSString *)clientType
                          MIMEType:(nonnull NSString *)MIMEType {
    [self.statisticsTool networkTrafficUsageWithURL:url
                                        sendBytes:sendBytes
                                        recvBytes:recvBytes
                                       clientType:clientType
                                         MIMEType:MIMEType];
}

- (void)networkTrafficUsageWithURL:(NSString *)url
                        requestLog:(NSString *)requestLog
                        clientType:(nonnull NSString *)clientType
                          MIMEType:(nonnull NSString *)MIMEType {
    [self.statisticsTool networkTrafficUsageWithURL:url
                                       requestLog:requestLog
                                       clientType:clientType
                                         MIMEType:MIMEType];
}

#pragma mark - span
- (void)startCustomTrafficSpanWithSpanName:(NSString *)trafficSpanName {
    if (![trafficSpanName isKindOfClass:[NSString class]]) { return; }
    if (trafficSpanName.length == 0) { return; }
    dispatch_sync(self.trafficCollectQueue, ^{
        NSDictionary *beforeInfo = [self.customSpanInfoDict hmd_objectForKey:trafficSpanName class:[NSDictionary class]];
        if (beforeInfo) {
            return;
        }
        long long startTime = [[NSDate date] timeIntervalSince1970] * 1000;
        hmd_IOBytes current = hmd_getFlowIOBytes();
        unsigned long long currentUsage = current.totalSent + current.totalReceived;
        NSDictionary *customInfo = @{
            kHMDTrafficCustomInfoBeforeUsage: @(currentUsage),
            kHMDTrafficCustomInfoBeforeTimestamp: @(startTime)
        };
        [self.customSpanInfoDict hmd_setObject:customInfo forKey:trafficSpanName];
        [self.statisticsTool addCustomSpanTrafficCollect:trafficSpanName];
    });
}

- (void)endCustomTrafficSpanWithSpanName:(NSString *)trafficSpanName completion:(void (^ _Nullable)(long long))completion {
    if (!trafficSpanName) { return; }
    __weak typeof(self) weakSelf = self;
    dispatch_sync(self.trafficCollectQueue, ^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSDictionary *beforeInfo = [self.customSpanInfoDict hmd_objectForKey:trafficSpanName class:[NSDictionary class]];
        if (beforeInfo) {
            long long currentTime = [[NSDate date] timeIntervalSince1970] * 1000;
            hmd_IOBytes current = hmd_getFlowIOBytes();
            unsigned long long currentUsage = current.totalSent + current.totalReceived;
            long long beforeTime = [beforeInfo hmd_longLongForKey:kHMDTrafficCustomInfoBeforeTimestamp];
            unsigned long long beforeUsage = [beforeInfo hmd_unsignedLongLongForKey:kHMDTrafficCustomInfoBeforeUsage];

            unsigned long long usage = currentUsage - beforeUsage;
            NSDictionary *customExtraValue = @{
                trafficSpanName?:@"unknown" : @(usage)
            };
            NSDictionary *extraInfo = @{
                kHMDTrafficCustomInfoInitTimeKey: @(beforeTime),
                kHMDTrafficCustomInfoEndTimeKey: @(currentTime)
            };
            HMDNetTrafficMonitorRecord *record = [HMDNetTrafficMonitorRecord newRecord];
            record.isCustomSpan = YES;
            record.customExtraValue = customExtraValue;
            record.customExtra = extraInfo;

            [strongSelf.statisticsTool endCustomSpanTrafficCollect:trafficSpanName completion:^(HMDNetTrafficIntervalUsageModel * _Nonnull interval) {
                // biz usage
                if (interval.businessUsage && interval.businessUsage.count > 0) {
                    // for report
                    NSArray *bizUsages = [strongSelf collectIntervalBizUsage:interval];
                    if (bizUsages && bizUsages.count > 0) {
                        record.trafficDetail = @{
                            kHMDTrafficReportKeyUsageDetail: bizUsages?:@[]
                        };
                    }
                }
                [strongSelf.curve pushRecord:record];
                [strongSelf.customSpanInfoDict removeObjectForKey:trafficSpanName];
                if (completion) {
                    completion(usage);
                }
            }];

        } else if(completion) {
            completion(0);
        }
    });
}

#pragma mark --- start and end  interval traffic
- (void)setupTimerForIntervalTrafficUsage {
    if (!self.intervalTrafficTimer) {
        intervalTrafficBeforeUsage = hmd_getFlowIOBytes();
        intervalTrafficBeforeAppStateUsage = intervalTrafficBeforeUsage;
        hmd_safe_dispatch_async(dispatch_get_main_queue(), ^{
            if ([UIApplication sharedApplication].applicationState == UIApplicationStateActive) {
                [HMDNetTrafficMonitor changeTrafficAppState:HMDNetTrafficApplicationStateForeground];
                self.statisticsTool.isBackground = NO;
            }
        });

        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, self.trafficCollectQueue);
        NSTimeInterval timerInterval = MAX(10, kHMDTrafficMonitorIntervalDuration);

        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, timerInterval * NSEC_PER_SEC), timerInterval * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
        __weak __typeof(self) wself = self;
        dispatch_source_set_event_handler(timer, ^{
            __strong typeof(wself) sself = wself;
            [sself trafficUsagerPreTenMinutes];
        });
        dispatch_resume(timer);
        self.intervalTrafficTimer = timer;
    }
}

- (void)stopTimeForIntervalTrafficUsageIfNeed {
    if (self.intervalTrafficTimer) {
        dispatch_source_cancel(self.intervalTrafficTimer);
        self.intervalTrafficTimer = nil;
        [self.statisticsTool resetStatisticsDataOnSafeThread];
    }
}

- (void)switchIntervalTimerWithStatus:(BOOL)enableIntervalTimer {
    BOOL isTimerinitialize = self.intervalTrafficTimer != nil;
    if (isTimerinitialize == enableIntervalTimer) { return; }
    if (enableIntervalTimer) {
        [self setupTimerForIntervalTrafficUsage];
    } else {
        [self stopTimeForIntervalTrafficUsageIfNeed];
    }
}

#pragma mark --- record interval traffic usage info
// 统计十分钟内的设备总流量
- (void)trafficUsagerPreTenMinutes {
    hmd_IOBytes current = hmd_getFlowIOBytes();
    hmd_IOBytes usageInterval = [[self class] relativeDataForIntervalUsageBefore:current];
    HMDNetTrafficApplicationStateType appState = [HMDNetTrafficMonitor currentTrafficAppState];

    // record traffic usage
    unsigned long long totalUsage = usageInterval.totalSent + usageInterval.totalReceived;
    unsigned long long wifiTotalUsage = usageInterval.wifiSent + usageInterval.wifiReceived;
    unsigned long long cellualrTotalUsage = usageInterval.cellularSent + usageInterval.cellularReceived;

    long long wifiBack = 0;
    long long wifiFront = 0;
    long long cellularBack = 0;
    long long cellularFront = 0;
    // no app state change
    if (intervalTrafficCellularFrontUsage == 0 &&
        intervalTrafficCellularBackUsage == 0 &&
        intervalTrafficWiFiFrontUsage == 0 &&
        intervalTrafficWiFiBackUsage == 0) {
        if (appState == HMDNetTrafficApplicationStateForeground) {
            wifiFront = wifiTotalUsage;
            cellularFront = cellualrTotalUsage;
        } else {
            wifiBack = wifiTotalUsage;
            cellularBack = cellualrTotalUsage;
        }
    } else {
        wifiFront = intervalTrafficWiFiFrontUsage;
        intervalTrafficWiFiFrontUsage = 0;
        wifiBack = intervalTrafficWiFiBackUsage;
        intervalTrafficWiFiBackUsage = 0;
        cellularFront = intervalTrafficCellularFrontUsage;
        intervalTrafficCellularFrontUsage = 0;
        cellularBack = intervalTrafficCellularBackUsage;
        intervalTrafficCellularBackUsage = 0;

        // the traffic usage from last app state change to now
        hmd_IOBytes beforeIO = intervalTrafficBeforeAppStateUsage;
        if (appState == HMDNetTrafficApplicationStateForeground) {
            u_int32_t wifiDiff = (current.wifiSent - beforeIO.wifiSent) + (current.wifiReceived - beforeIO.wifiReceived);
            u_int32_t cellularDiff = (current.cellularSent - beforeIO.cellularSent) + (current.cellularReceived - beforeIO.cellularReceived);
            wifiFront += wifiDiff;
            cellularFront += cellularDiff;
        } else if (appState == HMDNetTrafficApplicationStateBackground) {
            u_int32_t wifiDiff = (current.wifiSent - beforeIO.wifiSent) + (current.wifiReceived - beforeIO.wifiReceived);
            u_int32_t cellularDiff = (current.cellularSent - beforeIO.cellularSent) + (current.cellularReceived - beforeIO.cellularReceived);
            wifiBack += wifiDiff;
            cellularBack += cellularDiff;
        }
    }
    intervalTrafficBeforeAppStateUsage = current;

    NSString *netType = @"";
    if (wifiTotalUsage > 0 && cellualrTotalUsage > 0) {
        netType = @"wifi_mobile";
    } else if (wifiTotalUsage > 0 && cellualrTotalUsage == 0) {
        netType = @"wifi";
    } else {
        netType = @"mobile";
    }

    // app state type
    HMDNetTrafficFrontType frontType;
    if (appState == HMDNetTrafficApplicationStateForeground) {
        frontType = kHMDNetTrafficFrontTypeForeground;
    } else if (appState == HMDNetTrafficApplicationStateBackground) {
        frontType = kHMDNetTrafficFrontTypeBackgroundEverFront;
    } else if (appState == HMDNetTrafficApplicationStateNeverFront) {
        frontType = kHMDNetTrafficFrontTypeBackgroundNeverFront;
    }

    HMDNetTrafficMonitorRecord *record = [HMDNetTrafficMonitorRecord newRecordWithFrontType:frontType netType:netType];
    record.tenMinUsage = totalUsage;
    record.isTenMinRecord = YES;
    record.customExtraValue = @{
        kHMDTrafficReportUsageKeyWiFiBack: @(wifiBack),
        kHMDTrafficReportUsageKeyWiFiFront: @(wifiFront),
        kHMDTrafficReportUsageKeyMobileBack: @(cellularBack),
        kHMDTrafficReportUsageKeyMobileFront: @(cellularFront)
    };

    // out of threshold only totoalUsage record
    HMDNetTrafficMonitorConfig *trafficConfig = (HMDNetTrafficMonitorConfig *)self.config;
    if (trafficConfig.intervalTrafficThreshold > 0 &&
        totalUsage > trafficConfig.intervalTrafficThreshold) {
        record.isExceptionTraffic = YES;
        [record.exceptionTypes hmd_addObject:kHMDTrafficAbnormalTypeTotalUsage];
    } else if(appState == HMDNetTrafficApplicationStateBackground &&
              trafficConfig.backgroundTrafficThreshold > 0 &&
              totalUsage > trafficConfig.backgroundTrafficThreshold) {
        record.isExceptionTraffic = YES;
        [record.exceptionTypes hmd_addObject:kHMDTrafficAbnormalTypeBgUsage];
    } else if (appState == HMDNetTrafficApplicationStateNeverFront &&
               trafficConfig.neverFrontTrafficThreshold > 0 &&
               totalUsage > trafficConfig.neverFrontTrafficThreshold) {
        record.isExceptionTraffic = YES;
        [record.exceptionTypes hmd_addObject:kHMDTrafficAbnormalTypeNeverFrontUsage];
    }

    BOOL enableBizCollect = NO;
    if ([self.config isKindOfClass:[HMDNetTrafficMonitorConfig class]]) {
        enableBizCollect = ((HMDNetTrafficMonitorConfig *)self.config).enableBizTrafficCollect;
    }

    if (enableBizCollect) {
        __weak typeof(self) weakSelf = self;
        [self trafficDetialDumpWithTotalRecord:record
                                    completion:^{
           __strong typeof(weakSelf) strongSelf = weakSelf;
            if (record.exceptionTypes.count > 0) {
                record.isExceptionTraffic = YES;
            }
            [strongSelf processRecordUniformly:record];
        }];
    } else {
        [self processRecordUniformly:record];
    }

    // callback
    NSDictionary *callBackInfo = @{
        kHMDTrafficMonitorCallbackInfoKeyWiFiFront: @(wifiFront),
        kHMDTrafficMonitorCallbackInfoKeyCellularFront: @(cellularFront),
        kHMDTrafficMonitorCallbackInfoKeyWiFiBack: @(wifiBack),
        kHMDTrafficMonitorCallbackInfoKeyCellularBack: @(cellularBack)
    };

    [self executePublicCallBackWithMonitorType:kHMDTrafficMonitorCallbackTypeIntervalDeviceUsage usage:callBackInfo biz:nil];
}

+ (hmd_IOBytes)relativeDataForIntervalUsageBefore:(hmd_IOBytes)current {
    [self monitorInvalidIOBytesValue:current];
    hmd_IOBytes relative =
    {
        current.wifiSent >= intervalTrafficBeforeUsage.wifiSent ? (current.wifiSent - intervalTrafficBeforeUsage.wifiSent) : 0,
        current.wifiReceived >= intervalTrafficBeforeUsage.wifiReceived ? (current.wifiReceived - intervalTrafficBeforeUsage.wifiReceived) : 0,
        current.cellularSent >= intervalTrafficBeforeUsage.cellularSent ? (current.cellularSent - intervalTrafficBeforeUsage.cellularSent) : 0,
        current.cellularReceived >= intervalTrafficBeforeUsage.cellularReceived ? (current.cellularReceived - intervalTrafficBeforeUsage.cellularReceived) : 0,
        current.totalSent >= intervalTrafficBeforeUsage.totalSent ? (current.totalSent - intervalTrafficBeforeUsage.totalSent) : 0,
        current.totalReceived >= intervalTrafficBeforeUsage.totalReceived ? (current.totalReceived - intervalTrafficBeforeUsage.totalReceived) : 0
    };
    intervalTrafficBeforeUsage = current;

    return relative;
}

+ (void)monitorInvalidIOBytesValue:(hmd_IOBytes)current {
    if ((current.wifiSent < intervalTrafficBeforeUsage.wifiSent) ||
        (current.wifiReceived < intervalTrafficBeforeUsage.wifiReceived) ||
        (current.cellularSent < intervalTrafficBeforeUsage.cellularSent) ||
        (current.cellularReceived < intervalTrafficBeforeUsage.cellularReceived) ||
        (current.totalSent < intervalTrafficBeforeUsage.totalSent) ||
        (current.totalReceived < intervalTrafficBeforeUsage.totalReceived)
        ) {
        NSDictionary *metric = @{
            @"wifiSent" : @(current.wifiSent),
            @"wifiReceived" : @(current.wifiReceived),
            @"cellularSent" : @(current.cellularSent),
            @"cellularReceived" : @(current.cellularReceived),
            @"totalSent" : @(current.totalSent),
            @"totalReceived" : @(current.totalReceived),
            @"lastWifiSent" : @(intervalTrafficBeforeUsage.wifiSent),
            @"lastWifiReceived" : @(intervalTrafficBeforeUsage.wifiReceived),
            @"lastCellularSent" : @(intervalTrafficBeforeUsage.cellularSent),
            @"lastCellularReceived" : @(intervalTrafficBeforeUsage.cellularReceived),
            @"lastTotalSent" : @(intervalTrafficBeforeUsage.totalSent),
            @"lastTotalReceived" : @(intervalTrafficBeforeUsage.totalReceived),
        };
        [HMDMonitorService trackService:@"slardar_illegal_traffic_value" metrics:metric dimension:nil extra:nil];
    }
}

#pragma mark exception traffic

- (void)trafficDetialDumpWithTotalRecord:(HMDNetTrafficMonitorRecord *)record
                              completion:(void(^)(void))completion {
    // exception traffic standard
    __weak typeof(self) weakSelf = self;
    [self.statisticsTool intervalTrafficDetailWithModel:^(HMDNetTrafficIntervalUsageModel * _Nonnull interval) {

        __strong typeof(weakSelf) strongSelf = weakSelf;
        NSMutableDictionary *trafficDetail = [NSMutableDictionary dictionary];

        // large request
        NSArray<NSDictionary *> *largeUsage = [strongSelf collectIntervalLargeUsage:interval];
        if (largeUsage && largeUsage.count > 0) {
            [trafficDetail hmd_setObject:largeUsage forKey:kHMDTrafficReportKeyLargeUsageRequest];
            [record.exceptionTypes hmd_addObject:kHMDTrafficAbnormalTypeLargeRequest];
        }

        // high frequence request
        NSArray<NSDictionary *> *hightFreq = [strongSelf collectIntervalHighFreqRequest:interval];
        if (hightFreq && hightFreq.count > 0) {
            [trafficDetail hmd_setObject:hightFreq forKey:kHMDTrafficAbnormalTypeHighFreq];
            [record.exceptionTypes hmd_addObject:kHMDTrafficAbnormalTypeHighFreq];
        }

        // biz usage
        if (interval.businessUsage && interval.businessUsage.count > 0) {
            // for public callback
            [strongSelf callbackBizUsageInfoWithIntervalUsage:interval];

            // for report
            NSArray *bizUsages = [strongSelf collectIntervalBizUsage:interval];
            if (bizUsages && bizUsages.count > 0) {
                [trafficDetail hmd_setObject:bizUsages forKey:kHMDTrafficReportKeyUsageDetail];
            }
        }

        if (trafficDetail.count > 0) {
            record.trafficDetail = [trafficDetail copy];
        }

        if (completion) {
            completion();
        }
    }];
}

- (NSDictionary *)formatToTrafficDetailWithBizUsageArray:(NSArray<NSDictionary *> *)bizArray {
//    if (!bizArray || bizArray.count == nil) { return nil; }
    NSDictionary *detailMap = @{
        kHMDTrafficReportKeyUsageDetail: bizArray?:@[]
    };
    return detailMap;
}

#pragma mark --- analysis interval usage info
- (NSArray<NSDictionary *> *)collectIntervalLargeUsage:(HMDNetTrafficIntervalUsageModel *)interval {
    if (interval.largeRequest && interval.largeRequest.count > 0) {
        NSArray<NSDictionary *> *reportContent = [HMDNetTrafficSourceUsageModel formatNormalUsageInfosToStoredDicts:interval.largeRequest];
        return reportContent;
    }
    return nil;
}

- (NSArray<NSDictionary *> *)collectIntervalHighFreqRequest:(HMDNetTrafficIntervalUsageModel *)interval {
    // high frequency request
    if (interval.highFrequencyRequest && interval.highFrequencyRequest.count > 0) {
        NSArray<NSDictionary *> *reportContent = [HMDNetTrafficSourceUsageModel formatHighFreqUsageInfosToStoredDicts:interval.highFrequencyRequest];
        return reportContent;
    }
    return nil;
}

- (NSArray<NSDictionary *> *)collectIntervalBizUsage:(HMDNetTrafficIntervalUsageModel *)interval {
    NSMutableArray *usageDetails = [NSMutableArray array];
    BOOL needSource = YES;
    for (HMDNetTrafficBizUsageModel *biz in interval.businessUsage) {
        NSDictionary *bizDict = [biz formatGroupByBizWithNeedSource:needSource];
        if (bizDict) {
            [usageDetails hmd_addObject:bizDict];
        }
    }
    return [usageDetails copy];
}

- (void)callbackBizUsageInfoWithIntervalUsage:(HMDNetTrafficIntervalUsageModel *)interval {
    NSMutableDictionary *totalGroupNetMap = [NSMutableDictionary dictionary];
    NSMutableDictionary *bizGropNetMap  = [NSMutableDictionary dictionary];
    NSArray *netGrop = [interval groupByNetType];
    for (HMDNetTrafficNetTypeUsageModel *usageModel in netGrop) {
        NSDictionary *usageDetail = [self formatToTrafficDetailWithBizUsageArray:usageModel.bizUsage];
        [totalGroupNetMap hmd_setObject:@(usageModel.totalUsage) forKey:usageModel.netTypeName];
        [bizGropNetMap hmd_setObject:usageDetail forKey:usageModel.netTypeName];
    }
    [self executePublicCallBackWithMonitorType:kHMDTrafficMonitorCallBackTypeIntervalAppUsage usage:totalGroupNetMap biz:bizGropNetMap];
}

#pragma mark -- app state change ---
- (void)notificateConsumeEnterForground:(BOOL)stateChange {
    if (stateChange) {
        hmd_safe_dispatch_async(self.trafficCollectQueue, ^{
            hmd_IOBytes currentIO = hmd_getFlowIOBytes();
            hmd_IOBytes beforeIO = intervalTrafficBeforeAppStateUsage;
            intervalTrafficBeforeAppStateUsage = currentIO;

            u_int32_t wifiDiff = (currentIO.wifiSent - beforeIO.wifiSent) + (currentIO.wifiReceived - beforeIO.wifiReceived);
            u_int32_t cellularDiff = (currentIO.cellularSent - beforeIO.cellularSent) + (currentIO.cellularReceived - beforeIO.cellularReceived);
            intervalTrafficWiFiBackUsage += wifiDiff;
            intervalTrafficCellularBackUsage += cellularDiff;
            self.statisticsTool.isBackground = NO;
        });
    }
}

- (void)notificateConsumeEnterBackground:(BOOL)stateChange {
    if (stateChange) {
        hmd_safe_dispatch_async(self.trafficCollectQueue, ^{
            hmd_IOBytes currentIO = hmd_getFlowIOBytes();
            hmd_IOBytes beforeIO = intervalTrafficBeforeAppStateUsage;
            intervalTrafficBeforeAppStateUsage = currentIO;

            u_int32_t wifiDiff = (currentIO.wifiSent - beforeIO.wifiSent) + (currentIO.wifiReceived - beforeIO.wifiReceived);
            u_int32_t cellularDiff = (currentIO.cellularSent - beforeIO.cellularSent) + (currentIO.cellularReceived - beforeIO.cellularReceived);
            intervalTrafficWiFiFrontUsage += wifiDiff;
            intervalTrafficCellularFrontUsage += cellularDiff;
            self.statisticsTool.isBackground = YES;
        });
    }
}

@end
