//
//  BDXBridgeSubscribeEventMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/4.
//

#import "BDXBridgeSubscribeEventMethod.h"

@implementation BDXBridgeSubscribeEventMethod

- (NSString *)methodName
{
    return @"x.subscribeEvent";
}

- (Class)paramModelClass
{
    return BDXBridgeSubscribeEventMethodParamModel.class;
}

@end

@implementation BDXBridgeSubscribeEventMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"eventName": @"eventName",
        @"timestamp": @"timestamp",
    };
}

@end
