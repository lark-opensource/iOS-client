//
//  HMDOTManager+Report.m
//  Pods
//
//  Created by fengyadong on 2019/12/12.
//

#import "HMDOTManager+Report.h"
#import "Heimdallr+Private.h"
#import "HMDPerformanceReportRequest.h"
#import "HMDOTTrace.h"
#import "HMDOTSpan.h"
#import "HMDDebugRealConfig.h"
#import "HMDSessionTracker.h"
#import "HMDOTTrace+Private.h"
#import "HMDMacro.h"

@implementation HMDOTManager (Report)

#pragma mark - DataReporterDelegate
- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    self.reportingRequest = [[HMDPerformanceReportRequest alloc] init];
    self.reportingRequest.limitCount = limitCount;
    long long ignoreTime = MilliSecond([[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval]);
    
    NSArray<HMDStoreCondition *> *normalCondition = nil;
    if (ignoreTime) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"startTimestamp";
        condition1.threshold = ignoreTime;
        condition1.judgeType = HMDConditionJudgeGreater;

        normalCondition = @[condition1];
    }
    
    NSArray *traces = [self.heimdallr.database getObjectsWithTableName:[HMDOTTrace tableName] class:[HMDOTTrace class] andConditions:normalCondition orConditions:nil limit:limitCount];
    NSMutableArray *results = [NSMutableArray array];
    NSMutableArray *orConditions = [NSMutableArray array];
        
    for(HMDOTTrace *trace in traces) {
#ifdef DEBUG
        trace.isReporting = YES;
#endif
        //如果本次启动的trace还没有完成，不要上报，因为要保证一次trace内所有span上报的完整性
        if([trace.sessionID isEqualToString:[HMDSessionTracker sharedInstance].eternalSessionID] && !trace.isFinished) {
            continue;
        }
        
        NSDictionary *traceResult = [trace reportDictionary];
        if (traceResult) {
            [results addObject:traceResult];
        }
        
        HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
        condition.judgeType = HMDConditionJudgeEqual;
        condition.key = @"traceID";
        condition.stringValue = trace.traceID;
        
        [orConditions addObject:condition];
    }
    
    self.reportingRequest.dataOrConditions = [orConditions copy];
    
    NSArray<HMDOTSpan *> *records =
    [self.heimdallr.database getObjectsWithTableName:[[self storeClass] tableName] class:[self storeClass] andConditions:nil orConditions:self.reportingRequest.dataOrConditions];
    
    NSArray *spanResults = [[self storeClass] reportDataForRecords:records];
    if(spanResults.count > 0) {
        [results addObjectsFromArray:spanResults];
    }

    return [results copy];
}

- (void)performanceDataDidReportSuccess:(BOOL)isSuccess {
    if (isSuccess) {
        dispatch_async(self.spanIOQueue, ^{
            [self.heimdallr.database inTransaction:^BOOL{
                BOOL deleteTraceSuccess = [self.heimdallr.database deleteObjectsFromTable:[HMDOTTrace tableName] andConditions:self.reportingRequest.dataAndConditions orConditions:self.reportingRequest.dataOrConditions];
                BOOL deleteSpanSuccess = [self.heimdallr.database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:self.reportingRequest.dataAndConditions orConditions:self.reportingRequest.dataOrConditions];
                
                return deleteTraceSuccess && deleteSpanSuccess;
            }];
        });
    }
}

- (void)cleanupReportedPerformanceData {
    NSTimeInterval remainDays = self.heimdallr.config.cleanupConfig.maxRemainDays;
    NSTimeInterval ancientTime = [[NSDate date] timeIntervalSince1970] - (remainDays * (24 * 60 * 60));

    HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
    condition.judgeType = HMDConditionJudgeLess;
    condition.key = @"finishTimestamp";
    condition.threshold = (ancientTime * 1000);
    NSArray *traceConditions = @[condition];
    NSArray *traces = [self.heimdallr.database getObjectsWithTableName:[HMDOTTrace tableName] class:[HMDOTTrace class] andConditions:traceConditions orConditions:nil];

    NSMutableArray *spanConditions = [NSMutableArray array];
    for(HMDOTTrace *trace in traces) {
        HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
        condition.judgeType = HMDConditionJudgeEqual;
        condition.key = @"traceID";
        condition.stringValue = trace.traceID;
        [spanConditions addObject:condition];
    }

    dispatch_async(self.spanIOQueue, ^{
        [self.heimdallr.database inTransaction:^BOOL{
            BOOL deleteTraceSuccess = [self.heimdallr.database deleteObjectsFromTable:[HMDOTTrace tableName] andConditions:traceConditions orConditions:nil];
            BOOL deleteSpanSuccess = [self.heimdallr.database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:nil orConditions:spanConditions];
            return deleteTraceSuccess && deleteSpanSuccess;
        }];
    });
}

- (NSUInteger)properLimitCount {
    return 10;
}

- (NSArray *)debugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    if (![config checkIfAllowedDebugRealUploadWithType:kEnablePerformanceMonitor] &&
        ![config checkIfAllowedDebugRealUploadWithType:[self moduleName]]) {
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
    
    config.andConditions = debugRealConditions;
    
    NSArray *traces = [self.heimdallr.database getObjectsWithTableName:[HMDOTTrace tableName] class:[HMDOTTrace class] andConditions:debugRealConditions orConditions:nil limit:config.limitCnt];
    NSMutableArray *results = [NSMutableArray array];
    NSMutableArray *orConditions = [NSMutableArray array];
        
    for(HMDOTTrace *trace in traces) {
        //如果本次启动的trace还没有完成，不要上报，因为要保证一次trace内所有span上报的完整性
        if(trace.sessionID == [HMDSessionTracker sharedInstance].eternalSessionID && !trace.isFinished) {
            continue;
        }
        
        NSDictionary *traceResult = [trace reportDictionary];
        if (traceResult) {
            [results addObject:traceResult];
        }
        
        HMDStoreCondition *condition = [[HMDStoreCondition alloc] init];
        condition.judgeType = HMDConditionJudgeEqual;
        condition.key = @"traceID";
        condition.stringValue = trace.traceID;
        
        [orConditions addObject:condition];
    }
    
    config.orConditions = [orConditions copy];
        
    NSArray<HMDOTSpan *> *records =
    [self.heimdallr.database getObjectsWithTableName:[[self storeClass] tableName] class:[self storeClass] andConditions:nil orConditions:orConditions];
    
    NSArray *spanResults = [[self storeClass] reportDataForRecords:records];
    if(spanResults.count > 0) {
        [results addObjectsFromArray:spanResults];
    }
    
    return [results copy];
}

- (void)cleanupPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    dispatch_async(self.spanIOQueue, ^{
        [self.heimdallr.database inTransaction:^BOOL{
            BOOL deleteTraceSuccess = [self.heimdallr.database deleteObjectsFromTable:[HMDOTTrace tableName] andConditions:config.andConditions orConditions:nil];
            BOOL deleteSpanSuccess = [self.heimdallr.database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:nil orConditions:config.orConditions];
            
            return deleteTraceSuccess && deleteSpanSuccess;
        }];
    });
}

@end
