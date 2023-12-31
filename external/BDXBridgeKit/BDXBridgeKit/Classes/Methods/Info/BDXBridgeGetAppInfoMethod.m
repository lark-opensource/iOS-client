//
//  BDXBridgeGetAppInfoMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/17.
//

#import "BDXBridgeGetAppInfoMethod.h"

@implementation BDXBridgeGetAppInfoMethod

- (NSString *)methodName
{
    return @"x.getAppInfo";
}

- (Class)resultModelClass
{
    return BDXBridgeGetAppInfoMethodResultModel.class;
}

@end

@implementation BDXBridgeGetAppInfoMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"appID": @"appID",
        @"installID": @"installID",
        @"appName": @"appName",
        @"appVersion": @"appVersion",
        @"channel": @"channel",
        @"language": @"language",
        @"appTheme": @"appTheme",
        @"osVersion": @"osVersion",
        @"statusBarHeight": @"statusBarHeight",
        @"devicePlatform": @"devicePlatform",
        @"deviceModel": @"deviceModel",
        @"netType": @"netType",
        @"carrier": @"carrier",
        @"is32Bit": @"is32Bit",
        @"isTeenMode": @"isTeenMode",
    };
}

@end
