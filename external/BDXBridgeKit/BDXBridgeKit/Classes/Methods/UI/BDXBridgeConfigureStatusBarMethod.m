//
//  BDXBridgeConfigureStatusBarMethod.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2021/3/15.
//

#import "BDXBridgeConfigureStatusBarMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeConfigureStatusBarMethod

- (NSString *)methodName
{
    return @"x.configureStatusBar";
}

- (BDXBridgeAuthType)authType
{
    return BDXBridgeAuthTypeProtected;
}

- (Class)paramModelClass
{
    return BDXBridgeConfigureStatusBarMethodParamModel.class;
}

@end

@implementation BDXBridgeConfigureStatusBarMethodParamModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        _visible = YES;
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"style": @"style",
        @"visible": @"visible",
        @"backgroundColor": @"backgroundColor",
    };
}

+ (NSValueTransformer *)styleJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"light": @(BDXBridgeStatusStyleLight),
        @"dark": @(BDXBridgeStatusStyleDark),
    }];
}

+ (NSValueTransformer *)backgroundColorJSONTransformer
{
    return [BDXBridgeCustomValueTransformer colorTransformer];
}

@end

