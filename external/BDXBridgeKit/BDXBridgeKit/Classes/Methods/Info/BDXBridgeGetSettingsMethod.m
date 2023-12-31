//
//  BDXBridgeGetSettingsMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/7/10.
//

#import "BDXBridgeGetSettingsMethod.h"

@implementation BDXBridgeGetSettingsMethod

- (NSString *)methodName
{
    return @"x.getSettings";
}

- (Class)paramModelClass
{
    return BDXBridgeGetSettingsMethodParamModel.class;
}

- (Class)resultModelClass
{
    return BDXBridgeGetSettingsMethodResultModel.class;
}

@end

@implementation BDXBridgeGetSettingsMethodParamKeyModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"key": @"key",
        @"type": @"type",
    };
}

@end

@implementation BDXBridgeGetSettingsMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"keys": @"keys",
    };
}

+ (NSValueTransformer *)keysJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:BDXBridgeGetSettingsMethodParamKeyModel.class];
}

@end

@implementation BDXBridgeGetSettingsMethodResultModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"settings": @"settings",
    };
}

@end
