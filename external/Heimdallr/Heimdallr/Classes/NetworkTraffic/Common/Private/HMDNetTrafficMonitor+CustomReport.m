//
//  HMDNetTrafficMonitor+Report.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/9/2.
//

#import "HMDNetTrafficMonitor+CustomReport.h"
#import "Heimdallr+Private.h"
#import "HMDMonitor+Report.h"
#import "HMDNetTrafficMonitorRecord+Report.h"
#import <objc/runtime.h>

@interface HMDNetTrafficMonitor ()

@property (nonatomic, copy) NSArray *exceptionConditions;

@end

@implementation HMDNetTrafficMonitor (CustomReport)

- (void)setExceptionConditions:(NSArray *)exceptionConditions {
    objc_setAssociatedObject(self, @selector(exceptionConditions), exceptionConditions, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

}

- (NSArray *)exceptionConditions {
    return objc_getAssociatedObject(self, _cmd);
}

#pragma mark --- report
- (NSArray *)hmdCutomPerformanceDataWithCountLimit:(NSInteger)limitCount {
    self.reportingRequest.limitCount = limitCount;
    NSMutableArray *uploadData = [NSMutableArray array];
    NSTimeInterval currentTS = [[NSDate date] timeIntervalSince1970];
    // 指标数据
    self.reportingRequest = [[HMDPerformanceReportRequest alloc] init];
    self.reportingRequest.limitCount = limitCount;

    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"enableUpload";
    condition1.threshold = 0;
    condition1.judgeType = HMDConditionJudgeGreater;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = currentTS;
    condition2.judgeType = HMDConditionJudgeLess;

    HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
    condition3.key = @"isReported";
    condition3.threshold = 0;
    condition3.judgeType = HMDConditionJudgeEqual;

    self.reportingRequest.dataAndConditions = @[condition1, condition2, condition3];

    NSArray<HMDMonitorRecord *> *records = [self.heimdallr.database getObjectsWithTableName:[[self storeClass] tableName]
                                                                                      class:[self storeClass]
                                                                              andConditions:self.reportingRequest.dataAndConditions
                                                                               orConditions:nil
                                                                                      limit:self.reportingRequest.limitCount];

    NSArray *result = [(id)[self storeClass] aggregateDataWithRecords:records];
    if (result) {
        [uploadData addObjectsFromArray:result];
    }
    // 异常数据
    if ([self.config isKindOfClass:[HMDNetTrafficMonitorConfig class]] &&
        [(HMDNetTrafficMonitorConfig *)self.config enableExceptionDetailUpload] ) {
        self.reportingRequest = [[HMDPerformanceReportRequest alloc] init];
        self.reportingRequest.limitCount = limitCount;

        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"timestamp";
        condition1.threshold = currentTS;
        condition1.judgeType = HMDConditionJudgeLess;

        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"isExceptionTraffic";
        condition2.threshold = 1;
        condition2.judgeType = HMDConditionJudgeEqual;

        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"isReported";
        condition3.threshold = 0;
        condition3.judgeType = HMDConditionJudgeEqual;

        self.exceptionConditions = @[condition1, condition2, condition3];

        NSArray<HMDNetTrafficMonitorRecord *> *records = [self.heimdallr.database getObjectsWithTableName:[[self storeClass] tableName]
                                                                                         class:[self storeClass]
                                                                                 andConditions:self.exceptionConditions
                                                                                  orConditions:nil
                                                                                         limit:self.reportingRequest.limitCount];
        NSArray *result = [HMDNetTrafficMonitorRecord aggregateExceptionTrafficDataWithRecords:records];
        if (result && result.count > 0) {
            [uploadData addObjectsFromArray:result];
        }
    }

    return uploadData;
}

- (void)hmdCutomPerformanceDataReportSuccess:(BOOL)isSuccess {
    if (isSuccess) {
        // 性能数据上传完成之后 删除
        [self.heimdallr.database deleteObjectsFromTable:[[self storeClass] tableName]
                                          andConditions:self.reportingRequest.dataAndConditions
                                           orConditions:nil
                                                  limit:self.reportingRequest.limitCount];
        self.reportingRequest.dataAndConditions = nil;
        if (self.exceptionConditions) {
            [self.heimdallr.database deleteObjectsFromTable:[[self storeClass] tableName]
                                              andConditions:self.exceptionConditions
                                               orConditions:nil
                                                      limit:self.reportingRequest.limitCount];
            self.reportingRequest.dataAndConditions = nil;
        }
    }
}


@end
