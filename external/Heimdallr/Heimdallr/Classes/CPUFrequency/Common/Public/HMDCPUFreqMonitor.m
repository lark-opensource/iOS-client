//
//  HMDCPUFreqMonitor.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2021/8/3.
//

#import "HMDCPUFreqMonitor.h"
#include "HMDCPUFreqTool.h"
#import "NSDictionary+HMDSafe.h"
#import "Heimdallr+Private.h"
#import "HMDHeimdallrConfig.h"

#pragma mark
#pragma mark --- HMDCPUFreqInfo
@implementation HMDCPUFreqInfo

@end

#pragma mark
#pragma mark --- HMDCPUFreqMonitor

@interface HMDCPUFreqMonitor ()

@end

@implementation HMDCPUFreqMonitor

#pragma mark --- public method
+ (HMDCPUFreqInfo *)getCurrentCPUFrequency {
    NSTimeInterval start = NSProcessInfo.processInfo.systemUptime;
    NSInteger standardFreq = 0;
    HMDHeimdallrConfig *config = [Heimdallr shared].config;
    if ([config.commonInfo isKindOfClass:[NSDictionary class]]) {
        standardFreq = [config.commonInfo hmd_integerForKey:@"cpu_freq"] * 1000 * 1000; // config return MHZ  need * 10^6
    }

    HMDCPUFreqInfo *cpuFreq = [[HMDCPUFreqInfo alloc] init];
    cpuFreq.cpuFreqCurrent = hmd_cpu_frequency();
    cpuFreq.cpuFreqStandard = standardFreq;
    if (standardFreq > 0) {
        cpuFreq.cpuFreqScale = ((float)cpuFreq.cpuFreqCurrent) / ((float)standardFreq);
    }
    NSTimeInterval end = NSProcessInfo.processInfo.systemUptime;
    cpuFreq.timeUsage = (end - start) * 1000;
    return cpuFreq;
}


@end
