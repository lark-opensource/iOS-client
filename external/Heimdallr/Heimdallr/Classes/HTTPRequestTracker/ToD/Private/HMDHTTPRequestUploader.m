//
//  HMDHTTPRequestUploader.m
//  Heimdallr
//
//  Created by fengyadong on 2018/11/19.
//

#import "HMDHTTPRequestUploader.h"
#import "HMDStoreCondition.h"
#import "HMDHTTPDetailRecord.h"
#import "HMDDebugRealConfig.h"
#import "Heimdallr.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "NSArray+HMDJSON.h"
#import "HMDRecordStore+DeleteRecord.h"

@interface HMDHTTPRequestUploader()<HMDPerformanceReporterDataSource>

@property (nonatomic, copy) NSString *logType;
@property (nonatomic, assign) Class <HMDRecordStoreObject>recordClass;
@property (nonatomic, copy) NSArray<HMDStoreCondition *> *conditions;
@property (nonatomic, assign) HMDRecordLocalIDRange uploadingRange;
@property (nonatomic, assign) NSUInteger queryLimitCnt;
@property (nonatomic, copy) NSString *sdkAid;
@property (nonatomic, assign) NSTimeInterval sdkStartUploadTime;

@end

@implementation HMDHTTPRequestUploader

- (instancetype)initWithlogType:(NSString *)logType
                    recordClass:(Class <HMDRecordStoreObject>)recordClass
{
    if (self = [super init]) {
        self.logType = logType;
        self.recordClass = recordClass;
    }
    
    return self;
}

- (instancetype)initWithlogType:(NSString *)logType
                    recordClass:(Class<HMDRecordStoreObject>)recordClass
                         sdkAid:(NSString *)sdkAid
             sdkStartUploadTime:(NSTimeInterval)startTime {
    self = [self initWithlogType:logType recordClass:recordClass];
    if (self) {
        self.sdkAid = sdkAid;
        self.sdkStartUploadTime = startTime;
    }
    return self;
}

#pragma mark - upload

- (NSUInteger)properLimitCount {
    return 50;
}

- (CGFloat)properLimitSizeWeight {
    return 0.5;
}

- (NSArray *)debugRealPerformanceDataWithConfig:(HMDDebugRealConfig *)config {
    if (![config checkIfAllowedDebugRealUploadWithType:self.logType] && ![config checkIfAllowedDebugRealUploadWithType:kEnablePerformanceMonitor]) {
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
    
    HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
    condition3.key = @"logType";
    condition3.stringValue = self.logType;
    condition3.judgeType = HMDConditionJudgeEqual;
    
    NSArray<HMDStoreCondition *> *debugRealAndConditions = @[condition1,condition2,condition3];
    
    NSArray<HMDHTTPDetailRecord *> *recordsAll = [[Heimdallr shared].database getObjectsWithTableName:[self.recordClass tableName] class:self.recordClass andConditions:debugRealAndConditions orConditions:nil limit:config.limitCnt];
    
    NSArray *results = [self.recordClass reportDataForRecords:recordsAll];
    return results;
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
    
    HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
    condition3.key = @"logType";
    condition3.stringValue = self.logType;
    condition3.judgeType = HMDConditionJudgeEqual;
    
    NSArray<HMDStoreCondition *> *debugRealAndConditions = @[condition1,condition2,condition3];
    
    [[Heimdallr shared].database deleteObjectsFromTable:[self.recordClass tableName] andConditions:debugRealAndConditions orConditions:nil limit:config.limitCnt];
}

#pragma mark - DataReporterDelegate
- (NSArray *)performanceDataWithCountLimit:(NSInteger)limitCount {
    self.queryLimitCnt = limitCount ?: 0;
    NSTimeInterval ignoreTime = [[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval];
    
    NSArray<NSDictionary *> *results = nil;

    if ([self.logType isEqualToString:@"image_monitor"]) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"enableUpload";
        condition1.threshold = 0;
        condition1.judgeType = HMDConditionJudgeGreater;
        
        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"timestamp";
        condition2.threshold = [[NSDate date] timeIntervalSince1970];
        condition2.judgeType = HMDConditionJudgeLess;
        
        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"isReported";
        condition3.threshold = 0;
        condition3.judgeType = HMDConditionJudgeEqual;
        
        HMDStoreCondition *condition4 = [[HMDStoreCondition alloc] init];
        condition4.key = @"logType";
        condition4.stringValue = self.logType;
        condition4.judgeType = HMDConditionJudgeEqual;
        
        HMDStoreCondition *condition5 = [[HMDStoreCondition alloc] init];
        condition5.key = @"timestamp";
        condition5.threshold = ignoreTime;
        condition5.judgeType = HMDConditionJudgeGreater;
        
        self.conditions = @[condition1,condition2,condition3,condition4,condition5];
        NSArray<id<HMDRecordStoreObject>> *records = [[Heimdallr shared].database getObjectsWithTableName:[self.recordClass tableName] class:self.recordClass andConditions:self.conditions orConditions:nil limit:self.queryLimitCnt];
        
        if(records.count == 0) return nil;
        
        results = [self.recordClass aggregateDataForRecords:records];
    } else if ([self.logType isEqualToString:@"sdk_api_upload"] && self.sdkAid && self.sdkAid.length > 0) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"timestamp";
        NSTimeInterval uploadStartTime = 0;
        if (self.sdkStartUploadTime > 0) {
            uploadStartTime = self.sdkStartUploadTime;
        }
        condition1.threshold = MAX((uploadStartTime), (ignoreTime));
        condition1.judgeType = HMDConditionJudgeGreater;

        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"timestamp";
        condition2.threshold = [[NSDate date] timeIntervalSince1970];
        condition2.judgeType = HMDConditionJudgeLess;

        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"sdkAid";
        condition3.stringValue = self.sdkAid;
        condition3.judgeType = HMDConditionJudgeEqual;

        HMDStoreCondition *condition4 = [[HMDStoreCondition alloc] init];
        condition4.key = @"isReported";
        condition4.threshold = 0;
        condition4.judgeType = HMDConditionJudgeEqual;

        self.conditions = @[condition1,condition2, condition3, condition4];
        NSArray *records = [[Heimdallr shared].database getObjectsWithTableName:[self.recordClass tableName] class:self.recordClass andConditions:self.conditions orConditions:nil limit:self.queryLimitCnt];

        if(records == nil) return nil;

        results = [self.recordClass reportDataForRecords:records];

    } else{
        // api_all 和 api_error
        NSArray *records = [self fetchUploadRecords];
        if(records.count == 0) return nil;
        
        results = [self.recordClass reportDataForRecords:records];
    }
    return [results copy];
}

- (NSArray *)performanceDataWithLimitSize:(NSUInteger)limitSize
                               limitCount:(NSInteger)limitCount
                              currentSize:(NSUInteger *)currentSize {
    self.queryLimitCnt = limitCount ?: 0;
    NSArray<NSDictionary *> *results = nil;
    NSTimeInterval ignoreTime = [[HMDInjectedInfo defaultInfo] getIgnorePerformanceDataTimeInterval];
    NSArray *records = nil;
    if ([self.logType isEqualToString:@"image_monitor"]) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"enableUpload";
        condition1.threshold = 0;
        condition1.judgeType = HMDConditionJudgeGreater;

        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"timestamp";
        condition2.threshold = [[NSDate date] timeIntervalSince1970];
        condition2.judgeType = HMDConditionJudgeLess;

        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"isReported";
        condition3.threshold = 0;
        condition3.judgeType = HMDConditionJudgeEqual;

        HMDStoreCondition *condition4 = [[HMDStoreCondition alloc] init];
        condition4.key = @"logType";
        condition4.stringValue = self.logType;
        condition4.judgeType = HMDConditionJudgeEqual;
        
        HMDStoreCondition *condition5 = [[HMDStoreCondition alloc] init];
        condition5.key = @"timestamp";
        condition5.threshold = ignoreTime;
        condition5.judgeType = HMDConditionJudgeGreater;

        self.conditions = @[condition1,condition2,condition3,condition4,condition5];
        records = [[Heimdallr shared].database getObjectsWithTableName:[self.recordClass tableName] class:self.recordClass andConditions:self.conditions orConditions:nil limit:self.queryLimitCnt];

        if(records.count == 0) return nil;
    } else if ([self.logType isEqualToString:@"sdk_api_upload"] && self.sdkAid && self.sdkAid.length > 0) {
        HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
        condition1.key = @"timestamp";
        NSTimeInterval uploadStartTime = 0;
        if (self.sdkStartUploadTime > 0) {
            uploadStartTime = self.sdkStartUploadTime;
        }
        condition1.threshold = MAX((uploadStartTime), (ignoreTime));
        condition1.judgeType = HMDConditionJudgeGreater;

        HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
        condition2.key = @"timestamp";
        condition2.threshold = [[NSDate date] timeIntervalSince1970];
        condition2.judgeType = HMDConditionJudgeLess;

        HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
        condition3.key = @"sdkAid";
        condition3.stringValue = self.sdkAid;
        condition3.judgeType = HMDConditionJudgeEqual;

        HMDStoreCondition *condition4 = [[HMDStoreCondition alloc] init];
        condition4.key = @"isReported";
        condition4.threshold = 0;
        condition4.judgeType = HMDConditionJudgeEqual;
        
        HMDStoreCondition *condition5 = [[HMDStoreCondition alloc] init];
        condition5.key = @"timestamp";
        condition5.threshold = ignoreTime;
        condition5.judgeType = HMDConditionJudgeGreater;

        self.conditions = @[condition1,condition2, condition3, condition4,condition5];
        records = [[Heimdallr shared].database getObjectsWithTableName:[self.recordClass tableName] class:self.recordClass andConditions:self.conditions orConditions:nil limit:self.queryLimitCnt];

        if(records == nil) return nil;

    } else{
        records = [self fetchUploadRecords];
        if(records.count == 0) return nil;
    }

    NSMutableArray *reportedRecords = [NSMutableArray array];
    NSUInteger dataSize = 0;
    for (id<HMDRecordStoreObject> record in records) {
        [reportedRecords addObject:record];
        @autoreleasepool {
            NSArray *testResult = nil;
            if ([self.logType isEqualToString:@"image_monitor"]) {
                testResult = [self.recordClass aggregateDataForRecords:reportedRecords];
            } else {
                testResult = [self.recordClass reportDataForRecords:reportedRecords];;
            }
            NSData *data = [testResult hmd_jsonData];
            dataSize = data.length;
        }
        if (dataSize > limitSize) {
            break;
        }
    }
    *currentSize = (*currentSize) + dataSize;
    if (reportedRecords.count == 0) { return nil; }
    
    self.uploadingRange = [HMDRecordStore localIDRange:reportedRecords];

    if ([self.logType isEqualToString:@"image_monitor"]) {
        results = [self.recordClass aggregateDataForRecords:reportedRecords];
    } else {
        results = [self.recordClass reportDataForRecords:reportedRecords];;
    }
    return [results copy];
}

- (NSArray *)fetchUploadRecords {
    HMDStoreCondition *condition1 = [[HMDStoreCondition alloc] init];
    condition1.key = @"timestamp";
    condition1.threshold = [[NSDate date] timeIntervalSince1970];
    condition1.judgeType = HMDConditionJudgeLess;

    HMDStoreCondition *condition2 = [[HMDStoreCondition alloc] init];
    condition2.key = @"logType";
    condition2.stringValue = self.logType;
    condition2.judgeType = HMDConditionJudgeEqual;

    HMDStoreCondition *condition3 = [[HMDStoreCondition alloc] init];
    condition3.key = @"enableUpload";
    condition3.threshold = 0;
    condition3.judgeType = HMDConditionJudgeGreater;

    self.conditions = @[condition1,condition2,condition3];

    return [[Heimdallr shared].database getObjectsWithTableName:[self.recordClass tableName] class:self.recordClass andConditions:self.conditions orConditions:nil limit:self.queryLimitCnt];
}

- (void)performanceDataDidReportSuccess:(BOOL)isSuccess {
    if (isSuccess) {
        // 日志上传成功之后就删除, 现在 image_monitor 好像也没用了
        [[Heimdallr shared].database deleteObjectsFromTable:[self.recordClass tableName] andConditions:self.conditions orConditions:nil limit:self.queryLimitCnt];
    }
    else {
        //上报未成功，但是双发数据不需要重复发送，将 doubleUpload 属性设为 false,下次上报时不会双发
        [[Heimdallr shared].database inTransaction:^BOOL{
            BOOL result = [[Heimdallr shared].database updateRowsInTable:[self.recordClass tableName] onProperty:@"doubleUpload" propertyValue:@(0) withObject:self.recordClass andConditions:self.conditions orConditions:nil limit:self.queryLimitCnt];

            return result;
        }];
    }
}

- (void)performanceSizeLimitedDataDidReportSuccess:(BOOL)isSuccess {
    if (isSuccess) {

        // 日志上传成功之后就删除, 现在 image_monitor 好像也没用了
        [[Heimdallr shared].store cleanupRecordsWithRange:self.uploadingRange andConditions:self.conditions storeClass:self.recordClass];
    }
}

- (NSString *)description {
    return [NSString stringWithFormat:@"classname:%@,logType:%@",NSStringFromClass([self class]), self.logType];
}

#pragma mark --- drop data protocol
// empty method, the class don't need to conform drop data procotol
- (void)dropAllDataForServerState {

}

@end
