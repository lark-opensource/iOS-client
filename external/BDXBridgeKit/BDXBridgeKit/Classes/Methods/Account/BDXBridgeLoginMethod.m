//
//  BDXBridgeLoginMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/24.
//

#import "BDXBridgeLoginMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeLoginMethod

- (NSString *)methodName
{
    return @"x.login";
}

- (Class)paramModelClass
{
    return BDXBridgeLoginMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeLoginMethodResultModel.class;
}

@end

@implementation BDXBridgeLoginMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"context": @"context",
    };
}

@end

@implementation BDXBridgeLoginMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"status": @"status",
    };
}

+ (NSValueTransformer *)statusJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"loggedIn": @(BDXBridgeLoginStatusLoggedIn),
        @"cancelled": @(BDXBridgeLoginStatusCancelled),
    }];
}

@end
