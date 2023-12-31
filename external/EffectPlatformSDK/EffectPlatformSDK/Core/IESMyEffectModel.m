//
//  IESMyEffectModel.m
//  EffectPlatformSDK
//
//  Created by leizh007 on 2018/4/13.
//

#import "IESMyEffectModel.h"
#import <Mantle/MTLJSONAdapter.h>

@interface IESMyEffectModel () <MTLJSONSerializing>

@property(nonatomic, copy) NSArray<IESEffectModel *> *collection;

@end

@implementation IESMyEffectModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"type": @"type",
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
