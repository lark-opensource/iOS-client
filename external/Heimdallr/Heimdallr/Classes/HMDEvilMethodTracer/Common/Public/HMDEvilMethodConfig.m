//
//  HMDEvilMethodConfig.m
//  AWECloudCommand
//
//  Created by maniackk on 2021/6/3.
//

#import "HMDEvilMethodConfig.h"
#import "NSObject+HMDAttributes.h"
#import "HMDEvilMethodTracer.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleEvilMethodTracer = @"evil_method_trace";

HMD_MODULE_CONFIG(HMDEvilMethodConfig)

@implementation HMDEvilMethodConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(hangTime, hang_time, @(1.0), @(1.0))
        HMD_ATTR_MAP_DEFAULT(filterEvilMethod, filter_evil_method, @(YES), @(YES))
        HMD_ATTR_MAP_DEFAULT(filterMillisecond, filter_millisecond, @(1), @(1))
        HMD_ATTR_MAP_DEFAULT(collectFrameDrop, collect_frame_drop, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(collectFrameDropThreshold, collect_frame_drop_threshold, @(500), @(500))
    };
}

+ (NSString *)configKey {
    return kHMDModuleEvilMethodTracer;
}

- (id<HeimdallrModule>)getModule {
    return [HMDEvilMethodTracer sharedInstance];
}

@end
