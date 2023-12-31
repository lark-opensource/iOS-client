//
//  HMDControllerTimeManager+SizeLimitedReport.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDControllerTimeManager+SizeLimitedReport.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "NSArray+HMDJSON.h"
#import "HMDControllerTimeManager+Report.h"

@implementation HMDControllerTimeManager (SizeLimitedReport)
@dynamic uploadingRange;
@dynamic hmdCountLimit;
@dynamic andConditions;


- (NSArray *)performanceDataWithLimitSize:(NSUInteger)limitSize
                               limitCount:(NSInteger)limitCount
                              currentSize:(NSUInteger *)currentSize {

    self.hmdCountLimit = limitCount;
    NSArray<HMDControllerTimeRecord *> *records = [self fetchUploadRecords];

    NSMutableArray<HMDControllerTimeRecord *> *uploadRecords = [NSMutableArray array];

    NSUInteger dataSize = 0;
    for (HMDControllerTimeRecord *record in records) {
       [uploadRecords addObject:record];
       @autoreleasepool {
         NSArray *result = [self getAggregateDataWithRecords:records];
         NSData *data = [result hmd_jsonData];
         dataSize = data.length;
       }
       if (dataSize > limitSize) {
           break;
       }
    }
    *currentSize = (*currentSize) + dataSize;

    if (!uploadRecords || uploadRecords.count == 0) { return nil;}
    self.uploadingRange = [HMDRecordStore localIDRange:uploadRecords];
    NSArray *reportResult = [self getAggregateDataWithRecords:records];
    return [reportResult copy];
}

- (void)performanceSizeLimitedDataDidReportSuccess:(BOOL)isSuccess {
    if (isSuccess) {
        [self.heimdallr.store cleanupRecordsWithRange:self.uploadingRange andConditions:self.andConditions storeClass:[self storeClass]];
    }
}

@end
