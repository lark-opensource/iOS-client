//
//  HMDTTKAutoReleaseProtectionConfig.m
//  Heimdallr-_Dummy
//
//  Created by zhouyang11 on 2022/7/12.
//

#import "HMDTTKAutoReleaseProtectionConfig.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"
#import "HMDTTKAutoReleaseProtection.h"

NSString *const kHMDModuleAutoReleaseProtection = @"autoreleasepool_protection";

HMD_MODULE_CONFIG(HMDTTKAutoReleaseProtectionConfig)

@implementation HMDTTKAutoReleaseProtectionConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(methodGroupArray, method_group_array, @[], @[])
    };
}

+ (NSString *)configKey {
    return kHMDModuleAutoReleaseProtection;
}

- (id<HeimdallrModule>)getModule {
    return [HMDTTKAutoReleaseProtection sharedInstance];
}

@end
