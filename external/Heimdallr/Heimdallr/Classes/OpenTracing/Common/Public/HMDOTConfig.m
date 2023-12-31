//
//  HMDOTConfig.m
//  Pods
//
//  Created by fengyadong on 2019/12/12.
//

#import "HMDOTConfig.h"
#import "HMDOTManager.h"
#import "NSObject+HMDAttributes.h"
#import "hmd_section_data_utility.h"

#import "HMDMacro.h"
CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_STRICT_PROTOTYPES
#import <Hermas/Hermas.h>
CLANG_DIAGNOSTIC_POP
#import "HMDOTManager2.h"

NSString *const kHMDModuleOpenTracingTracker = @"tracing";

HMD_MODULE_CONFIG(HMDOTConfig)

@implementation HMDOTConfig

+ (NSDictionary *)hmd_attributeMapDictionary {
    return @{
        HMD_ATTR_MAP(allowServiceList, allow_service_list)
        HMD_ATTR_MAP(allowErrorList, allow_error_list)
    };
}

+ (NSString *)configKey {
    return kHMDModuleOpenTracingTracker;
}

- (id<HeimdallrModule>)getModule {
    if (hermas_enabled()) {
        return [HMDOTManager2 sharedInstance];
    } else {
        return [HMDOTManager sharedInstance];
    }
}

@end
