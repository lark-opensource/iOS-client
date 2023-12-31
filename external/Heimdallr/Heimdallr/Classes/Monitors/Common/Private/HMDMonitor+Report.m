//
//  HMDMonitor+Report.m
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/23.
//

#import "HMDMonitor+Report.h"
#import "HMDDebugRealConfig.h"
#import "Heimdallr+Private.h"
#import "HMDReportLimitSizeTool.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "NSArray+HMDJSON.h"
#import <objc/runtime.h>
#import "HMDStoreMemoryDB.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP


@implementation HMDMonitor (Report)

@dynamic reportingRequest;

- (NSArray *)getDataWithRecords:(NSArray<HMDMonitorRecord *> *)records {
    NSMutableArray *dataArray = [NSMutableArray array];
    
    for (HMDMonitorRecord *record in records) {
        NSDictionary *dataValue = [record reportDictionary];
        if (dataValue) {
            [dataArray addObject:dataValue];
        }
    }
    
    return [dataArray copy];
}

- (void)setCustomReportIMP:(NSNumber *)customeReportIMP {
    objc_setAssociatedObject(self, @selector(customReportIMP), customeReportIMP, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSNumber *)customReportIMP {
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark - DataReporterDelegate
- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    if (hermas_enabled()) {
        return nil;
    }
    
    if (self.customReportIMP.boolValue) {
        return [self hmdCutomPerformanceDataWithCountLimit:limitCount];
    }
    self.reportingRequest = [[HMDPerformanceReportRequest alloc] init];
    self.reportingRequest.limitCount = limitCount;
    
    NSArray<HMDMonitorRecord *> *records = [self fetchUploadRecords];
    
    NSArray *result = [(id)[self storeClass] aggregateDataWithRecords:records];

    return [result copy];
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
    
    NSArray<HMDMonitorRecord *> *records = [[Heimdallr shared].database getObjectsWithTableName:[[self storeClass] tableName]
                                                                                          class:[self storeClass]
                                                                                  andConditions:debugRealConditions
                                                                                   orConditions:nil
                                                                                          limit:config.limitCnt];
    
    NSArray *result = [self getDataWithRecords:records];
    
    return [result copy];
}

- (void)performanceDataDidReportSuccess:(BOOL)isSuccess
{
    if (hermas_enabled()) {
        return;
    }
    
    // clean data from memory database
    if (isSuccess && self.reportingRequest.limitCountFromMemory) {
        [self.heimdallr.store.memoryDB deleteObjectsFromTable:[[self storeClass] tableName] appID:self.heimdallr.userInfo.appID count:self.reportingRequest.limitCountFromMemory];
    }
    if (self.customReportIMP.boolValue) {
         [self hmdCutomPerformanceDataReportSuccess:isSuccess];
        return;
    }
    if (isSuccess) {
        // 性能数据上传完成之后 删除
        [self.heimdallr.database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:self.reportingRequest.dataAndConditions
                                           orConditions:nil
                                                  limit:self.reportingRequest.limitCount];
        self.reportingRequest.dataAndConditions = nil;
    }
}

- (void)cleanupPerformanceDataWithConfig:(HMDDebugRealConfig *)config
{
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
    
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:debugRealConditions
                                           orConditions:nil
                                                  limit:config.limitCnt];
}

- (void)cleanupNotUploadAndReportedPerformanceData {
    if (hermas_enabled()) {
        return;
    }
    
    HMDStoreCondition *cleanCondition = [[HMDStoreCondition alloc] init];
    cleanCondition.key = @"isReported";
    cleanCondition.threshold = 1;
    cleanCondition.judgeType = HMDConditionJudgeEqual;

    NSArray<HMDStoreCondition *> *cleanConditions = @[cleanCondition];
    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:cleanConditions orConditions:nil];

    [self cleanupUnusedPerformanfeData];
}

- (void)cleanupUnusedPerformanfeData {
    if (hermas_enabled()) {
        return;
    }
    
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"enableUpload";
    condition1.threshold = 1;
    condition1.judgeType = HMDConditionJudgeLess;

    NSArray *apiAllCondition = @[condition1];

    [[Heimdallr shared].database deleteObjectsFromTable:[[self storeClass] tableName] andConditions:apiAllCondition orConditions:nil];
}

#pragma - mark drop data

- (void)setDropData:(BOOL)dropData {
    if (self.curve) {
        [self.curve dropDataForServerState:dropData];
    }
}

- (void)dropAllDataForServerState {
    if (self.curve) {
        [self.curve dropAllDataForServerState];
    }
}

#pragma mark - custome report
- (NSArray *)hmdCutomPerformanceDataWithCountLimit:(NSInteger)limitCount {
    return nil;
}

- (void)hmdCutomPerformanceDataReportSuccess:(BOOL)isSuccess {

}

@end
