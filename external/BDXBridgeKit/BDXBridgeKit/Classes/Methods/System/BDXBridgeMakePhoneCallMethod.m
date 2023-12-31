//
//  BDXBridgeMakePhoneCallMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeMakePhoneCallMethod.h"

@implementation BDXBridgeMakePhoneCallMethod

- (NSString *)methodName
{
    return @"x.makePhoneCall";
}

- (Class)paramModelClass
{
    return BDXBridgeMakePhoneCallMethodParamModel.class;
}

@end

@implementation BDXBridgeMakePhoneCallMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"phoneNumber": @"phoneNumber",
    };
}

@end
