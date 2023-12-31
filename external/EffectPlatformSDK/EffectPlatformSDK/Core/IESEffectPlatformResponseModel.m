//
//  IESEffectPlatformResponseModel.m
//  EffectPlatformSDK
//
//  Created by ziyu.li on 2018/2/24.
//

#import "IESEffectPlatformResponseModel.h"
#import <EffectPlatformSDK/EffectPlatform.h>

@interface IESEffectPlatformResponseModel()
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *defaultFrontFilterID;
@property (nonatomic, copy) NSString *defaultRearFilterID;
@property (nonatomic, copy) NSArray <IESEffectModel *> *collection;
@property (nonatomic, copy) NSArray <IESEffectModel *> *effects;
@property (nonatomic, copy) NSArray <IESCategoryModel *> *categories;
@property (nonatomic, strong) IESPlatformPanelModel *panel;
@property (nonatomic, copy) NSMutableDictionary <NSString *, IESEffectModel *> *effectsMap;
@property (nonatomic, assign) BOOL needReprocessEffects;

@end

@implementation IESEffectPlatformResponseModel
+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"version": @"version",
             @"defaultFrontFilterID": @"front_effect_id",
             @"defaultRearFilterID": @"rear_effect_id",
             @"urlPrefix": @"url_prefix",
             @"collection": @"collection",
             @"effects": @"effects",
             @"categories": @"category",
             @"panel": @"panel",
             @"requestID" : @"requestID",
             };
}

- (NSArray<IESCategoryModel *> *)categories
{
    if (!_categories || ![_categories isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return _categories;
}

- (NSArray<IESEffectModel *> *)effects
{
    if (!_effects || ![_effects isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return _effects;
}

- (void)preProcessEffects
{
    // 使用response中的url_prefix和file_uri,icon_uri生成fileDownloadURL，iconDownloadURL
    if ([EffectPlatform sharedInstance].enableReducedEffectList) {
        NSArray<NSString *> *urlPrefix = self.urlPrefix;
        [self.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj setURLPrefix:urlPrefix];
        }];
        [self.collection enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj setURLPrefix:urlPrefix];
        }];
    }
    
    for (IESEffectModel *effect in _effects) {
        if ([effect isKindOfClass:[IESEffectModel class]] && !effect.childrenEffects) {
            [effect updateChildrenEffectsWithCollection:self.collection];
        }
        if (effect.effectIdentifier && effect) {
            self.effectsMap[effect.effectIdentifier] = effect;
        }
    }
    
    for (IESCategoryModel *category in self.categories) {
        if (category.effects.count <= 0) {
            if ([category isKindOfClass:[IESCategoryModel class]] && !category.effects) {
                [category fillEffectsWithEffectsMap:self.effectsMap];
            }
        }
    }
}

- (void)setPanelName:(NSString *)panelName {
    [self.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.panelName = panelName;
    }];
    [self.collection enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.panelName = panelName;
    }];
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
    }
    else if([key isEqualToString:@"categories"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESCategoryModel class]];
    }
    else if ([key isEqualToString:@"panel"]) {
        return [MTLJSONAdapter transformerForModelPropertiesOfClass:[IESPlatformPanelModel class]];
    }
    return nil;
}

- (id)copyWithZone:(NSZone *)zone {
    NSError *error;
    NSDictionary *dic = [MTLJSONAdapter JSONDictionaryFromModel:self error:&error];
    if (error) {
        return nil;
    }
    IESEffectPlatformResponseModel *copy = [MTLJSONAdapter modelOfClass:[self class] fromJSONDictionary:dic error:&error];
    return copy;
}

@end
