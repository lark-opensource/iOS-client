//
//  BDREPrivacyCommon.m
//  BDRuleEngine
//
//  Created by Chengmin Zhang on 2022/6/27.
//

#import "BDREPrivacyCommon.h"
#import "BDRuleParameterService.h"
#import "BDRuleEngineLogger.h"

static CFAbsoluteTime lastEnterBackgroundTime = -1;
static BOOL isBackground = NO;

@implementation BDREPrivacyCommon

+ (void)registerExtension
{
    [self _registerAppStatus];
    [self _registerAppColdLaunch];
    [self _registerAppHotLaunchTime];
    [self _registerOSVersion];
}

+ (void)appWillEnterForeground
{
    lastEnterBackgroundTime = 0;
    isBackground = NO;
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[PrivacyCommon] will enter foreground at %lf", lastEnterBackgroundTime];
    }];
}

+ (void)appDidEnterBackground
{
    lastEnterBackgroundTime = CFAbsoluteTimeGetCurrent();
    isBackground = YES;
    [BDRuleEngineLogger info:^NSString * _Nonnull{
        return [NSString stringWithFormat:@"[PrivacyCommon] enter background at %lf", lastEnterBackgroundTime];
    }];
}

#pragma mark - Private
+ (void)_registerAppStatus
{
    [BDRuleParameterService registerParameterWithKey:@"app_status" type:BDRuleParameterTypeString builder:^id _Nonnull(id<BDRuleParameterBuilderProtocol> fetcher) {
        if (isBackground) {
            if (lastEnterBackgroundTime <= 0) {
                [BDRuleEngineLogger error:^NSString * _Nonnull{
                    return @"[PrivacyCommon] current state is backgroud but didn't receive notification";
                }];
            }
            return @"background";
        }
        return @"foreground";
    }];
    [BDRuleParameterService registerParameterWithKey:@"enter_background_duration" type:BDRuleParameterTypeNumberOrBool builder:^id _Nonnull(id<BDRuleParameterBuilderProtocol> fetcher) {
        if (isBackground) {
            if (lastEnterBackgroundTime <= 0) {
                [BDRuleEngineLogger error:^NSString * _Nonnull{
                    return @"current state is backgroud but didn't receive notification";
                }];
            }
            CFTimeInterval duration = (CFAbsoluteTimeGetCurrent() - lastEnterBackgroundTime) * 1000;
            return @(duration);
        }
        return @0;
    }];
}

+ (void)_registerAppColdLaunch
{
    static CFTimeInterval kAppColdLaunchTime;
    kAppColdLaunchTime = CACurrentMediaTime();
    [BDRuleParameterService registerParameterWithKey:@"cold_launch_duration" type:BDRuleParameterTypeNumberOrBool builder:^id _Nonnull(id<BDRuleParameterBuilderProtocol> fetcher) {
        return @((CACurrentMediaTime() - kAppColdLaunchTime) * 1000);
    }];
}

+ (void)_registerAppHotLaunchTime
{
    static CFTimeInterval kAppHotLaunchTime;
    kAppHotLaunchTime = CACurrentMediaTime();
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                        object:nil
                         queue:nil
                    usingBlock:^(NSNotification * _Nonnull note) {
        CFTimeInterval currentTime = CACurrentMediaTime();
        kAppHotLaunchTime = currentTime;
    }];
    [BDRuleParameterService registerParameterWithKey:@"hot_launch_duration" type:BDRuleParameterTypeNumberOrBool builder:^id _Nonnull(id<BDRuleParameterBuilderProtocol> fetcher) {
        return @((CACurrentMediaTime() - kAppHotLaunchTime) * 1000);
    }];
}

+ (void)_registerOSVersion
{
    [BDRuleParameterService registerParameterWithKey:@"os_version" type:BDRuleParameterTypeString builder:^id _Nonnull(id<BDRuleParameterBuilderProtocol> fetcher) {
        return [[UIDevice currentDevice] systemVersion];
    }];
}

@end
