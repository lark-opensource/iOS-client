//
//  HMDHTTPRequestTracker+SizeLimitedReport.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDHTTPRequestTracker+SizeLimitedReport.h"
#import "HMDPerformanceReporter.h"

@implementation HMDHTTPRequestTracker (SizeLimitedReport)

- (NSArray *)performanceDataWithLimitSize:(NSUInteger)limitSize
                               limitCount:(NSInteger)limitCount
                              currentSize:(NSUInteger *)currentSize {
    NSMutableArray *networkData = [NSMutableArray array];
    NSUInteger expectionSize = limitSize;
    NSUInteger networkSize = 0;
    for (id<HMDPerformanceReporterDataSource> uploader in self.uploaders) {
        if ([uploader respondsToSelector:@selector(performanceDataWithLimitSize:limitCount:currentSize:)] &&
         networkSize < expectionSize) {
            NSUInteger surplusSize = expectionSize - networkSize;
            NSArray *networkRes = [uploader performanceDataWithLimitSize:surplusSize limitCount:limitCount currentSize:&networkSize];
            if (networkRes) {
                [networkData addObjectsFromArray:networkRes];
            }
        }
    }
    *currentSize = (*currentSize) + networkSize;
    return networkData;
}

@end
