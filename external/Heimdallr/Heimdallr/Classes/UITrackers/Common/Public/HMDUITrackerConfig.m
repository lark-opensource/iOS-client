//
//  HMDUITrackerConfig.m
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDUITrackerConfig.h"
#import "HMDUITrackerManager.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleUITracker = @"ui";

HMD_MODULE_CONFIG(HMDUITrackerConfig)

@implementation HMDUITrackerConfig

+ (NSString *)configKey {
    return kHMDModuleUITracker;
}

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(flushInterval, flush_interval, @(60), @(60))
        HMD_ATTR_MAP_DEFAULT(flushCount, flush_count, @(60), @(60))
        HMD_ATTR_MAP_DEFAULT(maxUploadCount, max_upload_count, @(1), @(1))
        HMD_ATTR_MAP_DEFAULT(recentAccessScenesLimit, recent_access_scenes_limit, @(0), @(20))
        HMD_ATTR_MAP_DEFAULT(ISASwizzleOptimization, isa_swizzle_optimization, @(NO), @(NO))
    };
}

- (id<HeimdallrModule>)getModule {
    return [HMDUITrackerManager sharedManager];
}

@end
