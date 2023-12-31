//
//  BDPPluginApplicationImpl.m
//  TTMicroAppImpl
//
//  Created by MacPu on 2019/1/9.
//

#import "BDPPluginApplicationImpl.h"
#import "EERoute.h"
#import <OPFoundation/EMASandBoxHelper.h>
#import <EEMicroAppSDK/EEMicroAppSDK-Swift.h>
#import <OPFoundation/BDPApplicationManager.h>
#import <OPFoundation/BDPTimorClient.h>

@interface BDPPluginApplicationImpl() <BDPApplicationPluginDelegate>

@end

@implementation BDPPluginApplicationImpl

+ (id<BDPBasePluginDelegate>)sharedPlugin
{
    static BDPPluginApplicationImpl *impl;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        impl = [[BDPPluginApplicationImpl alloc] init];
    });
    return impl;
}

- (NSDictionary *)bdp_registerApplicationInfo {
    id<EMAProtocol> delegate = [EMARouteProvider getEMADelegate];
    return @{
        BDPAppNameKey : delegate.appName ?: @"",
        BDPAppVersionKey :  ApplicationHelper.appVersion?: @"",
        BDPAppLanguageKey: ApplicationHelper.appLanguage ?: @""
    };
}

- (NSDictionary *)bdp_registerSceneInfo
{
    return @{
             @"in_mp": @(1037),                        // 小程序跳到小程序
             @"back_mp": @(1038),                      // 小程序返回小程序
             };
}

@end
