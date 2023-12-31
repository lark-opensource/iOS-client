//
//  HMDStartDetectorConfig.m
//  BDAlogProtocol
//
//  Created by 刘诗彬 on 2018/12/19.
//

#import "HMDStartDetectorConfig.h"
#import "HMDStartDetector.h"
#import "hmd_section_data_utility.h"
#import "AppStartTracker.h"

NSString *const kHMDModuleStartDetector = @"start";

HMD_MODULE_CONFIG(HMDStartDetectorConfig)

@implementation HMDStartDetectorConfig

+ (NSDictionary *)hmd_attributeMapDictionary
{
    return @{
             @"detectCPPInitializer":@"is_detector_cpp_initializer",
             @"detectLoad":@"is_detector_load"
             };
}

+ (NSString *)configKey
{
    return kHMDModuleStartDetector;
}

- (id<HeimdallrModule>)getModule
{
    return [HMDStartDetector share];
}

@end
