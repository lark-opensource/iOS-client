//
//  LKCExcptionCPUConfig.m
//  LarkMonitor
//
//  Created by sniperj on 2019/12/31.
//

#import "LKCExcptionCPUConfig.h"
#import "LKCExceptionCPU.h"
#import "NSObject+LKAttributes.h"

LK_CEXC_CONFIG(LKCExcptionCPUConfig)

NSString *const LKCEXCCPU = @"cpu_excption";

@implementation LKCExcptionCPUConfig

+ (NSDictionary *)lk_attributeMapDictionary {
    return @{
             LK_ATTRIBUTE_MAP_DEFAULT(highUsageRate, high_usage_rate, @(LKCEXCCPUDefaultHighUsageRate)),
             LK_ATTRIBUTE_MAP_DEFAULT(middleUsageRate, middle_usage_rate, @(LKCEXCCPUDefaultMiddleUsageRate)),
             LK_ATTRIBUTE_MAP_DEFAULT(lowUsageRate, low_usage_rate, @(LKCEXCCPUDefaultLowUsageRate))
             };
}

+ (NSString *)configKey {
    return LKCEXCCPU;
}

- (id<LKCExceptionProtocol>)getCustomException {
    return [LKCExceptionCPU sharedInstance];
}


@end
