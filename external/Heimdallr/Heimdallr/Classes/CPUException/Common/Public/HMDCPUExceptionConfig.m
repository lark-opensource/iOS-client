//
//  HMDCPUExceptionConfig.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2020/4/23.
//

#import "HMDCPUExceptionConfig.h"
#import "HMDCPUExceptionMonitor.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"
#import "HMDModuleConfig+StartWeight.h"

NSString *const kHMDModuleCPUExceptionMonitor = @"cpu_exception"; // CPU异常监控

HMD_MODULE_CONFIG(HMDCPUExceptionConfig)


@implementation HMDCPUExceptionConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(cpuThreshold, cpu_threshold, @(0.8), @(0.8))
        HMD_ATTR_MAP_DEFAULT(threadUsageThreshold, thread_usage_threshold, @(0.05), @(0.05))
        HMD_ATTR_MAP_DEFAULT(sampleInterval, sample_interval, @(1), @(1))
        HMD_ATTR_MAP_DEFAULT(ignoreDuplicate, ignore_duplicate, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(threadSuspend, thread_suspend, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(maxTreeDepth, max_tree_depth, @(50), @(50))
        HMD_ATTR_MAP_DEFAULT(enableThermalMonitor, enable_thermal_monitor, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enablePerformaceCollect, enable_performace_collect, @(YES), @(YES))
        HMD_ATTR_MAP_DEFAULT(characterScale, character_scale, @(0.5), @(0.5))
        HMD_ATTR_MAP_DEFAULT(powerConsumptionThreshold, power_consumption_threshold, @(90), @(90))
    };
}

+ (NSString *)configKey {
    return kHMDModuleCPUExceptionMonitor;
}

- (id<HeimdallrModule>)getModule {
    return [HMDCPUExceptionMonitor sharedMonitor];
}

- (BOOL)canStart {
    //由于性能问题，开启和上传绑定到一起
    return self.enableOpen;
}

- (HMDModuleStartWeight)startWeight {
    return HMDDefaultModuleStartWeight;
}

@end
