//
//  HMDOOMCrashTracker.m
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#include "pthread_extended.h"
#include <stdatomic.h>
#import "HMDOOMCrashConfig.h"
#import "HMDAppExitReasonDetector+Private.h"
#import <UIKit/UIKit.h>
#import "HMDSessionTracker.h"
#import "HMDOOMCrashRecord.h"
#import "HMDOOMCrashTracker.h"
#import "HMDOOMCrashInfo.h"
#import "HMDExceptionReporter.h"
#import "HMDMemoryUsage.h"
#import "HMDALogProtocol.h"
#import "HMDStoreCondition.h"
#import "HMDMacro.h"
#import "HMDDebugRealConfig.h"
#import "HMDExcludeModule.h"
#import "HMDExcludeModuleHelper.h"
#import "HMDDynamicCall.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDOOMAppState.h"
#import "HMDOOMCrashInfo.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDOOMCrashSDKLog.h"
#if RANGERSAPM
#import "RangersAPMDefines.h"
#endif
#import "Heimdallr.h"
#import "Heimdallr+Cleanup.h"
#import "Heimdallr+Private.h"

#import "HMDHermasHelper.h"
#import "HMDHermasCounter.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDDebugLogger.h"
#import "HMDServerStateService.h"

#define DEFAULT_OOM_UPLOAD_LIMIT 5
#define HMDOOMCrashExcludedTimeoutDefault 10

static NSString * const kHMDOOMCrashFinishDetectionNotification = @"HMDOOMCrashFinishDetectionNotification";
static NSString *const kHMDOOMCrashEventType = @"oom_crash";
// 检测到 FOOM 的通知（排除其它监控模块的原因后发出）
NSString * const HMDDidDetectOOMCrashNotification = @"HMDDidDetectOOMCrashNotification";

@interface HMDOOMCrashTracker () <HMDExceptionReporterDataProvider,HMDAPPExitReasonDetectorProtocol>
@property(atomic, strong) NSArray<HMDStoreCondition *> *andConditions;
@property(atomic, strong) HMDOOMCrashRecord *possibleRecord;
@property(atomic, strong) NSString *possibleInternalSession;
@property(atomic, readwrite, getter=isFinishDetection) BOOL finishDetection;
@property(atomic, readwrite, getter=isDetected) BOOL detected;
@property(nonatomic, assign) HMDApplicationRelaunchReason relaunchReason;
#if RANGERSAPM
@property (atomic, assign) BOOL uploadAlog;
@property (atomic, assign) NSInteger alogCrashBeforeTime;
#endif

@property(nonatomic, strong) HMInstance *instance;
@end

@implementation HMDOOMCrashTracker {
    pthread_mutex_t _startMutex;
    BOOL _isStarted;
}

#pragma mark - Intialization

SHAREDTRACKER(HMDOOMCrashTracker)

- (instancetype)init {
    if(self = [super init]) {
        mutex_init_normal(_startMutex);
//        _isStarted = NO;                  calloc
    }
    return self;
}

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}

- (void)start {
    pthread_mutex_lock(&_startMutex);
    if(_isStarted) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"[HMDOOMCrash start] without first stop");
        pthread_mutex_unlock(&_startMutex);
        return;
    }
    
    [super start];
    [HMDAppExitReasonDetector registerDelegate:self];
    [HMDAppExitReasonDetector start];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationSessionIDDidChange:)
                                                 name:kHMDSessionIDChangeNotification
                                               object:nil];
    
    _isStarted = YES;
    pthread_mutex_unlock(&_startMutex);
    [HMDDebugLogger printLog:@"OOMCrash-Monitor start successfully!"];
}

- (void)stop {
    pthread_mutex_lock(&_startMutex);
    if(!_isStarted) {
        HMDALOG_PROTOCOL_INFO_TAG(@"Heimdallr", @"[HMDOOMCrash stop] without first start");
        pthread_mutex_unlock(&_startMutex);
        return;
    }
    
    [super stop];
    [HMDAppExitReasonDetector deregisterDelegate:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:kHMDSessionIDChangeNotification
                                                  object:nil];
    
    _isStarted = NO;
    pthread_mutex_unlock(&_startMutex);
}

#pragma mark - Integrate with Heimdallr streaming service

#pragma mark sessionID did Change

- (void)applicationSessionIDDidChange:(NSNotification *)notUsed {
    [HMDAppExitReasonDetector triggerCurrentEnvironmentInformationSavingWithAction:@"sessionID changed"];
}

#pragma mark Upload data

// 监控模块实现，来返回采集的数据 (OOM 只上传一次 无需记录上传内容)
- (NSArray *)pendingExceptionData {                                               // 真实上传
    if (hermas_enabled()) {
        return nil;
    }
    
    return [self dealNotDebugRealPerformanceData];
}

// 监控模块实现，来返回采集的数据；ANR、OOM 需要实现
- (NSArray *)pendingDebugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config {     // 回捞数据
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = config.fetchStartTime;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = config.fetchEndTime;
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *andConditions = @[condition1,condition2];
    
    NSArray<HMDOOMCrashRecord *> *records =
    [[Heimdallr shared].database getObjectsWithTableName:[HMDOOMCrashTracker tableName]
                                                   class:[self storeClass]
                                           andConditions:andConditions
                                            orConditions:nil
                                                   limit:config.limitCnt];
    
    self.andConditions = andConditions;
    
    NSArray *result = [self getOOMDataWithRecords:records];
    
    return result;
}

- (NSArray *)dealNotDebugRealPerformanceData {                                          // 自己弄的
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *andConditions = @[condition1,condition2];
    
    NSArray<HMDOOMCrashRecord *> *records =
    [[Heimdallr shared].database getObjectsWithTableName:[HMDOOMCrashTracker tableName]
                                                   class:[self storeClass]
                                           andConditions:andConditions
                                            orConditions:nil
                                                   limit:DEFAULT_OOM_UPLOAD_LIMIT];
    
    self.andConditions = andConditions;
    
    NSArray *result = [self getOOMDataWithRecords:records];
    
    return result;
}

#pragma mark Logic for uploading aggregate data

- (NSArray *)getOOMDataWithRecords:(NSArray<HMDOOMCrashRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (HMDOOMCrashRecord *record in records) {
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        long long timestamp = MilliSecond(record.timestamp);
        
        [dataValue setValue:kHMDOOMCrashEventType forKey:@"event_type"];
        [dataValue setValue:record.sessionID forKey:@"session_id"];
        [dataValue setValue:record.internalStorageSession forKey:@"internal_session_id"];
        [dataValue setValue:@(timestamp) forKey:@"timestamp"];
        [dataValue setValue:@(record.appUsedMemory) forKey:@"memory_usage"];
        [dataValue setValue:@(record.freeDiskBlockSize) forKey:@"d_zoom_free"];
        [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)record.deviceFreeMemory)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
        [dataValue setValue:@(record.appUsedMemoryPercent) forKey:@"m_zoom_used_percent"];
        [dataValue setValue:@(record.freeMemoryPercent) forKey:HMD_Free_Memory_Percent_key];
        [dataValue setValue:record.business forKey:@"business"];
        [dataValue setValue:@(record.inAppTime) forKey:@"inapp_time"];
        [dataValue setValue:record.lastScene forKey:@"last_scene"];
        [dataValue setValue:record.operationTrace forKey:@"operation_trace"];
        [dataValue setValue:@(record.netQualityType) forKey:@"network_quality"];
        NSNumber *exception_main_address = record.customParams[@"exception_main_address"]?:@0;
        [dataValue hmd_setObject:exception_main_address forKey:@"exception_main_address"];
        [dataValue addEntriesFromDictionary:record.environmentInfo];
        [dataValue hmd_setObject:record.customParams[@"total_virtual_memory"] forKey:@"total_virtual_memory"];
        [dataValue hmd_setObject:record.customParams[@"used_virtual_memory"] forKey:@"used_virtual_memory"];
        if (record.customParams.count > 0)
            [dataValue setValue:record.customParams forKey:@"custom"];
        
        if (record.filters.count > 0) {
            [dataValue setValue:record.filters forKey:@"filters"];
        }
        
        if (record.binaryInfo) {
            [dataValue setValue:record.binaryInfo forKey:@"binary_info"];
        }
        
        [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDOOMCrashEventType];
        
        [dataArray addObject:dataValue];
        
        //upload the latest alog file before OOM Crash
#if !RANGERSAPM
        BOOL shouldUpload = DC_IS(DC_OB(DC_CL(HMDLogUploader, sharedInstance), shouldUploadAlogIfCrashed), NSNumber).boolValue;
        if (shouldUpload) {
            DC_OB(DC_CL(HMDLogUploader, sharedInstance), exceptionALogUploadWithEndTime:, record.timestamp);
#else
        if (self.uploadAlog) {
            NSTimeInterval fetchEndtime = record.timestamp;
            NSTimeInterval fetchStartTime = fetchEndtime -  self.alogCrashBeforeTime;
            if (fetchStartTime > 0 && fetchEndtime > 0) {
                DC_OB(DC_CL(HMDLogUploader, sharedInstance), reportALogWithFetchStartTime:fetchEndTime:scene:, fetchStartTime, fetchEndtime, @"crash");
            }
#endif
        }
    }
    
    return [dataArray copy];
}

#pragma mark - Clean up the data

#pragma mark Indicate Success / Failure Returns whether the message was successful

// Response 之后数据清除等工作
- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }
    
    if(isSuccess) {
        NSArray<HMDStoreCondition *> *andConditions;
        
        if((andConditions = self.andConditions) == nil) {
            HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
            condition1.key = @"timestamp";
            condition1.threshold = 0;
            condition1.judgeType = HMDConditionJudgeGreater;
            
            HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
            condition2.key = @"timestamp";
            condition2.threshold = [[NSDate date] timeIntervalSince1970];
            condition2.judgeType = HMDConditionJudgeLess;
            
            andConditions = @[condition1,condition2];
        }
        
        [[Heimdallr shared].database deleteObjectsFromTable:[HMDOOMCrashTracker tableName]
                                              andConditions:andConditions
                                               orConditions:nil
                                                      limit:DEFAULT_OOM_UPLOAD_LIMIT];
    }
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
    [[Heimdallr shared].database deleteObjectsFromTable:[HMDOOMCrashTracker tableName] andConditions:debugRealConditions orConditions:nil limit:config.limitCnt];
}

- (void)dropExceptionData {
    if (hermas_enabled()) {
        return;
    }
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *andConditions = @[condition1,condition2];
    [[Heimdallr shared].database deleteObjectsFromTable:[HMDOOMCrashTracker tableName]
                                          andConditions:andConditions
                                           orConditions:nil];
}

#pragma mark - integrated with outside dispatch to dispatch the OOM Crash info

+ (void)dispatchOOMDetectInformation:(NSString *)internalSessionID {
    DC_CL(HMDOOMDetector, OOMCrashTrackDetectOOMCallback:, internalSessionID);
}

+ (void)dispatchNoneOOMDetect {
    DC_CL(HMDOOMDetector, OOMCrashTrackDetectNoneOOMCallback);
}

#pragma mark - HMDOOMCrashDetectorDelegate protocol
- (void)setReason:(HMDApplicationRelaunchReason)reason {
    self.relaunchReason = reason;
}

- (HMDApplicationRelaunchReason)reason {
    return self.relaunchReason;
}

#pragma mark OOM Crash Detection

#ifdef DEBUG
static atomic_uint debug_count = 0;
#endif

- (void)didDetectExitReason:(HMDApplicationRelaunchReason)reason desc:(NSString*)desc info:(HMDOOMCrashInfo * _Nullable)info {
    if(reason != HMDApplicationRelaunchReasonFOOM) {
#ifdef DEBUG
        NSAssert(!debug_count++, @"[FATAL ERROR] Please preserve current environment"
                 " and contact Heimdallr developer ASAP.");
#endif
        self.detected = NO;
        self.finishDetection = YES;
        self.relaunchReason = reason;
        [self notifyDetectionFinished];
        if (hmd_log_enable()) {
            HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[OOMCrash] exclusive complete [Detecting other modules success]");
        }
        return;
    }
    NSTimeInterval timestamp = MAX(info.latestTime, info.memoryInfo.updateTime);
    NSString *sessionID = info.sessionID;
    NSString *internalSessionID = info.internalSessionID;
    double appTotalMemory = hmd_getDeviceMemoryLimit() / HMD_MB;

    HMDOOMCrashRecord *record = [HMDOOMCrashRecord newRecord];
    // record.localID (NSUInteger)
    record.sessionID = sessionID;
    record.internalStorageSession = internalSessionID;
    record.appUsedMemory = info.memoryInfo.appMemory / HMD_MB;
    
    if (appTotalMemory) record.appUsedMemoryPercent = record.appUsedMemory / appTotalMemory;
    
    record.deviceFreeMemory = info.memoryInfo.availableMemory / HMD_MB;
    uint64_t totalSizeLevel = hmd_calculateMemorySizeLevel(info.memoryInfo.totalMemory);
    uint64_t usedSizeLevel = hmd_calculateMemorySizeLevel(info.memoryInfo.usedMemory);
    
    if(totalSizeLevel) record.freeMemoryPercent = ((totalSizeLevel - usedSizeLevel)*1.0) / (totalSizeLevel*1.0);
#if RANGERSAPM
    record.freeDiskSpace = info.freeDisk;
#endif
    record.freeDiskBlockSize = info.freeDiskBlockSize;
    record.business = [HMDInjectedInfo defaultInfo].business ?: @"unknown";
    record.lastScene = info.lastScene;
    record.operationTrace = info.operationTrace;
    record.binaryInfo = info.binaryInfo;
    
    /* 尝试用 applicationSession 获取更准确的内容 */
    if(internalSessionID) {
        if (hermas_enabled()) {
            NSDictionary *latestSessionDic = [HMDSessionTracker latestSessionDicAtLastLaunch];
            if (latestSessionDic) {
                double sessionDuration = [latestSessionDic hmd_doubleForKey:@"duration"];
                double sessionTimestamp = [latestSessionDic hmd_doubleForKey:@"timestamp"];
                if(sessionTimestamp + sessionDuration > timestamp) {
                    timestamp = sessionTimestamp + sessionDuration;
                    double sessionAppUsedMemory = [[latestSessionDic hmd_stringForKey:@"memoryUsage"] doubleValue];
                    if (sessionAppUsedMemory != 0) {
                        record.appUsedMemory = sessionAppUsedMemory;
                        record.deviceFreeMemory = [[latestSessionDic hmd_stringForKey:@"freeMemory"] doubleValue];
                        double deviceMemoryUsage = [[latestSessionDic hmd_stringForKey:@"deviceMemoryUsage"] doubleValue];
                        
                        if(appTotalMemory) record.appUsedMemoryPercent = record.appUsedMemory / appTotalMemory;
                        
                        uint64_t sessionTotalSizeLevel = hmd_calculateMemorySizeLevel(info.memoryInfo.totalMemory);
                        uint64_t sessionUsedSizeLevel = hmd_calculateMemorySizeLevel(((uint64_t)deviceMemoryUsage) * HMD_MEMORY_MB);
                        
                        if(sessionTotalSizeLevel) record.freeMemoryPercent = ((sessionTotalSizeLevel - sessionUsedSizeLevel)*1.0) / (sessionTotalSizeLevel*1.0);
                    }
                }
                record.appVersion = [latestSessionDic hmd_stringForKey:@"app_version"];
                record.buildVersion = [latestSessionDic hmd_stringForKey:@"buildVersion"];
                record.sdkVersion = [latestSessionDic hmd_stringForKey:@"sdk_version"];
                record.osVersion = [latestSessionDic hmd_stringForKey:@"os_version"];
                
                NSDictionary *customParams = [latestSessionDic hmd_dictForKey:@"customParams"];
                if(customParams.count > 0) record.customParams = customParams;
                    
                NSDictionary *filters = [latestSessionDic hmd_dictForKey:@"filters"];
                if(filters.count > 0) record.filters = filters;
            }
        } else {
            CLANG_DIAGNOSTIC_PUSH
            CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
            HMDApplicationSession *latestSession = [HMDSessionTracker latestSessionAtLastLaunch];
            CLANG_DIAGNOSTIC_POP
            if(latestSession != nil) {
                if(latestSession.timestamp + latestSession.duration > timestamp) {
                    timestamp = latestSession.timestamp + latestSession.duration;
                    double sessionAppUsedMemory = latestSession.memoryUsage;
                    if (sessionAppUsedMemory != 0) {
                        record.appUsedMemory = sessionAppUsedMemory;
                        record.deviceFreeMemory = latestSession.freeMemory;
                        double deviceMemoryUsage = latestSession.deviceMemoryUsage;
                        
                        if(appTotalMemory) record.appUsedMemoryPercent = record.appUsedMemory / appTotalMemory;
                        
                        uint64_t sessionTotalSizeLevel = hmd_calculateMemorySizeLevel(info.memoryInfo.totalMemory);
                        uint64_t sessionUsedSizeLevel = hmd_calculateMemorySizeLevel(((uint64_t)deviceMemoryUsage) * HMD_MEMORY_MB);
                        
                        if(sessionTotalSizeLevel) record.freeMemoryPercent = ((sessionTotalSizeLevel - sessionUsedSizeLevel)*1.0) / (sessionTotalSizeLevel*1.0);
                    }
                }
                
                [record recoverWithSessionRecord:latestSession];
                
                if(latestSession.customParams.count > 0)
                    record.customParams = latestSession.customParams;
                if(latestSession.filters.count > 0)
                    record.filters = latestSession.filters;
                    
            }
        }
    }
    
    record.timestamp = timestamp;
    record.inAppTime = timestamp - info.appStartTime;
    
    if (info.appVersion.length > 0) {
        record.appVersion = info.appVersion;
    }
    if (info.buildVersion.length > 0) {
        record.buildVersion = info.buildVersion;
    }
    if (info.sysVersion.length > 0) {
        record.osVersion = info.sysVersion;
    }
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    // 注入内存警告的额外信息
    NSMutableDictionary *params = [(record.customParams ?: @{}) mutableCopy];
    
    bool memoryPressureValid = false;
    if (info.memoryPressure > 0) {
        // 10min内的内存警告认为是有效警告
        if (record.timestamp - info.memoryPressureTimestamp < ((HMDOOMCrashConfig*)self.config).memoryPressureValidInterval) {
            [params hmd_setObject:@(info.memoryPressure) forKey:@"memory-pressure"];
            NSString *dateString = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:info.memoryPressureTimestamp]];
            [params hmd_setObject:dateString forKey:@"memory-pressure-time"];
            memoryPressureValid = true;
        }
    }
    // 最后一次进入前台的时间
    if (info.enterForegoundTime > 0) {
        NSString *dateString = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:info.enterForegoundTime]];
        [params hmd_setObject:dateString forKey:@"enter_fg_time"];
    }
    
    if (info.enterBackgoundTime > 0) {
        NSString *dateString = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:info.enterBackgoundTime]];
        [params hmd_setObject:dateString forKey:@"enter_bg_time"];
    }
    
    [params hmd_setObject:[NSString stringWithFormat:@"%.2fMB",info.memoryInfo.appMemoryPeak/HMD_MB]
                   forKey:@"app_memory_peak"];
    NSString *updateTimeString = [formatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:info.memoryInfo.updateTime]];
    [params hmd_setObject:updateTimeString forKey:@"memory_update_time"];
    [params hmd_setObject:@(info.exception_main_address) forKey:@"exception_main_address"];
    if (info.slardarMallocUsageSize > 0) {
        [params hmd_setObject:@(info.slardarMallocUsageSize) forKey:@"slardar_malloc_usage"];
    }
    if (info.memoryInfo.totalVirtualMemory > 0 && info.memoryInfo.usedVirtualMemory > 0) {
        [params hmd_setObject:@(info.memoryInfo.totalVirtualMemory) forKey:@"total_virtual_memory"];
        [params hmd_setObject:@(info.memoryInfo.usedVirtualMemory) forKey:@"used_virtual_memory"];
    }
    record.customParams = [params copy];
    
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    if (record.filters) {
        [filters addEntriesFromDictionary:record.filters];
    }
    
    NSNumber *maybeWatchdog = DC_ET(DC_OB(DC_CL(HMDWatchDog, sharedInstance), lastTimeMaybeWatchdog), NSNumber);
    [filters hmd_setObject:maybeWatchdog.boolValue?@"1":@"0" forKey:@"maybe_watchdog"];
    
    [filters hmd_setObject:memoryPressureValid?[@(info.memoryPressure) stringValue]:@"0" forKey:@"memory_pressure"];
    [filters hmd_setObject:(info.isSlardarMallocInuse?@"1":@"0") forKey:@"slardar_malloc_inuse"];
    [filters hmd_setObject:info.isMemoryDumpInterrupt?@"1":@"0" forKey:@"memory_dump_interrupt"];
    //we think app memory peak over 800MB or pct40 may be has memory issue
    if (info.memoryInfo.appMemoryPeak >= 800 * HMD_MB) {
        [filters hmd_setObject:@"1" forKey:@"memory_issue"];
    } else if (info.memoryInfo.totalMemory > 0) {
        uint64_t pct40 = info.memoryInfo.totalMemory * .4;
        if (info.memoryInfo.appMemoryPeak >= pct40) {
            [filters hmd_setObject:@"1" forKey:@"memory_issue"];
        }
    }
    
    record.filters = filters;
    
#ifdef DEBUG
    static atomic_uint debug_count = 0;
    NSAssert(!debug_count++, @"[FATAL ERROR] Please preserve current environment"
                             " and contact Heimdallr developer ASAP.");
#endif
    self.possibleRecord = record;
    self.possibleInternalSession = internalSessionID;
    [self oomCrashDetected];
}

- (void)notifyDetectionFinished {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:@(self.relaunchReason) forKey:@"relaunch_reason"];
    [dict setObject:@(self.isDetected) forKey:@"oom_detected"];
    if (self.relaunchReason == HMDApplicationRelaunchReasonFOOM) {
        id memoryPressure = [self.possibleRecord.filters objectForKey:@"memory_pressure"];
        if (memoryPressure != nil) {
            [dict setObject:memoryPressure forKey:@"memory_pressure"];
        }
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kHMDOOMCrashFinishDetectionNotification object:self userInfo:[dict copy]];
    });
}

- (void)oomCrashDetected {
#ifdef DEBUG
    NSAssert(!debug_count++, @"[FATAL ERROR] Please preserve current environment"
                             " and contact Heimdallr developer ASAP.");
#endif
    NSAssert(self.possibleInternalSession != nil && self.possibleRecord != nil,
             @"[FATAL ERROR] Please preserve current environment"
                " and contact Heimdallr developer ASAP.");

    [HMDOOMCrashTracker dispatchOOMDetectInformation:self.possibleInternalSession];
    self.detected = YES;
    self.finishDetection = YES;

    [self notifyDetectionFinished];

    // 排除其它模块触发 crash 后确定为 FOOM，通知外部
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:HMDDidDetectOOMCrashNotification
                                                            object:nil
#if !RANGERSAPM
                                                          userInfo:@{@"record":self.possibleRecord
#else
                                                          userInfo:@{@"record":self.possibleRecord,
                                                                     RangersAPMExceptionNotificationInAppTimeKey:@(self.possibleRecord.inAppTime),
                                                                     RangersAPMExceptionNotificationAppIDsKey:@[[HMDInjectedInfo defaultInfo].appID?:@""]
#endif
                                                                   }
        ];
    });
    
    if (hermas_enabled()) {
        if (hermas_drop_data(kModuleExceptionName)) {
            return;
        }
        //upload the latest alog file before OOM Crash
        NSNumber *shouldUpload = DC_ET(DC_OB(DC_CL(HMDLogUploader, sharedInstance), shouldUploadAlogIfCrashed), NSNumber);
        if (shouldUpload.boolValue) {
            DC_OB(DC_CL(HMDLogUploader, sharedInstance), exceptionALogUploadWithEndTime:, self.possibleRecord.timestamp);
        }
        
        // 重构版本中：容灾和降级逻辑都在Hermas层，这里仅仅需要简单的record，考虑到实时性问题，采用HMRecordPriorityRealTime上传方式。
        // 直接写入mmap，并实时上传
        self.possibleRecord.sequenceCode = [[HMDHermasCounter shared] generateSequenceCode:@"HMDOOMCrashRecord"];
        [self.instance recordData:self.possibleRecord.reportDictionary priority:HMRecordPriorityRealTime];
        
    } else {
        if (hmd_drop_data(HMDReporterException)) {
            return;
        }
        [self didCollectOneRecord:self.possibleRecord trackerBlock:^(BOOL isFlushed) {
            if (isFlushed) {
                HMDStopUpload exceptionStopUpload = [HMDInjectedInfo defaultInfo].exceptionStopUpload;
                if (!(exceptionStopUpload && exceptionStopUpload())) {
                    [[HMDExceptionReporter sharedInstance] reportAllExceptionData];
                }
                [HMDDebugLogger printLog:@"OOM log is uploading..."];
            } else {
                HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"[OOMCrash] failed to save database");
            }
        }];
    }
}

#pragma mark - HMDRecordStoreObject protocol

+ (NSString *)tableName {
    return [[[HMDOOMCrashTracker sharedTracker] storeClass] tableName];
}

+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSArray <NSDictionary *>*)aggregateDataForRecords:(NSArray *)records {
    return nil;
}

#pragma mark - HeimdallrModule protocol

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDOOMCrashRecord class];
}

- (BOOL)needSyncStart {//启动时是否应该立即开启
    return NO;
}

- (BOOL)performanceDataSource {
    return NO;
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (void)updateConfig:(HMDOOMCrashConfig *)config {
    [super updateConfig:config];
    [HMDAppExitReasonDetector updateTimeInterval:config.updateSystemStateInterval];
    HMDAppExitReasonDetector.isFixNoDataMisjudgment = config.isFixNoDataMisjudgment;
    HMDAppExitReasonDetector.isNeedBinaryInfo = config.isNeedBinaryInfo;
}

- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    [super cleanupWithConfig:cleanConfig];
}

#pragma mark - HMDExcludedModule

- (NSString *)finishDetectionNotification {
    return kHMDOOMCrashFinishDetectionNotification;
}

+ (instancetype)excludedModule {
    return [HMDOOMCrashTracker sharedTracker];
}
@end
