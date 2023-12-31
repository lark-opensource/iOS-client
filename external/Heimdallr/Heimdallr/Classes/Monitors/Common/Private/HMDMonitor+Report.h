//
//  HMDMonitor+Report.h
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/23.
//

#import "HMDMonitor.h"
#import "HMDPerformanceReportRequest.h"

@interface HMDMonitor (Report)

@property (nonatomic, strong)HMDPerformanceReportRequest *reportingRequest;
@property (nonatomic, strong) NSNumber *customReportIMP;

- (NSArray *)hmdCutomPerformanceDataWithCountLimit:(NSInteger)limitCount;
- (void)hmdCutomPerformanceDataReportSuccess:(BOOL)isSuccess;

@end
