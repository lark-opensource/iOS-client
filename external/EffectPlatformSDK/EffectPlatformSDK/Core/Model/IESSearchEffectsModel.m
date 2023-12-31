//
//  IESSearchEffectsModel.m
//  EffectPlatformSDK
//
//  Created by pengzhenhuan on 2021/5/31.
//

#import "IESSearchEffectsModel.h"

@implementation IESSearchEffectsModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{
        @"cursor" : @"cursor",
        @"hasMore" : @"has_more",
        @"searchID" : @"search_id",
        @"searchTips" : @"search_tips",
        @"isUseHot" : @"use_hot",
        @"effects" : @"effects",
        @"collection" : @"collection",
        @"bindEffects" : @"bind_effects"
    };
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
    if ([key isEqualToString:@"effects"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
    } else if ([key isEqualToString:@"collection"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
    } else if ([key isEqualToString:@"bindEffects"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
    }
    return nil;
}

- (void)updateEffects {
    if (self.collection.count > 0) {
        for (IESEffectModel *effect in self.effects) {
            [effect updateChildrenEffectsWithCollection:self.collection];
        }
    }
}

@end
