//
//  AWECoverTextDraftModel.m
//  CameraClient-Pods-Aweme
//
//  Created by Fengfanhua.byte on 2020/4/21.
//

#import "AWECoverTextModel.h"

@implementation AWECoverTextModel

- (NSArray<NSString *> *)texts
{
    if (!_texts) {
        return [NSArray array];
    }
    return _texts;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"isStoryText" : @"isStoryText",
        @"isNone" : @"isNone",
        @"texts" : @"texts",
        @"textModel" : @"textModel",
        @"textEffectId" : @"textEffectId",
        @"location" : @"location",
        @"cursorLoc" : @"cursorLoc"
    };
}

+ (NSValueTransformer *)locationJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEInteractionStickerLocationModel class]];
}

+ (NSValueTransformer *)textModelJSONTransformer
{
    return [MTLJSONAdapter dictionaryTransformerWithModelClass:[AWEStoryTextImageModel class]];
}

@end
