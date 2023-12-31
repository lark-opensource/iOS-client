//
//  HMDOOMCrashConfig
//  Heimdallr
//
//  Created by sunrunwang on don't matter time
//

#import "HMDOOMCrashConfig.h"
#import "HMDOOMCrashTracker.h"
#if RANGERSAPM
#import "HMDOOMCrashConfig_RangersAPM.h"
#endif
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleOOMCrashTracker = @"oom_crash";

// Cooperate with Heimdallr
HMD_MODULE_CONFIG(HMDOOMCrashConfig)

@implementation HMDOOMCrashConfig

#pragma mark - HMDModuleConfig override

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(updateSystemStateInterval, update_system_state_interval, @(60), @(60))
        HMD_ATTR_MAP_DEFAULT(memoryPressureValidInterval, memory_pressure_valid_interval, @(600), @(600))
        HMD_ATTR_MAP_DEFAULT(isFixNoDataMisjudgment, is_fix_nodata_misjudgment, @(YES), @(YES))
        HMD_ATTR_MAP_DEFAULT(isNeedBinaryInfo, is_need_binary_info, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT_TOB(uploadAlog, upload_alog, @(NO))
        HMD_ATTR_MAP_DEFAULT_TOB(alogCrashBeforeTime, alog_crash_before_time, @(300))
    };
}

+ (NSString *)configKey {
    return kHMDModuleOOMCrashTracker;
}

- (id<HeimdallrModule>)getModule {
    return [HMDOOMCrashTracker sharedTracker];
}

- (BOOL)enableUpload {
    //只要出现OOMCrash就上报
    return YES;
}

@end
