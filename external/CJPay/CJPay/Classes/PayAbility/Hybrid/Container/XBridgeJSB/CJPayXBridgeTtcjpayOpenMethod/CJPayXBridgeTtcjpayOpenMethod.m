//
//  CJPayXBridgeTtcjpayOpenMethod.m
//  BDXBridgeKit
//
// ❗️❗️ DON'T CHANGE THIS FILE CONTENT ❗️❗️
//

#import "CJPayXBridgeTtcjpayOpenMethod.h"

#pragma mark - Method

@implementation CJPayXBridgeTtcjpayOpenMethod

- (NSString *)methodName
{
    return @"ttcjpay.open";
}
- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePrivate;
}

- (Class)paramModelClass
{
    return CJPayXBridgeTtcjpayOpenMethodParamModel.class;
}


+ (NSDictionary *)metaInfo
{
    return @{
        @"TicketID": @"27510"
    };
}
@end

#pragma mark - Param

@implementation CJPayXBridgeTtcjpayOpenMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"scheme": @"scheme",

    };
}
+ (NSSet<NSString *> *)requiredKeyPaths
{
    return [NSSet setWithArray:@[@"scheme",]];
}

@end


