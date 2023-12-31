//
//  IESEffectTopListResponseModel.m
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/10/18.
//

#import "IESEffectTopListResponseModel.h"

@interface IESEffectTopListResponseModel()

@property(nonatomic, copy) NSArray<IESEffectModel *> *collection;

@end

@implementation IESEffectTopListResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"cursor": @"cursor",
             @"lastUpdatedTime": @"last_updated_at",
             @"effects": @"effects",
             @"bindEffects": @"bind_effects",
             @"collection": @"collection"
             };
}

- (void)updateEffects
{
    if (self.collection && [self.collection isKindOfClass:[NSArray class]] && self.collection.count > 0) {
        for (IESEffectModel *effect in self.effects) {
            [effect updateChildrenEffectsWithCollection:self.collection];
        }
    }
}

+ (NSValueTransformer *)effectsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
}

+ (NSValueTransformer *)bindEffectsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
}

+ (NSValueTransformer *)collectionJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
}


@end
