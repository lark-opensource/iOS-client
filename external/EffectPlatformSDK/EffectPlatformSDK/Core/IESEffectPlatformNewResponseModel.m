//
//  IESEffectPlatformNewResponseModel.m
//  Pods
//
//  Created by li xingdong on 2019/4/8.
//

#import "IESEffectPlatformNewResponseModel.h"
#import <EffectPlatformSDK/EffectPlatform.h>

@interface IESEffectPlatformNewResponseModel()
@property (nonatomic, copy) NSString *version;
@property (nonatomic, copy) NSString *defaultFrontFilterID;
@property (nonatomic, copy) NSString *defaultRearFilterID;
@property (nonatomic, copy) IESCategoryEffectsModel *categoryEffects;
@property (nonatomic, copy) NSArray <IESCategoryModel *> *categories;
@property (nonatomic, strong) IESPlatformPanelModel *panel;
@property (nonatomic, copy) NSMutableDictionary <NSString *, IESEffectModel *> *effectsMap;
@property (nonatomic, assign) BOOL needReprocessEffects;
@property (nonatomic, copy) NSString *recId;

@end

@implementation IESEffectPlatformNewResponseModel

+ (NSDictionary *)JSONKeyPathsByPropertyKey
{
    return @{
             @"version": @"version",
             @"defaultFrontFilterID": @"front_effect",
             @"defaultRearFilterID": @"rear_effect",
             @"urlPrefix": @"url_prefix",
             @"categoryEffects": @"category_effects",
             @"categories": @"category_list",
             @"categorySampleEffects" : @"category_effect_list",
             @"panel": @"panel",
             @"recId": @"extra.rec_id",
             @"videoCategoryEffects" : @"category_effects_theme",
    };
}

- (NSArray<IESCategoryModel *> *)categories
{
    if (!_categories || ![_categories isKindOfClass:[NSArray class]]) {
        return nil;
    }
    return _categories;
}

- (void)setPanelName:(NSString *)panelName {
    [self.categoryEffects.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.panelName = panelName;
    }];
    [self.categoryEffects.collection enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.panelName = panelName;
    }];
    [self.categoryEffects.bindEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.panelName = panelName;
    }];
    [self.categorySampleEffects enumerateObjectsUsingBlock:^(IESCategorySampleEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.effect.panelName = panelName;
    }];
}

- (void)preProcessEffects
{
    // 使用response中的url_prefix和file_uri,icon_uri生成fileDownloadURL，iconDownloadURL
    if ([EffectPlatform sharedInstance].enableReducedEffectList) {
        NSArray<NSString *> *urlPrefix = self.urlPrefix;
        [self.categoryEffects.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj setURLPrefix:urlPrefix];
        }];
        [self.categoryEffects.collection enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj setURLPrefix:urlPrefix];
        }];
        [self.categoryEffects.bindEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj setURLPrefix:urlPrefix];
        }];
        [self.categorySampleEffects enumerateObjectsUsingBlock:^(IESCategorySampleEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj.effect setURLPrefix:urlPrefix];
        }];
    }
    
    if (self.recId.length > 0) {
        [self.categoryEffects.effects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.recId = self.recId;
        }];
        [self.categoryEffects.collection enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.recId = self.recId;
        }];
        [self.categoryEffects.bindEffects enumerateObjectsUsingBlock:^(IESEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.recId = self.recId;
        }];
        [self.categorySampleEffects enumerateObjectsUsingBlock:^(IESCategorySampleEffectModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.effect.recId = self.recId;
        }];
    }
    
    for (IESEffectModel *effect in _categoryEffects.effects) {
        if ([effect isKindOfClass:[IESEffectModel class]] && !effect.childrenEffects) {
            [effect updateChildrenEffectsWithCollection:_categoryEffects.collection];
        }
        if (effect.effectIdentifier && effect) {
            self.effectsMap[effect.effectIdentifier] = effect;
        }
    }

    for (IESCategoryModel *category in self.categories) {
        if ([category.categoryKey isEqualToString:self.categoryEffects.categoryKey]) {
            [category updateEffects:self.categoryEffects.effects collection:self.categoryEffects.collection];
        }
    }
}

- (NSMutableDictionary<NSString *,IESEffectModel *> *)effectsMap
{
    if (!_effectsMap) {
        _effectsMap = [@{} mutableCopy];
    }
    return _effectsMap;
}

+ (NSValueTransformer *)JSONTransformerForKey:(NSString *)key {
    if ([key isEqualToString:@"collection"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESEffectModel class]];
    } else if ([key isEqualToString:@"categoryEffects"]) {
        return [MTLJSONAdapter transformerForModelPropertiesOfClass:[IESCategoryEffectsModel class]];
    } else if([key isEqualToString:@"categories"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESCategoryModel class]];
    } else if ([key isEqualToString:@"panel"]) {
        return [MTLJSONAdapter transformerForModelPropertiesOfClass:[IESPlatformPanelModel class]];
    } else if ([key isEqualToString:@"categorySampleEffects"]) {
        return [MTLJSONAdapter arrayTransformerWithModelClass:[IESCategorySampleEffectModel class]];
    } else if ([key isEqualToString:@"videoCategoryEffects"]) {
        return [MTLJSONAdapter dictionaryTransformerWithModelClass:IESCategoryVideoEffectsModel.class];
    }
    return nil;
}

@end
