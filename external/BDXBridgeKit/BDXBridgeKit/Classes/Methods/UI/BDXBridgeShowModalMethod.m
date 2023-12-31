//
//  BDXBridgeShowModalMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/6.
//

#import "BDXBridgeShowModalMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeShowModalMethod

- (NSString *)methodName
{
    return @"x.showModal";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)paramModelClass
{
    return BDXBridgeShowModalMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeShowModalMethodResultModel.class;
}

@end

@implementation BDXBridgeShowModalMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"title": @"title",
        @"content": @"content",
        @"showCancel": @"showCancel",
        @"cancelText": @"cancelText",
        @"cancelColor": @"cancelColor",
        @"confirmText": @"confirmText",
        @"confirmColor": @"confirmColor",
        @"tapMaskToDismiss": @"tapMaskToDismiss",
    };
}

+ (NSValueTransformer *)cancelColorJSONTransformer
{
    return [BDXBridgeCustomValueTransformer colorTransformer];
}

+ (NSValueTransformer *)confirmColorJSONTransformer
{
    return [BDXBridgeCustomValueTransformer colorTransformer];
}

@end

@implementation BDXBridgeShowModalMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"action": @"action",
    };
}

+ (NSValueTransformer *)actionJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"confirm": @(BDXBridgeModalActionTypeConfirm),
        @"cancel": @(BDXBridgeModalActionTypeCancel),
        @"mask": @(BDXBridgeModalActionTypeMask),
    }];
}

@end
