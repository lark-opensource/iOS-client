//
//  HMDCloudCommandSetting.m
//  Heimdallr-dad8ba1e
//
//  Created by bytedance on 2021/11/29.
//

#import "HMDCloudCommandSetting.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDCloudCommandSetting

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(enableOpen, enable_open, @(YES), @(YES))
    };
}

@end
