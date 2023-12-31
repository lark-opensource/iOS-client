//
//  HMDPerformanceReporter+SizeLimitedReport.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDPerformanceReporter.h"

@interface HMDPerformanceReporter (SizeLimitedReport)

@property (nonatomic, strong) NSTimer *sizeLimitedReportTimer;
@property (atomic, assign) NSTimeInterval sizeLimitAvailableTime;

- (void)startSizeLimitedReportTimer;
- (void)stopSizeLimitedReportTimer;
- (void)reportPerformanceDataAsyncWithSizeLimited;
- (NSArray *)_dataArrayForSizeLimitedReportWithAddedMoudle:(NSMutableArray *)addedModules modules:(NSArray *)modules;
- (void)_sizeLimitedTimeAvaliableWithBody:(NSDictionary *)body;

@end
