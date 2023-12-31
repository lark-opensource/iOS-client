//
//  HMDExceptionTrackerConfig.m
//  AFgzipRequestSerializer
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDExceptionTrackerConfig.h"
#import "HMDExceptionTracker.h"
#import "NSObject+HMDAttributes.h"
#import "HMDModuleConfig+StartWeight.h"
#import "HMDProtector.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleProtectorName = @"protector";

HMD_MODULE_CONFIG(HMDExceptionTrackerConfig)

@implementation HMDExceptionTrackerConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP(openOptions, open_options)
        HMD_ATTR_MAP_DEFAULT(ignoreDuplicate, ignore_duplicate, @(HMDProtectDefaultIgnoreDuplicate), @(HMDProtectDefaultIgnoreDuplicate))
        HMD_ATTR_MAP_DEFAULT(ignoreTryCatch, ignore_try_catch, @(HMDProtectDefaultIgnoreTryCatch), @(HMDProtectDefaultIgnoreTryCatch))
        HMD_ATTR_MAP_DEFAULT(catchMethodList, custom_catch, @{}, @{})
        HMD_ATTR_MAP_DEFAULT(systemProtectList, system_protect, @[], @[])
        HMD_ATTR_MAP_DEFAULT(enableNSException, enable_nsexception, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(enableMachException, enable_mach_exception, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(machExceptionPrefix, mach_exception_prefix, @"com.bytedance", @"com.bytedance")
        HMD_ATTR_MAP_DEFAULT(machExceptionList, mach_exception_list, @{}, @{})
        HMD_ATTR_MAP_DEFAULT(machExceptionCloud, mach_exception_cloud, @{}, @{})
        HMD_ATTR_MAP_DEFAULT(uploadAlog, upload_alog, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(dispatchMainThread, dispatch_main_thread, @{}, @{})
        HMD_ATTR_MAP_DEFAULT_TOB(protectorUpload, protector_ratio, @(NO))
        HMD_ATTR_MAP_DEFAULT_TOB(arrayCreateMode, array_create_mode, @(0))
    };
}

+ (NSString *)configKey {
    return kHMDModuleProtectorName;
}

- (id<HeimdallrModule>)getModule {
    return [HMDExceptionTracker sharedTracker];
}

- (HMDModuleStartWeight)startWeight {
    return HMDProtectorModuleStartWeight;
}

@end
