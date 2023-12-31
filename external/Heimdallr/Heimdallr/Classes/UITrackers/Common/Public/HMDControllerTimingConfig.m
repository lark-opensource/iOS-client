//
//  HMDControllerTimingConfig.m
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDControllerTimingConfig.h"
#import "HMDControllerTimeManager.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

#import "Heimdallr.h"
#import "HMDControllerTimeManager2.h"
#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP

NSString *const kHMDModuleControllerTracker = @"page_load";

HMD_MODULE_CONFIG(HMDControllerTimingConfig)

@implementation HMDControllerTimingConfig

+ (NSString *)configKey {
    return kHMDModuleControllerTracker;
}

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP_DEFAULT(flushInterval, flush_interval, @(60), @(60))
        HMD_ATTR_MAP_DEFAULT(flushCount, flush_count, @(10), @(10))
    };
}

- (id<HeimdallrModule>)getModule {
    return hermas_enabled() ? [HMDControllerTimeManager2 sharedInstance] : [HMDControllerTimeManager sharedInstance];
}

@end
