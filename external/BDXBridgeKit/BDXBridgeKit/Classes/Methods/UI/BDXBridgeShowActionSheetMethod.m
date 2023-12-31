//
//  BDXBridgeShowActionSheetMethod.m
//  BDXBridgeKit
//
//  Created by suixudong on 2021/4/2.
//

#import "BDXBridgeShowActionSheetMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeShowActionSheetMethod

- (NSString *)methodName
{
    return @"x.showActionSheet";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypePublic;
}

- (Class)paramModelClass
{
    return BDXBridgeShowActionSheetMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeShowActionSheetMethodResultModel.class;
}

@end

#pragma mark - Param

@implementation BDXBridgeShowActionSheetMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"title": @"title",
        @"subtitle": @"subtitle",
        @"actions" : @"actions",
    };
}

+ (NSValueTransformer *)actionsJSONTransformer
{
    return [NSValueTransformer mtl_JSONArrayTransformerWithModelClass:[BDXBridgeActionSheetActions class]];
}

@end

@implementation BDXBridgeActionSheetActions

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"title": @"title",
        @"subtitle": @"subtitle",
        @"type" : @"type",
    };
}

+ (NSValueTransformer *)typeJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"default": @(BDXBridgeActionSheetActionsTypeDefault),
        @"warn": @(BDXBridgeActionSheetActionsTypeWarn),
    }];
}

@end

#pragma mark - Result

@implementation BDXBridgeActionSheetDetail

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"index": @"index",
    };
}

@end

@implementation BDXBridgeShowActionSheetMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"action": @"action",
        @"detail": @"detail",
    };
}

+ (NSValueTransformer *)actionJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"select": @(BDXBridgeActionSheetActionTypeSelect),
        @"dismiss": @(BDXBridgeActionSheetActionTypeDismiss),
    }];
}

@end
