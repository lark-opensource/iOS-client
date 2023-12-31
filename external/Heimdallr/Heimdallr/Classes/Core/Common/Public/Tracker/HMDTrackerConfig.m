//
//  HMDTrackerConfig.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//

#import "HMDTrackerConfig.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDTrackerConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(flushInterval, flush_interval, @(60), @(60))
        HMD_ATTR_MAP_DEFAULT(flushCount, flush_count, @(1), @(1))
    };
}

@end
