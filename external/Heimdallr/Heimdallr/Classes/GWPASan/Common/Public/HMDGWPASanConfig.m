//
//  HMDGWPASanConfig.m
//  AWECloudCommand
//
//  Created by maniackk on 2021/9/16.
//

#import "HMDGWPASanConfig.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"
#import "HMDGWPASanMonitor.h"

NSString *const kHMDModuleGWPASan = @"gwp_asan";

HMD_MODULE_CONFIG(HMDGWPASanConfig)

@implementation HMDGWPASanConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(MaxSimultaneousAllocations, max_simultaneous_allocations, @(1024), @(1024))
        HMD_ATTR_MAP_DEFAULT(SampleRate, sample_rate, @(1000), @(1000))
        HMD_ATTR_MAP_DEFAULT(isOpenDebugMode, is_open_debug_mode, @(0), @(0))
        HMD_ATTR_MAP_DEFAULT(MaxMapAllocationsDebugMode, max_map_allocation_debug_mode, @(131072), @(131072))
        HMD_ATTR_MAP_DEFAULT(useNewGWPAsan, use_new_gwp_asan, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(coredumpIfAsan, coredump_if_asan, @(NO), @(NO))
    };
}

+ (NSString *)configKey {
    return kHMDModuleGWPASan;
}

- (id<HeimdallrModule>)getModule {
    return [HMDGWPASanMonitor sharedMonitor];
}

@end
