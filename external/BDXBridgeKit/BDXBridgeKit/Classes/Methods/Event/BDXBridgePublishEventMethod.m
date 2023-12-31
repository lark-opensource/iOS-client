//
//  BDXBridgePublishEventMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/4.
//

#import "BDXBridgePublishEventMethod.h"

@implementation BDXBridgePublishEventMethod

- (NSString *)methodName
{
    return @"x.publishEvent";
}

- (Class)paramModelClass
{
    return BDXBridgePublishEventMethodParamModel.class;
}

@end

@implementation BDXBridgePublishEventMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"eventName": @"eventName",
        @"params": @"params",
        @"timestamp": @"timestamp",
    };
}

@end
