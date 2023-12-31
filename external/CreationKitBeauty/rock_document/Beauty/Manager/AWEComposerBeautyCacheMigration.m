//
//  AWEComposerBeautyCacheMigration.m
//  CameraClient
//
//  Created by ZhangYuanming on 2020/3/30.
//

#import <CreationKitBeauty/AWEComposerBeautyCacheMigration.h>
#import <CreationKitBeauty/AWEComposerBeautyCacheViewModel.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>

#define kBeautyCacheMigrationKey @"kBeautyCacheMigrationKey"
@interface AWEComposerBeautyCacheMigration()

@property (nonatomic, strong) AWEComposerBeautyCacheViewModel* beautyCacheManager;
@property (nonatomic, strong) NSNumber *lastABGroup;
@property (nonatomic, strong) NSString *panelName;

@end

@implementation AWEComposerBeautyCacheMigration


- (instancetype)initWithCacheManager:(AWEComposerBeautyCacheViewModel *)cacheManager
                          panelName:(nonnull NSString *)panelName
{
    self = [super init];
    if (self) {
        _beautyCacheManager = cacheManager;
        _panelName = panelName;
    }
    return self;
}

+ (BOOL)needUpdateCacheWithPanelName:(NSString *)panelName
{
    NSString *migrationKey = [AWEComposerBeautyCacheMigration migrationCacheKeyWithPanelName:panelName];
    NSInteger migrationVersion = [ACCCache() integerForKey:migrationKey];
    return migrationVersion == 0;
}

+ (void)markMigrationCompleteWithPanelName:(NSString *)panelName
{
    NSString *migrationKey = [AWEComposerBeautyCacheMigration migrationCacheKeyWithPanelName:panelName];
    [ACCCache() setInteger:1 forKey:migrationKey];
}

+ (NSString *)migrationCacheKeyWithPanelName:(NSString *)panelName
{
    NSString *migrationKey = [NSString stringWithFormat:@"%@-%@", kBeautyCacheMigrationKey, panelName];
    return migrationKey;
}

- (void)startCacheDataMigration:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
                    lastABGroup:(NSNumber *)lastABGroup
                     completion:(void(^)(void))completion
{
    self.lastABGroup = lastABGroup;
    BOOL needMigrate = [AWEComposerBeautyCacheMigration needUpdateCacheWithPanelName: self.panelName];
    if (!needMigrate) {
        ACCBLOCK_INVOKE(completion);
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        [self migrateAppliedEffectListWithCategories:categories];
        [self migrateAppliedEffectItemWithCategories:categories];

        [AWEComposerBeautyCacheMigration markMigrationCompleteWithPanelName:self.panelName];
        dispatch_async(dispatch_get_main_queue(), ^{
            ACCBLOCK_INVOKE(completion);
        });
    });
}

- (NSString *)oldCacheKeyForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                            gender:(AWEComposerBeautyGender)gender
{
    if ([effectWrapper isEffectSet] && !ACC_isEmptyString(effectWrapper.effect.effectIdentifier)) {
        return [NSString stringWithFormat:@"%@%@-%@",self.beautyCacheManager.cacheKeysObj.effectSetCachePrefix, effectWrapper.effect.effectIdentifier, @(gender)];
    }
    return nil;
}

- (NSString *)oldCacheKeyForEffectItem:(AWEComposerBeautyEffectItem *)effectItem
                              inEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                                gender:(AWEComposerBeautyGender)gender
{
    NSString *tag = [NSString stringWithFormat:@"%@-%@-%@", effectWrapper.effect.effectIdentifier, effectItem.tag, @(gender)];
    return [self.beautyCacheManager.cacheKeysObj.effectConfigurationPrefix stringByAppendingString:tag];
}

- (NSString *)oldCacheKeyForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                              gender:(AWEComposerBeautyGender)gender
{
    if (!ACC_isEmptyString(categoryWrapper.category.categoryIdentifier)) {
        return [NSString stringWithFormat:@"%@%@-%@",self.beautyCacheManager.cacheKeysObj.categoryCachePrefix, categoryWrapper.category.categoryIdentifier, @(gender)];
    }
    return nil;
}

- (void)migrateAppliedEffectItemWithCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    NSMutableArray *sortedCategories = @[].mutableCopy;
    [categories enumerateObjectsUsingBlock:^(AWEComposerBeautyEffectCategoryWrapper * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (_lastABGroup != nil && obj.group == [_lastABGroup integerValue]) {
            [sortedCategories acc_addObject:obj];
        } else {
            [sortedCategories insertObject:obj atIndex:0];
        }
    }];
    
    for (AWEComposerBeautyEffectCategoryWrapper *category in sortedCategories) {
        if (category.exclusive) {
            [self migrateAppliedEffectForCategory:category];
        }
        for (AWEComposerBeautyEffectWrapper *effectWrapper in category.effects) {
            if ([effectWrapper isEffectSet]) {
                [self migrateAppliedChildEffect: effectWrapper];
                
                for (AWEComposerBeautyEffectWrapper *childEffect in effectWrapper.childEffects) {
                    for (AWEComposerBeautyEffectItem *item in childEffect.items) {
                        [self migrateEffectItem:item inEffect:childEffect];
                    }
                }
            }
            for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
                [self migrateEffectItem:item inEffect:effectWrapper];
            }
        }
    }
}

#pragma mark - applied effect for category

- (void)migrateAppliedEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)category
{
    [self migrateAppliedEffectForCategory:category forGender:AWEComposerBeautyGenderMen];
    [self migrateAppliedEffectForCategory:category forGender:AWEComposerBeautyGenderWomen];
    [self migrateAppliedEffectForCategory:category forGender:AWEComposerBeautyGenderBoth];
}

- (void)migrateAppliedEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)category
                              forGender:(AWEComposerBeautyGender)gender
{
    if (!category.exclusive) {
        return;
    }
    NSString *appliedChildEffectID;
    NSString *cacheKey = [self oldCacheKeyForCategory:category gender:gender];
    if (!ACC_isEmptyString(cacheKey)) {
        appliedChildEffectID = [ACCCache() objectForKey:cacheKey];
    }
    if (!ACC_isEmptyString(appliedChildEffectID)) {
        for (AWEComposerBeautyEffectWrapper *effectWrapper in category.effects) {
            if ([effectWrapper.effect.effectIdentifier isEqualToString:appliedChildEffectID]) {
                AWEComposerBeautyEffectWrapper *oldEffect = category.selectedEffect;
                category.selectedEffect = effectWrapper;
                [self.beautyCacheManager updateAppliedEffectForCategory:category gender:gender];
                category.selectedEffect = oldEffect;
                return;
            }
        }
    }
}

#pragma mark - applied child effect

- (void)migrateAppliedChildEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self migrateAppliedChildEffect:effectWrapper forGender:AWEComposerBeautyGenderMen];
    [self migrateAppliedChildEffect:effectWrapper forGender:AWEComposerBeautyGenderWomen];
    [self migrateAppliedChildEffect:effectWrapper forGender:AWEComposerBeautyGenderBoth];
}

- (void)migrateAppliedChildEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                        forGender:(AWEComposerBeautyGender)gender
{
    NSString *oldCacheKey = [self oldCacheKeyForEffect:effectWrapper gender:gender];
    NSString *appliedChildEffectID = nil;
    if (!ACC_isEmptyString(oldCacheKey)) {
        appliedChildEffectID = [ACCCache() objectForKey:oldCacheKey];
    }
    
    if (!ACC_isEmptyString(appliedChildEffectID)) {
        for (AWEComposerBeautyEffectWrapper *childEffectWrapper in effectWrapper.childEffects) {
            if ([childEffectWrapper.effect.effectIdentifier isEqualToString:appliedChildEffectID]) {
                AWEComposerBeautyEffectWrapper *oldAppliedChildEffect = effectWrapper.appliedChildEffect;
                effectWrapper.appliedChildEffect = childEffectWrapper;
                [self.beautyCacheManager updateAppliedChildEffectForEffect:effectWrapper forGender:gender];
                effectWrapper.appliedChildEffect = oldAppliedChildEffect;
                break;
            }
        }
    }
}


#pragma mark - effect item value


/// Transfer the beauty slider proportion value of each item to the real value, and the composition of the key changes from effectid to resourceid
/// @param effectItem AWEComposerBeautyEffectItem
/// @param effectWrapper AWEComposerBeautyEffectWrapper
- (void)migrateEffectItem:(AWEComposerBeautyEffectItem *)effectItem
                 inEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self migrateEffectItem:effectItem inEffect:effectWrapper forGender:AWEComposerBeautyGenderMen];
    [self migrateEffectItem:effectItem inEffect:effectWrapper forGender:AWEComposerBeautyGenderWomen];
    [self migrateEffectItem:effectItem inEffect:effectWrapper forGender:AWEComposerBeautyGenderBoth];
}

- (void)migrateEffectItem:(AWEComposerBeautyEffectItem *)item
                 inEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                forGender:(AWEComposerBeautyGender)gender
{
    NSString *oldCacheKey = [self oldCacheKeyForEffectItem:item inEffect:effectWrapper gender:gender];
    NSNumber *number = [ACCCache() objectForKey:oldCacheKey];
    if (number != nil && [number isKindOfClass:NSNumber.class]) {
        [self.beautyCacheManager setRatio:[number floatValue] forEffect:effectWrapper tag:item.tag gender:gender];
    } else {
        // Cache migration before 920
        NSNumber *ratioNum = [self ratioNumberForTag_920:item.tag];
        if (ratioNum != nil) {
            [self.beautyCacheManager setRatio:[ratioNum floatValue] forEffect:effectWrapper tag:item.tag gender:gender];
        }
    }
}


#pragma mark - applied Effect ID list

/// Migrate the list of all beauty IDS applied last time: effect ID changes to resourceid
/// @param categories NSArray<AWEComposerBeautyEffectCategoryWrapper *> *
- (void)migrateAppliedEffectListWithCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories {
    NSMutableArray *availableEffects = [NSMutableArray array];
    for (AWEComposerBeautyEffectCategoryWrapper *category in categories) {
        for (AWEComposerBeautyEffectWrapper *effectWrapper in category.effects) {
            if ([effectWrapper isEffectSet]) {
                [availableEffects acc_addObjectsFromArray:effectWrapper.childEffects];
            } else {
                [availableEffects acc_addObject:effectWrapper];
            }
        }
    }
    
    [self migrateAppliedEffectsWithEffects:availableEffects forGender:AWEComposerBeautyGenderWomen];
    [self migrateAppliedEffectsWithEffects:availableEffects forGender:AWEComposerBeautyGenderMen];
    [self migrateAppliedEffectsWithEffects:availableEffects forGender:AWEComposerBeautyGenderBoth];
}

- (void)migrateAppliedEffectsWithEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)availableEffects
                               forGender:(AWEComposerBeautyGender)gender {
    NSArray<NSString *> *effectIds = [self.beautyCacheManager appliedEffectsFromCacheForGender:gender];
    
    if (effectIds.count <= 0) {
        return;
    }
    NSMutableArray<NSString *> *appliedEffects = [NSMutableArray array];

    for (NSString *effectID in effectIds) {
        if ([effectID isEqualToString:self.beautyCacheManager.cacheKeysObj.appliedFilterPlaceHolder]) {
            [appliedEffects acc_addObject:self.beautyCacheManager.cacheKeysObj.appliedFilterPlaceHolder];
        } else {
            for (AWEComposerBeautyEffectWrapper *effectWrapper in availableEffects) {
                if ([effectWrapper.effect.effectIdentifier isEqualToString:effectID]) {
                        [appliedEffects acc_addObject:effectWrapper.effect.resourceId];
                    break;
                }
            }
        }
    }
    
    /*
     In the camera msg_cameraDidStartRender callback, the cache is also updated in the main thread based on the applyeffects in the viewmodel.
     The following may be overwritten if executed first.
     */
    [self.beautyCacheManager cacheAppliedEffectsResourceIds:appliedEffects forGender:gender];
}

#pragma mark - migration of data from previous versions of 920

/// Before 920, the cache only used the tag in the effect item as the key
/// @param tag NSString
- (NSNumber *)ratioNumberForTag_920:(NSString *)tag
{
    if (tag.length == 0) {
        return nil;
    }
    NSString *key = [self.beautyCacheManager.cacheKeysObj.effectConfigurationPrefix stringByAppendingString:tag];
    id number = [ACCCache() objectForKey:key];
    if ([number isKindOfClass:NSNumber.class]) {
        return number;
    }
    return nil;
}

@end
