//
//  BDXBridgeShowToastMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeShowToastMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeShowToastMethod

- (NSString *)methodName
{
    return @"x.showToast";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)paramModelClass
{
    return BDXBridgeShowToastMethodParamModel.class;
}

@end

@implementation BDXBridgeShowToastMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"message": @"message",
        @"type": @"type",
        @"duration": @"duration",
    };
}

+ (NSValueTransformer *)typeJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"success": @(BDXBridgeToastTypeSuccess),
        @"error": @(BDXBridgeToastTypeError),
    }];
}

@end
