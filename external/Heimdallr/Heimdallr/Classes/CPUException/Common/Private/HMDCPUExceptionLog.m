//
//  HMDCPUExceptionLog.m
//  Heimdallr
//
//  Created by zhangxiao on 2020/10/15.
//

#import "HMDCPUExceptionLog.h"
#import "HMDTTMonitor.h"

@implementation HMDCPUExceptionLog

+ (void)hmd_CPUExceptionRecordTimeUsageWithTime:(long long)timeUsage eventName:(NSString *)eventName category:(NSDictionary *)catory {
    NSDictionary *timeUsageInfo = @{
        @"duration": @(timeUsage)
    };
    [[HMDTTMonitor defaultManager] hmdTrackService:eventName?:@"hmd_cpu_exception"
                                            metric:timeUsageInfo
                                          category:catory
                                             extra:nil];
}


@end
