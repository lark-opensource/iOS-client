//
//  BDXBridgeOpenMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/13.
//

#import "BDXBridgeOpenMethod.h"

@implementation BDXBridgeOpenMethod

- (NSString *)methodName
{
    return @"x.open";
}

- (Class)paramModelClass
{
    return BDXBridgeOpenMethodParamModel.class;
}

@end

@implementation BDXBridgeOpenMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"schema": @"schema",
        @"replace": @"replace",
        @"useSysBrowser": @"useSysBrowser",
    };
}

@end

