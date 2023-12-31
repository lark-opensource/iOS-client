//
//  HMDCPUExceptionMonitor+Reporter.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/9/9.
//

#import "HMDCPUExceptionMonitor+Reporter.h"
#import "HMDCPUExceptionV2Record.h"
#import "HMDExceptionReporter.h"
#import "Heimdallr+Private.h"
#import "NSArray+HMDSafe.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// PrivateServices
#import "HMDDebugLogger.h"

@implementation HMDCPUExceptionMonitor (Reporter)

@dynamic recordManager, readFromDB;

#pragma mark --- store delegate ---
- (BOOL)storeCPUExceptionRecords:(NSArray<HMDCPUExceptionV2Record *> *)records {
    if (records.count == 0) { return NO; }
    BOOL result = [self.heimdallr.database insertObjects:records into:[[[records firstObject] class] tableName]];
    return result;
}

- (BOOL)deleteCPUExceptionRecords:(NSArray<NSString *> *)recordUUIDs {
    NSMutableArray *conditions = [NSMutableArray array];
    for (NSString *recordUUID in recordUUIDs) {
        HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
        condition.key = @"uuid";
        condition.stringValue = recordUUID;
        condition.judgeType = HMDConditionJudgeEqual;
        [conditions hmd_addObject:condition];
    }

    BOOL isSuccess = [self.heimdallr.database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:nil orConditions:conditions];
    return isSuccess;
}

- (void)shouldReportCPUExceptionRecordNow {
    [[HMDExceptionReporter sharedInstance] reportExceptionDataWithExceptionTypes:@[@(HMDCPUExceptionType)]];
}

#pragma mark --- exception report ---
- (NSArray *)pendingExceptionData {
    if (hermas_enabled()) {
        return nil;
    }
    
    NSArray *dataArray = nil;
    if (self.readFromDB) {
        // read stored data
        dataArray = [self cpuExceptionDataFromStore];
    } else {
        // read memory data
        dataArray = [self cpuExceptionDataFromMemory];
    }
    if (dataArray.count) {
        [HMDDebugLogger printLog:@"CPUException log is uploading..."];
    }
    return dataArray;
}

- (void)exceptionReporterDidReceiveResponse:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }
    
    [self.recordManager cpuExceptionReportCompletion:YES];
}

- (void)dropExceptionData {
    if (hermas_enabled()) {
        return;
    }
    
    [self.recordManager cpuExceptionReportCompletion:YES];
}

- (NSArray *)cpuExceptionDataFromStore {
    self.recordManager.isRecordFromStore = YES;

    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970];
    HMDStoreCondition *condition0 = [[HMDStoreCondition alloc] init];
    condition0.key = @"timestamp";
    condition0.threshold = currentTime;
    condition0.judgeType = HMDConditionJudgeLess;
    NSArray*conditions = @[condition0];

    NSArray<HMDCPUExceptionV2Record *> *records =
    [self.heimdallr.database getObjectsWithTableName:[[self storeClass] tableName]
                                              class:[self storeClass]
                                      andConditions:conditions
                                       orConditions:nil
                                              limit:10];

    if (!records) { return nil; }
    NSArray *result = [self.recordManager cpuExceptionReprotDataWithRecords:records];
    return [result copy];
}

- (NSArray *)cpuExceptionDataFromMemory {
    // read memory data
    self.recordManager.isRecordFromStore = NO;
    NSArray *dataArray = [self.recordManager cpuExceptionReportData];
    return dataArray;
}

@end
