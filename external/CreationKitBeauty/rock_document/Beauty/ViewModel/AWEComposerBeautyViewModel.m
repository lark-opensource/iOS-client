//
//  AWEComposerBeautyViewModel.m
//  CameraClient
//
//  Created by chengfei xiao on 2020/1/19.
//

#import <CreationKitBeauty/AWEComposerBeautyViewModel.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectDownloader.h>
#import <CreationKitInfra/ACCConfigManager.h>

#import <CreativeKit/ACCMacros.h>
#import "CKBConfigKeyDefines.h"

@interface AWEComposerBeautyViewModel()
@property (nonatomic,   copy, readwrite) NSArray<AWEComposerBeautyEffectCategoryWrapper *> *filteredCategories;
@property (nonatomic,   copy, readwrite) NSString *businessName;// DMT is empty by default, other products set - XS / multi flash
@property (nonatomic, strong, readwrite) AWEComposerBeautyEffectCategoryWrapper *currentCategory;
@property (nonatomic, strong, readwrite) AWEComposerBeautyEffectViewModel *effectViewModel;
@property (nonatomic, strong, readwrite) AWEVideoPublishViewModel *publishModel;

@property (nonatomic, assign, readwrite) BOOL needUpdate;
@property (nonatomic, assign, readwrite) BOOL isPrimaryPanelEnabled; // only YES in recording page

@end

@implementation AWEComposerBeautyViewModel

#pragma mark - LifeCycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)initWithEffectViewModel:(AWEComposerBeautyEffectViewModel *)viewModel
                           businessName:(NSString *)businessName
                           publishModel:(AWEVideoPublishViewModel *)publishModel
{
    self = [super init];
    if (self) {
        _effectViewModel = viewModel;
        _businessName = businessName;
        _publishModel = publishModel;
        self.needUpdate = YES;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(p_downloadStatusChanged:)
                                                     name:kAWEComposerBeautyEffectUpdateNotification
                                                   object:nil];
    }
    return self;
}

#pragma mark - public methods

- (void)setReferExtra:(NSDictionary *)referExtra
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithDictionary:referExtra];
    [dict removeObjectForKey:@"shoot_entrance"];
    _referExtra = [dict copy];
}

- (void)setFilteredCategories:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)filteredCategories
{
    /*
     last change is to fix first install issue, but this issue
     is not clear and not fix correctly. so rollback
     */
    _filteredCategories = filteredCategories;
}

- (void)setCurrentCategory:(AWEComposerBeautyEffectCategoryWrapper *)currentCategory
{
    /*
     Bug path:
     1. first fetch the cache, then crawl from the web, the object address generated before and after is different.
     2. userSelected is something that the user clicked, but did not select. For example, in the download. userSelected is used when
        After the download is complete, after receiving a notification, determine whether the selected, the value is stored in memory temporarily.
     3. If the user comes in and quickly clicks on the Beauty panel, this uses the cached data and clicks to expand a secondary item, which updates the
        userSelected value, then after closing it, the data is refreshed again, and the new data is not synchronised with the userSelected
        This will result in a blank page when the beauty panel is opened again
     */

    if ([_currentCategory.category.categoryIdentifier isEqualToString: currentCategory.category.categoryIdentifier]
        && _currentCategory != nil) {
        
        if (_currentCategory.selectedEffect != nil && currentCategory.selectedEffect == nil) {
            NSString *effectIdentifier = _currentCategory.selectedEffect.effect.effectIdentifier;
            currentCategory.selectedEffect = [self p_findEffect:currentCategory withEffectIdentifier:effectIdentifier];
        }
        if (_currentCategory.userSelectedEffect != nil && currentCategory.userSelectedEffect == nil) {
            NSString *effectIdentifier = _currentCategory.userSelectedEffect.effect.effectIdentifier;
            currentCategory.userSelectedEffect = [self p_findEffect:currentCategory withEffectIdentifier:effectIdentifier];
        }
    }
    _currentCategory = currentCategory;
}

- (void)setSelectedEffect:(AWEComposerBeautyEffectWrapper *)selectedEffect
{
    AWEComposerBeautyEffectWrapper *oldEffectWrapper = _selectedEffect;
    _selectedEffect = selectedEffect;

    AWEComposerBeautyEffectCategoryWrapper *targetCategory = self.currentCategory;

    if (self.currentCategory.isPrimaryCategory) {
        if (self.currentCategory.selectedChildCategory) {
            targetCategory = self.currentCategory.selectedChildCategory;
        }
    }

    if (![selectedEffect isEffectSet]) {

        // cache the ratio of this effect
        [self.effectViewModel updateEffectRatioFromCache:selectedEffect];

        // remove old effect if exclusive
        if (targetCategory.exclusive && oldEffectWrapper) {
            [self.effectViewModel removeEffectWrapperFromAppliedEffects:oldEffectWrapper];
        }

        // update selected effect on target category
        if (targetCategory.exclusive) {
            [self.effectViewModel updateSelectedEffect:selectedEffect forCategory:targetCategory];
        }

        // update effectViewModel's applied effects
        [self.effectViewModel bringEffectWrapperToEnd:selectedEffect];


        // cache all the applied effects
        [self.effectViewModel cacheAppliedEffects];
    }
}


- (BOOL)enableBeautyCategorySwitch
{
    return self.currentCategory.isSwitchEnabled && self.prefersEnableBeautyCategorySwitch && self.currentCategory.userSelectedEffect.childEffects.count == 0;
}

- (void)enablePrimaryPanel
{
    self.isPrimaryPanelEnabled = YES;
    [self.effectViewModel enablePaternity];
}

#pragma mark - Reset

- (void)resetCategorySwitchState
{
    if ([self prefersEnableBeautyCategorySwitch]) {
        for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.filteredCategories) {
            if (categoryWrapper.isSwitchEnabled) {
                [self.effectViewModel.cacheObj setCategory:categoryWrapper switchOn:YES];
            }
        }
    }
}

- (BOOL)shouldDisableResetButton
{
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.filteredCategories) {
        if (![self isDefaultStatusCategory:categoryWrapper]) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)isDefaultStatusCategory:(AWEComposerBeautyEffectCategoryWrapper *)category
{
    // primary
    if (category.isPrimaryCategory) { // ATTENTION: here is a recursion
        
        BOOL selectNoDefaultCategory = category.selectedChildCategory &&
                                        category.defaultChildCategory &&
                                        ![category.selectedChildCategory.category.categoryIdentifier isEqualToString:category.defaultChildCategory.category.categoryIdentifier];
        if (selectNoDefaultCategory) {
            return NO;
        }

        for (AWEComposerBeautyEffectCategoryWrapper *primaryCategory in category.childCategories) {
            if (![self isDefaultStatusCategory:primaryCategory]) {
                return NO;
            }
        }
        return YES;
    }

    for (AWEComposerBeautyEffectWrapper *effectWrapper in category.effects) {
        if (![effectWrapper isInDefaultStatus]) {
            return NO;
        }
    }
    return YES;
}

- (void)resetAllComposerBeautyEffects
{
    AWEComposerBeautyEffectCategoryWrapper *selectedCategory = self.currentCategory;
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.filteredCategories) {

        // update current category
        if ([categoryWrapper.category.categoryIdentifier isEqualToString:selectedCategory.category.categoryIdentifier]) {
            selectedCategory = categoryWrapper;
        }

        // primary
        if (categoryWrapper.isPrimaryCategory) {
            for (AWEComposerBeautyEffectCategoryWrapper *childCategory in categoryWrapper.childCategories) {
                [self resetAllComposerBeautyEffectsOfCategory:childCategory];
            }
            categoryWrapper.selectedChildCategory = categoryWrapper.defaultChildCategory;
            [self.effectViewModel updateSelectedChildCateogry:categoryWrapper.selectedChildCategory lastChildCategory:nil forPrimaryCategory:categoryWrapper];
                        continue;
        }

        // normal
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            if ([effectWrapper isEffectSet]) {
                [self p_resetAppliedChildEffectForEffect:effectWrapper];
                for (AWEComposerBeautyEffectWrapper *childEffect in effectWrapper.childEffects) {
                    [self p_resetRatioForEffect:childEffect];
                }
            } else {
                [self p_resetRatioForEffect:effectWrapper];
            }
        }
        if (categoryWrapper.exclusive) {
            [self p_resetDefaultEffectForCategory:categoryWrapper];
        }
    }
    [self.effectViewModel clearAppliedEffects];
    [self.effectViewModel updateAppliedEffectsWithCategories:self.filteredCategories];
    self.currentCategory = selectedCategory; // would reload Panel
}

// reset category for primary reset mode
- (void)resetAllComposerBeautyEffectsOfCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
        if ([effectWrapper isEffectSet]) {
            [self p_resetAppliedChildEffectForEffect:effectWrapper];
            for (AWEComposerBeautyEffectWrapper *childEffect in effectWrapper.childEffects) {
                [self p_resetRatioForEffect:childEffect];
            }
        } else {
            [self p_resetRatioForEffect:effectWrapper];
        }
    }
    if (categoryWrapper.exclusive) {
        [self p_resetDefaultEffectForCategory:categoryWrapper];
    }
}

/// Set the intensity of all items in the category to 0
/// @param categoryWrapper AWEComposerBeautyEffectCategoryWrapper
- (void)resetComposerCategoryAllItemToZero:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    if (categoryWrapper.exclusive) {
        return;
    }
    
    for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
        if ([effectWrapper isEffectSet]) {
            [self p_resetAppliedChildEffectForEffect:effectWrapper];
            for (AWEComposerBeautyEffectWrapper *childEffect in effectWrapper.childEffects) {
                [self p_clearRatioForEffect:childEffect];
            }
        } else {
            [self p_clearRatioForEffect:effectWrapper];
        }
    }
}

- (void)p_resetRatioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    double defaultValue = [effectWrapper defaultRatio];
    effectWrapper.currentRatio = defaultValue;
    [self.effectViewModel.cacheObj setRatio:defaultValue forEffect:effectWrapper];
}

- (void)p_clearRatioForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    effectWrapper.currentRatio = 0;
    [self.effectViewModel.cacheObj setRatio:0 forEffect:effectWrapper];
}

- (void)p_resetAppliedChildEffectForEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if (![effectWrapper isEffectSet]) {
        return ;
    }
    AWEComposerBeautyEffectWrapper *defaultChild = [effectWrapper defaultChildEffect];
    [self.effectViewModel updateAppliedChildEffect:defaultChild forEffect:effectWrapper];
}

- (void)p_resetDefaultEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    if (!categoryWrapper.exclusive) {
        return ;
    }
    AWEComposerBeautyEffectWrapper *defaultEffect = [self p_defaultAppliedEffectForCategory:categoryWrapper];
    [self.effectViewModel updateSelectedEffect:defaultEffect forCategory:categoryWrapper];
}

- (AWEComposerBeautyEffectWrapper *)p_defaultAppliedEffectForCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    if (!categoryWrapper.exclusive) {
        return nil;
    }
    for (AWEComposerBeautyEffectWrapper *effect in categoryWrapper.effects) {
        if (effect.isDefault) {
            return effect;
        }
    }
    return [categoryWrapper.effects firstObject];
}

#pragma mark - Fetch data

// load cache resource, if no cache, fetch Effects

- (void)fetchBeautyEffects
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @weakify(self);
        [self.effectViewModel loadCachedEffectsWithCompletion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *cachedCategories, BOOL success) {
            @strongify(self);
            acc_dispatch_main_async_safe(^{
                NSArray<AWEComposerBeautyEffectCategoryWrapper *> *localCategories = cachedCategories;
                if (localCategories.count == 0) {
                    localCategories = [self.dataSource buildInCategories];
                }
                ACCBLOCK_INVOKE(self.fetchDataBlock, localCategories);
                if (self.needUpdate || !cachedCategories.count) {
                    [self.effectViewModel fetchUpdatedEffectsForce:cachedCategories.count == 0 completion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> * _Nullable updatedCategories, BOOL success) {
                        acc_dispatch_main_async_safe(^{
                            @strongify(self)
                            if (success) {
                                self.needUpdate = NO;
                                BOOL noNewUpdate = ACC_isEmptyArray(updatedCategories) && success;
                                
                                // If there is no need to update, an empty array will be returned. At this time, there is no need to refresh the original data and use the cache
                                if (!noNewUpdate || ACC_isEmptyArray(localCategories)) {
                                    ACCBLOCK_INVOKE(self.fetchDataBlock, updatedCategories);
                                }
                            }
                        });
                    }];
                }
            });
        }];
    });
}

#pragma mark - notification

- (void)p_downloadStatusChanged:(NSNotification *)notification
{
    NSObject *object = notification.object;
    if ([object isKindOfClass:[AWEComposerBeautyEffectWrapper class]]) {
        AWEComposerBeautyEffectWrapper *downloadStatusChangedEffectWrapper = (AWEComposerBeautyEffectWrapper *)object;
        AWEEffectDownloadStatus downloadStatus = [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadStatusOfEffect:downloadStatusChangedEffectWrapper];
        ACCBLOCK_INVOKE(self.downloadStatusChangedBlock,downloadStatusChangedEffectWrapper,downloadStatus);
    }
}

#pragma mark - Private

- (AWEComposerBeautyEffectWrapper *)p_findEffect:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
                          withEffectIdentifier:(NSString *)effectIdentifier
{
    for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
        
        if ([effectWrapper.effect.effectIdentifier isEqualToString:effectIdentifier]) {
            return effectWrapper;
        }
    }
    return nil;
}

@end
