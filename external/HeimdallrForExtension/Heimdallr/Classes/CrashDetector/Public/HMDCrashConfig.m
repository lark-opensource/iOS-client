//
//  HMDCrashConfig.m
//  Heimdallr
//
//  Created by 刘诗彬 on 2018/12/14.
//

#import "HMDCrashConfig.h"
#import "HMDCrashTracker.h"
#import "NSObject+Attributes.h"
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

+ (NSDictionary *)hmd_attributeMapDictionary
{
    return @{
             HMD_ATTRIBUTE_MAP_DEFAULT(launchThreshold, launch_threshold, @(8)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableAsyncStackTrace, enable_async_stack_trace, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableMultipleAsyncStackTrace, enable_multiple_async_stack_trace, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableRegisterAnalysis, enable_register_analysis, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableStackAnalysis, enable_stack_analysis, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableVMMap, enable_vmmap, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(maxVmmapCount, max_vmmap_count, @(3000)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableCPPBacktrace, enable_cpp_backtrace, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableContentAnalysis, enable_content_analysis, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableExtensionDetect, enable_extension_detect, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(enableIgnoreExitByUser, enable_ignore_exit, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(writeImageOnCrash, write_image_on_crash, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(setAssertMainThreadTransactions, set_assert_main_thread_transactions, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(extendFD, extend_fd, @(NO)),
             HMD_ATTRIBUTE_MAP_DEFAULT(maxStackTraceCount, stack_trace_count, @(256)),
             };
}

+ (NSString *)configKey
{
    return kHMDModuleCrashTracker;
}

#if !SIMPLIFYEXTENSION

- (void)hmd_setAttributes:(NSDictionary *)dataDic block:(void (^)(NSObject *, NSDictionary *))block
{
    [super hmd_setAttributes:dataDic block:block];
    self.crashUploadSetting = [HMDCommonAPISetting hmd_objectWithDictionary:[dataDic hmd_dictForKey:@"crash_upload_setting"]];
    self.allAPISetting = [HMDCommonAPISetting hmd_objectWithDictionary:[dataDic hmd_dictForKey:@"all_api_setting"]];
}

- (NSDictionary *)hmd_dataDictionary
{
    NSDictionary *superDict = [super hmd_dataDictionary];
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    if (superDict.count) {
        [mdict addEntriesFromDictionary:superDict];
    }
    [mdict hmd_setObject:[self.crashUploadSetting hmd_dataDictionary] forKey:@"crash_upload_setting"];
    [mdict hmd_setObject:[self.allAPISetting hmd_dataDictionary] forKey:@"all_api_setting"];
    return mdict;
}

- (void)updateWithAPISettings:(HMDGeneralAPISettings *)apiSettings
{
    self.crashUploadSetting = apiSettings.crashUploadSetting;
    self.allAPISetting = apiSettings.allAPISetting;
}

- (id<HeimdallrModule>)getModule
{
    return [HMDCrashTracker sharedTracker];
}

- (HMDModuleStartWeight)startWeight
{
    return HMDCrashModuleStartWeight;
}

#else

- (void)hmd_setAttributes:(NSDictionary *)dataDic block:(void (^)(NSObject *, NSDictionary *))block
{
    [super hmd_setAttributes:dataDic block:block];
}

- (NSDictionary *)hmd_dataDictionary
{
    NSDictionary *superDict = [super hmd_dataDictionary];
    NSMutableDictionary *mdict = [NSMutableDictionary dictionary];
    if (superDict.count) {
        [mdict addEntriesFromDictionary:superDict];
    }
    return mdict;
}

- (void)updateWithAPISettings:(id)apiSettings
{

}

#endif

- (NSDictionary *)configDictionary{
    return @{
        @"launch_threshold":@(self.launchThreshold) ?: @(8),
        @"enable_async_stack_trace":@(self.enableAsyncStackTrace) ?: @(NO),
        @"enable_multiple_async_stack_trace":@(self.enableMultipleAsyncStackTrace) ?: @(NO),
        @"enable_register_analysis":@(self.enableRegisterAnalysis) ?: @(NO),
        @"enable_stack_analysis":@(self.enableStackAnalysis) ?: @(NO),
        @"enable_vmmap":@(self.enableVMMap) ?: @(NO),
        @"enable_cpp_backtrace":@(self.enableCPPBacktrace) ?: @(NO),
        @"enable_content_analysis":@(self.enableContentAnalysis) ?: @(NO),
        @"enable_extension_detect":@(self.enableExtensionDetect) ?: @(NO),
        @"enable_ignore_exit":@(self.enableIgnoreExitByUser) ?: @(NO),
        @"stack_trace_count":@(self.maxStackTraceCount) ?:@(256)
    };
}

- (BOOL)enableUpload
{
    return YES;
}

@end
