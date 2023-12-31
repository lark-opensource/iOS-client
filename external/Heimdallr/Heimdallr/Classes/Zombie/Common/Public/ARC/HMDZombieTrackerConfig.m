//
//  HMDZombieTrackerConfig.m
//  AFgzipRequestSerializer
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDZombieTrackerConfig.h"
#import "HMDZombieMonitor.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleZombieDetector = @"zombie";

HMD_MODULE_CONFIG(HMDZombieTrackerConfig)

@implementation HMDZombieTrackerConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(monitorCFObj, monitor_cf_obj, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(classList, zombie_class_list, @[], @[])
        HMD_ATTR_MAP_DEFAULT(monitorClassList, monitor_class_list, @[], @[])
        HMD_ATTR_MAP_DEFAULT(maxZombieDeallocCount, max_zombie_count, @(100), @(100))
    };
}

+ (NSString *)configKey{
    return kHMDModuleZombieDetector;
}

- (id<HeimdallrModule>)getModule {
    return [HMDZombieMonitor sharedInstance];
}

@end
