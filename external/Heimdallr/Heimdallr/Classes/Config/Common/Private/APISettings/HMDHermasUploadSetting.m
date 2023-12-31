//
//  HMDHermasUploadSetting.m
//  Heimdallr-8bda3036
//
//  Created by liuhan on 2022/5/19.
//

#import "HMDHermasUploadSetting.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDHermasUploadSetting

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(limitUploadInterval, limit_upload_interval, @(15), @(15))
        HMD_ATTR_MAP_DEFAULT(limitUploadSize, limit_upload_size, @(10), @(10))
        HMD_ATTR_MAP_DEFAULT(maxLogNumber, max_log_number, @(1000), @(1000))
        HMD_ATTR_MAP_DEFAULT(maxFileSize, max_file_size, @(0.25), @(0.25))
        HMD_ATTR_MAP_DEFAULT(maxUploadSize, max_upload_size, @(20), @(20))
        HMD_ATTR_MAP_DEFAULT(uploadInterval, upload_interval, @(30), @(30))
        HMD_ATTR_MAP_DEFAULT(enableRefactorOpen, enable_refactor_open, @(NO), @(NO))
        HMD_ATTR_MAP_DEFAULT(recordThreadShareMask, record_thread_share_mask, @(14), @(14))
    };
}

@end
