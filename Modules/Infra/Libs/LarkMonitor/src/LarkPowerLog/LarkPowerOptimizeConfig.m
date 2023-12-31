//
//  LarkPowerOptimizeConfig.m
//  LarkMonitor-LarkMonitorAuto
//
//  Created by ByteDance on 2023/2/7.
//

#import "LarkPowerOptimizeConfig.h"
#import "NSDictionary+BDPL.h"

static BOOL lark_power_optimize_calayer_crash;

@implementation LarkPowerOptimizeConfig

+ (BOOL)enableOptimizeCALayerCrash {
    return lark_power_optimize_calayer_crash;
}

+ (void)updateConfig:(NSDictionary *)config {
    if ([[config bdpl_objectForKey:@"optimize_calayer_crash" cls:NSNumber.class] boolValue]) {
        lark_power_optimize_calayer_crash = true;
    } else {
        lark_power_optimize_calayer_crash = false;
    }
}

@end
