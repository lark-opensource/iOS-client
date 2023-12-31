//
//  BDXBridgeUnsubscribeEventMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/9/8.
//

#import "BDXBridgeUnsubscribeEventMethod.h"

@implementation BDXBridgeUnsubscribeEventMethod

- (NSString *)methodName
{
    return @"x.unsubscribeEvent";
}

- (Class)paramModelClass
{
    return BDXBridgeUnsubscribeEventMethodParamModel.class;
}

@end

@implementation BDXBridgeUnsubscribeEventMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"eventName": @"eventName",
    };
}

@end

