//
//  IESUserUsedStickerResponseModel.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/10.
//

#import "IESUserUsedStickerResponseModel.h"

@implementation IESUserUsedStickerResponseModel

- (instancetype)initWithDictionary:(NSDictionary *)dictionaryValue error:(NSError *__autoreleasing *)error {
    if (self = [super initWithDictionary:dictionaryValue error:error]) {
        if (self.collection.count > 0) {
            NSMutableDictionary<NSString *, IESEffectModel *> *dic = [[NSMutableDictionary alloc] initWithCapacity:self.collection.count];
            for (IESEffectModel *effect in self.collection) {
                if ([effect.effectIdentifier isKindOfClass:[NSString class]] && effect.effectIdentifier.length) {
                    dic[effect.effectIdentifier] = effect;
                }
            }
            for (IESEffectModel *effect in self.effects) {
                [effect updateChildrenEffectsWithCollectionDictionary:dic];
            }
        }
    }
    return self;
}

+ (NSDictionary *)JSONKeyPathsByPropertyKey {
    return @{@"effects": @"data",
             @"collection": @"collection"};
}

+ (NSValueTransformer *)effectsJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
}

+ (NSValueTransformer *)collectionJSONTransformer {
    return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
}

@end
