//
//  HMDLaunchTiming+Report.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/7/20.
//

#import "HMDLaunchTiming+Report.h"
#import "Heimdallr+Private.h"
#import "HMDLaunchTimingRecord.h"
#import "HMDPerformanceReportRequest.h"
#import "HMDDebugRealConfig.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
// Utility
#import "HMDMacroManager.h"

@implementation HMDLaunchTiming (Report)

@dynamic reportingRequest;

#pragma mark --- report delegate
- (NSUInteger)reporterPriority {
    return HMDReporterPriorityStartDetector;
}

- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    
    if (hermas_enabled()) {
        return nil;
    }

    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"enableUpload";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;

    NSArray<HMDStoreCondition *> *dataAddCondtion = @[condition1, condition2];

    NSArray<HMDLaunchTimingRecord *> *records =
    [[Heimdallr shared].store.database getObjectsWithTableName:[HMDLaunchTimingRecord tableName]
                                                         class:[HMDLaunchTimingRecord class]
                                                 andConditions:dataAddCondtion
                                                  orConditions:nil
                                                         limit:limitCount];

    if(records == nil) return nil;

    self.reportingRequest = [[HMDPerformanceReportRequest alloc] init];
    self.reportingRequest.limitCount = limitCount;
    self.reportingRequest.dataAndConditions = dataAddCondtion;

    NSArray *result = [self getDataWithRecords:records isDebugReal:NO];

    if (HMD_IS_DEBUG) {
        if (result.count > 0) {
            HMDLog(@"Heimdallr launch timing ayalyse success !!!");
        }
        return nil;
    }

    return [result copy];
}

- (void)cleanupPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    
    if (hermas_enabled()) {
        return;
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

    [[Heimdallr shared].store.database deleteObjectsFromTable:[[self storeClass] tableName]
                                                andConditions:debugRealConditions
                                                 orConditions:nil
                                                        limit:config.limitCnt];
}

- (void)performanceDataDidReportSuccess:(BOOL)isSuccess {
    if (hermas_enabled()) {
        return;
    }
    
    if (isSuccess) {
        [self.heimdallr.database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:self.reportingRequest.dataAndConditions
                                           orConditions:nil
                                                  limit:self.reportingRequest.limitCount];
    }
    self.reportingRequest = nil;
}

- (NSArray *)getDataWithRecords:(NSArray<HMDLaunchTimingRecord *> *)records isDebugReal:(BOOL)isDebugReal {
    NSMutableArray *dataArray = [NSMutableArray array];
    for (HMDLaunchTimingRecord *record in records) {
        NSDictionary *dataValue = [record reportDictWithDebugReal:isDebugReal];
        [dataArray addObject:dataValue];
    }
    return [dataArray copy];
}


@end
