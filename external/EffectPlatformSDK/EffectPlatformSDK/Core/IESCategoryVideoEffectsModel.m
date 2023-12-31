//
//  IESCategoryVideoEffectsModel.m
//  Indexer
//
//  Created by Fengfanhua.byte on 2021/12/10.
//

#import "IESCategoryVideoEffectsModel.h"

@implementation IESCategoryVideoEffectsModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
        @"version" : @"version",
        @"categoryKey" : @"category_key",
        @"collection" : @"collection",
        @"effects" : @"effect_with_video_url_list",
        @"bindEffects" : @"bind_effects"
    };
}

+ (NSValueTransformer *)effectsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:IESVideoEffectWrapperModel.class];
}

+ (NSValueTransformer *)collectionJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:IESEffectModel.class];
}

+ (NSValueTransformer *)bindEffectsJSONTransformer
{
    return [MTLJSONAdapter arrayTransformerWithModelClass:IESEffectModel.class];
}

@end
