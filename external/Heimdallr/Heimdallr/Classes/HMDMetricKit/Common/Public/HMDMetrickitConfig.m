//
//  HMDMetrickitConfig.m
//  Heimdallr
//
//  Created by maniackk on 2021/4/21.
//

#import "HMDMetrickitConfig.h"
#import "hmd_section_data_utility.h"
#import "HMDMetricKitTracker.h"
#import "NSObject+HMDAttributes.h"

NSString *const kHMDModuleMetrickitKey = @"metrickit";

HMD_MODULE_CONFIG(HMDMetrickitConfig)

@implementation HMDMetrickitConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(isUploadMetric, is_upload_metric, @(0), @(0))
        HMD_ATTR_MAP_DEFAULT(isFixSegmentRename, is_fix_segment_rename, @(1), @(1))
    };
}

+ (NSString *)configKey {
    return kHMDModuleMetrickitKey;
}

- (id<HeimdallrModule>)getModule {
    return [HMDMetricKitTracker sharedTracker];
}

- (BOOL)enableUpload {
    return YES;
}

@end
