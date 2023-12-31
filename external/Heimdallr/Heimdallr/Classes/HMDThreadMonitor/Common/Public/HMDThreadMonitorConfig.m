//
//  HMDThreadMonitorConfig.m
//  AWECloudCommand
//
//  Created by zhangxiao on 2021/9/8.
//

#import "HMDThreadMonitorConfig.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

HMD_MODULE_CONFIG(HMDThreadMonitorConfig)

NSString *const kHMDModuleThreadMonitor = @"thread";

@implementation HMDThreadMonitorConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(enableThreadCount, enable_thread_count, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(threadCountThreshold, thread_count_threshold, @(200), @(200))
        HMD_ATTR_MAP_DEFAULT(enableSpecialThreadCount, enable_special_thread_count, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(specialThreadThreshold, special_thread_count_threshold, @(50), @(50))
        HMD_ATTR_MAP_DEFAULT(enableThreadSample, enable_thread_sample, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(threadSampleInterval, thread_sample_interval, @(300), @(300))
        HMD_ATTR_MAP(businessList, business_list)
        HMD_ATTR_MAP(specialThreadWhiteList, special_thread_white_list)
        HMD_ATTR_MAP_DEFAULT(enableBacktrace, enable_backtrace, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(countAnalysisInterval, count_analysis_interval, @(600), @(600))
        HMD_ATTR_MAP_DEFAULT(enableThreadInversionCheck, enable_priority_inversion_check, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enableObserverSubThreadRunloop, enable_observer_subthread_runloop, @(NO), @(NO))
        HMD_ATTR_MAP(subThreadRunloopNameList, subthread_runloop_name_list)
        HMD_ATTR_MAP_DEFAULT(subThreadRunloopTimeoutDuration, subthread_runloop_timeout_duration, @(8), @(8))
    };
}

+ (NSString *)configKey {
    return kHMDModuleThreadMonitor;
}

- (id<HeimdallrModule>)getModule {
    return [HMDThreadMonitor shared];
}

@end
