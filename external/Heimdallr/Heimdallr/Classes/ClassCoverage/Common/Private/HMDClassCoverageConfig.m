//
//  HMDClassCoverageConfig.m
//  Pods
//
//  Created by kilroy on 2020/6/8.
//

#import <Foundation/Foundation.h>
#import "HMDClassCoverageConfig.h"
#import "HMDClassCoverageManager.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleClassCoverage = @"class_coverage";

HMD_MODULE_CONFIG(HMDClassCoverageConfig)

@implementation HMDClassCoverageConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(checkInterval, check_interval, @(120), @(120))
        HMD_ATTR_MAP_DEFAULT(wifiOnly, wifi_only, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(devicePerformanceLevelThreshold, device_performance_level_threshold, @(2), @(2))
    };
}

+ (NSString *)configKey {
    return kHMDModuleClassCoverage;
}

- (id<HeimdallrModule>)getModule {
    return [HMDClassCoverageManager sharedInstance];
}

@end
