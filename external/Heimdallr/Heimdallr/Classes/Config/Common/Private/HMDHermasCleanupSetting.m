//
//  HMDHermasCleanupSetting.m
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/5/20.
//

#import "HMDHermasCleanupSetting.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDHermasCleanupSetting

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(maxStoreSize, max_store_size, @(500), @(500))
        HMD_ATTR_MAP_DEFAULT(maxStoreTime, max_store_time, @(7), @(7))
    };
}

@end
