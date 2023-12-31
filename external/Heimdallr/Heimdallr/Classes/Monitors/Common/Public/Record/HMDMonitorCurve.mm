//
//  HMDMonitorCurve.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2017/12/11.
//

#import "HMDMonitorCurve.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "HMDCPUMonitorRecord.h"
#import "HMDMemoryMonitorRecord.h"
#import "HMDFPSMonitorRecord.h"
#import "HMDALogProtocol.h"
#import "pthread_extended.h"
#import "HMDReportLimitSizeTool.h"
#import "HMDGCD.h"
#import "HMDCustomReportManager.h"
#import "HMDReportDowngrador.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

#import "HMDHermasManager.h"
// PrivateServices
#import "HMDServerStateService.h"

@interface HMDMonitorCurve()
{
    CFTimeInterval lastFlushTimestamp;
    CFTimeInterval _startTimestamp;
    pthread_rwlock_t _recordRWLock;
}
@property (nonatomic, strong, readwrite) NSMutableArray *records;
@property (nonatomic, strong) dispatch_queue_t syncQueue;
@property (nonatomic, assign)BOOL dropData;

@end

@implementation HMDMonitorCurve

- (instancetype)initWithCurveName:(NSString *)name recordClass:(Class)recordClass {
    self = [super init];
    if (self) {
        _name = name;
        _records = [[NSMutableArray alloc] init];
        _recordClass = recordClass;
        _flushCount = 5;
        _flushInterval = 30;
        _syncQueue = dispatch_queue_create("com.hmdmonitors.syncQueue", DISPATCH_QUEUE_SERIAL);
        pthread_rwlock_init(&_recordRWLock, NULL);

        if (!_startTimestamp) {
            _startTimestamp = [[NSDate date] timeIntervalSince1970];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    }
    return self;
}

- (instancetype)init {
    return [self initWithCurveName:@"" recordClass:[HMDMonitorRecord class]];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)pushRecord:(HMDMonitorRecord *)record {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self updateRecord:record forceWrite:NO];
    });
}

- (void)pushRecordToDBImmediately:(HMDMonitorRecord *)record {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self updateRecord:record forceWrite:YES];
    });
}

- (void)updateRecord:(HMDMonitorRecord *)record forceWrite:(BOOL)forceWrite
{
    if (hmd_drop_data(HMDReporterPerformance)) return;
    if (hmd_downgrade_performance(@"performance_monitor")) return;
    
    if (record && [record.class isSubclassOfClass:_recordClass]) {
        [self.storageDelegate updateRecordWithConfig:record];
        [record addInfo];
        if (!self.records.count) {
            _startTime = record.timestamp;
        }
        pthread_rwlock_wrlock(&_recordRWLock);
        [self.records addObject:record];
        pthread_rwlock_unlock(&_recordRWLock);

        if (!self.maxRecord || [self.maxRecord compare:record forKeyPath:@"value"] == NSOrderedAscending) {
            _maxRecord = record;
        }
        if (!self.minRecord || [self.maxRecord compare:record forKeyPath:@"value"] == NSOrderedDescending) {
            _minRecord = record;
        }
        _duration = record.timestamp - _startTime;
    }
    if (lastFlushTimestamp == 0) {
        lastFlushTimestamp = [[NSDate date] timeIntervalSince1970];
    }
    
    CFTimeInterval now = [[NSDate date] timeIntervalSince1970];
    BOOL isExceedTimeThreshold = now - lastFlushTimestamp >= _flushInterval;
    BOOL isExceedCountThreshold = self.records.count >= _flushCount;
    if (isExceedTimeThreshold || isExceedCountThreshold || forceWrite) {
        if (self.performanceReportEnable && ([HMDCustomReportManager defaultManager].currentConfig.customReportMode == HMDCustomReportModeSizeLimit)) {
            [self.storageDelegate recordSizeCalculationWithRecord:record];
        }
        // storage in database
        [self.storageDelegate monitorCurve:self willSaveRecords:self.records];
        // remove memory cache
        pthread_rwlock_wrlock(&_recordRWLock);
        [self.records removeAllObjects];
        pthread_rwlock_unlock(&_recordRWLock);

        lastFlushTimestamp = now;
    }
}

- (void)pushRecordImmediately {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self updateRecord:nil forceWrite:YES];
    });
}

- (HMDMonitorRecord *)currentRecord
{
    HMDMonitorRecord *record = nil;
    pthread_rwlock_rdlock(&_recordRWLock);
    record = _records.lastObject;
    pthread_rwlock_unlock(&_recordRWLock);
    return record;
}

- (NSArray<HMDMonitorRecord*>*)recordsInAppTimeFrom:(CFTimeInterval)fromTime to:(CFTimeInterval)toTime sessionID:(NSString *)sessionID recordClass:(Class)recordClass
{
    if (recordClass == [HMDCPUMonitorRecord class]) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"inAppTime";
        condition1.threshold = fromTime;
        condition1.judgeType = HMDConditionJudgeGreater;
        
        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"inAppTime";
        condition2.threshold = toTime;
        condition2.judgeType = HMDConditionJudgeLess;
        
        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"sessionID";
        condition3.stringValue = sessionID;
        condition3.judgeType = HMDConditionJudgeEqual;
        
        return [[Heimdallr shared].database getObjectsWithTableName:@"HMDCPUMonitorRecord" class:HMDCPUMonitorRecord.class andConditions:@[condition1,condition2,condition3] orConditions:nil];
    }
    else if (recordClass == [HMDMemoryMonitorRecord class]) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"inAppTime";
        condition1.threshold = fromTime;
        condition1.judgeType = HMDConditionJudgeGreater;
        
        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"inAppTime";
        condition2.threshold = toTime;
        condition2.judgeType = HMDConditionJudgeLess;
        
        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"sessionID";
        condition3.stringValue = sessionID;
        condition3.judgeType = HMDConditionJudgeEqual;
        
        return [[Heimdallr shared].database getObjectsWithTableName:@"HMDMemoryMonitorRecord" class:HMDMemoryMonitorRecord.class andConditions:@[condition1,condition2,condition3] orConditions:nil];
    } else if (recordClass == [HMDFPSMonitorRecord class]) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"inAppTime";
        condition1.threshold = fromTime;
        condition1.judgeType = HMDConditionJudgeGreater;
        
        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"inAppTime";
        condition2.threshold = toTime;
        condition2.judgeType = HMDConditionJudgeLess;
        
        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"sessionID";
        condition3.stringValue = sessionID;
        condition3.judgeType = HMDConditionJudgeEqual;
        
        return [[Heimdallr shared].database getObjectsWithTableName:@"HMDFPSMonitorRecord" class:HMDFPSMonitorRecord.class andConditions:@[condition1,condition2,condition3] orConditions:nil];
    }
    
    return [NSArray new];
}

- (void)asyncActionOnCurveQueue:(dispatch_block_t)action {
    if(!action) {
        return;
    }
    hmd_safe_dispatch_async(self.syncQueue, ^{
        action();
    });
}

#pragma mark -- receiveNotification
- (void)applicationEnterBackground:(NSNotification *)notification {
    if (self.records.count > 0) {
        hmd_safe_dispatch_async(self.syncQueue, ^{
            [self.storageDelegate monitorCurve:self willSaveRecords:self.records];
            [self.records removeAllObjects];
        });

    }
}

#pragma - mark drop data

- (void)dropDataForServerState:(BOOL)drop {
    self.dropData = drop;
}

- (void)dropAllDataForServerState {
    hmd_safe_dispatch_async(self.syncQueue, ^{
        [self.records removeAllObjects];
        [self.storageDelegate dropAllMonitorRecords];
    });
}

- (void)recordDataDirectly:(NSDictionary *_Nonnull)dic {
    // do nothing
}

@end
