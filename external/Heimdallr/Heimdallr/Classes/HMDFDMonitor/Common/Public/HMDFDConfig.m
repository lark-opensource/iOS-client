//
//  FDConfig.m
//  Heimdallr
//
//  Created by wangyinhui on 2021/6/29.
//

#import "HMDFDConfig.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"
#import "HMDFDTracker.h"

NSString *const kHMDModuleFDMonitor = @"fd";

HMD_MODULE_CONFIG(HMDFDConfig)

@implementation HMDFDConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(sampleInterval, sample_interval, @(0), @(0))
        HMD_ATTR_MAP_DEFAULT(fdWarnRate, fd_warn_rate, @(0.7), @(0.7))
        HMD_ATTR_MAP_DEFAULT(maxFD, max_fd, @(0), @(0))
    };
}

+ (NSString *)configKey {
    return kHMDModuleFDMonitor;
}

- (id<HeimdallrModule>)getModule {
    return [HMDFDTracker sharedTracker];
}

@end
