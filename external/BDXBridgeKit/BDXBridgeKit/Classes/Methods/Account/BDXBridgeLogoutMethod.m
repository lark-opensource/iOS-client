//
//  BDXBridgeLogoutMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/24.
//

#import "BDXBridgeLogoutMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeLogoutMethod

- (NSString *)methodName
{
    return @"x.logout";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeLogoutMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeLogoutMethodResultModel.class;
}

@end

@implementation BDXBridgeLogoutMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"context": @"context",
    };
}

@end

@implementation BDXBridgeLogoutMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"status": @"status",
    };
}

+ (NSValueTransformer *)statusJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"loggedOut": @(BDXBridgeLogoutStatusLoggedOut),
        @"cancelled": @(BDXBridgeLogoutStatusCancelled),
    }];
}

@end
