//
//  HMDANRTracker.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDANRTracker.h"
#import "HMDANRRecord.h"
#import "HMDSessionTracker.h"
#import "HMDMacro.h"
#import "HMDANRRecord.h"
#import "HMDExceptionReporter.h"
#import "Heimdallr.h"
#import "HMDDebugRealConfig.h"
#import "Heimdallr+Private.h"
#import "HMDDiskUsage.h"
#import "HMDMemoryUsage.h"
#import "HMDStoreIMP.h"
#import "HMDANRMonitor.h"
#import "HMDANRConfig.h"
#import "HMDALogProtocol.h"
#import "HMDNetworkHelper.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDInjectedInfo+UniqueKey.h"
#include <math.h>
#import "NSObject+HMDAttributes.h"
#import "HMDFlameGraphInfo.h"
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"

NSString *const kEnableANRMonitor = @"enable_anr_monitor";
static NSString *const kHMDANREventType = @"lag";
#define DEFAULT_ANR_UPLOAD_LIMIT 5

@interface HMDANRTracker ()<HMDExceptionReporterDataProvider,HMDANRMonitorDelegate>
{
    CFTimeInterval _runloopStartTime;
    NSArray<HMDStoreCondition *> *andConditions;
}
@end

@implementation HMDANRTracker
SHAREDTRACKER(HMDANRTracker)

- (void)dealloc {
    [self stop];
}

- (instancetype)init
{
    self = [super init];
    if (self) { // EMPTY
    }
    return self;
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDANRRecord class];
}

- (void)start {
    [super start];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [[HMDANRMonitor sharedInstance] setDelegate:self];
    });
    [[HMDANRMonitor sharedInstance] start];
    [HMDDebugLogger printLog:@"Lag-Monitor start successfully!"];
}

- (void)stop {
    [super stop];
    [[HMDANRMonitor sharedInstance] stop];
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (void)updateConfig:(HMDANRConfig *)config {
    if(![config isValid]) {
        //downgrade for performance reason
        config = [HMDANRConfig hmd_objectWithDictionary:nil];
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Heimdallr ANR Module config invalid!");
    }
    
    [super updateConfig:config];
    HMDANRMonitor *instance = [HMDANRMonitor sharedInstance];
    instance.timeoutInterval = config.timeoutInterval;
    instance.sampleTimeoutInterval = config.sampleTimeoutInterval;
    instance.sampleInterval = config.sampleInterval;
    instance.ignoreBackground = config.ignoreBackground;
    instance.ignoreDuplicate = config.ignoreDuplicate;
    instance.ignoreBacktrace = config.ignoreBacktrace;
    instance.suspend = config.suspend;
    instance.enableSample = config.enableSample;
    instance.launchThreshold = config.launchThreshold;
    instance.maxContinuousReportTimes = config.maxContinuousReportTimes;
    instance.enableRunloopMonitorV2 = config.enableRunloopMonitorV2;
    instance.runloopMonitorThreadSleepInterval = config.runloopMonitorThreadSleepInterval;
#if DEBUG
    instance.enableRunloopMonitorV2 = YES;
#endif
    self.uploadCount = config.maxUploadCount;
}

- (void)didBlockWithInfo:(HMDANRMonitorInfo *)info {
    if (hmd_drop_data(HMDReporterException)){
        return;
    }
    HMDANRMonitor *instance = [HMDANRMonitor sharedInstance];
    HMDANRRecord *record = [HMDANRRecord newRecord];
    record.anrTime = info.anrTime;
    record.blockDuration = (long)(info.duration * 1000);
    record.inAppTime = info.inAppTime;
    record.anrLogStr = [record generateANRLogStringWithStack:info.stackLog];
    hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
    record.memoryUsage = memoryBytes.appMemory/HMD_MB;
    record.freeMemoryUsage = memoryBytes.availabelMemory/HMD_MB;
    record.freeDiskBlockSize = [HMDDiskUsage getFreeDisk300MBlockSize];
    record.business = [HMDInjectedInfo defaultInfo].business ?: @"unknown";
    record.access = [HMDNetworkHelper connectTypeName];
    record.lastScene = [HMDTracker getLastSceneIfAvailable];
    record.operationTrace = [HMDTracker getOperationTraceIfAvailable];
    record.isLaunch = info.isLaunch;
    record.flameGraph = info.flameGraph;
    record.binaryImages = info.binaryImages;
    NSMutableDictionary *custom = [NSMutableDictionary dictionary];
    [custom setValue:[HMDInjectedInfo defaultInfo].userID forKey:@"user_id"];
    if ([HMDInjectedInfo defaultInfo].scopedUserID) {
        [custom setValue:[HMDInjectedInfo defaultInfo].scopedUserID forKey:@"scoped_user_id"];
    }
    [custom setValue:[HMDInjectedInfo defaultInfo].userName forKey:@"user_name"];
    [custom setValue:[HMDInjectedInfo defaultInfo].email forKey:@"email"];
    [custom addEntriesFromDictionary:[HMDInjectedInfo defaultInfo].customContext];
    record.customParams =  [custom copy];
    NSMutableDictionary *filters = nil;
    if ([HMDInjectedInfo defaultInfo].filters) {
        filters = [[NSMutableDictionary alloc] initWithDictionary:[HMDInjectedInfo defaultInfo].filters];
    }
    else {
        filters = [[NSMutableDictionary alloc] init];
    }
#if !RANGERSAPM
    [filters setValue:info.sampleFlag ? @"1" : @"0" forKey:@"sample_flag"];
    [filters setValue:info.background ? @"1" : @"0" forKey:@"background"];
    [filters setValue:info.isUITrackingRunloopMode ? @"1" : @"0" forKey:@"isScrolling"];
    [filters setValue:@(info.mainThreadCPUUsage) forKey:@"main_thread_cpu_usage"];
#endif
    record.isSampleHit = info.sampleFlag;
    record.isBackground = info.background;
    record.isScrolling = info.isUITrackingRunloopMode;
    record.filters = [filters copy];
    
    
    NSMutableDictionary *settings = [NSMutableDictionary new];
    [settings setValue:@((int)(1000*instance.timeoutInterval)) forKey:@"timeout_interval"];
    [settings setValue:@(instance.enableSample) forKey:@"enable_sample"];
    [settings setValue:@((int)(1000*instance.sampleInterval)) forKey:@"sample_interval"];
    [settings setValue:@((int)(1000*instance.sampleTimeoutInterval)) forKey:@"sample_timeout_interval"];
    [settings setValue:@(instance.ignoreBackground) forKey:@"ignore_background"];
    [settings setValue:@(instance.ignoreDuplicate) forKey:@"ignore_duplicate"];
    [settings setValue:@(instance.ignoreBacktrace) forKey:@"ignore_backtrace"];
    [settings setValue:@(instance.suspend) forKey:@"threads_suspend"];
    [settings setValue:@(instance.launchThreshold) forKey:@"launch_threshold"];
    record.settings = [settings copy];
    
    HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[ANR] blockDuration: %f", info.duration);
    [self didCollectOneRecord:record trackerBlock:^(BOOL isFlushed) {
        if (isFlushed) {
            [self uploadANRLogIfNeeded];
        }
    }];
}

- (NSArray<HMDANRRecord *> *)recordsFilteredByConditions:(NSArray<HMDStoreCondition *>*)conditions {
    return [[Heimdallr shared].database getObjectsWithTableName:[HMDANRRecord tableName] class:[HMDANRRecord class] andConditions:conditions orConditions:nil orderingProperty:@"localID" orderingType:HMDOrderDescending];
}
#pragma mark - upload

- (void)uploadANRLogIfNeeded {
    HMDStopUpload exceptionStopUpload = [HMDInjectedInfo defaultInfo].exceptionStopUpload;
    if (exceptionStopUpload && exceptionStopUpload()) {
        return;
    }
    [[HMDExceptionReporter sharedInstance] reportAllExceptionData];
    [HMDDebugLogger printLog:@"Lag log is uploading..."];
}

- (NSArray *)getANRDataWithRecords:(NSArray<HMDANRRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (HMDANRRecord *record in records) {
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];

        long long timestamp = MilliSecond(record.timestamp);
        
        hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
        double allMemory = memoryBytes.totalMemory/HMD_MB;
        
        [dataValue setValue:@(timestamp) forKey:@"timestamp"];
        [dataValue setValue:kHMDANREventType forKey:@"event_type"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:record.anrLogStr forKey:@"stack"];
        [dataValue setValue:@(record.memoryUsage) forKey:@"memory_usage"];
        [dataValue setValue:@(record.freeDiskBlockSize) forKey:@"d_zoom_free"];
        [dataValue setValue:@(hmd_calculateMemorySizeLevel(record.freeMemoryUsage*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
        double free_memory_percent = (int)(record.freeMemoryUsage/allMemory*100)/100.0;
        [dataValue setValue:@(free_memory_percent) forKey:HMD_Free_Memory_Percent_key];
        [dataValue setValue:record.business forKey:@"business"];
        [dataValue setValue:record.lastScene forKey:@"last_scene"];
        [dataValue setValue:record.operationTrace forKey:@"operation_trace"];
        [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [dataValue setValue:@(record.anrTime) forKey:@"anr_runloop_time"];
        [dataValue setValue:record.access forKey:@"access"];
        [dataValue setValue:@(record.blockDuration) forKey:@"block_duration"];
        [dataValue setValue:@(record.isLaunch) forKey:@"is_launch"];
        [dataValue setValue:record.settings forKey:@"settings"];
        [dataValue hmd_setObject:@(record.isScrolling) forKey:@"is_scrolling"];
        [dataValue hmd_setObject:@(record.isBackground) forKey:@"is_background"];
        [dataValue hmd_setObject:@(record.isSampleHit) forKey:@"sample_flag"];
        [dataValue setValue:@(record.netQualityType) forKey:@"network_quality"];
        [dataValue setValue:record.flameGraph forKey:@"flame_graph"];
        [dataValue setValue:record.binaryImages forKey:@"binary_images"];
      
        if (record.customParams.count > 0) {
            [dataValue setValue:record.customParams forKey:@"custom"];
        }
        if (record.filters.count > 0) {
            [dataValue setValue:record.filters forKey:@"filters"];
        }
        
        [dataValue addEntriesFromDictionary:record.environmentInfo];
        
        [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDANREventType];
        
        [dataArray addObject:dataValue];
    }
    
    return [dataArray copy];
}

- (NSArray *)pendingDebugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config {
    if (![config checkIfAllowedDebugRealUploadWithType:kEnableANRMonitor]) {
        return nil;
    }

    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = config.fetchStartTime;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = config.fetchEndTime;
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *debugRealConditions = @[condition1,condition2];
    
    NSArray<HMDANRRecord *> *records = [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName] class:[self storeClass] andConditions:debugRealConditions orConditions:nil limit:config.limitCnt];
    
    NSArray *result = [self getANRDataWithRecords:records];
    
    return [result copy];
}

- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = config.fetchStartTime;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = config.fetchEndTime;
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *debugRealConditions = @[condition1,condition2];
    // 清空数据库
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:debugRealConditions orConditions:nil limit:config.limitCnt];
}

- (NSArray *)dealNotDebugRealPerformanceData {
    //目前对于有性能损耗的模块，没命中上报的用户本地不采集，因此之前上报时候的限制可以放开
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;
    
    andConditions = @[condition1,condition2];
    
    NSArray<HMDANRRecord *> *records = [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName] class:[self storeClass] andConditions:andConditions orConditions:nil limit:DEFAULT_ANR_UPLOAD_LIMIT];
    if (records.count < self.uploadCount) {
        return nil;
    }
    
    NSArray *result = [self getANRDataWithRecords:records];
    return [result copy];
}

- (long long)dbMaxSize {
    return 50;
}

#pragma mark - DataReporterDelegate
- (NSArray *)pendingExceptionData {
    return [self dealNotDebugRealPerformanceData];
}

- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
    if(isSuccess)
        [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                              andConditions:andConditions
                                               orConditions:nil
                                                      limit:DEFAULT_ANR_UPLOAD_LIMIT];
}

- (void)dropExceptionData {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *conditions = @[condition1,condition2];
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:conditions
                                           orConditions:nil];
}

@end
