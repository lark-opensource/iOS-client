//
//  BDXBridgeCanIUseMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/10.
//

#import "BDXBridgeCanIUseMethod.h"

@implementation BDXBridgeCanIUseMethod

- (NSString *)methodName
{
    return @"x.canIUse";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return BDXBridgeCanIUseMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeCanIUseMethodResultModel.class;
}

@end

@implementation BDXBridgeCanIUseMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"method": @"method",
    };
}

@end

@implementation BDXBridgeCanIUseMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"isAvailable": @"isAvailable",
        @"params": @"params",
        @"results": @"results",
    };
}

@end
