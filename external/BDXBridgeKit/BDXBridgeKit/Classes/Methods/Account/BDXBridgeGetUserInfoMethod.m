//
//  BDXBridgeGetUserInfoMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/29.
//

#import "BDXBridgeGetUserInfoMethod.h"

@implementation BDXBridgeGetUserInfoMethod

- (NSString *)methodName
{
    return @"x.getUserInfo";
}

- (Class)resultModelClass
{
    return BDXBridgeGetUserInfoMethodResultModel.class;
}

@end

@implementation BDXBridgeGetUserInfoMethodResultUserInfoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"userID": @"userID",
        @"secUserID": @"secUserID",
        @"uniqueID": @"uniqueID",
        @"nickname": @"nickname",
        @"avatarURL": @"avatarURL",
        @"hasBoundPhone": @"hasBoundPhone",
    };
}

@end

@implementation BDXBridgeGetUserInfoMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"hasLoggedIn": @"hasLoggedIn",
        @"userInfo": @"userInfo",
    };
}

@end
