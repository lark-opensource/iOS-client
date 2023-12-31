//
//  HMDUITrackerManager+SizeLimitedReport.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDUITrackerManager+SizeLimitedReport.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "NSArray+HMDJSON.h"

static NSString *HMDUITrackerManagerSetterGetterKey = @"nameWithSetterGetterKey";

@implementation HMDUITrackerManager (SizeLimitedReport)

@dynamic uploadingRange;
@dynamic andConditions;
@dynamic hmdCountLimit;

- (NSArray *)performanceDataWithLimitSize:(NSUInteger)limitSize
                               limitCount:(NSInteger)limitCount
                              currentSize:(NSUInteger *)currentSize {
    self.hmdCountLimit = limitCount ?: 0;
    NSArray<HMDUITrackRecord *> *records  = [self fetchUploadRecords];

    if (records.count < self.uploadCount) { return nil; }
    NSMutableArray<HMDUITrackRecord *> *uploadRecords = [NSMutableArray array];
    NSUInteger dataSize = 0;
    for (HMDUITrackRecord *record in records) {
       [uploadRecords addObject:record];
       @autoreleasepool {
           NSArray *result = [self getUITrackerDataWithRecords:uploadRecords];
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
    NSArray *reportResult = [self getUITrackerDataWithRecords:uploadRecords];
    return  [reportResult copy];
}


- (void)performanceSizeLimitedDataDidReportSuccess:(BOOL)isSuccess {
    if (isSuccess) {
        [self.heimdallr.store cleanupRecordsWithRange:self.uploadingRange andConditions:self.andConditions storeClass:[self storeClass]];
    }
}

@end
