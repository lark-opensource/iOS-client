//
//  HMDLaunchTiming+Report.h
//  Heimdallr
//
//  Created by zhangxiao on 2021/7/20.
//

#import "HMDLaunchTiming.h"

@class HMDPerformanceReportRequest;

NS_ASSUME_NONNULL_BEGIN

@interface HMDLaunchTiming (Report)

@property (nonatomic, strong, nullable) HMDPerformanceReportRequest *reportingRequest;

@end

NS_ASSUME_NONNULL_END
