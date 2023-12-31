//
//  HMDCrashConfig.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//

#import "HMDCrashConfig.h"
#import "HMDCrashTracker.h"
#import "NSObject+HMDAttributes.h"
#import "NSDictionary+HMDSafe.h"
#if !SIMPLIFYEXTENSION
#import "HMDModuleConfig+StartWeight.h"
#import "HMDGeneralAPISettings.h"
#import "HMDCommonAPISetting.h"
#import "hmd_section_data_utility.h"
#endif

NSString *const kHMDModuleCrashTracker = @"crash";

#if !SIMPLIFYEXTENSION
HMD_MODULE_CONFIG(HMDCrashConfig)
#endif

@implementation HMDCrashConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(launchThreshold, launch_threshold, @(8), @(8))
        HMD_ATTR_MAP_DEFAULT(enableAsyncStackTrace, enable_async_stack_trace, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enableMultipleAsyncStackTrace, enable_multiple_async_stack_trace, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enableRegisterAnalysis, enable_register_analysis, @(NO), @(YES))
        HMD_ATTR_MAP_DEFAULT(enableStackAnalysis, enable_stack_analysis, @(NO), @(YES))
        HMD_ATTR_MAP_DEFAULT(enableVMMap, enable_vmmap, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(maxVmmapCount, max_vmmap_count, @(3000), @(3000))
        HMD_ATTR_MAP_DEFAULT(enableCPPBacktrace, enable_cpp_backtrace, @(NO), @(YES))
        HMD_ATTR_MAP_DEFAULT(enableContentAnalysis, enable_content_analysis, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enableExtensionDetect, enable_extension_detect, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enableIgnoreExitByUser, enable_ignore_exit, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(writeImageOnCrash, write_image_on_crash, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(setAssertMainThreadTransactions, set_assert_main_thread_transactions, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(extendFD, extend_fd, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(maxStackTraceCount, stack_trace_count, @(256), @(256))
#if !SIMPLIFYEXTENSION
        HMD_ATTR_MAP_CLASS(crashUploadSetting, crash_upload_setting, HMDCommonAPISetting)
        HMD_ATTR_MAP_CLASS(allAPISetting, all_api_setting, HMDCommonAPISetting)
#endif
        HMD_ATTR_MAP_TOB(currentAppID, currentAid)
        HMD_ATTR_MAP_DEFAULT_TOB(updateAsFirstLaunch, update_as_first_launch, @(YES))
        HMD_ATTR_MAP_DEFAULT_TOB(uploadAlog, upload_alog, @(NO))
        HMD_ATTR_MAP_DEFAULT_TOB(alogCrashBeforeTime, alog_crash_before_time, @(300))
    };
}

+ (NSString *)configKey {
    return kHMDModuleCrashTracker;
}

#if !SIMPLIFYEXTENSION

- (void)updateWithAPISettings:(HMDGeneralAPISettings *)apiSettings {
    self.crashUploadSetting = apiSettings.crashUploadSetting;
    self.allAPISetting = apiSettings.allAPISetting;
}

- (id<HeimdallrModule>)getModule {
    return [HMDCrashTracker sharedTracker];
}

- (HMDModuleStartWeight)startWeight {
    return HMDCrashModuleStartWeight;
}

#else

- (void)updateWithAPISettings:(id)apiSettings {}

#endif

- (NSDictionary *)configDictionary{
    return [self hmd_dataDictionary];
}

- (BOOL)enableUpload {
    return YES;
}

@end
