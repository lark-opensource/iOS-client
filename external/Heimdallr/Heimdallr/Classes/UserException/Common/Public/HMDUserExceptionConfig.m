//
//  HMDUserExceptionConfig.m
//  Heimdallr
//
//  Created by 谢俊逸 on 2019/4/1.
//

#import "HMDUserExceptionConfig.h"
#import "HMDUserExceptionTracker.h"
#if RANGERSAPM
#import "HMDUserExceptionConfig_RangersAPM.h"
#endif
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

NSString *const kHMDModuleUserException = @"user_exception";

HMD_MODULE_CONFIG(HMDUserExceptionConfig)

@implementation HMDUserExceptionConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT2(maxUploadCount, max_upload_count, @(5), user_exception_max_upload_count, @(5))
        HMD_ATTR_MAP_DEFAULT2(typeBlockList, block_type_list, @{}, user_exception_block_type_list, @{})
        HMD_ATTR_MAP_DEFAULT2(typeAllowList, allow_type_list, @[], user_exception_allow_type_list, @[])
        HMD_ATTR_MAP_TOB(currentAppID, current_appID)
        HMD_ATTR_MAP_DEFAULT_TOB(appIDs, aids, @[])
    };
}

+ (NSString *)configKey {
    return kHMDModuleUserException;
}

- (id<HeimdallrModule>)getModule {
    return [HMDUserExceptionTracker sharedTracker];
}

- (BOOL)canStart {
    return self.enableOpen && self.enableUpload;
}

@end
