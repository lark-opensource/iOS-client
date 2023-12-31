//
//  HMDMonitor+SizeLimitedReport.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/11.
//

#import "HMDMonitor+SizeLimitedReport.h"
#import "Heimdallr+Private.h"
#import "HMDStoreIMP.h"
#import "HMDALogProtocol.h"
#import "NSArray+HMDJSON.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

@implementation HMDMonitor (SizeLimitedReport)

@dynamic reportingRequest;

- (NSArray *)performanceDataWithLimitSize:(NSUInteger)limitSize
                               limitCount:(NSInteger)limitCount
                              currentSize:(NSUInteger *)currentSize {
    
    if (hermas_enabled()) {
        return nil;
    }
    
    self.reportingRequest = [[HMDPerformanceReportRequest alloc] init];
    self.reportingRequest.limitCount = limitCount;

    NSArray *records = [self fetchUploadRecords];

    NSMutableArray *reportedRecords = [NSMutableArray array];
    NSUInteger dataSize = 0;
    for (HMDMonitorRecord *record in records) {
        [reportedRecords addObject:record];
        @autoreleasepool {
            NSArray *result = [(id)[self storeClass] aggregateDataWithRecords:reportedRecords];
            NSData *data = [result hmd_jsonData];
            dataSize = data.length;
        }
        if (dataSize > limitSize) {
            break;
        }
    }
    *currentSize = (*currentSize) + dataSize;

    if (reportedRecords.count == 0) {
        return nil;
    }

    self.reportingRequest.uploadingRange = [HMDRecordStore localIDRange:reportedRecords];
    NSArray *reportArray = [(id)[self storeClass] aggregateDataWithRecords:reportedRecords];
    return [reportArray copy];
}

- (void)performanceSizeLimitedDataDidReportSuccess:(BOOL)isSuccess {
    // hijack
    if (hermas_enabled()) {
        return;
    }
    
    if (isSuccess) {
        [self.heimdallr.store cleanupRecordsWithRange:self.reportingRequest.uploadingRange andConditions:self.reportingRequest.dataAndConditions storeClass:[self storeClass]];
    }
}

@end
