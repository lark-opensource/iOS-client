//
//  HMDHTTPRequestTracker.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/21.
//

#include "pthread_extended.h"
#import "HMDHTTPRequestTracker.h"
#import "HMDHTTPDetailRecord.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDStoreCondition.h"
#import "HMDDebugRealConfig.h"
#import "HMDStoreIMP.h"
#import "HMDHTTPRequestUploader.h"
#import "HMDHTTPTrackerConfig.h"
#import "HMDHTTPRequestRecord.h"
#import "HMDMacro.h"
#import "HMDDynamicCall.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDRecordCleanALog.h"
#import "HMDHTTPRequestTracker+Private.h"
#import "pthread_extended.h"
#import "HMDDoubleReporter.h"
#import "HMDReportDowngrador.h"

// 由于 HMDHTTPRequestTracker 的引用较多，所以选择内部if-else重构方式
#import "HMDHermasHelper.h"
#import "HMDHermasCounter.h"
#import "HMDHermasManager.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDServerStateService.h"

#import "HMDInjectedInfo+LegacyDBOptimize.h"

@interface HMDHTTPRequestTracker()<HMDPerformanceReporterDataSource>

@property (nonatomic, strong, readwrite) NSArray <HMDPerformanceReporterDataSource> *uploaders;
@property (nonatomic, assign, readwrite) BOOL ignoreCancelError;
@property (nonatomic, assign, readwrite) BOOL recordResponseBodyEnabled;//是否记录responsebody，默认不开启
@property (nonatomic, assign, readwrite) BOOL enableNSURLProtocolAndChromium; // 是否同时开启原生和TTNet 监控
@property (nonatomic, assign, readwrite) BOOL enableWebViewMonitor; // 是否开启webview监控
@property (nonatomic, assign, readwrite) long long responseBodyThreshold;//responsebody异常阈值限制，size超过该阈值则忽略，默认10KB
@property (atomic, assign, readwrite) NSTimeInterval lastUploadAllTime;
@property (nonatomic, strong,readwrite) NSMutableSet *visitorSet;
@property (nonatomic, assign) BOOL isNewAllowedCheck;
@property (nonatomic, strong) NSMutableSet<HMDHTTPRequestTrackerCallback> *trackerCallbacks;

@end

@implementation HMDHTTPRequestTracker {
    pthread_rwlock_t _allowListOpRWLock;
    pthread_rwlock_t _callbackRWLock;
}

SHAREDTRACKER(HMDHTTPRequestTracker)

- (instancetype)init {
    if (self = [super init]) {
        _ignoreCancelError = NO;
        _recordResponseBodyEnabled = NO;
        _responseBodyThreshold = 10*HMD_KB;
        _visitorSet = [NSMutableSet set];
        _trackerCallbacks = [NSMutableSet set];
        pthread_rwlock_init(&_allowListOpRWLock, NULL);
        pthread_rwlock_init(&_callbackRWLock, NULL);
        [self setupReportModules];
    }
    
    return self;
}

- (HMInstance *)instanceWithAid:(NSString *)aid {
    return [[HMEngine sharedEngine] instanceWithModuleId:kModulePerformaceName aid:aid];
}

- (void)setupReportModules {
    
    NSMutableArray <id <HMDPerformanceReporterDataSource>> *uploaders = [[NSMutableArray alloc] init];

    id <HMDPerformanceReporterDataSource> apiAllUploader = (id <HMDPerformanceReporterDataSource>)[[HMDHTTPRequestUploader alloc] initWithlogType:@"api_all"  recordClass:[self storeClass]];

    if (apiAllUploader) {
        [uploaders addObject:apiAllUploader];
    }
    
    id <HMDPerformanceReporterDataSource> apiErrorUploader = (id <HMDPerformanceReporterDataSource>)[[HMDHTTPRequestUploader alloc] initWithlogType:@"api_error" recordClass:[self storeClass]];

    if (apiErrorUploader) {
        [uploaders addObject:apiErrorUploader];
    }
    self.uploaders = [uploaders copy];
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDHTTPDetailRecord class];
}

- (void)start {
    [super start];
    
    [self judgeMonitorPriority];
    
    if ([self isTTNetAvailable]) {
        DC_CL(HMDTTNetMonitor, changeMonitorTTNetImpSwitch);
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recieveTTNetImpChangeNotification:) name:@"kHMDTTeNetImpChangeNotification" object:nil];
    }
}

- (void)stop {
    [super stop];
    
    [self setTTNetMonitorSwitch:NO];
    [self setURLLoadingMonitorSwitch:NO];
    [self setWebViewMonitorSwitch:NO];
    if ([self isTTNetAvailable]) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"kHMDTTeNetImpChangeNotification" object:nil];
    }
}

- (void)judgeMonitorPriority {
    //优先级原则：
    //1.如果用TTNet的chromium内核，仅开启基于TTNet的网络监控
    //2.如果用TTNet的AFNetworking内核或者未集成TTNet,仅开启原生网络监控，因为此条件下原生和TTNet监控同时开启会重复记录
    //3.如果没集成原生网络监控功能，并且用TTNet的AFNetworking内核，则仅开启基于TTNet的网络监控
    [self setTTNetMonitorSwitch:[self shouldMonitorTTNet]];
    [self setURLLoadingMonitorSwitch:[self shouldMonitorURLLoadingSystem]];
    [self setWebViewMonitorSwitch:[self shouldMonitorWebView]];
}

- (void)recieveTTNetImpChangeNotification:(NSNotification *)notification {
    if (!self.isRunning) { return; }
    [self judgeMonitorPriority];
}

- (BOOL)shouldMonitorTTNet {
    if (![self isTTNetAvailable]) return NO;
    if ([self isTTNetChromiumIMP]) return YES;
    return ![self isHMDURLProtocolAvailable];
}

- (BOOL)shouldMonitorURLLoadingSystem {
    if (![self isHMDURLProtocolAvailable]) return NO;
    if (![self isTTNetAvailable]) return YES;
    if (![self isTTNetChromiumIMP]) {
        return YES;
    } else {
        return self.enableNSURLProtocolAndChromium;
    }
}

// 需要开启TTNet的监控后，才能开启webview的监控
- (BOOL)shouldMonitorWebView {
    if(![self shouldMonitorTTNet]) return NO;
    else return self.enableWebViewMonitor;
}

- (BOOL)isTTNetChromiumIMP {
    return DC_IS(DC_OB(DC_CL(HMDTTNetMonitor, sharedMonitor), isTTNetChromiumCore), NSNumber).boolValue;
}

- (BOOL)isTTNetAvailable {
    Class clazz = NSClassFromString(@"HMDTTNetMonitor");
    return clazz != NULL;
}

- (BOOL)isHMDURLProtocolAvailable {
    Class clazz = NSClassFromString(@"HMDURLProtocol");
    return clazz != NULL;
}

- (BOOL)isHMDWebViewMonitorAvailable {
    Class clazz = NSClassFromString(@"HMDWebViewMonitor");
    return clazz != NULL;
}

- (void)setTTNetMonitorSwitch:(BOOL)isOn {
    id monitor = DC_CL(HMDTTNetMonitor, sharedMonitor);
    if(isOn) DC_OB(monitor, start);
    else DC_OB(monitor, stop);
}

- (void)setURLLoadingMonitorSwitch:(BOOL)isOn {
    if (isOn) {
        DC_CL(HMDURLProtocol, start);
    } else {
        DC_CL(HMDURLProtocol, stop);
    }
}

- (void)setWebViewMonitorSwitch:(BOOL)isOn {
    id monitor = DC_CL(HMDWebViewMonitor, sharedMonitor);
    if(isOn) DC_OB(monitor, start);
    else DC_OB(monitor, stop);
}

- (void)setTTNetMonitorUpdateConfig {
    id monitor = DC_CL(HMDTTNetMonitor, sharedMonitor);
    DC_OB(monitor, updateTTNetConfig);
}

- (void)updateHMDURLProtocolConfig:(HMDHTTPTrackerConfig *)config {
    if ([self shouldMonitorURLLoadingSystem]) {
        DC_CL(HMDURLProtocol, updateHMDURLProtocolConfig:, config);
    }
}

- (BOOL)needSyncStart {
    return YES;
}

- (void)prepareForDefaultStart {
    self.trackerConfig.enableAPIAllUpload = YES;
}

- (BOOL)performanceDataSource {
    return YES;
}

- (long long)dbMaxSize {
    return 20000;
}

- (void)updateConfig:(HMDHTTPTrackerConfig *)config {
    [super updateConfig:config];

    self.ignoreCancelError = config.ignoreCancelError;
    self.recordResponseBodyEnabled = config.responseBodyEnabled;
    self.responseBodyThreshold = config.responseBodyThreshold;
    self.enableNSURLProtocolAndChromium = config.enableNSURLProtocolAndChromium;
    self.enableWebViewMonitor = config.enableWebViewMonitor;

    if (self.isRunning) {
        [self judgeMonitorPriority];
        [self setTTNetMonitorUpdateConfig];
        [self updateHMDURLProtocolConfig:config];
    }
}

- (BOOL)shouldRecordResponsebBodyForRecord:(HMDHTTPDetailRecord *)record rawData:(NSData *)rawData {
    if (![rawData isKindOfClass:[NSData class]]) {
        return NO;
    }
    
    NSError *error = nil;
    //1.ignore binary
    //2.check switch and body size less than threshold
    //3.check json serialization success
    
    BOOL shouldRecord =  ![record isRawBinary]
    && (self.recordResponseBodyEnabled && rawData.length <= self.responseBodyThreshold)
    && ([NSJSONSerialization JSONObjectWithData:rawData options:kNilOptions error:&error] && !error);
    
    return shouldRecord;
}

- (NSArray<HMDHTTPDetailRecord *> *)recordsFilteredByConditions:(NSArray<HMDStoreCondition *>*)conditions {

    return [[Heimdallr shared].database  getObjectsWithTableName:[HMDHTTPDetailRecord tableName] class:[HMDHTTPDetailRecord class] andConditions:conditions orConditions: nil orderingProperty:@"localID" orderingType:HMDOrderDescending];
}

- (void)addRecord:(HMDHTTPDetailRecord *)record
{
    if (!self.isRunning) {
        return;
    }
    
    // api error
    if (!record.isSuccess && self.trackerConfig.enableAPIErrorUpload) {
        HMDHTTPDetailRecord *newRecord = [record copy];
        newRecord.logType = @"api_error";
        [self didCollectOneRecord:newRecord];
    }
    
    record.logType = @"api_all";
    [self didCollectOneRecord:record];
}

- (void)updateRecordWithConfig:(HMDHTTPDetailRecord *)record //HTTPTracker的enable_upload是特殊的字段，这里进行特殊处理
{
    if (![record isKindOfClass:HMDHTTPDetailRecord.class]) {
        return;
    }

    record.enableRandomSampling = 0;

    //在白名单肯定需要上传
    if([record.logType isEqualToString:@"api_error"]) {
        record.enableUpload = 1;
    } else if([record.logType isEqualToString:@"api_all"]) {
        // 命中 api_allow_list 肯定上报
        if (record.inWhiteList) {
            record.enableUpload = 1;
        }
        // 宿主和sdk的网络采样都要遵循 enable_base_api_all
        else if(self.trackerConfig.baseApiAll.floatValue > 0) {
            record.enableUpload = 1;
        }
        // sdk 网络数据已做判断，这里只判断宿主的网络数据
        else if(!record.sdkAid) {
            record.enableUpload = self.trackerConfig.enableAPIAllUpload ? 1 : 0;
        }
        
        if (!record.enableUpload && record.isHitMovingLine && !record.isSDK) {
            record.singlePointOnly = 1;
        }
        record.enableUpload = record.enableUpload ? record.enableUpload : record.isHitMovingLine;
        
        NSSet *set = [[HMDDoubleReporter sharedReporter] isRunning] ? [HMDDoubleReporter sharedReporter].allowPathSet : nil;
        
        if(set && record.enableUpload) {
            if([set containsObject:record.path] || [set containsObject:[record.path stringByAppendingString:@"/"]]) {
                record.doubleUpload = YES;
            }
        }
    }
    
    if (hermas_enabled()) {
        record.sequenceCode = record.enableUpload ? [[HMDHermasCounter shared] generateSequenceCode:@"HMDHTTPDetailRecord"] : -1;
    }
}

- (void)didCollectOneRecord:(HMDHTTPDetailRecord *)record {
    // 判断这条record是sdk网络监控还是宿主网络监控
    NSString *aid = HMDIsEmptyString(record.sdkAid) ? [HMDInjectedInfo defaultInfo].appID : record.sdkAid;

    if(hmd_drop_data_sdk(HMDReporterPerformance, aid) || hmd_downgrade_performance_aid(record.logType, aid)) {
        return ;
    }
    
    if (hermas_enabled()) {
        if (hermas_drop_data_sdk(kModulePerformaceName, aid)) {
            return;
        }
        
        HMDHTTPDetailRecord *detailRecord = record;
        
        // update needUpload
        [self updateRecordWithConfig:detailRecord];
        
        [HMDTracker asyncActionOnTrackerQueue:^{
            // will collect dispatch
            [self httpDetailRecordWillCollected:detailRecord];
            // 写入
            if ([detailRecord.logType isEqualToString:@"image_monitor"]) {
                // do nothing
            } else if (detailRecord.sdkAid && detailRecord.sdkAid.length > 0) {
                HMInstance *instance = [self instanceWithAid:detailRecord.sdkAid];
                BOOL enableCacheMovingLineUnHitLog = NO;
                enableCacheMovingLineUnHitLog = [DC_OB(DC_CL(HMDOTManagerConfig, defaultConfig), GetEnableCacheUnHitLogStrValue) boolValue];
                enableCacheMovingLineUnHitLog = enableCacheMovingLineUnHitLog && detailRecord.isMovingLine;
                
                [instance recordData:detailRecord.reportDictionary priority:HMRecordPriorityDefault forceSave:enableCacheMovingLineUnHitLog];
            } else {
                // api_all 和 api_error
                HMInstance *instance = [self instanceWithAid:[HMDInjectedInfo defaultInfo].appID];
                BOOL enableCacheMovingLineUnHitLog = NO;
                enableCacheMovingLineUnHitLog = [DC_OB(DC_CL(HMDOTManagerConfig, defaultConfig), GetEnableCacheUnHitLogStrValue) boolValue];
                enableCacheMovingLineUnHitLog = enableCacheMovingLineUnHitLog && detailRecord.isMovingLine;
                
                [instance recordData:detailRecord.reportDictionary priority:HMRecordPriorityDefault forceSave:enableCacheMovingLineUnHitLog];
            }
        }];

        // did collect dispatch
        if ([record isKindOfClass:[HMDHTTPDetailRecord class]]) {
            [self httpDetailRecordDidCollected:(HMDHTTPDetailRecord *)record];
        }

    } else {
        if(hmd_drop_data_sdk(HMDReporterPerformance, aid)) {
            return ;
        }
        
        [super didCollectOneRecord:record];
        
        if ([record isKindOfClass:[HMDHTTPDetailRecord class]]) {
            [self httpDetailRecordDidCollected:(HMDHTTPDetailRecord *)record];
        }
    }
}

- (void)flushRecord:(HMDTrackerRecord *)record async:(BOOL)async trackerBlock:(TrackerDataToDBBlock)block {
    if ([record isKindOfClass:[HMDHTTPDetailRecord class]]) {
        [self httpDetailRecordWillCollected:(HMDHTTPDetailRecord *)record];
    }
    [super flushRecord:record async:async trackerBlock:block];
}

- (void)httpDetailRecordDidCollected:(HMDHTTPDetailRecord *)record {
    __weak typeof(self) weakSelf = self;
    [HMDTracker asyncActionOnTrackerQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        for (id<HMDHTTPRequestTrackerRecordDelegate> visitor in strongSelf.visitorSet) {
            if ([visitor respondsToSelector:@selector(asyncHMDHTTPRequestTackerDidCollectedRecord:)]) {
                [visitor asyncHMDHTTPRequestTackerDidCollectedRecord:record];
            }
        };
    }];
}

- (void)httpDetailRecordWillCollected:(HMDHTTPDetailRecord *)record {
    for (id<HMDHTTPRequestTrackerRecordDelegate> visitor in self.visitorSet) {
        if ([visitor respondsToSelector:@selector(asyncHMDHTTPRequestTackerWillCollectedRecord:)]) {
            [visitor asyncHMDHTTPRequestTackerWillCollectedRecord:record];
        }
    };
}

#pragma mark - getter

- (HMDHTTPTrackerConfig *)trackerConfig
{
    HMDModuleConfig *config = self.config;
    if ([config isKindOfClass:HMDHTTPTrackerConfig.class]) {
        return (HMDHTTPTrackerConfig *)config;
    }
    return nil;
}

#pragma - mark drop data

- (void)dropAllDataForServerState {
    return;
}

- (void)removeData:(NSMutableArray *)array WithAid:(NSString *)aid {
    // 删除宿主网络records和db
    if([aid isEqualToString:HMDInjectedInfo.defaultInfo.appID]) {
        if ([array isKindOfClass:[NSArray class]]) {
            [array enumerateObjectsUsingBlock:^(HMDHTTPDetailRecord*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[HMDHTTPDetailRecord class]] && HMDIsEmptyString(obj.sdkAid)) {
                    [self.records removeObject:obj];
                }
            }];
        }
        HMDStoreCondition *aidCondition = [[HMDStoreCondition alloc] init];
        aidCondition.key = @"sdkAid";
        aidCondition.judgeType = HMDConditionJudgeIsNULL;
        NSArray<HMDStoreCondition *> *cleanCondition = @[aidCondition];
        [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:cleanCondition orConditions:nil];
    }
    // 删除sdk网络records和db
    else {
        if ([array isKindOfClass:[NSArray class]]) {
            [array enumerateObjectsUsingBlock:^(HMDHTTPDetailRecord*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if ([obj isKindOfClass:[HMDHTTPDetailRecord class]] && !HMDIsEmptyString(obj.sdkAid) && [aid isEqualToString:obj.sdkAid]) {
                    [self.records removeObject:obj];
                }
            }];
        }
        HMDStoreCondition *aidCondition = [[HMDStoreCondition alloc] init];
        aidCondition.key = @"sdkAid";
        aidCondition.stringValue = aid;
        aidCondition.judgeType = HMDConditionJudgeEqual;
        NSArray<HMDStoreCondition *> *cleanCondition = @[aidCondition];
        [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:cleanCondition orConditions:nil];
    }
}

- (void)dropAllDataForServerStateWithAid:(NSString *)aid {
    dispatch_on_tracker_queue(YES, ^{
        [self removeData:self.records WithAid:aid];
    });
}

#pragma mark - HMDPerformanceReporterDataSource Method

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityHTTPRequestTracker;
}

- (NSUInteger)properLimitCount {
    return 50;
}

- (CGFloat)properLimitSizeWeight {
    return 0.5;
}

- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    if (hermas_enabled()) {
        return nil;
    }
    
    NSUInteger index = 0;
    if ([HMDInjectedInfo defaultInfo].enableLegacyDBOptimize) {
        [self.lock lock];
        index = self.insertIndex;
        BOOL hasNewData = self.hasNewData;
        [self.lock unlock];
        
        if (!hasNewData) {
            return nil;
        }
    }
    
    NSArray *networkData = [NSArray array];
    for (id<HMDPerformanceReporterDataSource> uploader in self.uploaders) {
        if ([uploader respondsToSelector:@selector(performanceDataWithCountLimit:)]) {
            networkData = [networkData arrayByAddingObjectsFromArray:[uploader performanceDataWithCountLimit:limitCount]];
        }
    }
    
    if ([HMDInjectedInfo defaultInfo].enableLegacyDBOptimize) {
        if (networkData.count == 0) {
            [self.lock lock];
            if (index == self.insertIndex) {
                self.hasNewData = NO;
            }
            [self.lock unlock];
        }
    }
    
    self.lastUploadAllTime = [[NSDate date] timeIntervalSince1970];
    return networkData;
}

- (NSArray *)debugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    NSArray *networkData = [NSArray array];
    for (id<HMDPerformanceReporterDataSource> uploader in self.uploaders) {
        if ([uploader respondsToSelector:@selector(debugRealPerformanceDataWithConfig:)]) {
            networkData = [networkData arrayByAddingObjectsFromArray:[uploader debugRealPerformanceDataWithConfig:config]];
        }
    }
#ifdef DEBUG
    static pthread_mutex_t mtx = PTHREAD_MUTEX_INITIALIZER;
    static NSMutableDictionary *globalDictionary;
    pthread_mutex_lock(&mtx);
    if(globalDictionary == nil) globalDictionary = [NSMutableDictionary dictionary];
    for(id maybeDictionary in networkData) {
        NSDictionary *currentDictionary;
        if((currentDictionary = DC_IS(maybeDictionary, NSDictionary)) != nil) {
            NSNumber *value;
            if((value = DC_IS(currentDictionary[@"endtime"], NSNumber)) != nil) {
                NSString *key = value.stringValue;
                NSDictionary *previousDictionary;
                if((previousDictionary = [globalDictionary valueForKey:key]) != nil) {
                    fprintf(stderr, "[ERROR] ENCOUNTER debugReal uploading duplication\nPreviousDictionary:%s\nCurrentDictionary:%s\n", previousDictionary.description.UTF8String, currentDictionary.description.UTF8String);
                }
                else [globalDictionary setObject:currentDictionary forKey:key];
            }
            else __builtin_trap();
        }
        else __builtin_trap();
    }
    pthread_mutex_unlock(&mtx);
#endif
    return networkData;
}

- (void)cleanupPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    if (hermas_enabled()) {
        return;
    }
    
    for (id<HMDPerformanceReporterDataSource> uploader in self.uploaders) {
        if ([uploader respondsToSelector:@selector(cleanupPerformanceDataWithConfig:)]) {
            [uploader cleanupPerformanceDataWithConfig:config];
        }
    }
    hmdDebugRealReportClearModuleDataALog("network");
}

- (void)performanceDataDidReportSuccess:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }
    
    for (id<HMDPerformanceReporterDataSource> uploader in self.uploaders) {
        if ([uploader respondsToSelector:@selector(performanceDataDidReportSuccess:)]) {
            [uploader performanceDataDidReportSuccess:isSuccess];
        }
    }
    self.lastUploadAllTime = 0;
    hmdPerfReportClearModuleDataALog("network");
}

- (void)performanceSizeLimitedDataDidReportSuccess:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }
    
    for (id<HMDPerformanceReporterDataSource> uploader in self.uploaders) {
        if ([uploader respondsToSelector:@selector(performanceSizeLimitedDataDidReportSuccess:)]) {
            [uploader performanceSizeLimitedDataDidReportSuccess:isSuccess];
        }
    }
    hmdSizeLimitPerfReportClearModuleDataALog("network");
}

- (void)cleanupNotUploadAndReportedPerformanceData {
    [self cleanupReportedHTTPDetailRecordData];
    [self cleanupUnSampleAPIAllPerformanceData];
    // image_monitor 已经下线, db过大的时候直接清理掉
    [self cleanupUselessImageMonitorPerformanceData];
}

- (void)cleanupReportedHTTPDetailRecordData {
    HMDStoreCondition *cleanCondition = [[HMDStoreCondition alloc] init];
    cleanCondition.key = @"isReported";
    cleanCondition.threshold = 1;
    cleanCondition.judgeType = HMDConditionJudgeEqual;

    NSArray<HMDStoreCondition *> *cleanConditions = @[cleanCondition];
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:cleanConditions orConditions:nil];
}

- (void)cleanupUnSampleAPIAllPerformanceData {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"enableUpload";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeEqual;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"logType";
    condition2.stringValue = @"api_all";
    condition2.judgeType = HMDConditionJudgeEqual;
    NSArray *apiAllCondition = @[condition1, condition2];

    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:apiAllCondition orConditions:nil];
}

- (void)cleanupUselessImageMonitorPerformanceData {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"logType";
    condition1.stringValue = @"image_monitor";
    condition1.judgeType = HMDConditionJudgeEqual;
    NSArray *apiAllCondition = @[condition1];

    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:apiAllCondition orConditions:nil];
}

#pragma mark --- sdk About
- (NSArray *)performanceSDKDataWitLimitCount:(NSInteger)limitCount sdkAid:(NSString *)sdkAid {
    if (hermas_enabled()) {
        return nil;
    }
    
    id <HMDPerformanceReporterDataSource> sdkUploader = (id <HMDPerformanceReporterDataSource>)[[HMDHTTPRequestUploader alloc] initWithlogType:@"sdk_api_upload"  recordClass:[self storeClass] sdkAid:sdkAid sdkStartUploadTime:self.lastUploadAllTime];

    return [sdkUploader performanceDataWithCountLimit:limitCount];
}

#pragma mark --- record visitor manager
- (void)addRecordVisitor:(id<HMDHTTPRequestTrackerRecordDelegate>)visitor {
    if (!visitor) { return; }
    __weak typeof(self) weakSelf = self;
    [HMDTracker asyncActionOnTrackerQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.visitorSet addObject:visitor];
    }];
}

- (void)removeRecordVisitor:(id<HMDHTTPRequestTrackerRecordDelegate>)visitor {
    if (!visitor) { return; }
    __weak typeof(self) weakSelf = self;
    [HMDTracker asyncActionOnTrackerQueue:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf.visitorSet removeObject:visitor];
    }];
}

- (void)addHTTPRequestTrackerCallback:(HMDHTTPRequestTrackerCallback _Nonnull )callback {
    if(!callback) {
        return ;
    }
    pthread_rwlock_wrlock(&_callbackRWLock);
    [self.trackerCallbacks addObject:callback];
    pthread_rwlock_unlock(&_callbackRWLock);
}

- (void)removeHTTPRequestTrackerCallback:(HMDHTTPRequestTrackerCallback _Nonnull )callback {
    if(!callback) {
        return ;
    }
    pthread_rwlock_wrlock(&_callbackRWLock);
    [self.trackerCallbacks removeObject:callback];
    pthread_rwlock_unlock(&_callbackRWLock);
}

- (NSDictionary *)callHTTPRequestTrackerCallback:(HMDHTTPDetailRecord *)record {
    pthread_rwlock_rdlock(&_callbackRWLock);
    NSSet *callbacks = [self.trackerCallbacks copy];
    pthread_rwlock_unlock(&_callbackRWLock);
    
    if(!callbacks || callbacks.count == 0) {
        return nil;
    }
    
    __block NSMutableDictionary *extra = [NSMutableDictionary dictionary];
    
    [callbacks enumerateObjectsUsingBlock:^(HMDHTTPRequestTrackerCallback _Nonnull callback, BOOL * _Nonnull stop) {
        [extra addEntriesFromDictionary:callback(record)];
    }];
    
    if (![NSJSONSerialization isValidJSONObject:extra]) {
        NSAssert(NO, @"HMDHTTPDetailRecord add biz extra value exception, the value is invaliad");
        return nil;
    }
    
    return [extra copy];
}

#pragma mark --- allowed list op
- (void)urlAllowedCheckOptimized:(BOOL)useOptimized {
    pthread_rwlock_wrlock(&_allowListOpRWLock);
    self.isNewAllowedCheck = useOptimized;
    pthread_rwlock_unlock(&_allowListOpRWLock);
}

@end
