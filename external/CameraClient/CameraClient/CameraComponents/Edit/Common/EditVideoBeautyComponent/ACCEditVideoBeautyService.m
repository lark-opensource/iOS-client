//
//  ACCEditVideoBeautyService.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2021/1/17.
//

#import "ACCEditVideoBeautyService.h"
#import "ACCBeautyBuildInDataSourceImpl.h"
#import <CreationKitArch/ACCRepoBeautyModel.h>
#import <CreationKitComponents/ACCBeautyDataHandler.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import <CreationKitBeauty/AWEComposerBeautyEffectDownloader.h>
#import "ACCEditVideoBeautyRestorer.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreativeKit/ACCMacros.h>

@interface ACCEditVideoBeautyService()

@property (nonatomic, strong, readonly) ACCRepoBeautyModel *repoBeautyModel;

@end

@implementation ACCEditVideoBeautyService

IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)

#pragma mark - Setter & Getter

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
}

- (AWEComposerBeautyViewModel *)composerVM
{
    if (!_composerVM) {
        _composerVM = [[AWEComposerBeautyViewModel alloc] initWithEffectViewModel:self.effectViewModel
                                                                     businessName:@"editbeauty"                       
                                                                     publishModel:self.inputData.publishModel];
        _composerVM.referExtra = self.inputData.publishModel.repoTrack.referExtra;
        _composerVM.prefersEnableBeautyCategorySwitch = NO;
        _composerVM.dataSource = [[ACCBeautyBuildInDataSourceImpl alloc] init];
        @weakify(self);
        _composerVM.fetchDataBlock = ^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> * _Nullable categories) {
            @strongify(self);
            [self p_handleCategoriesLoaded:categories];
        };
        
        _composerVM.downloadStatusChangedBlock = ^(AWEComposerBeautyEffectWrapper * _Nullable effectWrapper, AWEEffectDownloadStatus downloadStatus) {
            @strongify(self);
            [self handleDownloadStatusChanged:effectWrapper];
        };
    }
    return _composerVM;
}

- (AWEComposerBeautyEffectViewModel *)effectViewModel {
    if (!_effectViewModel) {
        ACCBeautyDataHandler *dataHandler = [[ACCBeautyDataHandler alloc]init];
        _effectViewModel = [[AWEComposerBeautyEffectViewModel alloc] initWithCacheViewModel:nil
                                                                                  panelName:nil
                                                                           migrationHandler:nil
                                                                                dataHandler:dataHandler];
        [_effectViewModel updateWithGender:self.repoBeautyModel.gender
                            cameraPosition:AWEComposerBeautyCameraPositionFront];
    }
    return _effectViewModel;
}

- (ACCRepoBeautyModel *)repoBeautyModel
{
    return self.inputData.publishModel.repoBeauty;
}


#pragma mark - Public

- (void)fetchBeautyEffects
{
    [self.composerVM fetchBeautyEffects];
}

- (void)resetAllComposerBeautyEffectsValueAndRemoveAll
{
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.composerVM.filteredCategories) {
        AWEComposerBeautyEffectWrapper *noneEffect = nil;
        AWEComposerBeautyEffectWrapper *defaultEffect = nil;
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            if ([effectWrapper isEffectSet]) {
                for (AWEComposerBeautyEffectWrapper *childEffect in effectWrapper.childEffects) {
                    childEffect.currentRatio = 0;
                    
                    [self removeComposerBeautyEffect:childEffect];
                    if (childEffect.isDefault) {
                        effectWrapper.appliedChildEffect = childEffect;
                    }
                }
            } else {
                effectWrapper.currentRatio = 0;
                [self removeComposerBeautyEffect:effectWrapper];
            }
            
            if (effectWrapper.isNone) {
                noneEffect = effectWrapper;
            }
            if (effectWrapper.isDefault) {
                defaultEffect = effectWrapper;
            }
            
            if (categoryWrapper.exclusive) {
                categoryWrapper.selectedEffect = defaultEffect ?: noneEffect;
                categoryWrapper.userSelectedEffect = defaultEffect ?: noneEffect;
            }
        }
    }
}

- (void)clearAllEffectAndReset
{
    [self resetAllComposerBeautyEffectsValueAndRemoveAll];
    
    self.repoBeautyModel.beautyValueDic = @{};
    self.repoBeautyModel.selectedAlbumDic = @{};
    self.repoBeautyModel.selectedBeautyDic = @{};
}


- (void)resetAllEffectToCurrentDraftInfo
{
    [self resumeBeautyEffectFromDraftWithData:self.composerVM.filteredCategories];
}

- (BOOL)hadChangeBeautyCompareDraft
{
    return ![[self generateBeautyValueDic] isEqualToDictionary:self.repoBeautyModel.beautyValueDic ?: @{}]
    || ![[self generateSelectedBeautyDic] isEqualToDictionary:(self.repoBeautyModel.selectedBeautyDic.allKeys.count > 0 ? self.repoBeautyModel.selectedBeautyDic : [self generateDefaultSelectedBeautyDic])]
    || ![[self generateSelectedAlbumDic] isEqualToDictionary:self.repoBeautyModel.selectedAlbumDic ?: @{}];
}

- (void)updateDraftBeautyInfo
{
    self.repoBeautyModel.beautyValueDic = [self generateBeautyValueDic];
    self.repoBeautyModel.selectedBeautyDic = [self generateSelectedBeautyDic];
    self.repoBeautyModel.selectedAlbumDic = [self generateSelectedAlbumDic];
    self.repoBeautyModel.appliedEffectIds = [self generateAppliedEffectIds];
}

- (void)resumeBeautyEffectFromDraft
{
    NSDictionary *beautyValueDic = [self repoBeautyModel].beautyValueDic;
    if (beautyValueDic.allKeys.count == 0) {
        return;
    }
    
    if (self.composerVM.filteredCategories.count > 0) {
        [self resumeBeautyEffectFromDraftWithData:self.composerVM.filteredCategories];
    } else {
        @weakify(self);
        [self.composerVM.effectViewModel loadCachedEffectsWithCompletion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> * _Nullable categories, BOOL success) {
            @strongify(self);
            if (categories.count == 0) {
                [self fetchBeautyEffects];
                return;
            }
            
            [self.effectViewModel filterCategories:categories
                                                                   withGender:self.repoBeautyModel.gender
                                                               cameraPosition:AWEComposerBeautyCameraPositionFront
                                                                   completion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *filteredCategories, BOOL success) {
                
                @strongify(self);
                [self resumeBeautyEffectFromDraftWithData:filteredCategories];
            }];
            
        }];
    }
}

- (void)updateAvailabilityForEffectsInCategories:(NSArray *)categories
{
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in categories) {
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            if (![effectWrapper isEffectSet]) {
                effectWrapper.available = [self availabilityForEffectWrapper:effectWrapper];
            } else {
                effectWrapper.available = YES;
                BOOL atLeastOneChildAvailable = NO;
                for (AWEComposerBeautyEffectWrapper *childEffect in effectWrapper.childEffects) {
                    childEffect.available = [self availabilityForEffectWrapper:childEffect];
                    if (childEffect.available) {
                        atLeastOneChildAvailable = YES;
                    }
                }
                effectWrapper.available = atLeastOneChildAvailable;
            }
        }
    }
}

#pragma mark - Private

- (BOOL)availabilityForEffectWrapper:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    BOOL available = YES;
    NSString *resourcePath = effectWrapper.effect.resourcePath;
    if (ACC_isEmptyString(resourcePath)) {
        // 还没下载的都算是可点击、可用
        return YES;
    }
    if (ACC_isEmptyArray(effectWrapper.items)) {
        IESComposerJudgeResult *judgeResult = [self.editService.effect judgeComposerPriority:effectWrapper.effect.resourcePath tag:@""];
        NSInteger result = judgeResult.result;
        if (result < 0) {
            available = NO;
        }
    } else {
        for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
            IESComposerJudgeResult *judgeResult = [self.editService.effect judgeComposerPriority:effectWrapper.effect.resourcePath tag:[item tag]];
            NSInteger result = judgeResult.result;
            if (result < 0) {
                available = NO;
                break;
            }
        }
    }
    return available;
}

- (void)resumeBeautyEffectFromDraftWithData:(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    [self clearAllComposerBeautyEffects];
    NSArray<AWEComposerBeautyEffectWrapper *> *lastAppliedEffects = [ACCEditVideoBeautyRestorer effectsToApplyForResume:[self.inputData publishModel] forCategories:categories];
    
    for (AWEComposerBeautyEffectWrapper *effectWrapper in lastAppliedEffects) {
        
        if (effectWrapper.downloaded) {
            [self applyEffect:effectWrapper replaceOldEffect:nil autoRemoveZeroRatio:YES];
        } else {
            [[AWEComposerBeautyEffectDownloader defaultDownloader] downloadEffects:@[effectWrapper]];
        }
    }
}

- (void)p_handleCategoriesLoaded:(NSArray <AWEComposerBeautyEffectCategoryWrapper *> *)categories
{
    @weakify(self);
    [self.effectViewModel filterCategories:categories
                                                           withGender:self.repoBeautyModel.gender
                                                       cameraPosition:AWEComposerBeautyCameraPositionFront
                                                           completion:^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> *categories, BOOL success) {
        @strongify(self);
        if (categories.count == 0) {
            [self.composerVM setFilteredCategories:[self.composerVM.dataSource buildInCategories]];
        } else {
            [self.composerVM setFilteredCategories:categories];
        }
        [self updateCurrentComposerCategory];
        [self resumeBeautyEffectFromDraftWithData:categories];
        [self updateAvailabilityForEffectsInCategories:categories];
    }];
}

- (void)updateCurrentComposerCategory
{
    NSString *cachedCategoryKey = [self.effectViewModel.cacheObj cachedSelectedCategory];
    AWEComposerBeautyEffectCategoryWrapper *currentCategory = [self.composerVM.filteredCategories firstObject];
    for (AWEComposerBeautyEffectCategoryWrapper *category in self.composerVM.filteredCategories) {
        if ([category.category.categoryIdentifier isEqualToString:cachedCategoryKey]) {
            currentCategory = category;
            break;
        } else if (category.isDefault) {
            currentCategory = category;
        }
    }
    [self.composerVM setCurrentCategory:currentCategory];
}


- (NSDictionary *)generateBeautyValueDic
{
    NSMutableDictionary<NSString *, NSNumber *> *beautyValueDic = [NSMutableDictionary dictionary];
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.composerVM.filteredCategories) {
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            
            if ([effectWrapper isEffectSet]) {
                for (AWEComposerBeautyEffectWrapper *childEffectWrapper in effectWrapper.childEffects) {
                    
                    if (!ACC_FLOAT_EQUAL_ZERO(childEffectWrapper.currentRatio)) {
                        beautyValueDic[childEffectWrapper.effect.resourceId] = @([childEffectWrapper currentSliderValue]);
                    }
                }
            } else {
                if (!ACC_FLOAT_EQUAL_ZERO(effectWrapper.currentRatio)) {
                    beautyValueDic[effectWrapper.effect.resourceId] = @([effectWrapper currentSliderValue]);
                }
            }
        }
    }
    
    return [beautyValueDic copy];
}

- (NSDictionary *)generateSelectedBeautyDic
{
    NSMutableDictionary<NSString *, NSString *> *selectedBeautyDic = [NSMutableDictionary dictionary];
    
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.composerVM.filteredCategories) {
        
        if (categoryWrapper.exclusive) {
            selectedBeautyDic[categoryWrapper.category.categoryIdentifier] = categoryWrapper.selectedEffect.effect.effectIdentifier;
        }
    }
    
    return [selectedBeautyDic copy];
}

- (NSDictionary *)generateDefaultSelectedBeautyDic
{
    NSMutableDictionary<NSString *, NSString *> *selectedBeautyDic = [NSMutableDictionary dictionary];
    
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.composerVM.filteredCategories) {
        
        if (categoryWrapper.exclusive) {
            AWEComposerBeautyEffectWrapper *noneEffect = nil;
            AWEComposerBeautyEffectWrapper *defaultEffect = nil;
            for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
                if (effectWrapper.isNone) {
                    noneEffect = effectWrapper;
                }
                if (effectWrapper.isDefault) {
                    defaultEffect = effectWrapper;
                }
                selectedBeautyDic[categoryWrapper.category.categoryIdentifier] = defaultEffect.effect.effectIdentifier ?: noneEffect.effect.effectIdentifier;
            }
        }
    }
    
    return [selectedBeautyDic copy];
}


/// 构造记录所有选中的二级小项的关系
- (NSDictionary *)generateSelectedAlbumDic
{
    NSMutableDictionary<NSString *, NSString *> *selectedAlbumDic = [NSMutableDictionary dictionary];
    
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.composerVM.filteredCategories) {
        
        for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
            // 如果选中的是默认二级小项，而且强度值为0，不记录
            if (!categoryWrapper.exclusive && effectWrapper.isEffectSet) {
                if (effectWrapper.appliedChildEffect.currentRatio > 0 || ![effectWrapper.appliedChildEffect isEqual:effectWrapper.defaultChildEffect]) {
                    
                    selectedAlbumDic[effectWrapper.effect.resourceId] = effectWrapper.appliedChildEffect.effect.resourceId;
                }
            }
        }
    }
    
    return selectedAlbumDic;
}


/// 生成所有当前应用的美颜的Effect ID，滑竿值不为0
- (NSArray *)generateAppliedEffectIds
{
    NSMutableArray<NSString *> *appliedEffectIds = [NSMutableArray array];
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.composerVM.filteredCategories) {
        
        if (categoryWrapper.exclusive) {
            if (!ACC_FLOAT_EQUAL_ZERO(categoryWrapper.selectedEffect.currentRatio)) {
                [appliedEffectIds addObject:categoryWrapper.selectedEffect.effect.effectIdentifier];
            }
        } else {
            for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
                
                if ([effectWrapper isEffectSet]) {
                    if (!ACC_FLOAT_EQUAL_ZERO(effectWrapper.appliedChildEffect.currentRatio)) {
                        [appliedEffectIds addObject:effectWrapper.appliedChildEffect.effect.effectIdentifier];
                    }
                } else {
                    if (!ACC_FLOAT_EQUAL_ZERO(effectWrapper.currentRatio)) {
                        [appliedEffectIds addObject:effectWrapper.effect.effectIdentifier];
                    }
                }
            }
        }
    }
    
    return [appliedEffectIds copy];
}

- (void)removeComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
//    if (effectWrapper) {
//        NSArray *nodes = [effectWrapper nodes];
//        [self.editService.beauty removeComposerNodesWithTags:nodes];
//    }
    
    if (effectWrapper) {
        [self.editService.beauty removeBeautyEffects:@[effectWrapper]];
    }
}

- (void)removeComposerBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effects
{
    [self.editService.beauty removeBeautyEffects:effects];
}

- (void)applyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
   replaceOldEffect:(AWEComposerBeautyEffectWrapper *)oldEffectWrapper
{
    [self applyEffect:effectWrapper replaceOldEffect:oldEffectWrapper autoRemoveZeroRatio:NO];
}


/// append 某个美颜，并替换旧的，同时更新强度效果
/// @param effectWrapper 新美颜
/// @param oldEffectWrapper 旧美颜
/// @param autoRemoveZeroRatio BOOL 如果强度是0，是否主动remove，而不是更新强度
- (void)applyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
   replaceOldEffect:(AWEComposerBeautyEffectWrapper *)oldEffectWrapper
autoRemoveZeroRatio:(BOOL)autoRemoveZeroRatio
{
    // 如果替换特效用replace，否则用add
    if (oldEffectWrapper && oldEffectWrapper != effectWrapper) {
//        NSArray *oldNodes = [oldEffectWrapper nodes];
//        NSArray *nodes = [effectWrapper nodes];
//        [self.editService.beauty replaceComposerNodesWithNewTag:nodes
//                                                            old:oldNodes];
        
        [self.editService.beauty replaceComposerBeauty:effectWrapper withOld:oldEffectWrapper];
    } else {
//        NSArray *nodes = [effectWrapper nodes];
//        [self.editService.beauty appendComposerNodesWithTags:nodes];
        
        [self.editService.beauty appendComposerBeautys:@[effectWrapper]];
    }
    [self updateEffectWithRatio:effectWrapper.currentRatio
                      forEffect:effectWrapper
            autoRemoveZeroRatio:autoRemoveZeroRatio];
}


/// 更新美颜强度。记住，必须是先append 美颜后，此方法才可以正常应用
/// @param ratio 比例值，相对于滑竿
/// @param effectWrapper 美颜小项
/// @param autoRemoveZeroRatio BOOL 如果强度是0，是否主动remove，而不是更新强度，
///        remove更好，但是某些场景不希望频繁remove和append，比如调节滑竿值到0的时候又不松手
- (void)updateEffectWithRatio:(float)ratio
                    forEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
          autoRemoveZeroRatio:(BOOL)autoRemoveZeroRatio
{
    if (ACC_FLOAT_EQUAL_ZERO(ratio) && autoRemoveZeroRatio) {
        [self removeComposerBeautyEffect:effectWrapper];
    } else {
//        for (AWEComposerBeautyEffectItem *item in effectWrapper.items) {
//            float value = [item effectValueForRatio:ratio];
//            [self.editService.beauty updateComposerNode:effectWrapper.effect.resourcePath key:item.tag value:value];
//        }
        
        effectWrapper.currentRatio = ratio;
        [self.editService.beauty updateBeautyEffect:effectWrapper];
    }
}


/// 清除当前已应用的所有美颜
- (void)clearAllComposerBeautyEffects
{
    NSArray<AWEComposerBeautyEffectWrapper *> *effects = self.effectViewModel.currentEffects;
    [self clearComposerBeautyEffects:effects];
}

- (void)clearComposerBeautyEffects:(NSArray<AWEComposerBeautyEffectWrapper *> *)effectWrappers
{
//    NSMutableArray *nodeTags = [NSMutableArray new];
//    for (AWEComposerBeautyEffectWrapper *effectWrapper in effectWrappers) {
//        if ([effectWrapper downloaded]) {
//            [nodeTags addObjectsFromArray:[effectWrapper nodes]];
//        }
//    }
//    [self.editService.beauty removeComposerNodesWithTags:nodeTags];
    
    [self.editService.beauty removeBeautyEffects:effectWrappers];
}


- (void)handleDownloadStatusChanged:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    if (!effectWrapper.downloaded) {
        return;
    }
    NSDictionary *beautyValueDic = [self repoBeautyModel].beautyValueDic;
    
    NSNumber *sliderNum = ACCDynamicCast(beautyValueDic[effectWrapper.effect.resourceId], NSNumber);
    CGFloat sliderValue = [sliderNum floatValue];
    [effectWrapper updateRatioWithSliderValue:sliderValue];
    
    if (sliderNum && !ACC_FLOAT_EQUAL_ZERO(sliderValue)) {
        if (effectWrapper.categoryWrapper.exclusive && [effectWrapper.categoryWrapper.selectedEffect isEqual:effectWrapper]) {
            [self applyEffect:effectWrapper replaceOldEffect:nil autoRemoveZeroRatio:YES];
        }
        
        if (!effectWrapper.categoryWrapper.exclusive) {
            if (effectWrapper.parentEffect.isEffectSet && [effectWrapper.parentEffect.appliedChildEffect isEqual:effectWrapper]) {
                [self applyEffect:effectWrapper replaceOldEffect:nil autoRemoveZeroRatio:YES];
            } else if (!effectWrapper.parentEffect.isEffectSet) {
                [self applyEffect:effectWrapper replaceOldEffect:nil autoRemoveZeroRatio:YES];
            }
        }
    }
}


@end
