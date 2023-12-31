//
//  HMDWatchDogTracker.m
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#include "pthread_extended.h"
#import "HMDWatchDogDelegate.h"
#import "HMDWatchDogDefine.h"
#import "HMDWatchDogTracker.h"
#import "HMDWatchDogConfig.h"
#import "HMDWatchDogRecord.h"
#import "HMDDebugRealConfig.h"
#import "HMDExceptionReporter.h"
#import "HMDMacro.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "Heimdallr+Cleanup.h"
#import "HMDSessionTracker.h"
#import "HMDStoreCondition.h"
#import "HMDALogProtocol.h"
#import "HMDMemoryUsage.h"
#import "HMDExcludeModule.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "HMDDynamicCall.h"
#import "NSObject+HMDAttributes.h"
#import "HMDDiskUsage.h"
#import "HeimdallrUtilities.h"
#import "NSDictionary+HMDSafe.h"

#import "HMDHermasHelper.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDMonitorService.h"

NSString *const kHMDWatchDogFinishDetectionNotification = @"HMDWatchDogFinishDetectionNotification";

#define DEFAULT_WATCH_DOG_UPLOAD_LIMIT 5

static double get_free_memory_percent(double freeMemoryUsage) {
    double allMemory = hmd_getTotalMemoryBytes()/HMD_MB;
    return (int)(freeMemoryUsage/allMemory*100)/100.0;
    
}

@interface HMDWatchDogTracker () <HMDWatchDogDelegate, HMDExcludeModule, HMDExceptionReporterDataProvider>
@property(atomic, strong) NSArray<HMDStoreCondition *> *addCond;
@property(atomic, strong) NSArray<HMDStoreCondition *> *orCond;

@property(atomic, readwrite, getter=isFinishDetection) BOOL finishDetection;
@property(atomic, readwrite, getter=isDetected) BOOL detected;

@property(nonatomic, strong) HMInstance *instance;
@end

@implementation HMDWatchDogTracker

SHAREDTRACKER(HMDWatchDogTracker)

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}

- (void)start {
    [super start];
    [HMDWatchDog sharedInstance].delegate = self;
    [[HMDWatchDog sharedInstance] start];
}

- (void)stop {
    [super stop];
    [[HMDWatchDog sharedInstance] stop];
}

- (NSArray *)pendingExceptionData {
    if (hermas_enabled()) {
        return nil;
    }
    
    return [self dealNotDebugRealPerformanceData];
}

- (NSArray *)pendingDebugRealExceptionDataWithConfig:(HMDDebugRealConfig *)config {
    HMDStoreCondition *cond1 = [[HMDStoreCondition alloc] init];
    cond1.key = @"timestamp";
    cond1.threshold = config.fetchStartTime;
    cond1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *cond2 = [[HMDStoreCondition alloc] init];
    cond2.key = @"timestamp";
    cond2.threshold = config.fetchEndTime;
    cond2.judgeType = HMDConditionJudgeLess;
    NSArray<HMDStoreCondition *> *addCond = @[cond1,cond2];
    NSArray<HMDWatchDogRecord *> *records =
    [[Heimdallr shared].database getObjectsWithTableName:[HMDWatchDogTracker tableName]
                                                   class:[self storeClass]
                                           andConditions:addCond
                                            orConditions:nil
                                                   limit:config.limitCnt];
    self.addCond = addCond; self.orCond = nil;
    NSArray *result = [self getWatchDogDataWithRecords:records];
    return result;
}

- (NSArray *)dealNotDebugRealPerformanceData {
    HMDStoreCondition *cond1 = [[HMDStoreCondition alloc] init];
    cond1.key = @"timestamp";
    cond1.threshold = 0;
    cond1.judgeType = HMDConditionJudgeGreater;
    HMDStoreCondition *cond2 = [[HMDStoreCondition alloc] init];
    cond2.key = @"timestamp";
    cond2.threshold = [[NSDate date] timeIntervalSince1970];
    cond2.judgeType = HMDConditionJudgeLess;
    NSArray<HMDStoreCondition *> *andCond = @[cond1,cond2];
    NSArray<HMDWatchDogRecord *> *records =
    [[Heimdallr shared].database getObjectsWithTableName:[HMDWatchDogTracker tableName]
                                                   class:[self storeClass]
                                           andConditions:andCond
                                            orConditions:nil
                                                   limit:DEFAULT_WATCH_DOG_UPLOAD_LIMIT];
    self.addCond = andCond; self.orCond = nil;
    NSArray *result = [self getWatchDogDataWithRecords:records];
    return result;
}

- (NSArray *)getWatchDogDataWithRecords:(NSArray<HMDWatchDogRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    NSTimeInterval lastTimestamp = 0;
    for (HMDWatchDogRecord *record in records) {
        NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
        [dataValue setValue:kHMDWatchDogEventType forKey:@"event_type"];
        [dataValue setValue:@(record.memoryUsage) forKey:kHMDWatchDogExportKeyMemoryUsage];
        [dataValue setValue:@(record.freeDiskBlocks) forKey:kHMDWatchDogExportKeyFreeDiskBlocks];
        [dataValue setValue:@(hmd_calculateMemorySizeLevel(((uint64_t)record.freeMemoryUsage)*HMD_MEMORY_MB)) forKey:HMD_Free_Memory_Key];
        [dataValue setValue:@(get_free_memory_percent(record.freeMemoryUsage)) forKey:HMD_Free_Memory_Percent_key];
        [dataValue setValue:record.backtrace forKey:kHMDWatchDogExportKeyStack];
        [dataValue setValue:record.connectionTypeName forKey:kHMDWatchDogExportKeyNetwork];
        [dataValue setValue:@(record.timeoutDuration * 1000) forKey:kHMDWatchDogExportKeyTimeoutDuration];
        long long timestamp = MilliSecond(record.timestamp);
        [dataValue setValue:record.sessionID forKey:kHMDWatchDogExportKeySessionID];
        [dataValue setValue:record.internalSessionID forKey:kHMDWatchDogExportKeyInternalSessionID];
        [dataValue setValue:@(timestamp) forKey:kHMDWatchDogExportKeyTimestamp];
        [dataValue setValue:@(record.inAppTime) forKey:kHMDWatchDogExportKeyinAppTime];
        [dataValue setValue:record.business forKey:kHMDWatchDogExportKeyBusiness];
        [dataValue setValue:record.lastScene forKey:kHMDWatchDogExportKeylastScene];
        [dataValue setValue:record.operationTrace forKey:kHMDWatchDogExportKeyOperationTrace];
        [dataValue setValue:@(record.isBackground) forKey:kHMDWatchDogExportKeyIsBackground];
        [dataValue setValue:@(record.isLaunchCrash) forKey:kHMDWatchDogExportKeyIsLaunchCrash];
        [dataValue setValue:record.settings forKey:kHMDWatchDogExportKeySettings];
        [dataValue hmd_setObject:@(record.main_thread_cpu_usage) forKey:kHMDWatchDogExportKeyMainThreadCPUUssage];
        [dataValue hmd_setObject:@(record.host_cpu_usage) forKey:kHMDWatchDogExportKeyHostCPUUssage];
        [dataValue hmd_setObject:@(record.task_cpu_usage) forKey:kHMDWatchDogExportKeyTaskCPUUssage];
        [dataValue hmd_setObject:@(record.cpu_count) forKey:kHMDWatchDogExportKeyCPUCount];
        if (record.customParams.count > 0)
            [dataValue setValue:record.customParams forKey:kHMDWatchDogExportKeyCustom];
        if (record.filters.count > 0) {
            [dataValue setValue:record.filters forKey:kHMDWatchDogExportKeyFilters];
        }
        
        [dataValue setValue:record.timeline forKey:kHMDWatchDogExportKeyTimeline];
        [dataValue addEntriesFromDictionary:record.environmentInfo];
        [dataValue setObject:@(record.isMainDeadlock) forKey:kHMDWatchDogExportKeyIsMainDeadlock];
        if(record.deadlock){
            [dataValue setObject:record.deadlock forKey:kHMDWatchDogExportKeyDeadlock];
        }
        [dataValue setObject:@(record.exceptionMainAddress) forKey:kHMDWatchDogExportKeyExeptionMainAdress];
        [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDWatchDogEventType];
        
        [dataArray addObject:dataValue];
        
        if (record.timestamp > lastTimestamp) {
            lastTimestamp = record.timestamp;
        }
    }
    
    // 同步上传Alog日志
    if (lastTimestamp > 0 && [HMDWatchDog sharedInstance].uploadAlog) {
        DC_OB(DC_CL(HMDLogUploader, sharedInstance), exceptionALogUploadWithEndTime:, lastTimestamp);
    }
    
    return [dataArray copy];
}

- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }
    
    if(isSuccess) {
        NSArray<HMDStoreCondition *> *addCond;
        NSArray<HMDStoreCondition *> *orCond;
        if((addCond = self.addCond) == nil) {
            HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
            condition1.key = @"timestamp";
            condition1.threshold = 0;
            condition1.judgeType = HMDConditionJudgeGreater;
            HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
            condition2.key = @"timestamp";
            condition2.threshold = [[NSDate date] timeIntervalSince1970];
            condition2.judgeType = HMDConditionJudgeLess;
            addCond = @[condition1,condition2];
        }
        orCond = self.orCond;
        [[Heimdallr shared].database deleteObjectsFromTable:[HMDWatchDogTracker tableName]
                                              andConditions:addCond
                                               orConditions:orCond
                                                      limit:DEFAULT_WATCH_DOG_UPLOAD_LIMIT];
    }
}

- (void)cleanupExceptionDataWithConfig:(HMDDebugRealConfig *)config {
    HMDStoreCondition *cond1 = [[HMDStoreCondition alloc] init];
    cond1.key = @"timestamp";
    cond1.threshold = config.fetchStartTime;
    cond1.judgeType = HMDConditionJudgeGreater;
    HMDStoreCondition *cond2 = [[HMDStoreCondition alloc] init];
    cond2.key = @"timestamp";
    cond2.threshold = config.fetchEndTime;
    cond2.judgeType = HMDConditionJudgeLess;
    NSArray<HMDStoreCondition *> *debugRealConditions = @[cond1,cond2];
    [[Heimdallr shared].database deleteObjectsFromTable:[HMDWatchDogTracker tableName] andConditions:debugRealConditions orConditions:nil limit:config.limitCnt];
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
    NSArray<HMDStoreCondition *> *addCond = @[condition1,condition2];
    [[Heimdallr shared].database deleteObjectsFromTable:[HMDWatchDogTracker tableName]
                                          andConditions:addCond
                                           orConditions:nil];
}

#pragma mark - HMDWatchDogDelegate

- (void)watchDogDidDetectSystemKillWithData:(NSDictionary *)dictionary {
    NSString *backtraceString = dictionary[kHMDWatchDogExportKeyStack];
    NSString *access = dictionary[kHMDWatchDogExportKeyNetwork];
    NSString *powerState = [dictionary hmd_stringForKey:kHMDWatchDogExportKeyPowerState];
    NSString *thermalState = [dictionary hmd_stringForKey:kHMDWatchDogExportKeyThermalState];
    NSString *internalSession = dictionary[kHMDWatchDogExportKeyInternalSessionID];
    NSString *thatTimeApplicationSession = dictionary[kHMDWatchDogExportKeySessionID];
    NSString *lastScene = dictionary[kHMDWatchDogExportKeylastScene];
    NSString *business = dictionary[kHMDWatchDogExportKeyBusiness];
    NSString *timeline = dictionary[kHMDWatchDogExportKeyTimeline];
    NSString *appVersion = dictionary[kHMDWatchDogExportKeyAppVersion];
    NSString *buildVersion = dictionary[kHMDWatchDogExportKeyBuildVersion];
    NSDictionary *operationTrace = dictionary[kHMDWatchDogExportKeyOperationTrace];
    double main_thread_cpu_usage = [dictionary hmd_doubleForKey:kHMDWatchDogExportKeyMainThreadCPUUssage];
    double host_cpu_usage = [dictionary hmd_doubleForKey:kHMDWatchDogExportKeyHostCPUUssage];
    double task_cpu_usage = [dictionary hmd_doubleForKey:kHMDWatchDogExportKeyTaskCPUUssage];
    int cpu_count = [dictionary hmd_intForKey:kHMDWatchDogExportKeyCPUCount];
    NSArray *vids = [dictionary hmd_arrayForKey:kHMDWatchDogExportKeyVids];
    if (![operationTrace isKindOfClass:[NSDictionary class]]) {
        operationTrace = nil;
    }
    NSDictionary *custom = dictionary[kHMDWatchDogExportKeyCustom];
    if (![custom isKindOfClass:[NSDictionary class]]) {
        custom = nil;
    }else {
        NSMutableDictionary *mutableCustom = [custom mutableCopy];
        [mutableCustom hmd_setObject:powerState forKey:kHMDWatchDogExportKeyPowerState];
        [mutableCustom hmd_setObject:thermalState forKey:kHMDWatchDogExportKeyThermalState];
        
        //TODO remove on develop
        [mutableCustom hmd_setObject:@(main_thread_cpu_usage) forKey:kHMDWatchDogExportKeyMainThreadCPUUssage];
        [mutableCustom hmd_setObject:@(host_cpu_usage) forKey:kHMDWatchDogExportKeyHostCPUUssage];
        [mutableCustom hmd_setObject:@(task_cpu_usage) forKey:kHMDWatchDogExportKeyTaskCPUUssage];
        [mutableCustom hmd_setObject:@(cpu_count) forKey:kHMDWatchDogExportKeyCPUCount];
        
        [mutableCustom hmd_setObject:vids forKey:kHMDWatchDogExportKeyVids];
        
        custom = [mutableCustom copy];
    }
    NSDictionary *filters = dictionary[kHMDWatchDogExportKeyFilters];
    if (![filters isKindOfClass:[NSDictionary class]]) {
        filters = nil;
    }else {
        NSMutableDictionary *mutableFilters = [filters mutableCopy];
        [mutableFilters hmd_setObject:powerState forKey:kHMDWatchDogExportKeyPowerState];
        [mutableFilters hmd_setObject:thermalState forKey:kHMDWatchDogExportKeyThermalState];
        
        [mutableFilters hmd_setObject:@(main_thread_cpu_usage) forKey:kHMDWatchDogExportKeyMainThreadCPUUssage];
        [mutableFilters hmd_setObject:@(host_cpu_usage) forKey:kHMDWatchDogExportKeyHostCPUUssage];
        [mutableFilters hmd_setObject:@(task_cpu_usage) forKey:kHMDWatchDogExportKeyTaskCPUUssage];
        [mutableFilters hmd_setObject:@(cpu_count) forKey:kHMDWatchDogExportKeyCPUCount];
        
        filters = [mutableFilters copy];
    }
    double memoryUsage = [(NSNumber *)dictionary[kHMDWatchDogExportKeyMemoryUsage] doubleValue];
    double freeMemoryUsage = [(NSNumber *)dictionary[kHMDWatchDogExportKeyFreeMemoryUsage] doubleValue];
    NSInteger freeDiskBlocks = 0;
    if (dictionary[kHMDWatchDogExportKeyFreeDiskBlocks]) {
        freeDiskBlocks= [(NSNumber *)dictionary[kHMDWatchDogExportKeyFreeDiskBlocks] integerValue];
    } else {
        double freeDisk = [(NSNumber *)dictionary[kHMDWatchDogExportKeyFreeDiskUsage] doubleValue];
        freeDiskBlocks = [HMDDiskUsage getDisk300MBBlocksFrom:(freeDisk * HMD_MB)]; // watch dog 在存储时转成了 MB, 这里在合规计算处理的时候都是统一按照 byte 来处理的, 所以这里进行一个还原;
    }

    CFTimeInterval timeoutDuration = [(NSNumber *)dictionary[kHMDWatchDogExportKeyTimeoutDuration] doubleValue];
    CFTimeInterval timeStamp = [(NSNumber *)dictionary[kHMDWatchDogExportKeyTimestamp] doubleValue];
    CFTimeInterval inAppTime = [(NSNumber *)dictionary[kHMDWatchDogExportKeyinAppTime] doubleValue];
    BOOL isBackground = [(NSNumber *)dictionary[kHMDWatchDogExportKeyIsBackground] boolValue];
    BOOL isLaunchCrash = [(NSNumber *)dictionary[kHMDWatchDogExportKeyIsLaunchCrash] boolValue];
    NSDictionary *settings = dictionary[kHMDWatchDogExportKeySettings];
    NSArray *deadlock = dictionary[kHMDWatchDogExportKeyDeadlock];
    unsigned long mainAdress = [(NSNumber *)dictionary[kHMDWatchDogExportKeyExeptionMainAdress] longValue];
    HMDWatchDogRecord *record = [HMDWatchDogRecord newRecord];
    BOOL isMainDeadLock = [(NSNumber *)dictionary[kHMDWatchDogExportKeyIsMainDeadlock] boolValue];
    record.sessionID = thatTimeApplicationSession;
    record.timestamp = timeStamp;
    record.inAppTime = inAppTime;
    record.business = business ? business : @"unknown";
    record.lastScene = lastScene ? lastScene : @"unknown";
    record.operationTrace = operationTrace;
    record.internalSessionID = internalSession;
    record.memoryUsage = memoryUsage;
    record.freeMemoryUsage = freeMemoryUsage;
    record.freeDiskBlocks = freeDiskBlocks;
    record.timeoutDuration = timeoutDuration;
    record.backtrace = backtraceString;
    record.connectionTypeName = access;
    record.background = isBackground;
    record.launchCrash = isLaunchCrash;
    record.filters = filters;
    record.settings = settings;
    record.enableUpload = self.config.enableUpload ? 1 : 0;
    record.customParams = custom;
    record.timeline = timeline;
    record.main_thread_cpu_usage = main_thread_cpu_usage;
    record.host_cpu_usage = host_cpu_usage;
    record.task_cpu_usage = task_cpu_usage;
    record.cpu_count = cpu_count;
    if (appVersion.length > 0) {
        record.appVersion = appVersion;
    }
    if (buildVersion.length > 0) {
        record.buildVersion = buildVersion;
    }
    if(internalSession) {
        if (hermas_enabled()) {
            NSDictionary *latestSessionDic = [HMDSessionTracker latestSessionDicAtLastLaunch];
            if (latestSessionDic) {

                record.appVersion = [latestSessionDic hmd_stringForKey:@"app_version"];
                record.buildVersion = [latestSessionDic hmd_stringForKey:@"buildVersion"];
                record.sdkVersion = [latestSessionDic hmd_stringForKey:@"sdk_version"];
                record.osVersion = [latestSessionDic hmd_stringForKey:@"os_version"];
                
                NSDictionary *customParams = [latestSessionDic hmd_dictForKey:@"customParams"];
                if(record.customParams == nil) record.customParams = customParams;
                    
                NSDictionary *filters = [latestSessionDic hmd_dictForKey:@"filters"];
                if(record.filters == nil) record.filters = filters;
            }
        } else {
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_DEPRECATED_DECLARATIONS
            HMDApplicationSession *latestSession = [HMDSessionTracker latestSessionAtLastLaunch];
CLANG_DIAGNOSTIC_POP
            if(latestSession) {
                [record recoverWithSessionRecord:latestSession];
                if (record.filters == nil) {
                    record.filters = latestSession.filters;
                }
                
                if (record.customParams == nil) {
                    record.customParams = latestSession.customParams;
                }
            }
        }
        
    }
    if (isMainDeadLock){
        record.MainDeadlock = isMainDeadLock;
        if (filters) {
            NSMutableDictionary *mutablefilters = [filters mutableCopy];
            [mutablefilters setObject:@(YES) forKey:kHMDWatchDogExportKeyIsMainDeadlock];
            record.filters = [mutablefilters copy];
        }else{
            record.filters = @{kHMDWatchDogExportKeyIsMainDeadlock: @(YES)};
        }
    }
    if (deadlock.count > 0){
        record.deadlock = deadlock;
    }
    record.exceptionMainAddress = mainAdress;
    
    if (hermas_enabled()) {
        if (hermas_drop_data(kModuleExceptionName)) {
            return;
        }
        
        // 更新record
        [self updateRecordWithConfig:record];
        
        // 实时写入并上传(考虑到实时性问题，采用HMRecordPriorityRealTime上传方式)
        [self.instance recordData:record.reportDictionary priority:HMRecordPriorityRealTime];
        
        // 原来的逻辑是每次从数据库中取的时候进行Alog，现在应该在record的时候，同步上传Alog日志（正常情况下，watchdog的数据只应该有1条，所以频繁性可以控制）
        if (record.timestamp > 0 && [HMDWatchDog sharedInstance].uploadAlog) {
            DC_OB(DC_CL(HMDLogUploader, sharedInstance), exceptionALogUploadWithEndTime:, record.timestamp);
        }
    } else {
        if (hmd_drop_data(HMDReporterException)){
            return;
        }
        [self didCollectOneRecord:record trackerBlock:^(BOOL isFlushed) {
            if (isFlushed){
                HMDStopUpload exceptionStopUpload = [HMDInjectedInfo defaultInfo].exceptionStopUpload;
                if (!(exceptionStopUpload && exceptionStopUpload())) {
                    [[HMDExceptionReporter sharedInstance] reportAllExceptionData];
                }
            }
        }];
    }
     
    
    self.detected = YES;
    self.finishDetection = YES;
    self.isTimeoutLastTime = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDWatchDogFinishDetectionNotification
                                                        object:self
                                                      userInfo:@{
                                                          @"timeoutDuration" : @(record.timeoutDuration),
                                                          @"inAppTime" : @(record.inAppTime),
                                                          @"background" : @(record.background),
                                                          @"lastScene" : record.lastScene,
                                                          @"MainDeadlock": @(record.MainDeadlock),
                                                          @"memoryUsage": @(record.memoryUsage),
                                                          @"freeMemoryUsage": @(record.freeMemoryUsage),
                                                          @"freeMemoryPercent":@(get_free_memory_percent(record.freeMemoryUsage)),
                                                          @"freeDiskBlocks": @(record.freeDiskBlocks),
                                                          @"business": record.business
                                                      }];
    
    NSString *reasonStr = @"System kills forcedly";
    NSDictionary *category = @{@"reason":reasonStr};
    [HMDMonitorService trackService:@"hmd_app_relaunch_reason" metrics:nil dimension:category extra:nil];
    
    HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[Watchdog] application relaunch reason: %@ timeout %f sec", reasonStr, timeoutDuration);
}

- (void)watchDogDidDetectUserForceQuitWithData:(NSDictionary *)dic {
    CFTimeInterval timeoutDuration = [(NSNumber *)dic[kHMDWatchDogExportKeyTimeoutDuration] doubleValue];
    self.detected = YES;
    self.finishDetection = YES;
    self.isTimeoutLastTime = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDWatchDogFinishDetectionNotification object:self];
    
    NSString *reasonStr = @"User exit forcedly";
    NSDictionary *category = @{@"reason":reasonStr};
    [HMDMonitorService trackService:@"hmd_app_relaunch_reason" metrics:nil dimension:category extra:nil];
    
    HMDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[Watchdog] application relaunch reason: %@ threshold %f sec", reasonStr, timeoutDuration);
}

- (void)watchDogDidNotHappenLastTime {
    self.detected = NO;
    self.finishDetection = YES;
    self.isTimeoutLastTime = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDWatchDogFinishDetectionNotification object:self];
}

#pragma mark - Override

- (NSString *)finishDetectionNotification {
    return kHMDWatchDogFinishDetectionNotification;
}

+ (instancetype)excludedModule {
    return [HMDWatchDogTracker sharedTracker];
}

+ (NSString *)tableName {
    return [[[HMDWatchDogTracker sharedTracker] storeClass] tableName];
}

+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSArray <NSDictionary *>*)aggregateDataForRecords:(NSArray *)records {
    return nil;
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDWatchDogRecord class];
}

- (BOOL)needSyncStart {
    return YES;
}

- (BOOL)performanceDataSource {
    return NO;
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (void)updateConfig:(HMDWatchDogConfig *)config {
    if(![config isValid]) {
        //downgrade for performance reason
        config = [HMDWatchDogConfig hmd_objectWithDictionary:nil];
        HMDALOG_PROTOCOL_ERROR_TAG(@"Heimdallr", @"Heimdallr Watchdog Module config invalid!");
    }
        
    [super updateConfig:config];
    HMDWatchDog *shared = [HMDWatchDog sharedInstance];
    shared.timeoutInterval = config.timeoutInterval;
    shared.sampleInterval = config.sampleInterval;
    shared.launchCrashThreshold = config.launchCrashThreshold;
    shared.suspend = config.suspend;
    shared.ignoreBackground = config.ignoreBackground;
    shared.lastThreadsCount = config.lastThreadsCount;
    shared.uploadAlog = config.uploadAlog;
    shared.uploadMemoryLog = config.uploadMemoryLog;
    shared.raiseMainThreadPriority = config.raiseMainThreadPriority;
    shared.raiseMainThreadPriorityInterval = config.raiseMainThreadPriorityInterval;
    shared.enableRunloopMonitorV2 = config.enableRunloopMonitorV2;
    shared.runloopMonitorThreadSleepInterval = config.runloopMonitorThreadSleepInterval;
#if DEBUG
    shared.enableRunloopMonitorV2 = YES;
#endif
}

- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    [super cleanupWithConfig:cleanConfig];
}

@end
