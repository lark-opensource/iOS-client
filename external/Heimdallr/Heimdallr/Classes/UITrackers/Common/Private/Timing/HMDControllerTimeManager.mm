//
//  HMDControllerTimeManager.m
//  Heimdallr
//
//  Created by joy on 2018/5/10.
//

#import "HMDControllerTimeManager.h"
#import "Heimdallr.h"
#import "HMDPerformanceReporter.h"
#import "Heimdallr+Private.h"
#import "HMDDebugRealConfig.h"
#import "HMDPerformanceAggregate.h"
#import "HMDMacro.h"
#import "HMDStoreCondition.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "HMDControllerTimingConfig.h"
#import "Heimdallr+Cleanup.h"
#import "HMDTrackerConfig.h"
#import "HMDControllerTimingConfig.h"
#import "HMDRecordStore+DeleteRecord.h"
#import "NSArray+HMDJSON.h"
#import "HMDControllerTimeManager+Report.h"
#import "HMDGCD.h"

#import "HMDHermasManager.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

#import "HMDReportDowngrador.h"
// PrivateServices
#import "HMDServerStateService.h"

#define kControllerTimeFlushCount 10

static HMDControllerTimeManager *shared = nil;
@interface HMDControllerTimeManager() <HMDPerformanceReporterDataSource> {
    CFTimeInterval _startTimestamp;
}
@property (nonatomic, assign, readwrite) CFTimeInterval lastFlushTimestamp;
@property (nonatomic, strong) NSMutableArray<HMDControllerTimeRecord *> *recordsArray;
@property (nonatomic, strong) dispatch_queue_t syncQueue;
@property (nonatomic, assign) HMDRecordLocalIDRange uploadingRange;
@property (nonatomic, assign) NSInteger hmdCountLimit;
@property (nonatomic, strong) NSArray<HMDStoreCondition *> *andConditions;

@end
@implementation HMDControllerTimeManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (instancetype)init {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [super init];
        
        self.syncQueue = dispatch_queue_create("com.hmdcontrollermonitor.syncQueue", DISPATCH_QUEUE_SERIAL);

        [HMDControllerMonitor sharedInstance].delegate = (id<HMDControllerMonitorDelegate>)self;
        [[NSNotificationCenter defaultCenter] addObserver:shared
                                                 selector:@selector(applicationWillEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
    });
    return shared;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [super allocWithZone:zone];
    });
    return shared;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - HeimdallrModule

- (void)setupWithHeimdallr:(Heimdallr *)heimdallr {
    [super setupWithHeimdallr:heimdallr];
}

- (void)start {
    [super start];
    _startTimestamp = [[NSDate date] timeIntervalSince1970];
}

- (void)stop {
    [super stop];
}

- (Class<HMDRecordStoreObject>)storeClass {
    return [HMDControllerTimeRecord class];
}

- (BOOL)performanceDataSource
{
    return YES;
}

- (void)cleanupWithConfig:(HMDCleanupConfig *)cleanConfig {
    [self.heimdallr cleanupDatabaseWithConfig:cleanConfig tableName:[self.storeClass tableName]];
    [self.heimdallr cleanupDatabase:[self.storeClass tableName] limitSize:[self dbMaxSize]];
}

- (void)updateConfig:(HMDModuleConfig *)config {
    [super updateConfig:config];
}

- (long long)dbMaxSize {
    return 10000;
}

- (NSMutableArray<HMDControllerTimeRecord *> *)recordsArray {
    if (!_recordsArray) {
        _recordsArray = [NSMutableArray new];
    }
    return _recordsArray;
}
- (void)tracksCountChangedWithImmediately:(BOOL)immediately {
    NSUInteger flushCount = ((HMDControllerTimingConfig *)self.config).flushCount;
    float flushInterval = ((HMDControllerTimingConfig *)self.config).flushInterval;
    if (self.lastFlushTimestamp == 0) {
        self.lastFlushTimestamp = [[NSDate date] timeIntervalSince1970];
    }
    CFTimeInterval nowTimeStamp = [[NSDate date] timeIntervalSince1970];
    BOOL isExceedTimeThreshold = nowTimeStamp - self.lastFlushTimestamp > flushInterval;
    BOOL isExceedCountThreshold = self.recordsArray.count > flushCount;
    if (isExceedTimeThreshold || isExceedCountThreshold || immediately) {
        
        if ([self.heimdallr.database insertObjects:self.recordsArray
                                                    into:[self.storeClass tableName]])
        {
            [self.heimdallr updateRecordCount:self.recordsArray.count];
            [self clearRecordsArray];
            //update
            self.lastFlushTimestamp = nowTimeStamp;
        }
    }
}
- (void)clearRecordsArray {
    [self.recordsArray removeAllObjects];
}

#pragma mark -- receiveNotification
- (void)applicationWillEnterBackground:(NSNotification *)notification {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        if ([self.heimdallr.database insertObjects:self.recordsArray
                                                    into:[self.storeClass tableName]])
        {
            [self.heimdallr updateRecordCount:self.recordsArray.count];
            [self clearRecordsArray];
        }
    });
}
#pragma mark - delegate
- (void)hmdControllerName:(NSString *)pageName typeName:(NSString *)typeName timeInterval:(NSTimeInterval)interval isFirstOpen:(NSInteger)isFirstOpen {
    
    if (!self.isRunning || hmd_drop_data(HMDReporterPerformance) || hmd_downgrade_performance(@"performance_monitor")) {
        return;
    }
    
    HMDControllerTimeRecord *record = [HMDControllerTimeRecord newRecord];
    record.timeInterval = interval;
    record.pageName = pageName;
    record.typeName = typeName;
    record.isFirstOpen = isFirstOpen;
    record.enableUpload = self.config.enableUpload ? 1 : 0;
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self.recordsArray addObject:record];
        [self tracksCountChangedWithImmediately:NO];
    });
}
#pragma mark -- upload

- (NSUInteger)reporterPriority {
    return HMDReporterPriorityControllerTimeManager;
}

- (NSArray *)debugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    if (![config checkIfAllowedDebugRealUploadWithType:kEnablePerformanceMonitor] &&
        ![config checkIfAllowedDebugRealUploadWithType:kHMDModuleControllerTracker]) {
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
    NSArray<HMDControllerTimeRecord *> *records = [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName] class:[self storeClass] andConditions:debugRealConditions orConditions:nil limit:config.limitCnt];
    
    
    NSArray *result = [self getDataWithRecords:records];
    
    return [result copy];
}

- (void)cleanupPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = config.fetchStartTime;
    condition1.judgeType = HMDConditionJudgeGreater;
    
    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = config.fetchEndTime;
    condition2.judgeType = HMDConditionJudgeLess;
    
    NSArray<HMDStoreCondition *> *debugRealConditions = @[condition1,condition2];
    
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:debugRealConditions orConditions:nil limit:config.limitCnt];
}
        
- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    self.hmdCountLimit = limitCount ?: 0;
    NSArray *records = [self fetchUploadRecords];
    
    if(records == nil) return nil;
    NSArray *result = [self getAggregateDataWithRecords:records];
    return [result copy];
}

- (NSArray *)fetchUploadRecords {
    HMDStoreCondition *condition0 = [[HMDStoreCondition alloc] init];
    condition0.key = @"enableUpload";
    condition0.threshold = 0;
    condition0.judgeType = HMDConditionJudgeGreater;

    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = [[NSDate date] timeIntervalSince1970];
    condition1.judgeType = HMDConditionJudgeLess;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"isReported";
    condition2.threshold = 0;
    condition2.judgeType = HMDConditionJudgeEqual;

    self.andConditions = @[condition0, condition1, condition2];

    NSArray<HMDControllerTimeRecord *> *records = [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName] class:[self storeClass] andConditions:self.andConditions orConditions:nil limit:self.hmdCountLimit];
    return records;
}

- (void)performanceDataSaveImmediately {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self tracksCountChangedWithImmediately:YES];
    });
}

- (void)performanceDataDidReportSuccess:(BOOL)isSuccess {
    if (isSuccess) {
        // 上传成功删除数据
        [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:self.andConditions orConditions:nil limit:self.hmdCountLimit];
    }
}

- (void)cleanupNotUploadAndReportedPerformanceData {
    HMDStoreCondition *cleanCondition = [[HMDStoreCondition alloc] init];
    cleanCondition.key = @"isReported";
    cleanCondition.threshold = 1;
    cleanCondition.judgeType = HMDConditionJudgeEqual;

    NSArray<HMDStoreCondition *> *cleanConditions = @[cleanCondition];
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:cleanConditions orConditions:nil];
}

#pragma - mark drop data

- (void)dropAllDataForServerState {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self clearRecordsArray];
        [[Heimdallr shared].database deleteAllObjectsFromTable:[[self storeClass] tableName]];
    });
}

@end
