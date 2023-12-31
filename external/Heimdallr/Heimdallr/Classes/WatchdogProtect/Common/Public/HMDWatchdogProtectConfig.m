//
//  HMDWatchdogProtectConfig.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/4/8.
//

#import "HMDWatchdogProtectConfig.h"
#import "HMDWatchdogProtectTracker.h"
#import "HMDWatchdogProtectManager.h"
#import "NSObject+HMDAttributes.h"
#import "HMDWatchdogProtectDefine.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleWatchdogProtectKey = @"watchdog_protect";

HMD_MODULE_CONFIG(HMDWatchdogProtectConfig)

@implementation HMDWatchdogProtectConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    NSMutableArray *defaultTypeList = [NSMutableArray arrayWithCapacity:4];
    if (HMDWPDefaultUIPasteboardProtect) {
        [defaultTypeList addObject:HMDWPUIPasteboardKey];
    }
    if (HMDWPDefaultUIApplicationProtect) {
        [defaultTypeList addObject:HMDWPUIApplicationKey];
    }
    if (HMDWPDefaultYYCacheProtect) {
        [defaultTypeList addObject:HMDWPYYCacheKey];
    }
    if (HMDWPDefaultNSUserDefaultProtect) {
        [defaultTypeList addObject:HMDWPNSUserDefaultKey];
    }
    
    return @{
        HMD_ATTR_MAP_DEFAULT(timeoutInterval, timeout_interval, @(HMDWPDefaultTimeoutInterval), @(HMDWPDefaultTimeoutInterval))
        HMD_ATTR_MAP_DEFAULT(launchThreshold, launch_threshold, @(HMDWPDefaultLaunchThreshold), @(HMDWPDefaultLaunchThreshold))
        HMD_ATTR_MAP_DEFAULT(typeList, type_list, [defaultTypeList copy], [defaultTypeList copy])
        HMD_ATTR_MAP_DEFAULT(dynamicProtect, dynamic_protect, @[], @[])
        HMD_ATTR_MAP_DEFAULT(dynamicProtectAnyThread, dynamic_protect_any_thread, @[], @[])
    };
}

+ (NSString *)configKey {
    return kHMDModuleWatchdogProtectKey;
}

- (id<HeimdallrModule>)getModule {
    return [HMDWatchdogProtectTracker sharedTracker];
}

@end
