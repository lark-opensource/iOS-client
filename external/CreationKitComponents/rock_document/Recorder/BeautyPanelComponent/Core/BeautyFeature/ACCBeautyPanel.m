//
//  ACCBeautyPanelComponent.m
//  Pods
//

#import "ACCBeautyPanel.h"
#import "ACCBeautyManager.h"
#import <CreationKitInfra/IESEffectModel+AWEExtension.h>
#import "ACCBeautyDataHandler.h"
#import "ACCBeautyComponentConfigProtocol.h"
#import <CreationKitBeauty/AWEComposerBeautyCacheMigration.h>
#import <CreationKitBeauty/ACCBeautyDefine.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import "AWEComposerBeautyViewController+ACCPanelViewProtocol.h"
#import <IESInject/IESInject.h>
#import <CreativeKit/ACCServiceLocator.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCBeautyConfigKeyDefines.h"
#import "ACCBeautyDataService.h"

@interface ACCBeautyPanel ()
@property (nonatomic, strong, readwrite) ACCBeautyPanelViewModel *viewModel; // only contains business name

@property (nonatomic, strong, readwrite) AWEComposerBeautyViewController *composerBeautyViewController;
@property (nonatomic, strong, readwrite) AWEComposerBeautyViewModel *composerVM;
@property (nonatomic, strong, readwrite) AWEComposerBeautyEffectViewModel *effectViewModel;
@property (nonatomic, strong) id<ACCBeautyComponentConfigProtocol> config;
@property (nonatomic, strong) AWEVideoPublishViewModel *publishModel;

@end

@implementation ACCBeautyPanel
IESAutoInject(ACCBaseServiceProvider(), config, ACCBeautyComponentConfigProtocol)

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (instancetype)initWithViewModel:(ACCBeautyPanelViewModel *)viewModel
                  effectViewModel:(AWEComposerBeautyEffectViewModel *)effectViewModel
                     publishModel: (AWEVideoPublishViewModel *)publishModel
{
    self = [super init];
    if (self) {
        _viewModel = viewModel;
        _effectViewModel = effectViewModel;
        _publishModel = publishModel;
    }
    return self;
}


#pragma mark - public methods

- (void)showPanel
{
    [self.panelViewController showPanelView:self.beautyPanelView duration:0.25f];
}

- (void)reloadCurrentPanel
{
    [self p_reloadComposerBeautyPanel];
}

#pragma mark - composer beauty

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
    
    [self p_reloadComposerBeautyPanel];
}

- (void)p_reloadComposerBeautyPanel
{
    if (_composerBeautyViewController) {
        acc_dispatch_main_async_safe(^{
            [self.composerBeautyViewController reloadPanel];
        });
    } else {
        ACCLog(@"not open panel yet");
    }
}

- (void)clearSelection
{
    if (_composerBeautyViewController) {
        acc_dispatch_main_async_safe(^{
            [self.composerBeautyViewController clearSelection];
        });
    } else {
        ACCLog(@"not open panel yet");
    }
}

#pragma mark - getter

- (AWEComposerBeautyViewModel *)composerVM
{
    if (!_composerVM) {
        //viewmodel
        _composerVM = [[AWEComposerBeautyViewModel alloc] initWithEffectViewModel:self.effectViewModel
                                                                     businessName:self.viewModel.businessName
                                                                     publishModel:self.publishModel];
        _composerVM.referExtra = self.dataService.referExtra;
        _composerVM.dataSource = self.composerVMDataSource;
        _composerVM.prefersEnableBeautyCategorySwitch = ACCConfigBool(kConfigBool_studio_enable_record_beauty_switch);
        @weakify(self);
        _composerVM.fetchDataBlock = ^(NSArray<AWEComposerBeautyEffectCategoryWrapper *> * _Nullable categories) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.fetchComposerDataBlock,categories);
        };
        
        _composerVM.downloadStatusChangedBlock = ^(AWEComposerBeautyEffectWrapper * _Nullable effectWrapper, AWEEffectDownloadStatus downloadStatus) {
            @strongify(self);
            [self __handleDownloadStatusChanged:effectWrapper status:downloadStatus];
        };
    }
    return _composerVM;
}

- (AWEComposerBeautyViewController *)composerBeautyViewController
{
    if (!_composerBeautyViewController) {
        _composerBeautyViewController = [[AWEComposerBeautyViewController alloc] initWithViewModel:self.composerVM];
        _composerBeautyViewController.uiConfig.iconStyle = [self p_cellIconStyle];
        _composerBeautyViewController.delegate = self.composerBeautyDelegate;
        @weakify(self);
        _composerBeautyViewController.externalDismissBlock = ^{
            @strongify(self);
            [self.panelViewController dismissPanelView:self.beautyPanelView duration:0.25f];
        };
    }
    return _composerBeautyViewController;
}

- (id<ACCPanelViewProtocol>)beautyPanelView
{
    return self.composerBeautyViewController;
}

#pragma mark - composer beauty notification

- (BOOL)p_useBeautySwitch
{
    return [self.config useBeautySwitch];
}

- (void)__handleDownloadStatusChanged:(AWEComposerBeautyEffectWrapper *)downloadStatusChangedEffectWrapper
                               status:(AWEEffectDownloadStatus)downloadStatus
{
    if (!ACCConfigBool(kConfigBool_enable_advanced_composer) || [self p_useBeautySwitch]) {
        return ;
    }

    BOOL isBeautyOn = [ACCCache() boolForKey:HTSVideoRecorderBeautyKey];

    NSArray *appliedEffects = self.effectViewModel.currentEffects;
    if (downloadStatus == AWEEffectDownloadStatusDownloaded && isBeautyOn) {
       if ([appliedEffects containsObject:downloadStatusChangedEffectWrapper]) {
           for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.composerVM.filteredCategories) {
               for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
                   if (![effectWrapper isEffectSet]) {
                       if ([effectWrapper isEqual:downloadStatusChangedEffectWrapper]) {
                           AWEComposerBeautyEffectWrapper *canceledEffect = nil;
                           if (categoryWrapper.exclusive) {
                               canceledEffect = categoryWrapper.selectedEffect;
                               categoryWrapper.selectedEffect = effectWrapper;
                           }
                           [self.composerBeautyDelegate selectComposerBeautyEffect:effectWrapper ratio:effectWrapper.currentRatio oldEffect:canceledEffect];
                           break;
                       }
                   } else {
                       for (AWEComposerBeautyEffectWrapper *childEffectWrapper in effectWrapper.childEffects) {
                           if ([childEffectWrapper isEqual:downloadStatusChangedEffectWrapper]) {
                               if ([effectWrapper.appliedChildEffect isEqual:downloadStatusChangedEffectWrapper]) {
                                   [self.composerBeautyDelegate selectComposerBeautyEffect:childEffectWrapper ratio:downloadStatusChangedEffectWrapper.currentRatio oldEffect:nil];
                                   break;
                               }
                           }
                       }
                   }
               }
           }
       } else {
           for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.composerVM.filteredCategories) {
               NSString *cachedCandidateForCategory = [self.effectViewModel.cacheObj cachedCandidateChildEffectIDForParentItemID:categoryWrapper.category.categoryIdentifier];
               if ([downloadStatusChangedEffectWrapper.effect.effectIdentifier isEqualToString:cachedCandidateForCategory]) {
                   [self.composerBeautyDelegate selectComposerBeautyEffect:downloadStatusChangedEffectWrapper ratio:downloadStatusChangedEffectWrapper.currentRatio oldEffect:nil];
                   [self.effectViewModel updateSelectedEffect:downloadStatusChangedEffectWrapper forCategory:categoryWrapper];
                   break;
               }
               for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
                   if ([effectWrapper isEffectSet]) {
                       NSString *cachedCandidateForEffect = [self.effectViewModel.cacheObj cachedCandidateChildEffectIDForParentItemID:effectWrapper.effect.effectIdentifier];
                       if ([downloadStatusChangedEffectWrapper.effect.effectIdentifier isEqualToString:cachedCandidateForEffect]) {
                           [self.composerBeautyDelegate selectComposerBeautyEffect:downloadStatusChangedEffectWrapper ratio:downloadStatusChangedEffectWrapper.currentRatio oldEffect:nil];
                           [self.effectViewModel updateAppliedChildEffect:downloadStatusChangedEffectWrapper forEffect:effectWrapper];
                       }
                   }
               }
           }
       }
    }

    //update ui logic
    AWEComposerBeautyEffectWrapper *onScreenEffectWrapper = nil;
    NSString *cachedCandidateForCategory = [self.effectViewModel.cacheObj cachedCandidateChildEffectIDForParentItemID:self.composerVM.currentCategory.category.categoryIdentifier];
    for (AWEComposerBeautyEffectWrapper *effectWrapper in self.composerVM.currentCategory.effects) {
       if ([effectWrapper isEffectSet]) {
           NSString *cachedCandidateForEffect = [self.effectViewModel.cacheObj cachedCandidateChildEffectIDForParentItemID:effectWrapper.effect.effectIdentifier];
           for (AWEComposerBeautyEffectWrapper *childEffectWrapper in effectWrapper.childEffects) {
               if ([childEffectWrapper isEqual:downloadStatusChangedEffectWrapper] || [downloadStatusChangedEffectWrapper.effect.effectIdentifier isEqualToString:cachedCandidateForEffect]) {
                   onScreenEffectWrapper = downloadStatusChangedEffectWrapper;
                   break;
               }
           }
       } else {
           if ([effectWrapper isEqual:downloadStatusChangedEffectWrapper] || [downloadStatusChangedEffectWrapper.effect.effectIdentifier isEqualToString:cachedCandidateForCategory]) {
               onScreenEffectWrapper = downloadStatusChangedEffectWrapper;
               break;
           }
       }
    }
    if (onScreenEffectWrapper) {
       [self p_reloadComposerBeautyPanel];
    }
}

- (AWEBeautyCellIconStyle)p_cellIconStyle
{
    return ACCConfigInt(kConfigInt_beauty_effect_icon_style) == AWEBeautyCellIconStyleRound ? AWEBeautyCellIconStyleRound: AWEBeautyCellIconStyleSquare;
}


@end
