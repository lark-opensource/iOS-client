//
//  HMDMonitor+SizeLimitedReport.h
//  Heimdallr
//
//  Created by zhangxiao on 2020/3/12.
//

#import "HMDMonitor.h"
#import "HMDPerformanceReportRequest.h"


NS_ASSUME_NONNULL_BEGIN

@interface HMDMonitor (SizeLimitedReport)

@property (nonatomic, strong)HMDPerformanceReportRequest *reportingRequest;

@end

NS_ASSUME_NONNULL_END
