//
//  HMDDoubleUploadSettings.m
//  Heimdallr
//
//  Created by bytedance on 2022/3/4.
//

#import "HMDDoubleUploadSettings.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDDoubleUploadSettings

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP(enableOpen, enable_open)
        HMD_ATTR_MAP(hostAndPath, host_and_path)
        HMD_ATTR_MAP(allowList, allow_list)
    };
}

@end
