//
//  AWEInteractionPOIStickerModel.m
//  CameraClient-Pods-CameraClient
//
//  Created by yangying on 2021/3/22.
//

#import "AWEInteractionPOIStickerModel.h"

#import <EffectPlatformSDK/IESEffectModel.h>

@implementation AWEInteractionModernPOIStickerInfoModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"currentEffectIndex" : @"currentEffectIndex",
        @"currentPath" : @"currentPath",
        @"effects" : @"effects"
    };
}

+ (NSValueTransformer *)effectsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:IESEffectModel.class];
}

@end

@implementation AWEInteractionPOIStickerModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    NSMutableDictionary *keyPathDict = [NSMutableDictionary dictionaryWithDictionary:[[[AWEInteractionPOIStickerModel class] superclass] JSONKeyPathsByPropertyKey]];
    [keyPathDict addEntriesFromDictionary:@{
        @"poiInfo"    : @"poi_info",
        @"poiStyleInfo" : @"poiStyleInfo",
    }];
    return keyPathDict;
}

- (NSInteger)indexFromType
{
    return 0;
}

@end
