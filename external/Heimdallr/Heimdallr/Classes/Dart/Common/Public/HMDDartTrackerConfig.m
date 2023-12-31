//
//  HMDDartTrackerConfig.m
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDDartTrackerConfig.h"
#import "HMDDartTracker.h"
#import "hmd_section_data_utility.h"
#import "NSObject+HMDAttributes.h"

NSString *const kHMDModuleDartTracker = @"dart";

HMD_MODULE_CONFIG(HMDDartTrackerConfig)

@implementation HMDDartTrackerConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(uploadAlog, upload_alog, @(NO), @(NO))
    };
}

+ (NSString *)configKey {
    return kHMDModuleDartTracker;
}

- (id<HeimdallrModule>)getModule {
    return [HMDDartTracker sharedTracker];
}

@end
