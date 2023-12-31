//
//  HMDConfigFetchSetting.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/19.
//

#import "HMDConfigFetchSetting.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDConfigFetchSetting

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(fetchInterval, fetch_setting_interval, @(3600), @(3600))
    };
}

@end
