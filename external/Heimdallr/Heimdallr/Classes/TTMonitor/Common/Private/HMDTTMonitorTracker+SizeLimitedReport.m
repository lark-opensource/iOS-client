//
//  HMDTTMonitorTracker+SizeLimitedReport.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDTTMonitorTracker+SizeLimitedReport.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "NSArray+HMDJSON.h"
#import "HMDTTMonitorTracker+Privated.h"
#import "HMDMonitorDataManager.h"
#import "HMDStoreCondition.h"

@implementation HMDTTMonitorTracker (SizeLimitedReport)
@dynamic hmdCountLimit;
@dynamic normalCondition;
@dynamic uploadingRange;
@dynamic dataManager;

- (NSArray *)performanceDataWithLimitSize:(NSUInteger)limitSize
                               limitCount:(NSInteger)limitCount
                              currentSize:(NSUInteger *)currentSize {
    self.hmdCountLimit = limitCount ?: 0;
    NSTimeInterval ignoreTime = [[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval];

    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"needUpload";
    condition1.threshold = 1;
    condition1.judgeType = HMDConditionJudgeEqual;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"timestamp";
    condition2.threshold = [[NSDate date] timeIntervalSince1970];
    condition2.judgeType = HMDConditionJudgeLess;

    HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
    condition3.key = @"appID";
    condition3.stringValue = self.dataManager.appID;
    condition3.judgeType = HMDConditionJudgeEqual;

    NSArray<HMDStoreCondition *> *normalCondition = nil;
    if (ignoreTime) {
        HMDStoreCondition *condition4 = [[HMDStoreCondition alloc] init];
        condition4.key = @"timestamp";
        condition4.threshold = ignoreTime;
        condition4.judgeType = HMDConditionJudgeGreater;

        normalCondition = @[condition1,condition2,condition3,condition4];
    }
    else {
        normalCondition = @[condition1,condition2,condition3];
    }
    
    NSArray<HMDTTMonitorRecord *> *tmpRecords = [self.dataManager.store.database getObjectsWithTableName:[[self trackerStoreClass] tableName] class:[self trackerStoreClass] andConditions:normalCondition orConditions:nil limit:limitCount];
    if (!tmpRecords) { return nil; }

    NSMutableArray<HMDTTMonitorRecord *> *trackRecords = [NSMutableArray array];
    NSUInteger dataSize = 0;
    for (HMDTTMonitorRecord *record in tmpRecords) {
        [trackRecords addObject:record];
        @autoreleasepool {
            NSArray *trackResult = [self getTracksDataWithRecords:trackRecords];
            NSData *data = [trackResult hmd_jsonData];
            dataSize = data.length;
        }
        if (dataSize > limitSize) {
            break;
        }
    }
    *currentSize = (*currentSize) + dataSize;

    if (!trackRecords || trackRecords.count == 0) { return nil;}
    self.uploadingRange = [HMDRecordStore localIDRange:trackRecords];
    self.normalCondition = normalCondition;

    NSArray *trackResult = [self getTracksDataWithRecords:trackRecords];

    NSMutableArray *dataArray = [NSMutableArray array];

    if (trackResult) {
        [dataArray addObjectsFromArray:trackResult];
    }
    
    return [dataArray copy];
}

- (void)performanceSizeLimitedDataDidReportSuccess:(BOOL)isSuccess {
    if (isSuccess) {
        [self.dataManager.store cleanupRecordsWithRange:self.uploadingRange andConditions:self.normalCondition storeClass:[self trackerStoreClass]];
    }
}


@end
