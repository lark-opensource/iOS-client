//
//  HMDLaunchAnalyseConfig.m
//  AWECloudCommand
//
//  Created by maniackk on 2020/9/10.
//

#import "HMDLaunchAnalyseConfig.h"
#import "NSObject+HMDAttributes.h"
#import "HMDLaunchAnalyseMonitor.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleLaunchAnalyse = @"launch_analyse";

HMD_MODULE_CONFIG(HMDLaunchAnalyseConfig)

@implementation HMDLaunchAnalyseConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(maxCollectTime, max_collect_time, @(20), @(20))
        HMD_ATTR_MAP_DEFAULT(maxErrorTime, max_error_time, @(500), @(500))
    };
}

+ (NSString *)configKey {
    return kHMDModuleLaunchAnalyse;
}

- (id<HeimdallrModule>)getModule {
    return [HMDLaunchAnalyseMonitor sharedMonitor];
}

@end
