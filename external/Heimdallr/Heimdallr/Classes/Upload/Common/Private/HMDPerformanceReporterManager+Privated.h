//
//  HMDPerformanceReporterManager+Privated.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDPerformanceReporterManager.h"

@interface HMDPerformanceReporterManager (Privated)

- (void)reportPerformanceDataAsyncWithSizeLimitedReporter:(HMDPerformanceReporter *_Nonnull)reporter
                                                    block:(PerformanceReporterBlock _Nullable)block;

@end
