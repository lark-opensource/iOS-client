//
//  AWEComposerBeautyEffectViewModel.m
//  AWEStudio
//
//  Created by Shen Chen on 2019/8/5.
//

#import <CreationKitBeauty/AWEComposerBeautyEffectViewModel.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectDownloader.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectKeys.h>
#import <CreationKitInfra/ACCI18NConfigProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitArch/CKConfigKeysDefines.h>

NSString *const AWEComposerBeautyEffectPanelAdvanced = @"composer1";
NSString *const AWEComposerBeautyEffectPanelDefault = @"beautifynew1";

@interface AWEComposerBeautyEffectViewModel()

@property (nonatomic, strong, readonly) NSString *panelName;
@property (nonatomic, strong) NSMutableArray *appliedEffects; // applied effects in all categories
@property (nonatomic, copy, readwrite) NSArray *availableEffects; // effects in all categories
@property (nonatomic, strong) AWEComposerBeautyEffectWrapper *placeHolderEffectForFilter;

@property (nonatomic, assign) AWEComposerBeautyGender currentGender;
@property (nonatomic, assign) AWEComposerBeautyCameraPosition cameraPosition;

@property (nonatomic, strong) AWEComposerBeautyEffectKeys *effectKeysObj;
@property (nonatomic, strong, readwrite) AWEComposerBeautyCacheViewModel *cacheObj;
@property (nonatomic, strong) id<AWEComposerBeautyMigrationProtocol> cacheMigrationManager;
@property (nonatomic, strong) id<AWEComposerBeautyDataHandleProtocol> dataHandler;
@property (nonatomic, strong) NSNumber *lastABGroup;
@property (nonatomic, assign, readwrite) BOOL isPaternityEnabled;
@end


@implementation AWEComposerBeautyEffectViewModel

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithCacheViewModel:(nullable AWEComposerBeautyCacheViewModel *)cacheObj
                             panelName:(NSString *)panelName
{
    return [self initWithCacheViewModel:cacheObj
                              panelName:panelName
                       migrationHandler:nil
                            dataHandler:nil];
}

- (instancetype)initWithCacheViewModel:(nullable AWEComposerBeautyCacheViewModel *)cacheObj
                             panelName:(nullable NSString *)panelName
                      migrationHandler:(nullable id<AWEComposerBeautyMigrationProtocol>)migrationHandler
                           dataHandler:(nullable id<AWEComposerBeautyDataHandleProtocol>)dataHandler
{
    self = [super init];
    if (self) {
        _dataHandler = dataHandler;
        _cacheObj = cacheObj;
        _effectKeysObj = [[AWEComposerBeautyEffectKeys alloc] initWithBusinessName:_cacheObj.businessName];
        _currentGender = AWEComposerBeautyGenderWomen;
        _cacheMigrationManager = migrationHandler;

        if (panelName) {
            _panelName = [panelName copy];
        } else {
            _panelName = AWEComposerBeautyEffectPanelAdvanced;
        }
        NSString *lastPanelName = [ACCCache() objectForKey:self.effectKeysObj.lastPanelNameKey];
        if (![lastPanelName isEqual:_panelName]) {
            [self.cacheObj clearCachedAppliedEffects];
        }
        _lastABGroup = [ACCCache() objectForKey:self.effectKeysObj.lastABGroupKey];
        if ((_lastABGroup == nil) || [_lastABGroup isKindOfClass:[NSNull class]] || [_lastABGroup integerValue] != [_dataHandler currentABGroup]) {
            [self.cacheObj clearCachedAppliedEffects];
            [ACCCache() setObject:@([_dataHandler currentABGroup]) forKey:self.effectKeysObj.lastABGroupKey];
        }
        
        NSString *lastRegion = [ACCCache() objectForKey:self.effectKeysObj.lastRegionKey];
        if (![lastRegion isEqual:[ACCI18NConfig() currentRegion]]) {
            [self.cacheObj clearCachedAppliedEffects];
            [ACCCache() setObject:[ACCI18NConfig() currentRegion] forKey:self.effectKeysObj.lastRegionKey];
        }
        _didModifyStatus = [ACCCache() boolForKey:self.effectKeysObj.userHadModifiedKey];
    }
    return self;
}

#pragma mark - setter

- (void)setDidModifyStatus:(BOOL)didModifyStatus
{
    if (!_didModifyStatus) {
        _didModifyStatus = YES;
        [ACCCache() setBool:YES forKey:self.effectKeysObj.userHadModifiedKey];
    }
}

- (void)enablePaternity
{
    self.isPaternityEnabled = YES;
}

#pragma mark - getter

- (NSArray *)currentEffects
{
    NSMutableArray *effects = [NSMutableArray array];
    NSArray *appliedEffects = [self.appliedEffects copy];
    for (AWEComposerBeautyEffectWrapper *effect in appliedEffects) {
        if (!effect.isFilter) {
            [effects acc_addObject:effect];
        }
    }
    return [effects copy];
}

- (void)clearAppliedEffects
{
    [self.appliedEffects removeAllObjects];
    [self.cacheObj cacheAppliedEffects:@[]];
}

- (NSArray *)effectsAfterFilter
{
    NSMutableArray *effects = [NSMutableArray array];
    BOOL filterFound = NO;
    NSArray *appliedEffects = [self.appliedEffects copy];
    for (AWEComposerBeautyEffectWrapper *effect in appliedEffects) {
        if (effect.isFilter) {
            filterFound = YES;
        } else {
            if (filterFound) {
                [effects acc_addObject:effect];
            }
        }
    }
    return [effects copy];
}

- (NSArray *)effectsBeforeFilter
{
    NSMutableArray *effects = [NSMutableArray array];
    NSArray *appliedEffects = [self.appliedEffects copy];
    for (AWEComposerBeautyEffectWrapper *effect in appliedEffects) {
        if (effect.isFilter) {
            break;
        } else {
            [effects acc_addObject:effect];
        }
    }
    return [effects copy];
}

- (AWEComposerBeautyEffectWrapper *)placeHolderEffectForFilter
{
    if (!_placeHolderEffectForFilter) {
        _placeHolderEffectForFilter = [[AWEComposerBeautyEffectWrapper alloc] initWithEffect:nil isFilter:YES];
    }
    return _placeHolderEffectForFilter;
}

#pragma mark - updateWithGender

- (void)updateWithGender:(AWEComposerBeautyGender)gender
{
    BOOL needUpdateDatasource = NO;
    if (gender != self.currentGender) {
        needUpdateDatasource = YES;
    }
    [self updateWithGender:gender cameraPosition:self.cameraPosition];
    if (needUpdateDatasource) {
        [self prepareDataSource];
    }
}

- (void)updateWithGender:(AWEComposerBeautyGender)gender
          cameraPosition:(AWEComposerBeautyCameraPosition)cameraPosition
{
    self.currentGender = gender;
    self.cameraPosition = cameraPosition;
    [self.cacheObj updateCurrentGender:gender cameraPosition:cameraPosition];
}


#pragma mark - cache & fetch

- (void)cacheAppliedEffects
{
    [self.cacheObj cacheAppliedEffects:self.appliedEffects];
}

// load cache from effect platform
- (void)loadCachedEffectsWithCompletion:(AWEComposerBeautyEffectLoadBlock)completion
{
    [ACCCache() setObject:self.panelName forKey:self.effectKeysObj.lastPanelNameKey];

    IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:self.panelName];

    BOOL hasValidCache = !ACC_isEmptyArray(cachedResponse.categories);

    @weakify(self);
    if (hasValidCache) {
        IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:self.panelName];
        [self p_updateCategoriesWithResponse:cachedResponse completion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *categories, BOOL success) {
            @strongify(self);
            // build parent-child relations
            if (self.isPaternityEnabled) {
                [self p_bindPaternityWithCategories:categories];
                [self p_addNoneCateogryToParentCateogries:categories];
            }
            NSDictionary *infoDict = @{@"isPrimaryEnabled" : self.isPaternityEnabled ? @"YES":@"NO",
                                       @"categories" : [self namesArrayOfCategories:categories]
            };
            NSString *infoString = [NSString stringWithFormat:@"ComposerBeautyPrimary-DEBUG: info: %@", infoDict];
            NSString *logString = [@[@"==========", infoString, @"==========="] componentsJoinedByString:@"\n"];
            AWELogToolInfo(AWELogToolTagRecord, @"%@", logString);
            ACCBLOCK_INVOKE(completion, categories, success);
        }];
    } else {
        ACCBLOCK_INVOKE(completion, nil, NO);
    }
}

- (void)p_bindPaternityWithCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    [categories enumerateObjectsUsingBlock:^(AWEComposerBeautyEffectCategoryWrapper * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        AWEComposerBeautyEffectCategoryWrapper *parent = [self findParentCategoryIn:categories forCategory:obj];
        parent.childCategories = [parent.childCategories arrayByAddingObject:obj];
        obj.parentCategory = parent;
        if (obj.isDefaultChildCategory) {
            parent.defaultChildCategory = obj;
        }
    }];
}

- (AWEComposerBeautyEffectCategoryWrapper *)findParentCategoryIn:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories forCategory:(AWEComposerBeautyEffectCategoryWrapper *)category
{
    __block AWEComposerBeautyEffectCategoryWrapper *parent;
    [categories enumerateObjectsUsingBlock:^(AWEComposerBeautyEffectCategoryWrapper * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.categoryId isEqualToString:category.parentId]) {
            parent = obj;
            *stop = YES;
        }
    }];
    return parent;
}

-(void)p_addNoneCateogryToParentCateogries:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    [categories enumerateObjectsUsingBlock:^(AWEComposerBeautyEffectCategoryWrapper * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isPrimaryCategory) {
            AWEComposerBeautyEffectCategoryWrapper *noneCategory = [self p_generateNoneCategory];
            noneCategory.parentId = obj.categoryId;
            noneCategory.parentCategory = obj;
            NSMutableArray *childs = [NSMutableArray arrayWithObject:noneCategory];
            [childs acc_addObjectsFromArray:obj.childCategories];
            obj.childCategories = childs;
        }
    }];
}

-(AWEComposerBeautyEffectCategoryWrapper *)p_generateNoneCategory
{
    NSDictionary *categoryDic = @{
        @"categoryIdentifier": @"none"
    };
    NSError *error = nil;
    IESCategoryModel *category = [[IESCategoryModel alloc] initWithDictionary:categoryDic error:&error];
    if (error) {
        return nil;
    }
    AWEComposerBeautyEffectCategoryWrapper *noneCategory = [[AWEComposerBeautyEffectCategoryWrapper alloc] init];
    noneCategory.category = category;
    noneCategory.primaryCategoryName = ACCLocalizedString(@"none", nil);
    noneCategory.isNoneCategory = YES;
    noneCategory.categoryId = @"noneId";
    return noneCategory;
}

// only for edit page
- (NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)localCachedBeautyData
{
    IESEffectPlatformResponseModel *cachedResponse = [EffectPlatform cachedEffectsOfPanel:self.panelName];
    NSArray<IESCategoryModel *> *categories = cachedResponse.categories;
    NSMutableArray *categoryWrappers = [NSMutableArray array];
    for (IESCategoryModel *category in categories) {
        AWEComposerBeautyEffectCategoryWrapper *categoryWrapper = [[AWEComposerBeautyEffectCategoryWrapper alloc] initWithCategory:category];
        if (categoryWrapper
            && !ACC_isEmptyArray(categoryWrapper.effects)
            && [self canShowCategory:categoryWrapper withGender:self.currentGender]) {
            [categoryWrappers acc_addObject:categoryWrapper];
        }
    }

    return [categoryWrappers copy];
}

- (void)fetchUpdatedEffectsForce:(BOOL)forceUpdate
                      completion:(AWEComposerBeautyEffectLoadBlock)completion
{
    if (forceUpdate) {
        [self p_fetchCategoriesAndEffects:completion];
        return;
    }
    @weakify(self);
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    [EffectPlatform checkEffectUpdateWithPanel:self.panelName effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code) completion:^(BOOL needUpdate) {
        @strongify(self);
        if (!needUpdate) {
            [ACCMonitor() trackService:@"aweme_effect_list_error"
                             status:70
                              extra:@{
                                  @"panel" : self.panelName ?: @"",
                                  @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                  @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                  @"needUpdate" : @(NO)
                              }];
            ACCBLOCK_INVOKE(completion, nil, YES);
        } else {
            [self p_fetchCategoriesAndEffects:completion];
        }
    }];
}

- (void)p_fetchCategoriesAndEffects:(void (^)(NSArray <AWEComposerBeautyEffectCategoryWrapper *> *, BOOL))completion
{
    CFTimeInterval startTime = CFAbsoluteTimeGetCurrent();
    @weakify(self)
    [EffectPlatform downloadEffectListWithPanel:self.panelName
                                      saveCache:YES
                           effectTestStatusType:ACCConfigInt(kConfigInt_effect_test_status_code)
                                     completion:^(NSError * _Nullable error, IESEffectPlatformResponseModel * _Nullable response) {
        @strongify(self)

        if (error || !response) {
            [ACCMonitor() trackService:@"aweme_effect_list_error"
                             status:71
                              extra:@{
                                  @"panel" : self.panelName ?: @"",
                                  @"errorDesc" : error.description ?: @"",
                                  @"errorCode" : @(error.code),
                                  @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                  @"needUpdate" : @(YES)
                              }];
            ACCBLOCK_INVOKE(completion, nil, NO);
            return;
        } else {
            [ACCMonitor() trackService:@"aweme_effect_list_error"
                             status:70
                              extra:@{
                                  @"panel" : self.panelName ?: @"",
                                  @"duration" : @((CFAbsoluteTimeGetCurrent() - startTime) * 1000),
                                  @"abParam": @(ACCConfigInt(kConfigInt_platform_optimize_strategy)),
                                  @"needUpdate" : @(YES)
                              }];
            [self p_updateCategoriesWithResponse:response completion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *filteredCategories, BOOL succses) {
                @strongify(self);
                // build parent child relations
                if (self.isPaternityEnabled) {
                    [self p_bindPaternityWithCategories:filteredCategories];
                    [self p_addNoneCateogryToParentCateogries:filteredCategories];
                }
                acc_dispatch_main_async_safe(^{
                    ACCBLOCK_INVOKE(completion, filteredCategories, succses);
                });
            }];
        }
    }];
}

#pragma mark - filter categories - prepareDataSource

- (void)prepareDataSource
{
    @weakify(self)
    [self loadCachedEffectsWithCompletion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *categories, BOOL success) {
        @strongify(self)
        [self filterCategories:categories withGender:self.currentGender cameraPosition:self.cameraPosition completion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *filteredCategories, BOOL success) {
            [self updateAppliedEffectsWithCategories:filteredCategories];
        }];
    }];
}

- (void)filterCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
              completion:(AWEComposerBeautyEffectLoadBlock)completion
{
    [self filterCategories:categories withGender:self.currentGender cameraPosition:self.cameraPosition completion:completion];
}

- (void)filterCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
              withGender:(AWEComposerBeautyGender)gender
          cameraPosition:(AWEComposerBeautyCameraPosition)cameraPosition
              completion:(AWEComposerBeautyEffectLoadBlock)completion
{
    [self updateWithGender:gender cameraPosition:cameraPosition];
    NSMutableArray <AWEComposerBeautyEffectCategoryWrapper *> *filteredCategories = [NSMutableArray array];

    // recover cache value of categories
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in categories) {
        BOOL isAvailable = [self canShowCategory:categoryWrapper withGender:gender];
        if (isAvailable) {
            [filteredCategories acc_addObject:categoryWrapper];
            [self.cacheObj updateCategoryFromCache:categoryWrapper multiSlider:self.multiSlider];
        }
    }

    // update appliedEffects and availiableEffects status
    [self updateAppliedEffectsWithCategories:filteredCategories];
    [self updateAvailableEffectsWithCategories:filteredCategories];
    ACCBLOCK_INVOKE(completion, [filteredCategories copy], YES);
}

- (BOOL)canShowCategory:(AWEComposerBeautyEffectCategoryWrapper  *)categoryWrapper
             withGender:(AWEComposerBeautyGender)gender
{
    NSInteger group = [_dataHandler currentABGroup];

    if (!ACC_isEmptyString(categoryWrapper.parentId)) {
        return NO;
    }
    BOOL availableForCurrentProduct = YES;
    if (_dataHandler) {
        availableForCurrentProduct = [_dataHandler filterBeautyWithCategoryWrapper:categoryWrapper];
    }
    if (!categoryWrapper.isLocalEffect && (categoryWrapper.group != group || !availableForCurrentProduct)) {
        return NO;
    }

    if (!(
          (gender == AWEComposerBeautyGenderBoth && categoryWrapper.gender == AWEComposerBeautyGenderBoth) ||
          (gender != AWEComposerBeautyGenderBoth && ((categoryWrapper.gender == AWEComposerBeautyGenderBoth || categoryWrapper.gender == gender)))
          )
        ) {
        availableForCurrentProduct = NO;
    }

    return availableForCurrentProduct;
}

// restore/construct Categories
// transfer IESCategoryModel to AWEComposerBeautyEffectCategoryWrapper
// after getting response from cache or network
- (void)p_updateCategoriesWithResponse:(IESEffectPlatformResponseModel *)response
                            completion:(AWEComposerBeautyEffectLoadBlock)completion
{
    if (ACC_isEmptyArray(response.categories)) {
        ACCBLOCK_INVOKE(completion, nil, NO);
        return;
    }
    NSArray<IESCategoryModel *> *categories = response.categories;
    NSMutableArray *categoryWrappers = [NSMutableArray array];
    for (IESCategoryModel *category in categories) {
        AWEComposerBeautyEffectCategoryWrapper *categoryWrapper = [[AWEComposerBeautyEffectCategoryWrapper alloc] initWithCategory:category responseModel:response];
        if (categoryWrapper && !ACC_isEmptyArray(categoryWrapper.effects)) {
            [categoryWrappers acc_addObject:categoryWrapper];
        }
    }
    ACCBLOCK_INVOKE(completion, categoryWrappers, YES);
}

/// assign self.availableEffects and  download each effect resource of each category passed in
- (void)updateAvailableEffectsWithCategories:(NSArray <AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    NSMutableArray *availableCategories = [NSMutableArray array];
    for (AWEComposerBeautyEffectCategoryWrapper *category in categories) {
        if (category.isPrimaryCategory) {
            [availableCategories acc_addObjectsFromArray:category.childCategories];
            /// download selected primary Category in advance
            AWEComposerBeautyEffectCategoryWrapper *advancedDownloadCategory = category.selectedChildCategory ?: category.defaultChildCategory;
            for (AWEComposerBeautyEffectWrapper *effect in advancedDownloadCategory.effects) {
                if (effect.isEffectSet) {
                    [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadEffects:effect.childEffects];
                } else {
                    [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadEffects:@[effect]];
                }
            }
        } else {
            [availableCategories acc_addObject:category];
        }
    }

    NSMutableArray *availableEffects = [NSMutableArray array];

    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in availableCategories) {
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            if ([effectWrapper isEffectSet]) {
                [availableEffects acc_addObjectsFromArray:effectWrapper.childEffects];
            } else {
                [availableEffects acc_addObject:effectWrapper];
            }
        }
    }
    self.availableEffects = [availableEffects copy];
    [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadEffects:self.availableEffects];
}


// assign self.appliedEffects
- (void)updateAppliedEffectsWithCategories:(NSArray <AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    /// preprocess
    NSMutableArray *availableCategories = [NSMutableArray array];
    NSMutableArray *appliableCategories = [NSMutableArray array];
    for (AWEComposerBeautyEffectCategoryWrapper *category in categories) {
        if (category.isPrimaryCategory) {
            [availableCategories acc_addObjectsFromArray:category.childCategories];
            NSString *cachedChildCategoryId = [self.cacheObj cachedSelectedCategoryIdForParentCategory:category];
            AWEComposerBeautyEffectCategoryWrapper *targetCategory = category.selectedChildCategory ?: category.defaultChildCategory;

            for (AWEComposerBeautyEffectCategoryWrapper *child in category.childCategories) {
                if ([child.categoryId isEqualToString:cachedChildCategoryId]) {
                    targetCategory = child;
                    break;
                }
            }
            [appliableCategories acc_addObject:targetCategory];
        } else {
            [availableCategories acc_addObject:category];
            [appliableCategories acc_addObject:category];
        }
    }

    NSMutableArray *appliedEffects = [NSMutableArray array];
    NSArray *cachedAppliedEffects = [self.cacheObj appliedEffectsFromCache]; // string array
    NSArray *effectsWithoutFilter = [cachedAppliedEffects mtl_arrayByRemovingObject:self.cacheObj.cacheKeysObj.appliedFilterPlaceHolder];
    if (!ACC_isEmptyArray(effectsWithoutFilter)) {

        // available effects
        NSMutableArray *availableEffects = [NSMutableArray array];
        for (AWEComposerBeautyEffectCategoryWrapper *category in availableCategories) {
            for (AWEComposerBeautyEffectWrapper *effectWrapper in category.effects) {
                if ([effectWrapper isEffectSet]) {
                    [availableEffects acc_addObjectsFromArray:effectWrapper.childEffects];
                } else {
                    [availableEffects acc_addObject:effectWrapper];
                }
            }
        }
        // applied effects
        for (NSString *resourceID in cachedAppliedEffects) {
            if ([resourceID isEqualToString:self.cacheObj.cacheKeysObj.appliedFilterPlaceHolder]) {
                [appliedEffects acc_addObject:self.placeHolderEffectForFilter];
            } else {
                for (AWEComposerBeautyEffectWrapper *effectWrapper in availableEffects) {
                    if ([effectWrapper.effect.resourceId isEqualToString:resourceID]) {
                        [appliedEffects acc_addObject:effectWrapper];
                        break;
                    }
                }
            }
        }
    }

    // no cached applied effects
    NSArray *applingEffectsWithoutFilter = [appliedEffects mtl_arrayByRemovingObject:self.placeHolderEffectForFilter];
    if (ACC_isEmptyArray(effectsWithoutFilter) ||
        ACC_isEmptyArray(applingEffectsWithoutFilter)) {
        
        [appliedEffects removeAllObjects];
        [appliedEffects acc_addObject:self.placeHolderEffectForFilter];
        
        for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in appliableCategories) {
            for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
                BOOL isAvailable = YES;
                if (_dataHandler) {
                    isAvailable = [_dataHandler filterBeautyWithEffectWrapper:effectWrapper];
                }
                if (!isAvailable) {
                    continue;
                }
                // appliedChildEffect
                if ([effectWrapper isEffectSet]) {
                    AWEComposerBeautyEffectWrapper *appliedEffectWrapper = nil;
                    
                    // Determine whether there is a cache value
                    NSString *appliedChildResourceID = [self.cacheObj appliedChildResourceIdForEffect:effectWrapper];
                    for (AWEComposerBeautyEffectWrapper *childEffectWrapper in effectWrapper.childEffects) {
                        if ([childEffectWrapper.effect.resourceId isEqualToString:appliedChildResourceID] && !childEffectWrapper.disableCache) {
                            appliedEffectWrapper = childEffectWrapper;
                            break;
                        } else if (childEffectWrapper.isDefault) {
                            appliedEffectWrapper = childEffectWrapper;
                        }
                    }
                    appliedEffectWrapper = appliedEffectWrapper ?: [effectWrapper defaultChildEffect];
                    effectWrapper.appliedChildEffect = appliedEffectWrapper;
                    if (appliedEffectWrapper && !appliedEffectWrapper.isNone) {
                        [appliedEffects acc_addObject:appliedEffectWrapper];
                    }
                } else {
                    BOOL shouldAddToAppliedEffects = NO;
                    if (categoryWrapper.exclusive) {
                        if (categoryWrapper.selectedEffect) {
                            // if selectedEffect not nil, should apply this
                            if ([categoryWrapper.selectedEffect isEqual:effectWrapper]) {
                                shouldAddToAppliedEffects = YES;
                            }
                        } else if (effectWrapper.isDefault) {
                            // if selectedEffect is nil, we should apply the default effect
                            categoryWrapper.selectedEffect = effectWrapper;
                            shouldAddToAppliedEffects = YES;
                        }
                    } else {
                        shouldAddToAppliedEffects = YES;
                    }
                    if (shouldAddToAppliedEffects && !effectWrapper.isNone) {
                        [appliedEffects acc_addObject:effectWrapper];
                    }
                }
            }
        }
        
        [self.cacheObj cacheAppliedEffects:appliedEffects];
    }
    
    self.appliedEffects = appliedEffects;
}

#pragma mark - update applied effects

// add
- (void)addEffectWrapperToAppliedEffects:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if ([effectWrapper isEffectSet]) {
        return;
    }

    if (!ACC_isEmptyString(effectWrapper.effect.effectIdentifier) || effectWrapper.isFilter) {
        [self.appliedEffects acc_addObject:effectWrapper];
    }
}

// batch add
- (void)addEffectsArrayToAppliedEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectsArray
{
    for (AWEComposerBeautyEffectWrapper *effect in effectsArray) {

        AWEComposerBeautyEffectWrapper *target = effect;
        if ([effect isEffectSet]) {
            target = effect.appliedChildEffect;
        }

        if (![self.appliedEffects containsObject:target]) {
            [self addEffectWrapperToAppliedEffects:target];
        }
    }
}

// remove
- (void)removeEffectWrapperFromAppliedEffects:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if (effectWrapper.isEffectSet) {
        [self.appliedEffects removeObjectsInArray:effectWrapper.childEffects];
    } else {
        [self.appliedEffects removeObject:effectWrapper];
    }
}

// batch remove
- (void)removeEffectsArrayFromAppliedEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectsArray
{
    if (!ACC_isEmptyArray(effectsArray)) {

        [self.appliedEffects removeObjectsInArray:effectsArray];

        for (AWEComposerBeautyEffectWrapper *effectWrapper in effectsArray) {
            if (effectWrapper.isEffectSet) {
                [self.appliedEffects removeObjectsInArray:effectWrapper.childEffects];
            }
        }
    }
}

// adjustment
- (void)bringEffectWrapperToEnd:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self removeEffectWrapperFromAppliedEffects:effectWrapper];
    [self addEffectWrapperToAppliedEffects:effectWrapper];
    [self cacheAppliedEffects];
}

// adjustment
- (void)bringEffectWrapperToFront:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self removeEffectWrapperFromAppliedEffects:effectWrapper];
    if ([effectWrapper isEffectSet]) {
        return ;
    }

    if (!ACC_isEmptyString(effectWrapper.effect.effectIdentifier) || effectWrapper.isFilter) {
        [self.appliedEffects insertObject:effectWrapper atIndex:0];
    }
    [self cacheAppliedEffects];
}

#pragma mark - update specific effect

- (void)updateAppliedChildEffect:(AWEComposerBeautyEffectWrapper *)childEffectWrapper
                       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if ([effectWrapper isEffectSet]) {
        if (effectWrapper.appliedChildEffect) {
            [self removeEffectWrapperFromAppliedEffects:effectWrapper.appliedChildEffect];
        }
        // Prevent secondary items with the same ID under multiple primary items
        if (childEffectWrapper) {
            [self removeEffectWrapperFromAppliedEffects:childEffectWrapper];
        }
        effectWrapper.appliedChildEffect = childEffectWrapper;
        if (effectWrapper.appliedChildEffect) {
            [self addEffectWrapperToAppliedEffects:effectWrapper.appliedChildEffect];
        }
    } else {
        [self removeEffectWrapperFromAppliedEffects:effectWrapper];
        [self addEffectWrapperToAppliedEffects:effectWrapper];
    }
    [self.cacheObj updateAppliedChildEffectForEffect:effectWrapper];
}

- (void)updateAppliedChildEffect:(AWEComposerBeautyEffectWrapper *)childEffectWrapper
                       forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                          gender:(AWEComposerBeautyGender)gender
{
    if (gender == _currentGender) {
        [self updateAppliedChildEffect:childEffectWrapper forEffect:effectWrapper];
        return;
    }
    
    NSArray<NSString *> *resourceIds = [self.cacheObj appliedEffectsFromCacheForGender:gender];
    NSMutableArray<NSString *> *appliedEffects = [NSMutableArray array];

    // udpate applied list
    for (NSString *resourceID in resourceIds) {
        if ([effectWrapper isEffectSet]) {
            if ([resourceID isEqualToString:effectWrapper.appliedChildEffect.effect.resourceId]) {
                continue;
            }
        } else {
            if ([resourceID isEqualToString:childEffectWrapper.effect.resourceId]) {
                continue;
            }
        }
        [appliedEffects acc_addObject:resourceID];
    }
    
    AWEComposerBeautyEffectWrapper *oldChildEffect = effectWrapper.appliedChildEffect;
    if ([effectWrapper isEffectSet]) {
        effectWrapper.appliedChildEffect = childEffectWrapper;
    }
    [self.cacheObj cacheAppliedEffectsResourceIds:appliedEffects forGender:gender];
    [self.cacheObj updateAppliedChildEffectForEffect:effectWrapper forGender:gender];
    // restore
    if ([effectWrapper isEffectSet]) {
        effectWrapper.appliedChildEffect = oldChildEffect;
    }
}

- (void)updateEffectRatioFromCache:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if (!self.cacheObj) {
        return;
    }
    if (self.isMultiSlider) {
        for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
            float currentRatio = [self.cacheObj ratioForEffectItem:item];
            item.currentRatio = currentRatio;
        }
    } else {
        [effectWrapper updateWithStrength:[self.cacheObj ratioForEffect:effectWrapper]];
    }
}

#pragma mark - update specific category

- (void)updateSelectedEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                 forCategory:(AWEComposerBeautyEffectCategoryWrapper *)category
{
    AWEComposerBeautyEffectCategoryWrapper *targetCategory = category;

    if (category.isPrimaryCategory && category.selectedChildCategory) {
        targetCategory = category.selectedChildCategory;
    }

    targetCategory.userSelectedEffect = effectWrapper;
    if (!targetCategory.exclusive || !effectWrapper || [effectWrapper isEffectSet]) {
        return ;
    }
    if (targetCategory.selectedEffect) {
        [self removeEffectWrapperFromAppliedEffects:targetCategory.selectedEffect];
    }
    targetCategory.selectedEffect = effectWrapper;
    [self addEffectWrapperToAppliedEffects:effectWrapper];
    [self.cacheObj updateAppliedEffectForCategory:targetCategory];
}

- (void)updateSelectedEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                 forCategory:(AWEComposerBeautyEffectCategoryWrapper *)category
                      gender:(AWEComposerBeautyGender)gender
{
    if (self.currentGender == gender) {
        [self updateSelectedEffect:effectWrapper forCategory:category];
        return;
    }

    if (!category.exclusive || !effectWrapper || [effectWrapper isEffectSet]) {
        return ;
    }

    NSArray<NSString *> *resourceIds = [self.cacheObj appliedEffectsFromCacheForGender:gender];
    NSMutableArray<NSString *> *appliedEffects = [NSMutableArray array];

    for (NSString *resourceID in resourceIds) {
        BOOL hadOldEffect = NO;
        for (AWEComposerBeautyEffectWrapper *subEffectWrapper in category.effects) {
            if ([resourceID isEqualToString:subEffectWrapper.effect.resourceId]) {
                hadOldEffect = YES;
                break;
            }
        }
        if (hadOldEffect) {
            continue;
        }
        [appliedEffects acc_addObject:resourceID];
    }
    [appliedEffects acc_addObject:effectWrapper.effect.resourceId];
    AWEComposerBeautyEffectWrapper *oldChildEffect = category.selectedEffect;
    category.selectedEffect = effectWrapper;
    [self.cacheObj cacheAppliedEffectsResourceIds:appliedEffects forGender:gender];
    [self.cacheObj updateAppliedEffectForCategory:category gender:gender];
    // restore
    category.selectedEffect = oldChildEffect;
}

#pragma mark - update specific Primary Category

- (void)updateSelectedChildCateogry:(AWEComposerBeautyEffectCategoryWrapper *)childCategory
                  lastChildCategory:(AWEComposerBeautyEffectCategoryWrapper *)lastChildCategory
                 forPrimaryCategory:(AWEComposerBeautyEffectCategoryWrapper *)primaryCatgory
{
    if (primaryCatgory.isChildCategoryExclusive) {
        // remove last cateogry effects
        [self removeEffectsArrayFromAppliedEffects:lastChildCategory.effects];
    }

    [self addEffectsArrayToAppliedEffects:childCategory.effects];

    primaryCatgory.selectedChildCategory = childCategory;

    [self cacheAppliedEffects];

    [self.cacheObj cacheSelectedChildCategoryId:childCategory.category.categoryIdentifier forParentCategory:primaryCatgory];
}

#pragma mark - debug helper

- (NSArray *)appliedEffectsName
{
    return [self appliedIdsWithArray:self.appliedEffects];
}

- (NSArray *)appliedNameWithArray:(NSArray<AWEComposerBeautyEffectWrapper *> *)array
{
    NSMutableArray *result = [NSMutableArray array];
    for (AWEComposerBeautyEffectWrapper *effect in array) {
        [result acc_addObject:effect.effect.effectName];
    }
    return result;
}

- (NSArray *)appliedIdsWithArray:(NSArray<AWEComposerBeautyEffectWrapper *> *)array
{
    NSMutableArray *result = [NSMutableArray array];
    for (AWEComposerBeautyEffectWrapper *effect in array) {
        [result acc_addObject:effect.effect.effectIdentifier];
    }
    return result;
}

- (NSArray *)appliedCategoryWithArray:(NSArray<AWEComposerBeautyEffectWrapper *> *)array
{
    NSMutableArray *result = [NSMutableArray array];
    for (AWEComposerBeautyEffectWrapper *effect in array) {
        NSString *name = @"empty";

        if (effect.isEffectSet) {
            name = effect.parentEffect.categoryWrapper.category.categoryName;
        } else {
            name = effect.categoryWrapper.category.categoryName;
        }
        [result acc_addObject:name];
    }
    return result;
}

- (NSString *)categoryNameOfEffect:(AWEComposerBeautyEffectWrapper *)effect
{
    NSString *name = @"empty";

    if (effect.isEffectSet) {
        name = effect.parentEffect.categoryWrapper.category.categoryName;
    } else {
        name = effect.categoryWrapper.category.categoryName;
    }
    return name;
}

- (NSArray *)namesArrayOfCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    NSMutableArray *result = [NSMutableArray array];
    [categories enumerateObjectsUsingBlock:^(AWEComposerBeautyEffectCategoryWrapper * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result acc_addObject: obj.category.categoryName];
    }];
    return result;
}

- (NSArray *)idsArrayOfCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    NSMutableArray *result = [NSMutableArray array];
    [categories enumerateObjectsUsingBlock:^(AWEComposerBeautyEffectCategoryWrapper * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [result acc_addObject: obj.category.categoryIdentifier];
    }];
    return result;
}

#pragma mark - update Filter placeholder

- (void)updateAppliedFilter:(IESEffectModel *)filterModel
{
    AWEComposerBeautyEffectWrapper *filterToRemove = self.placeHolderEffectForFilter;
    if (filterToRemove) {
        [self removeEffectWrapperFromAppliedEffects:filterToRemove];
    }
    if (filterModel) {
        [self addEffectWrapperToAppliedEffects:self.placeHolderEffectForFilter];
    }
    [self.cacheObj cacheSelectedFilter:filterModel.resourceId];
    [self cacheAppliedEffects];
}

- (void)bringFilterToFront
{
    AWEComposerBeautyEffectWrapper *filterToRemove = self.placeHolderEffectForFilter;
    if (filterToRemove) {
        [self removeEffectWrapperFromAppliedEffects:filterToRemove];
        [self bringEffectWrapperToFront:filterToRemove];
    }
}

@end
