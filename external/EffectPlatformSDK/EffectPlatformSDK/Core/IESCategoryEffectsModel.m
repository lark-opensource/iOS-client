//
//  IESCategoryEffectsModel.m
//  Pods
//
//  Created by li xingdong on 2019/4/8.
//

#import "IESCategoryEffectsModel.h"

@interface IESCategoryEffectsModel()

@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *categoryKey;
@property (nonatomic, copy) NSArray <IESEffectModel *> *collection;
@property (nonatomic, copy) NSArray <IESEffectModel *> *effects;
@property (nonatomic, copy) NSMutableDictionary <NSString *, IESEffectModel *> *effectsMap;
@property (nonatomic, assign) BOOL hasMore;
@property (nonatomic, assign) NSInteger cursor;
@property (nonatomic, assign) NSInteger sortingPosition;

@end

@implementation IESCategoryEffectsModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"version": @"version",
             @"categoryKey": @"category_key",
             @"collection": @"collection",
             @"effects": @"effects",
             @"hasMore": @"has_more",
             @"cursor": @"cursor",
             @"sortingPosition": @"sorting_position",
             @"bindEffects": @"bind_effects"
             };
}

- (NSArray<IESEffectModel *> *)effects
{
    if (!_effects || ![_effects isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return _effects;
}

- (NSMutableDictionary<NSString *,IESEffectModel *> *)effectsMap
{
    if (!_effectsMap) {
        _effectsMap = [@{} mutableCopy];
    }
    return _effectsMap;
}

- (NSArray *)downloadedEffects
{
    return [self.effects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(IESEffectModel *model, NSDictionary<NSString *,id> * _Nullable bindings) {
        return model.downloaded;
    }]];
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
    if ([key isEqualToString:@"collection"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
    } else if ([key isEqualToString:@"effects"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
    } else if ([key isEqualToString:@"bindEffects"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
    }
    return nil;
}

@end
