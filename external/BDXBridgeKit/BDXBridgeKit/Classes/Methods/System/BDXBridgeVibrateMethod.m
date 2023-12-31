//
//  BDXBridgeVibrateMethod.m
//  BDXBridgeKit
//
//  Created by yihan on 2021/2/28.
//

#import "BDXBridgeVibrateMethod.h"
#import "BDXBridgeCustomValueTransformer.h"

@implementation BDXBridgeVibrateMethod

- (NSString *)methodName
{
    return @"x.vibrate";
}

- (Class)paramModelClass
{
    return BDXBridgeVibrateMethodParamModel.class;
}

@end

@implementation BDXBridgeVibrateMethodParamModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"duration": @"duration",
        @"style": @"style",
    };
}

+ (NSValueTransformer *)styleJSONTransformer
{
    return [BDXBridgeCustomValueTransformer enumTransformerWithDictionary:@{
        @"light": @(BDXBridgeVibrationStyleLight),
        @"medium": @(BDXBridgeVibrationStyleMedium),
        @"heavy": @(BDXBridgeVibrationStyleHeavy), 
    }];
}

@end
