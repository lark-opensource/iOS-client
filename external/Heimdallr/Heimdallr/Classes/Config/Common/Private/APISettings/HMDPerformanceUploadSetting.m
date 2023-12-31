//
//  HMDPerformanceUploadSetting.m
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/5/19.
//

#import "HMDPerformanceUploadSetting.h"
#import "NSObject+HMDAttributes.h"

@implementation HMDPerformanceUploadSetting

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(maxRetryCount, max_retry_count, @(4), @(4))
        HMD_ATTR_MAP_DEFAULT(uploadInterval, uploading_interval, @(120), @(120))
        HMD_ATTR_MAP_DEFAULT(onceMaxCount, once_max_count, @(100), @(100))
        HMD_ATTR_MAP_DEFAULT(reportFailBaseInterval, report_fail_base_interval, @(15), @(15))
        HMD_ATTR_MAP_DEFAULT(enableNetQualityReport, enable_net_quality_report, @(YES), @(YES))
        HMD_ATTR_MAP_DEFAULT(enableDowngradeByChannel, enable_downgrade_by_channel, @(NO), @(YES))
    };
}

@end
