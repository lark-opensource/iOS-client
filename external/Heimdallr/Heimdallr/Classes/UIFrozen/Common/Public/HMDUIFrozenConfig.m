//
//  HMDUIFrozenConfig.m
//  AWECloudCommand
//
//  Created by 白昆仑 on 2020/3/24.
//

#import "HMDUIFrozenConfig.h"
#import "HMDUIFrozenTracker.h"
#import "HMDUIFrozenManager.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleUIFrozenKey = @"ui_frozen";

HMD_MODULE_CONFIG(HMDUIFrozenConfig)

@implementation HMDUIFrozenConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(operationCountThreshold, operation_count_threshold, @(HMDUIFrozenDefaultOperationCountThreshold), @(HMDUIFrozenDefaultOperationCountThreshold))
        HMD_ATTR_MAP_DEFAULT(launchCrashThreshold, launch_crash_threshold, @(HMDUIFrozenDefaultLaunchCrashThreshold), @(HMDUIFrozenDefaultLaunchCrashThreshold))
        HMD_ATTR_MAP_DEFAULT(uploadAlog, upload_alog, @(HMDUIFrozenDefaultUploadAlog), @(HMDUIFrozenDefaultUploadAlog))
        HMD_ATTR_MAP_DEFAULT(enableGestureMonitor, enable_gesture_monitor, @(HMDUIFrozenDefaultEnableGestureMonitor), @(HMDUIFrozenDefaultEnableGestureMonitor))
        HMD_ATTR_MAP_DEFAULT(gestureCountThreshold, gesture_count_threshold, @(HMDUIFrozenDefaultGestureCountThreshold), @(HMDUIFrozenDefaultGestureCountThreshold))
    };
}

+ (NSString *)configKey {
    return kHMDModuleUIFrozenKey;
}

- (id<HeimdallrModule>)getModule {
    return [HMDUIFrozenTracker sharedTracker];
}

@end
