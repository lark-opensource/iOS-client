//
//  BDXBridgeCloseMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/13.
//

#import "BDXBridgeCloseMethod.h"

@implementation BDXBridgeCloseMethod

- (NSString *)methodName
{
    return @"x.close";
}

- (Class)paramModelClass
{
    return BDXBridgeCloseMethodParamModel.class;
}

@end

@implementation BDXBridgeCloseMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"containerID": @"containerID",
        @"animated": @"animated",
    };
}

@end

