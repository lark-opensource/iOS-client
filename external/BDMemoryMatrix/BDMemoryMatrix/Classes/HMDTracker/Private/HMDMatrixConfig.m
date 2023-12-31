//
//  HMDMatrixConfig.m
//  BDMemoryMatrix
//
//  Created by zhouyang11 on 2022/5/18.
//

#import "HMDMatrixConfig.h"
#import <Heimdallr/hmd_section_data_utility.h>
#import <Heimdallr/NSObject+Attributes.h>
#import "HMDMatrixMonitor.h"

NSString *const kHMDModuleMatrix = @"matrix";

HMD_MODULE_CONFIG(HMDMatrixConfig)

@implementation HMDMatrixConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTRIBUTE_MAP_DEFAULT(isVCLevelEnabled, is_vc_level_enabled, @(NO)),
        HMD_ATTRIBUTE_MAP_DEFAULT(isCrashUploadEnabled, is_crash_upload_enabled, @(NO)),
        HMD_ATTRIBUTE_MAP_DEFAULT(isMemoryPressureUploadEnabled, is_memory_pressure_upload_enabled, @(NO)),
        HMD_ATTRIBUTE_MAP_DEFAULT(isAsyncStackEnabled, is_async_stack_enabled, @(NO)),
        HMD_ATTRIBUTE_MAP_DEFAULT(isEventTimeEnabled, is_event_time_enabled, @(NO)),
        HMD_ATTRIBUTE_MAP_DEFAULT(minGenerateMinuteInterval, min_generate_minute_interval, @(10)),
        HMD_ATTRIBUTE_MAP_DEFAULT(maxTimesPerDay, max_times_per_day, @(100)),
        HMD_ATTRIBUTE_MAP_DEFAULT(minRemainingDiskSpaceMB, min_remaining_disk_space_mb, @(300)),
        HMD_ATTRIBUTE_MAP_DEFAULT(isWatchDogUploadEnabled, is_watchDog_upload_enabled, @(NO)),
        HMD_ATTRIBUTE_MAP_DEFAULT(isEnforceUploadEnabled, is_enforce_upload_enabled, @(NO))
             };
}

+ (NSString *)configKey {
    return kHMDModuleMatrix;
}

- (id<HeimdallrModule>)getModule {
    return [HMDMatrixMonitor sharedMonitor];
}

- (BOOL)canStartTaskIndependentOfStart {
    return YES;
}

@end
