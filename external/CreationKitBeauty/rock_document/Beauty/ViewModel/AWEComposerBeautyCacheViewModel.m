//
//  AWEComposerBeautyCacheViewModel.m
//  CameraClient
//
//  Created by HuangHongsen on 2019/11/4.
//

#import <CreationKitBeauty/AWEComposerBeautyCacheViewModel.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import "CKBConfigKeyDefines.h"

static const NSInteger kAWEComposerBeautyForceAsFemaleCount = 3;

@interface AWEComposerBeautyCacheViewModel()

@property (nonatomic, strong) NSMutableDictionary *candidateCache;
@property (nonatomic, assign) AWEComposerBeautyGender currentGender;
@property (nonatomic, assign) AWEComposerBeautyCameraPosition cameraPosition;

@property (nonatomic,   copy, readwrite) NSString *businessName;
@property (nonatomic, strong, readwrite) AWEComposerBeautyCacheKeys *cacheKeysObj;
@end

@implementation AWEComposerBeautyCacheViewModel

/**
 Cache:
 1. applied effects - - > applied effects in EffectViewModel
 2. selected category - - > currentCategory  in EffectViewModel
 3. selected child effect of category
 4. switch mode of category
 5. selected child effect of effect
 */

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithBusinessName:(NSString *)businessName
{
    self = [super init];
    if (self) {
        _businessName = businessName;
        _cacheKeysObj = [[AWEComposerBeautyCacheKeys alloc] initWithBusinessName:_businessName];
        _currentGender = AWEComposerBeautyGenderWomen;
    }
    return self;
}

- (void)updateCurrentGender:(AWEComposerBeautyGender)gender cameraPosition:(AWEComposerBeautyCameraPosition)cameraPosition
{
    self.currentGender = gender;
    self.cameraPosition = cameraPosition;
}


#pragma mark - utils

- (NSString *)cacheIDSeparator
{
    return @"|-|";
}

- (NSNumber *)effectNumberForTag:(NSString *)tag
{
    if (tag.length == 0) {
        return nil;
    }
    NSString *key = [self.cacheKeysObj.effectConfigurationPrefix stringByAppendingString:tag];
    id number = [ACCCache() objectForKey:key];
    if ([number isKindOfClass:NSNumber.class]) {
        return number;
    }
    return nil;
}

- (float)effectValueForTag:(NSString *)tag
{
    NSNumber *number = [self effectNumberForTag:tag];
    if (number != nil) {
        return [number floatValue];
    } else {
        return 0;
    }
}

- (void)setEffectValue:(float)value forTag:(NSString *)tag
{
    if (tag.length == 0) {
        return;
    }
    NSString *key = [self.cacheKeysObj.effectConfigurationPrefix stringByAppendingString:tag];
    [ACCCache() setObject:@(value) forKey:key];
}

- (float)convertToRatioForEffectValue:(float)effectValue
                       withEffectItem:(AWEComposerBeautyEffectItem *)item
{
    if (effectValue > 0 && !ACC_FLOAT_EQUAL_ZERO(item.maxValue)) {
        return MIN(effectValue, item.maxValue) / item.maxValue;
    } else if (effectValue < 0  && item.minValue < 0.f) {
        return fabs(MAX(item.minValue, effectValue)) / item.minValue;
    }
    return 0.f;
}

- (float)convertToValueForRatio:(float)ratio
                 withEffectItem:(AWEComposerBeautyEffectItem *)item
{
    float normalRatio = MIN(ratio, 1.0);
    normalRatio = MAX(normalRatio, -1.0);
    float value = normalRatio * item.maxValue;
    if (normalRatio < 0.f && item.minValue < 0.f) {
        value = fabs(normalRatio) * item.minValue;
    }
    return value;
}

#pragma mark - cache key

// Rule: restoreid tag gender
- (NSString *)cacheKeyForEffectItem:(AWEComposerBeautyEffectItem *)effectItem
{
    return [self cacheKeyForEffectItem:effectItem gender:self.currentGender];
}

- (NSString *)cacheKeyForEffectItem:(AWEComposerBeautyEffectItem *)effectItem
                             gender:(AWEComposerBeautyGender)gender
{
    return [NSString stringWithFormat:@"%@-%@", [effectItem tagForCache], @(gender)];
}

// Rule: prefix + restoreid gender
- (NSString *)cacheKeyForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    return [self cacheKeyForEffect:effectWrapper gender:self.currentGender];
}

- (NSString *)cacheKeyForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                         gender:(AWEComposerBeautyGender)gender
{
    if ([effectWrapper isEffectSet] && !ACC_isEmptyString(effectWrapper.effect.resourceId)) {
        return [NSString stringWithFormat:@"%@%@-%@",
                self.cacheKeysObj.effectSetCachePrefix,
                effectWrapper.effect.resourceId,
                @(gender)];
    }
    return nil;
}

- (NSString *)cacheKeyForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    return [self cacheKeyForCategory:categoryWrapper gender:self.currentGender];
}

- (NSString *)cacheKeyForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                           gender:(AWEComposerBeautyGender)gender
{
    if (!ACC_isEmptyString(categoryWrapper.category.categoryIdentifier)) {
        return [NSString stringWithFormat:@"%@%@-%@",
                self.cacheKeysObj.categoryCachePrefix,
                categoryWrapper.category.categoryIdentifier,
                @(gender)];
    }
    return nil;
}

#pragma mark - switch on

- (void)setCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper switchOn:(BOOL)isOn
{
    if (!categoryWrapper) {
        return;
    }
    NSString *key = [self.cacheKeysObj.categorySwitchOnKey stringByAppendingString:categoryWrapper.category.categoryIdentifier];
    [ACCCache() setBool:isOn forKey:key];
}

- (BOOL)isCategorySwitchOn:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    if (!categoryWrapper) {
        return NO;
    }
    NSString *key = [self.cacheKeysObj.categorySwitchOnKey stringByAppendingString:categoryWrapper.category.categoryIdentifier];
    id number = [ACCCache() objectForKey:key];
    if ([number isKindOfClass:NSNumber.class]) {
        return [number boolValue];
    }
    // default is on
    return ACCConfigBool(kConfigBool_beauty_category_switch_default_value);
}

#pragma mark - candidate effect

- (void)updateCandidateChildEffect:(AWEComposerBeautyEffectWrapper *)childEffectWrapper
                   forParentItemID:(NSString *)parentItemID
{
    if (!self.candidateCache) {
        self.candidateCache = [NSMutableDictionary dictionary];
    }
    NSString *effectId = childEffectWrapper.effect.effectIdentifier;
    if (!childEffectWrapper.disableCache && !ACC_isEmptyString(effectId)) {
        [self.candidateCache setObject:effectId forKey:parentItemID];
    } else {
        [self.candidateCache removeObjectForKey:parentItemID];
    }
}

- (NSString *)cachedCandidateChildEffectIDForParentItemID:(NSString *)parentItemID
{
    if (ACC_isEmptyString(parentItemID)) {
        return nil;
    }
    return [self.candidateCache acc_stringValueForKey:parentItemID];
}

#pragma mark - Applied Effects -

- (NSArray <NSString *> *)appliedEffectsFromCache
{
    return [self appliedEffectsFromCacheForKey:[self cacheKeyForAppliedEffects]];
}

- (NSArray <NSString *> *)appliedEffectsFromCacheForGender:(AWEComposerBeautyGender)gender
{
    NSString *cacheKey = [self cachedKeyForAppliedEffectsOfGender:gender];
    return [self appliedEffectsFromCacheForKey:cacheKey];
}

- (NSArray <NSString *> *)appliedEffectsFromCacheForKey:(NSString *)cacheKey
{
    NSObject *obj = [ACCCache() objectForKey:cacheKey];
    NSMutableArray *cachedEffects = [NSMutableArray array];
    if (![obj isKindOfClass:[NSString class]]) {
        return [cachedEffects copy];
    }
    NSString *idStrings = (NSString *)obj;
    NSArray *effects = [idStrings componentsSeparatedByString:[self cacheIDSeparator]];
    for (NSObject *item in effects) {
        if ([item isKindOfClass:[NSString class]]) {
            NSString *cachedID = (NSString *)item;
            if (!ACC_isEmptyString(cachedID)) {
                [cachedEffects acc_addObject:cachedID];
            }
        }
    }
    return [cachedEffects copy];
}

#pragma mark cache of applied effects

- (NSString *)cacheKeyForAppliedEffects
{
    return [self cachedKeyForAppliedEffectsOfGender:self.currentGender];
}

- (NSString *)cachedKeyForAppliedEffectsOfGender:(AWEComposerBeautyGender)gender
{
    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@", self.cacheKeysObj.effectAppliedEffectsCacheKey, @(gender)];
    return cacheKey;
}

- (void)clearCachedAppliedEffects
{
    [ACCCache() removeObjectForKey:[self cachedKeyForAppliedEffectsOfGender:AWEComposerBeautyGenderWomen]];
    [ACCCache() removeObjectForKey:[self cachedKeyForAppliedEffectsOfGender:AWEComposerBeautyGenderMen]];
}

- (void)cacheAppliedEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)appliedEffects
{
    NSString *logInfo = [NSString stringWithFormat:@"===Composer: flush cache %@-%@：",
                         self.currentGender == AWEComposerBeautyGenderMen ? ACCLocalizedString(@"male", nil) : ACCLocalizedString(@"female", nil),
                         self.cameraPosition == AWEComposerBeautyCameraPositionFront ?  @"front" : @"back"];
    NSMutableArray *appliedEffectIDs = [NSMutableArray array];
    for (AWEComposerBeautyEffectWrapper *effectWrapper in appliedEffects) {
        if (!effectWrapper.disableCache) {
            logInfo = [logInfo stringByAppendingFormat:@"%@,", effectWrapper];
            if (effectWrapper.isFilter) {
                [appliedEffectIDs acc_addObject:self.cacheKeysObj.appliedFilterPlaceHolder];
            } else {
                if (!ACC_isEmptyString(effectWrapper.effect.resourceId)) {
                    [appliedEffectIDs acc_addObject:effectWrapper.effect.resourceId];
                }
            }
        }
    }
    ACCLog(@"%@", logInfo);
    [self cacheAppliedEffectsResourceIds:appliedEffectIDs forGender:self.currentGender];
}

- (void)cacheAppliedEffectsResourceIds:(NSArray<NSString *> *)resourceIds
                             forGender:(AWEComposerBeautyGender)gender
{
    NSString *appliedEffectIDString = [resourceIds componentsJoinedByString:[self cacheIDSeparator]];
    NSString *cacheKey = [self cachedKeyForAppliedEffectsOfGender:gender];
    [ACCCache() setObject:appliedEffectIDString forKey:cacheKey];
}


#pragma mark - PrimaryCategory -

- (NSString *)p_cacheKeyForChildCategoryIdOfCategory:(AWEComposerBeautyEffectCategoryWrapper *)cateogry
{
    NSString *key = [NSString stringWithFormat:@"%@-%@", self.cacheKeysObj.selectedChildCategoryCachePrefix, cateogry.category.categoryIdentifier];
    return key;
}

- (NSString *)p_cacheKeyForSelectedNoneOfCategory:(AWEComposerBeautyEffectCategoryWrapper *)cateogry
{
    NSString *key = [NSString stringWithFormat:@"%@-%@", self.cacheKeysObj.selectedChildCategoryCachePrefix, @"none"];
    return key;
}

- (void)cacheSelectedChildCategoryId:(NSString *)childCategoryId forParentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategory
{
    // selected
    NSString *cacheKey = [self p_cacheKeyForChildCategoryIdOfCategory:parentCategory];
    [ACCCache() setObject:childCategoryId forKey:cacheKey];
}

- (NSString *)cachedSelectedCategoryIdForParentCategory:(AWEComposerBeautyEffectCategoryWrapper *)parentCategory
{
    NSString *cacheKey = [self p_cacheKeyForChildCategoryIdOfCategory:parentCategory];
    return [ACCCache() stringForKey:cacheKey];
}


#pragma mark - Category -

#pragma mark cache selectedCategory

- (void)cacheSelectedCategory:(NSString *)categoryIdentifier
{
    if (ACC_isEmptyString(categoryIdentifier)) {
        return ;
    }
    [ACCCache() setObject:categoryIdentifier forKey:[self p_cacheKeyForCurrentTab]];
}

- (NSString *)cachedSelectedCategory
{
    return [ACCCache() objectForKey:[self p_cacheKeyForCurrentTab]];
}

- (NSString *)p_cacheKeyForCurrentTab
{
    return [NSString stringWithFormat:@"%@-%@", self.cacheKeysObj.panelLastSelectedTabIDKey, @(self.currentGender)];
}

#pragma mark update Category from cache

- (void)updateCategoryFromCache:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    [self updateCategoryFromCache:categoryWrapper multiSlider:NO gender:self.currentGender];
}

- (void)updateCategoryFromCache:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                    multiSlider:(BOOL)isMultiSlider
{
    [self updateCategoryFromCache:categoryWrapper multiSlider:isMultiSlider gender:self.currentGender];
}

// recover category data from cache
- (void)updateCategoryFromCache:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                    multiSlider:(BOOL)isMultiSlider
                         gender:(AWEComposerBeautyGender)gender
{
    // recover effects strength
    for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
        [self updateEffectWithCachedStrength:effectWrapper multiSlider:isMultiSlider gender:gender];
    }

    // recover selectedEffect and userSelectedEffect
    if (categoryWrapper.exclusive) {
        categoryWrapper.userSelectedEffect = nil;
        categoryWrapper.selectedEffect = nil;
        NSString *cacheKey = [self cacheKeyForCategory:categoryWrapper gender:gender];
        if (ACC_isEmptyString(cacheKey)) {
            return ;
        }
        NSString *appliedChildResourceID = [ACCCache() objectForKey:cacheKey];
        AWEComposerBeautyEffectWrapper *noneEffect = nil;
        AWEComposerBeautyEffectWrapper *defaultEffect = nil;
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            if (effectWrapper.isNone) {
                noneEffect = effectWrapper;
            }
            if (effectWrapper.isDefault) {
                defaultEffect = effectWrapper;
            }
            if ([effectWrapper.effect.resourceId isEqualToString:appliedChildResourceID]) {
                if (!effectWrapper.disableCache) {
                    categoryWrapper.selectedEffect = effectWrapper;
                }
            }
        }
        if (categoryWrapper.exclusive && !categoryWrapper.selectedEffect) {
            categoryWrapper.selectedEffect = defaultEffect ? : noneEffect;
        }
    }

    // if Primary
    if (categoryWrapper.isPrimaryCategory) {
        // recover selectedChildCategory, first we need to store the value we need
        NSString *categoryId = [self cachedSelectedCategoryIdForParentCategory:categoryWrapper];
        [categoryWrapper.childCategories enumerateObjectsUsingBlock:^(AWEComposerBeautyEffectCategoryWrapper * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.category.categoryIdentifier isEqualToString:categoryId]) {
                categoryWrapper.selectedChildCategory = obj;
                *stop = YES;
            }
        }];
        // recover each childCategory
        for (AWEComposerBeautyEffectCategoryWrapper *childCategroy in categoryWrapper.childCategories) {
            [self updateCategoryFromCache:childCategroy multiSlider:isMultiSlider gender:gender];
        }

    }
}

#pragma mark update appliedEffect for Category

- (void)updateAppliedEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    [self updateAppliedEffectForCategory:categoryWrapper gender:self.currentGender];
}

- (void)updateAppliedEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                                gender:(AWEComposerBeautyGender)gender
{
    if (ACC_isEmptyString(categoryWrapper.category.categoryIdentifier) || !categoryWrapper.exclusive) {
        return ;
    }
    NSString *cacheKey = [self cacheKeyForCategory:categoryWrapper gender:gender];
    if (!ACC_isEmptyString(cacheKey)) {
        AWEComposerBeautyEffectWrapper *selectedEffectWrapper = categoryWrapper.selectedEffect;
        if (!selectedEffectWrapper || ACC_isEmptyString(selectedEffectWrapper.effect.resourceId) || categoryWrapper.selectedEffect.disableCache) {
            [ACCCache() removeObjectForKey:cacheKey];
        } else {
            [ACCCache() setObject:selectedEffectWrapper.effect.resourceId forKey:cacheKey];
        }
    }
}

- (void)clearAppliedEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    if (ACC_isEmptyString(categoryWrapper.category.categoryIdentifier) || !categoryWrapper.exclusive) {
        return ;
    }
    NSString *cacheKey = [self cacheKeyForCategory:categoryWrapper];
    if (!ACC_isEmptyString(cacheKey)) {
        [ACCCache() removeObjectForKey:cacheKey];
    }
}


#pragma mark - Specific Effect -

#pragma mark ratio for specific effect

- (float)ratioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    return [self ratioForEffect:effectWrapper gender:self.currentGender];
}

- (float)ratioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                 gender:(AWEComposerBeautyGender)gender
{
    AWEComposerBeautyEffectItem *item = effectWrapper.items.firstObject;
    return [self ratioForEffectItem:item gender:gender];
}

- (float)ratioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                    tag:(NSString *)tag
{
    return [self ratioForEffect:effectWrapper tag:tag gender:self.currentGender];
}

- (float)ratioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                    tag:(NSString *)tag
                 gender:(AWEComposerBeautyGender)gender
{
    for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
        if ([item.tag isEqualToString:tag]) {
            NSNumber *effectNumber = [self effectNumberForTag:[self cacheKeyForEffectItem:item gender:gender]];
            
            if (effectNumber != nil) {
                return [self convertToRatioForEffectValue:[effectNumber floatValue] withEffectItem:item];
            }
        }
    }
    return [self ratioForEffect:effectWrapper gender:gender];
}


#pragma mark set retio for specific effect
// set ratio
- (void)setRatio:(float)ratio
       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self setRatio:ratio forEffect:effectWrapper gender:self.currentGender];
}

- (void)setRatio:(float)ratio
       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
          gender:(AWEComposerBeautyGender)gender
{
    for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
        float value = [self convertToValueForRatio:ratio withEffectItem:item];
        [self setEffectValue:value forTag:[self cacheKeyForEffectItem:item gender:gender]];
    }
}

- (void)setRatio:(float)ratio
       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
             tag:(NSString *)tag
{
    [self setRatio:ratio forEffect:effectWrapper tag:tag gender:self.currentGender];
}

- (void)setRatio:(float)ratio
       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
             tag:(NSString *)tag
          gender:(AWEComposerBeautyGender)gender
{
    BOOL tagFound = NO;
    for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
        if ([item.tag isEqualToString:tag]) {
            tagFound = YES;
            float value = [self convertToValueForRatio:ratio withEffectItem:item];
            [self setEffectValue:value forTag:[self cacheKeyForEffectItem:item gender:gender]];
            break;
        }
    }
    if (!tagFound) {
        [self setRatio:ratio forEffect:effectWrapper gender:gender];
    }
}

#pragma mark update Cached Strength for specific effect

- (void)updateEffectWithCachedStrength:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self updateEffectWithCachedStrength:effectWrapper multiSlider:NO gender:self.currentGender];
}

- (void)updateEffectWithCachedStrength:(AWEComposerBeautyEffectWrapper *)effectWrapper
                           multiSlider:(BOOL)isMultiSlider
{
    [self updateEffectWithCachedStrength:effectWrapper multiSlider:isMultiSlider gender:self.currentGender];
}

- (void)updateEffectWithCachedStrength:(AWEComposerBeautyEffectWrapper *)effectWrapper
                           multiSlider:(BOOL)isMultiSlider
                                gender:(AWEComposerBeautyGender)gender
{
    if ([effectWrapper isEffectSet]) {
        NSString *cacheKey = [self cacheKeyForEffect:effectWrapper gender:gender];
        NSString *appliedChildResourceID = nil;
        if (!ACC_isEmptyString(cacheKey)) {
            appliedChildResourceID = [ACCCache() objectForKey:cacheKey];
        }
        AWEComposerBeautyEffectWrapper *defaultEffect = [effectWrapper defaultChildEffect];
        for (AWEComposerBeautyEffectWrapper *childEffectWrapper in effectWrapper.childEffects) {
            [self updateDefaultRatioForEffectWrapper:childEffectWrapper multiSlider:isMultiSlider gender:gender];
        }
        effectWrapper.appliedChildEffect = defaultEffect;
        if (!ACC_isEmptyString(appliedChildResourceID)) {
            for (AWEComposerBeautyEffectWrapper *childEffectWrapper in effectWrapper.childEffects) {
                if ([childEffectWrapper.effect.resourceId isEqualToString:appliedChildResourceID]) {
                    if (!childEffectWrapper.disableCache) {
                        effectWrapper.appliedChildEffect = childEffectWrapper;
                    }
                    break;
                }
            }
        }
    } else {
        [self updateDefaultRatioForEffectWrapper:effectWrapper multiSlider:isMultiSlider gender: gender];
    }
}

#pragma mark update default ratio for specific effect

- (void)updateDefaultRatioForEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
                               multiSlider:(BOOL)isMultiSlider
{
    [self updateDefaultRatioForEffectWrapper:effectWrapper multiSlider:isMultiSlider gender:self.currentGender];
}

- (void)updateDefaultRatioForEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
                               multiSlider:(BOOL)isMultiSlider
                                    gender:(AWEComposerBeautyGender)gender
{
    if (effectWrapper.disableCache) {
        // use default ratio
        float currentRatio = effectWrapper.defaultRatio;
        [effectWrapper updateWithStrength:currentRatio];
    } else if (isMultiSlider) {
        // every item has different intensity
        for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
            float currentRatio = [self ratioForEffectItem:item];
            item.currentRatio = currentRatio;
        }
    } else {
        // every item has the same intensity
        float currentRatio = [self ratioForEffect:effectWrapper gender:gender];
        [effectWrapper updateWithStrength:currentRatio];
    }
}

#pragma mark update appliedChild for specific effect

- (void)updateAppliedChildEffectForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self updateAppliedChildEffectForEffect:effectWrapper forGender:self.currentGender];
}

- (void)updateAppliedChildEffectForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                forGender:(AWEComposerBeautyGender)gender
{
    if (ACC_isEmptyString(effectWrapper.effect.resourceId)) {
        return;
    }
    if ([effectWrapper isEffectSet]) {
        NSString *cacheKey = [self cacheKeyForEffect:effectWrapper gender:gender];
        if (!ACC_isEmptyString(cacheKey)) {
            AWEComposerBeautyEffectWrapper *appliedChildEffect = effectWrapper.appliedChildEffect;
            if (!appliedChildEffect || ACC_isEmptyString(appliedChildEffect.effect.resourceId) || appliedChildEffect.disableCache) {
                [ACCCache() removeObjectForKey:cacheKey];
            } else {
                [ACCCache() setObject:appliedChildEffect.effect.resourceId forKey:cacheKey];
            }
        }
    }
}

- (void)clearAppliedChildEffectForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if (ACC_isEmptyString(effectWrapper.effect.resourceId) || ![effectWrapper isEffectSet]) {
        return ;
    }
    NSString *cacheKey = [self cacheKeyForEffect:effectWrapper];
    if (!ACC_isEmptyString(cacheKey)) {
        [ACCCache() removeObjectForKey:cacheKey];
    }
}

#pragma mark appliedChildResource for specific effect

- (NSString *)appliedChildResourceIdForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    return [self appliedChildResourceIdForEffect:effectWrapper gender:self.currentGender];
}

- (NSString *)appliedChildResourceIdForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                       gender:(AWEComposerBeautyGender)gender
{
    if (![effectWrapper isEffectSet]) {
        return nil;
    }
    NSString *cacheKey = [self cacheKeyForEffect:effectWrapper gender:gender];
    NSString *appliedChildResourceID = nil;
    if (!ACC_isEmptyString(cacheKey)) {
        appliedChildResourceID = [ACCCache() objectForKey:cacheKey];
    }
    return appliedChildResourceID;
}

#pragma mark selected timestamp for specific effect

- (double)lastSelectedTimestamp:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NSString *cacheKey = [self keyForCacheSelectedTimestamp:effectWrapper];
    return [[ACCCache() stringForKey:cacheKey] doubleValue];
}

- (void)cacheSelectedTimestampForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NSString *cacheKey = [self keyForCacheSelectedTimestamp:effectWrapper];
    [ACCCache() setString:effectWrapper.effect.tagsUpdatedTimeStamp forKey:cacheKey];
}

- (void)cacheSelectedTimestamp:(double)timestamp
                     forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NSString *cacheKey = [self keyForCacheSelectedTimestamp:effectWrapper];
    [ACCCache() setString:[NSString stringWithFormat:@"%f", timestamp] forKey:cacheKey];
}

- (NSString *)keyForCacheSelectedTimestamp:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    NSString *resourceId = effectWrapper.effect.resourceId ?: @"";
    NSString *cacheKey = [self.cacheKeysObj.selectedTimeStampKey stringByAppendingString:resourceId];
    return cacheKey;
}


#pragma mark - Effect Item -

#pragma mark ratio for effect item

- (float)ratioForEffectItem:(AWEComposerBeautyEffectItem *)item
{
    return [self ratioForEffectItem:item gender:self.currentGender];
}

- (float)ratioForEffectItem:(AWEComposerBeautyEffectItem *)item
                     gender:(AWEComposerBeautyGender)gender
{
    NSNumber *number = [self effectNumberForTag:[self cacheKeyForEffectItem:item gender:gender]];
    if (number != nil) {
        float effectValue = [number floatValue];
        return [self convertToRatioForEffectValue:effectValue withEffectItem:item];
    } else {
        return item.defaultRatio;
    }
    return 0.f;
}

#pragma mark set ratio for effect item

- (void)setRatio:(float)ratio
   forEffectItem:(AWEComposerBeautyEffectItem *)item
{
    [self setRatio:ratio forEffectItem:item gender:_currentGender];
}

- (void)setRatio:(float)ratio
   forEffectItem:(AWEComposerBeautyEffectItem *)item
          gender:(AWEComposerBeautyGender)gender
{
    float value = [self convertToValueForRatio:ratio withEffectItem:item];
    [self setEffectValue:value forTag:[self cacheKeyForEffectItem:item gender:gender]];
}



#pragma mark - Filter -

- (void)cacheSelectedFilter:(NSString *)filterID
{
    [self cacheSelectedFilter:filterID withCameraPosition:self.cameraPosition];
}

- (void)cacheSelectedFilter:(NSString *)filterID
         withCameraPosition:(AWEComposerBeautyCameraPosition)cameraPosition
{
    NSString *cacheKey = [self cacheKeyForFilterWithCameraPosition:cameraPosition];
    if (filterID) {
        [ACCCache() setObject:filterID forKey:cacheKey];
    } else {
        [ACCCache() removeObjectForKey:cacheKey];
    }
}

- (NSString *)cachedFilterID
{
    return [ACCCache() objectForKey:[self cacheKeyForFilter]];
}

- (NSString *)cacheKeyForFilter
{
    return [self cacheKeyForFilterWithCameraPosition:self.cameraPosition];
}

- (NSString *)cacheKeyForFilterWithCameraPosition:(AWEComposerBeautyCameraPosition)cameraPosition
{
    return [NSString stringWithFormat:@"%@-%@", self.cacheKeysObj.appliedFilterIDKey, @(cameraPosition)];
}

#pragma mark - Gender Identity Related -

- (void)updateRecognizedGender:(AWEComposerBeautyGender)gender
{
    if (![self shouldAlwaysRecognizeAsFemale]) {
        NSInteger count = 0;
        if (gender == AWEComposerBeautyGenderWomen) {
            NSObject *cachedObject = [ACCCache() objectForKey:self.cacheKeysObj.consecutiveRecognizedAsFemaleCountKey];
            if ([cachedObject isKindOfClass:[NSNumber class]]) {
                NSNumber *numberOfConsecutiveAsFemale = (NSNumber *)cachedObject;
                count = [numberOfConsecutiveAsFemale integerValue];
            }
            count++;
        } else {
            count = 0;
        }
        [ACCCache() setObject:@(count) forKey:self.cacheKeysObj.consecutiveRecognizedAsFemaleCountKey];
    }
}

// PM needs: if they are identified as women three times in a row, they are forced to be women
- (BOOL)shouldAlwaysRecognizeAsFemale
{
    NSObject *cachedObject = [ACCCache() objectForKey:self.cacheKeysObj.consecutiveRecognizedAsFemaleCountKey];
    if ([cachedObject isKindOfClass:[NSNumber class]]) {
        NSNumber *numberOfConsecutiveAsFemale = (NSNumber *)cachedObject;
        NSInteger count = [numberOfConsecutiveAsFemale integerValue];
        return count >= kAWEComposerBeautyForceAsFemaleCount;
    }
    return NO;
}

@end

