//
//  HMDUIFrozenTracker.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/23.
//

#import "HMDUIFrozenTracker.h"
#import "HMDExceptionReporter.h"
#import "HMDUIFrozenManager.h"
#import "HMDUIFrozenDetectProtocol.h"
#import "HMDUIFrozenRecord.h"
#import "HMDUIFrozenConfig.h"
#import "HMDStoreCondition.h"
#import "HMDDynamicCall.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "HMDExcludeModule.h"
#import "HMDDebugRealConfig.h"
#import "HMDUIFrozenDefine.h"
#import "HMDMemoryUsage.h"
#import "HMDMacro.h"
#import "HMDInjectedInfo+UniqueKey.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDALogProtocol.h"
#import "HMDUserExceptionTracker.h"

#import "HMDHermasHelper.h"
#import "HMDHermasManager.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDServerStateService.h"
#import "HMDMonitorService.h"

static NSString *const kHMDUIFrozenFinishDetectionNotification = @"HMDUIFrozenFinishDetectionNotification";
NSString *const kHMDUIFrozenEventType = @"UIFrozen";
static NSUInteger const kHMDUIFrozenUploadLimitCount = 5;

@interface HMDUIFrozenTracker() <HMDUIFrozenDetectProtocol, HMDExcludeModule>
@property(nonatomic, strong) NSArray<HMDStoreCondition *> *andConditions;
@property(atomic, readwrite, getter=isFinishDetection) BOOL finishDetection;
@property(atomic, readwrite, getter=isDetected) BOOL detected;

@property (nonatomic, strong) HMInstance *instance;
@end

@implementation HMDUIFrozenTracker

SHAREDTRACKER(HMDUIFrozenTracker)

#pragma mark - HeimdallrModule

- (HMInstance *)instance {
    if (!_instance) {
        _instance = [[HMEngine sharedEngine] instanceWithModuleId:kModuleExceptionName aid:[HMDInjectedInfo defaultInfo].appID];
    }
    return _instance;
}



- (void)start {
    [super start];
    [HMDUIFrozenManager sharedInstance].delegate = self;
    [[HMDUIFrozenManager sharedInstance] start];
}

- (void)stop {
    [super stop];
    [[HMDUIFrozenManager sharedInstance] stop];
}

+ (NSArray <NSDictionary *>*)reportDataForRecords:(NSArray *)records {
    return nil;
}

+ (NSArray <NSDictionary *>*)aggregateDataForRecords:(NSArray *)records {
    return nil;
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDUIFrozenRecord class];
}

- (BOOL)needSyncStart {
    return NO;
}

- (BOOL)performanceDataSource {
    return NO;
}

- (BOOL)exceptionDataSource {
    return YES;
}

- (void)updateConfig:(HMDUIFrozenConfig *)config {
    config.enableUpload = YES;
    [super updateConfig:config];
    HMDUIFrozenManager *shared = [HMDUIFrozenManager sharedInstance];
    shared.operationCountThreshold = config.operationCountThreshold;
    shared.launchCrashThreshold = config.launchCrashThreshold;
    shared.uploadAlog = config.uploadAlog;
    shared.enableGestureMonitor = config.enableGestureMonitor;
    shared.gestureCountThreshold = config.gestureCountThreshold;
}

- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    [super cleanupWithConfig:cleanConfig];
}

#pragma mark - HMDExcludeModule

- (NSString *)finishDetectionNotification {
    return kHMDUIFrozenFinishDetectionNotification;
}

+ (instancetype)excludedModule {
    return [HMDUIFrozenTracker sharedTracker];
}

- (HMDExceptionType)exceptionType {
    return HMDUIFrozenExceptionType;
}

#pragma mark - HMDUIFrozenDetectProtocol

- (void)didDetectUIFrozenWithData:(NSDictionary *)data {
    BOOL needDrop = hermas_enabled() ? hermas_drop_data(kModuleExceptionName) : hmd_drop_data(HMDReporterException);
    if (needDrop) return;
    
    HMDUIFrozenRecord *record = [HMDUIFrozenRecord newRecord];
    // 监控数据
    record.frozenType = data[kHMDUIFrozenKeyType];
    record.targetViewDescription = data[kHMDUIFrozenKeyTargetView];
    record.targetWindowDescription = data[kHMDUIFrozenKeyTargetWindow];
    //版本升级新增字段
    if ([data hmd_hasKey:kHMDUIFrozenKeyViewHierarchy]){
        record.viewHierarchy = [data hmd_dictForKey:kHMDUIFrozenKeyViewHierarchy];
    }
    if ([data hmd_hasKey:kHMDUIFrozenKeyViewControllerHierarchy]){
        record.viewControllerHierarchy = data[kHMDUIFrozenKeyViewControllerHierarchy];
    }
    if ([data hmd_hasKey:kHMDUIFrozenKeyViewControllerHierarchy]){
        record.responseChain = data[kHMDUIFrozenKeyResponseChain];
    }
    if ([data hmd_hasKey:kHMDUIFrozenKeyNearViewController]){
        record.nearViewController = [data hmd_stringForKey:kHMDUIFrozenKeyNearViewController];
    }
    if ([data hmd_hasKey:kHMDUIFrozenKeyNearViewControllerDesc]){
        record.nearViewControllerDesc = [data hmd_stringForKey:kHMDUIFrozenKeyNearViewControllerDesc];
    }
    record.startTS = [data hmd_doubleForKey:kHMDUIFrozenKeyStartTimestamp];
    record.timestamp = [data hmd_doubleForKey:kHMDUIFrozenKeyTimestamp];
    record.operationCount = [data hmd_unsignedIntegerForKey:kHMDUIFrozenKeyOperationCount];
    record.settings = data[kHMDUIFrozenKeySettings];
    record.inAppTime = [data hmd_doubleForKey:kHMDUIFrozenKeyinAppTime];
    record.launchCrash = [data hmd_boolForKey:kHMDUIFrozenKeyIsLaunchCrash];

    // 性能数据
    record.connectionTypeName = data[kHMDUIFrozenKeyNetwork];
    record.memoryUsage = [data hmd_doubleForKey:kHMDUIFrozenKeyMemoryUsage];
    record.freeMemoryUsage = [data hmd_doubleForKey:HMD_Free_Memory_Key];
    record.freeDiskBlocks = [data hmd_doubleForKey:kHMDUIFrozenKeyFreeDiskBlockSize];

    // 业务数据
    record.business = data[kHMDUIFrozenKeyBusiness];
    record.internalSessionID = data[kHMDUIFrozenKeyInternalSessionID];
    record.sessionID = data[kHMDUIFrozenKeySessionID];
    record.lastScene = data[kHMDUIFrozenKeylastScene];
    record.operationTrace = [data hmd_dictForKey:kHMDUIFrozenKeyOperationTrace];
    record.customParams = [data hmd_dictForKey:kHMDUIFrozenKeyCustom];
    record.filters = [data hmd_dictForKey:kHMDUIFrozenKeyFilters];

    if (hermas_enabled()) {
        // update record
        [self updateRecordWithConfig:record];
        
        // reocrd data
        BOOL recordImmediately = [HMDHermasHelper recordImmediately];
        HMRecordPriority priority = recordImmediately ? HMRecordPriorityRealTime : HMRecordPriorityHigh;
        [self.instance recordData:record.reportDictionary priority:priority];
        
        // hmd track loss key
        if (record.nearViewController == nil || record.viewHierarchy.count == 0) {
            DC_OB(DC_CL(HMDTTMonitor, heimdallrTTMonitor), hmdTrackService:metric:category:extra:, @"uifrozen_update_loss_key", nil, nil, nil);
        }
        
        // upload alog
        if ([HMDUIFrozenManager sharedInstance].uploadAlog) {
            DC_OB(DC_CL(HMDLogUploader, sharedInstance), uploadLastAlogBeforeTime:, record.timestamp);
        }
        
    } else {
        [self didCollectOneRecord:record trackerBlock:^(BOOL isFlushed) {
            if (isFlushed) {
                [[HMDExceptionReporter sharedInstance] reportExceptionDataWithExceptionTypes:@[@(HMDUIFrozenExceptionType)]];
            }
        }];
    }
    
    self.detected = YES;
    self.finishDetection = YES;
    NSString *reason = @"UIFrozen";
    NSDictionary *category = @{@"reason":reason};
    [HMDMonitorService trackService:@"hmd_app_relaunch_reason" metrics:nil dimension:category extra:nil];
    
    BDALOG_PROTOCOL_WARN_TAG(@"Heimdallr", @"[UIFrozen] application relaunch reason: %@", reason);
    if (record.nearViewController==nil || record.viewHierarchy.count==0) {
        [HMDMonitorService trackService:@"uifrozen_record_loss_key" metrics:nil dimension:nil extra:nil];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kHMDUIFrozenFinishDetectionNotification
                                                        object:self
                                                      userInfo:nil];
}

#pragma mark - HMDExceptionReporterDelegate

- (NSArray *)pendingExceptionData {
    if (hermas_enabled()) {
        return nil;
    }
    
    HMDStoreCondition *cond1 = [[HMDStoreCondition alloc] init];
    cond1.key = @"timestamp";
    cond1.threshold = 0;
    cond1.judgeType = HMDConditionJudgeGreater;
    HMDStoreCondition *cond2 = [[HMDStoreCondition alloc] init];
    cond2.key = @"timestamp";
    cond2.threshold = [[NSDate date] timeIntervalSince1970];
    cond2.judgeType = HMDConditionJudgeLess;
    _andConditions = @[cond1,cond2];
    NSArray<HMDUIFrozenRecord *> *records =
    [[Heimdallr shared].database getObjectsWithTableName:[self tableName]
                                                   class:[self storeClass]
                                           andConditions:_andConditions
                                            orConditions:nil
                                                   limit:kHMDUIFrozenUploadLimitCount];
    NSArray *result = [self getUIFrozenDataWithRecords:records];
    return result;
}


- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }
    
    if (!isSuccess) {
        return;
    }
    
    if (_andConditions) {
        [[Heimdallr shared].database deleteObjectsFromTable:[self tableName]
                                              andConditions:_andConditions
                                               orConditions:nil
                                                      limit:kHMDUIFrozenUploadLimitCount];
    }
}

-(void)dropExceptionData {
    if (hermas_enabled()) {
        return;
    }
    
    HMDStoreCondition *cond1 = [[HMDStoreCondition alloc] init];
    cond1.key = @"timestamp";
    cond1.threshold = 0;
    cond1.judgeType = HMDConditionJudgeGreater;
    HMDStoreCondition *cond2 = [[HMDStoreCondition alloc] init];
    cond2.key = @"timestamp";
    cond2.threshold = [[NSDate date] timeIntervalSince1970];
    cond2.judgeType = HMDConditionJudgeLess;
    NSArray<HMDStoreCondition *> *conditions = @[cond1,cond2];
    [[Heimdallr shared].database deleteObjectsFromTable:[self tableName]
                                          andConditions:conditions
                                           orConditions:nil];
}

#pragma mark - Private

- (NSString *)tableName {
    return [[self storeClass] tableName];
}

- (NSArray *)getUIFrozenDataWithRecords:(NSArray<HMDUIFrozenRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    NSTimeInterval lastTimestamp = 0;
    for (HMDUIFrozenRecord *record in records) {
        @autoreleasepool {
            NSMutableDictionary *dataValue = [NSMutableDictionary dictionary];
            [dataValue setValue:kHMDUIFrozenEventType forKey:@"event_type"];
            
            // 监控数据
            [dataValue setValue:record.frozenType forKey:kHMDUIFrozenKeyType];
            [dataValue setValue:record.targetViewDescription forKey:kHMDUIFrozenKeyTargetView];
            [dataValue setValue:record.targetWindowDescription forKey:kHMDUIFrozenKeyTargetWindow];
            [dataValue setValue:record.viewHierarchy forKey:kHMDUIFrozenKeyViewHierarchy];
            [dataValue setValue:record.viewControllerHierarchy forKey:kHMDUIFrozenKeyViewControllerHierarchy];
            [dataValue setValue:record.responseChain forKey:kHMDUIFrozenKeyResponseChain];
            [dataValue setValue:record.nearViewController forKey:kHMDUIFrozenKeyNearViewController];
            [dataValue setValue:record.nearViewControllerDesc forKey:kHMDUIFrozenKeyNearViewControllerDesc];

            [dataValue setValue:@(record.operationCount) forKey:kHMDUIFrozenKeyOperationCount];
            long long timestamp = MilliSecond(record.timestamp);
            [dataValue setValue:@(timestamp) forKey:kHMDUIFrozenKeyTimestamp];
            [dataValue setValue:@(record.timestamp-record.startTS) forKey:@"duration"];
            [dataValue setValue:@(record.inAppTime) forKey:kHMDUIFrozenKeyinAppTime];
            [dataValue setValue:@(record.isLaunchCrash) forKey:kHMDUIFrozenKeyIsLaunchCrash];
            [dataValue setValue:record.settings forKey:kHMDUIFrozenKeySettings];
            
            // 性能数据
            [dataValue setValue:@(record.memoryUsage) forKey:kHMDUIFrozenKeyMemoryUsage];
            hmd_MemoryBytes memoryBytes = hmd_getMemoryBytes();
            double allMemory = memoryBytes.totalMemory;
            [dataValue setValue:@(record.freeDiskBlocks) forKey:kHMDUIFrozenKeyFreeDiskBlockSize];
            [dataValue setValue:@(hmd_calculateMemorySizeLevel(record.freeMemoryUsage)) forKey:HMD_Free_Memory_Key];
            double free_memory_percent = (int)(record.freeMemoryUsage/allMemory*100)/100.0;
            [dataValue setValue:@(free_memory_percent) forKey:HMD_Free_Memory_Percent_key];
            [dataValue setValue:record.connectionTypeName forKey:kHMDUIFrozenKeyNetwork];
            
            // 业务数据
            [dataValue setValue:record.sessionID forKey:kHMDUIFrozenKeySessionID];
            [dataValue setValue:record.business forKey:kHMDUIFrozenKeyBusiness];
            [dataValue setValue:record.lastScene forKey:kHMDUIFrozenKeylastScene];
            [dataValue setValue:record.operationTrace forKey:kHMDUIFrozenKeyOperationTrace];
            if (record.customParams.count > 0)
                [dataValue setValue:record.customParams forKey:kHMDUIFrozenKeyCustom];
            if (record.filters.count > 0) {
                [dataValue setValue:record.filters forKey:kHMDUIFrozenKeyFilters];
            }

            [dataValue addEntriesFromDictionary:record.environmentInfo];
            [[HMDInjectedInfo defaultInfo] confUniqueKeyForData:dataValue timestamp:timestamp eventType:kHMDUIFrozenEventType];
            [dataArray addObject:dataValue];
            if (record.timestamp > lastTimestamp) {
                lastTimestamp = record.timestamp;
            }
            if (record.nearViewController==nil || record.viewHierarchy.count==0) {
                [HMDMonitorService trackService:@"uifrozen_record_loss_key" metrics:nil dimension:nil extra:nil];
            }
        }
    }
    
    // 同步上传Alog日志
    if (lastTimestamp > 0 && [HMDUIFrozenManager sharedInstance].uploadAlog) {
        DC_OB(DC_CL(HMDLogUploader, sharedInstance), uploadLastAlogBeforeTime:, lastTimestamp);
    }
    
    return [dataArray copy];
}

@end
