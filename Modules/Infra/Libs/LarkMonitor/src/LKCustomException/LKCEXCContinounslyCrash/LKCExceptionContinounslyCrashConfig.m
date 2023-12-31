//
//  LKCExceptionContinounslyCrashConfig.m
//  LarkMonitor
//
//  Created by sniperj on 2019/12/31.
//

#import "LKCExceptionContinounslyCrashConfig.h"
#import "LKCExceptionContinounslyCrash.h"
#import "NSObject+LKAttributes.h"

LK_CEXC_CONFIG(LKCExceptionContinounslyCrashConfig)

NSString *const LKCEXCContinuouslyCrash = @"continuously_crash";

@implementation LKCExceptionContinounslyCrashConfig

+ (NSString *)configKey {
    return LKCEXCContinuouslyCrash;
}

- (id<LKCExceptionProtocol>)getCustomException {
    return [LKCExceptionContinounslyCrash sharedInstance];
}

+ (NSDictionary *)lk_attributeMapDictionary {
    return @{
             LK_ATTRIBUTE_MAP_DEFAULT(launchTimeThreshold, launch_time_threshold, @(LCKEXCContinounsCrashLaunchTimeThreshold)),
             LK_ATTRIBUTE_MAP_DEFAULT(crashCount, crash_count, @(LCKEXCContinounsCrashCount))
             };
}

@end
