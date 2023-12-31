//
//  HMDLaunchAnalysisConfig.m
//  Heimdallr
//
//  Created by zhangxiao on 2021/5/27.
//

#import "HMDLaunchTimingConfig.h"
#import "HMDLaunchTiming.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleLaunchAnalysis = @"launch_timing";

HMD_MODULE_CONFIG(HMDLaunchTimingConfig)

@implementation HMDLaunchTimingConfig

+ (NSDictionary *)hmd_attributeMapDictionary
{
    return @{
             @"enableCollectPerf":@"enable_collect_perf",
             @"enableCollectNet":@"enable_collect_net"
             };
}

+ (NSString *)configKey
{
    return kHMDModuleLaunchAnalysis;
}

- (id<HeimdallrModule>)getModule
{
    return [HMDLaunchTiming shared];
}

@end
