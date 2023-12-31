//
//  BDXBridgeSendSMSMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeSendSMSMethod.h"

@implementation BDXBridgeSendSMSMethod

- (NSString *)methodName
{
    return @"x.sendSMS";
}

- (Class)paramModelClass
{
    return BDXBridgeSendSMSMethodParamModel.class;
}

@end

@implementation BDXBridgeSendSMSMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"phoneNumber": @"phoneNumber",
        @"content": @"content",
    };
}

@end
