//
//  ACCEditVideoBeautyComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by zhangyuanming on 2020/11/24.
//

#import "ACCEditVideoBeautyComponent.h"
#import <CreationKitInfra/ACCLogProtocol.h>
#import "ACCEditToolBarContainer.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCEditTransitionServiceProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCEditVideoBeautyViewController.h"
#import "ACCConfigKeyDefines.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCEditVideoBeautyService.h"
#import <CreationKitArch/ACCRepoBeautyModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel+Repository.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreationKitArch/ACCRepoBeautyModel.h>
#import "ACCEditVideoBeautyRestorer.h"
#import "ACCEditVideoBeautyServiceProtocol.h"
#import "ACCDraftProtocol.h"
#import <EffectPlatformSDK/EffectPlatform.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import "ACCVideoEditStickerContainerConfig.h"
#import "ACCStickerServiceProtocol.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/AWERepoDraftModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import "ACCEditBarItemExtraData.h"
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarAdapterUtils.h"
#import <CameraClientModel/ACCVideoCanvasType.h>

@interface ACCEditVideoBeautyComponent()<
ACCEditVideoBeautyViewControllerDelegate,
ACCEditSessionLifeCircleEvent
>

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) ACCEditVideoBeautyViewController *composerBeautyViewController;
@property (nonatomic, strong) ACCEditVideoBeautyService *beautyService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;

@end

@implementation ACCEditVideoBeautyComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)

#pragma mark - LifeCycle

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (void)loadComponentView {
    if (ACCConfigBool(kConfigBool_enable_editor_beauty) &&
        [self publishModel].repoVideoInfo.canvasType != ACCVideoCanvasTypeShareAsStory &&
        [self publishModel].repoVideoInfo.canvasType != ACCVideoCanvasTypeRePostVideo) {
        [self.viewContainer addToolBarBarItem:[self beautyBarItem]];
    }
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - Get & Set

- (AWEVideoPublishViewModel *)publishModel
{
    return self.beautyService.inputData.publishModel;
}

- (ACCEditVideoBeautyService *)beautyService
{
    if (!_beautyService) {
        _beautyService = [self.modelFactory createViewModel:[ACCEditVideoBeautyService class]];
    }
    return _beautyService;
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCEditVideoBeautyServiceProtocol), self.beautyService);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.editService addSubscriber:self];
}

- (ACCRepoBeautyModel *)repoBeautyModel
{
    return [self publishModel].repoBeauty;
}

#pragma mark - Action

- (void)beautyClicked
{
    [self.viewContainer.topRightBarItemContainer resetFoldState];
    self.editService.preview.stickerEditMode = YES;
    [self.editService.preview pause];
    [self.beautyService updateAvailabilityForEffectsInCategories:self.beautyService.composerVM.filteredCategories];
    
    @weakify(self);
    ACCStickerContainerView *stickerContainerView = [self.stickerService.stickerContainer copyForContext:@"" modConfig:^(NSObject<ACCStickerContainerConfigProtocol> * _Nonnull config) {
        if ([config isKindOfClass:ACCVideoEditStickerContainerConfig.class]) {
            ACCVideoEditStickerContainerConfig *rConfig = (id)config;
            [rConfig reomoveSafeAreaPlugin];
            [rConfig removeAdsorbingPlugin];
            [rConfig removePreviewViewPlugin];
        }
    } modContainer:^(ACCStickerContainerView * _Nonnull stickerContainerView) {
        @strongify(self);
        [stickerContainerView configWithPlayerFrame:self.stickerService.stickerContainer.frame
                                          allowMask:NO];
    } enumerateStickerUsingBlock:^(__kindof ACCBaseStickerView * _Nonnull stickerView, NSUInteger idx, ACCStickerGeometryModel * _Nonnull geometryModel, ACCStickerTimeRangeModel * _Nonnull timeRangeModel) {
        stickerView.config.showSelectedHint = NO;
        stickerView.config.secondTapCallback = NULL;
        geometryModel.preferredRatio = NO;
        stickerView.stickerGeometry.preferredRatio = NO;
    }];
    
    ACCEditVideoBeautyViewController *beautyViewController = [[ACCEditVideoBeautyViewController alloc]
                              initWithViewModel:self.beautyService.composerVM
                                    editService:self.editService
                              stickerContainerView:stickerContainerView];
    _composerBeautyViewController = beautyViewController;
    _composerBeautyViewController.uiConfig.iconStyle = [self cellIconStyle];
    _composerBeautyViewController.delegate = self;
    _composerBeautyViewController.externalDismissBlock = ^{
        @strongify(self);
        [self dismissBeautyPanel];
    };
    [self.transitionService presentViewController:self.composerBeautyViewController completion:nil];
    
    NSMutableDictionary *attributes = [self.publishModel.repoTrack.referExtra mutableCopy];
    attributes[@"enter_from"] = @"video_edit_page";
    [ACCTracker() trackEvent:@"click_beautify_entrance" params:attributes needStagingFlag:NO];
}

#pragma mark - Private

- (ACCBarItem<ACCEditBarItemExtraData*>*)beautyBarItem {
    ACCBarItemResourceConfig *config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarBeautyContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* barItem = [[ACCBarItem alloc] init];
    barItem.title = config.title;
    barItem.imageName = config.imageName;
    barItem.location = config.location;
    barItem.itemId = ACCEditToolBarBeautyContext;
    barItem.type = ACCBarItemFunctionTypeCover;
    @weakify(self);
    barItem.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        [self beautyClicked];
    };
    barItem.needShowBlock = ^BOOL{
        return ACCConfigBool(kConfigBool_enable_editor_beauty);
    };
    barItem.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeFilter];
    return barItem;
}


- (AWEBeautyCellIconStyle)cellIconStyle
{
    return ACCConfigInt(kConfigInt_beauty_effect_icon_style) == AWEBeautyCellIconStyleRound ? AWEBeautyCellIconStyleRound: AWEBeautyCellIconStyleSquare;
}

- (void)dismissBeautyPanel
{
    self.editService.preview.stickerEditMode = NO;
    @weakify(self);
    [self.transitionService dismissViewController:self.composerBeautyViewController
                                       completion:^{
        @strongify(self);
        self.composerBeautyViewController = nil;
        self.editService.preview.stickerEditMode = NO;
        [self.editService.preview seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
            @strongify(self);
            [self.editService.preview play];
        }];
        if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
            [self.viewContainer.topRightBarItemContainer resetFoldState];
        }
    }];
}

- (void)saveDraftIfNeed
{
    if (!self.publishModel.repoDraft.isDraft) {
        [ACCDraft() saveDraftWithPublishViewModel:self.publishModel
                                            video:self.publishModel.repoVideoInfo.video
                                           backup:!self.publishModel.repoDraft.originalDraft
                                       completion:^(BOOL success, NSError *error) {
            if (error) {
                ACC_LogError(@"save draft error: %@", error);
                ACCLog(@"save draft error: %@", error);
            }
        }];
    }
}

#pragma mark - ACCEditSessionLifeCircleEvent

- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService
{
    if (ACCConfigBool(kConfigBool_enable_editor_beauty)) {
        [self.beautyService fetchBeautyEffects];
    }
}

- (void)onCreateEditSessionCompletedWithEditService:(id<ACCEditServiceProtocol>)editService
{
    // 从草稿箱可以点击草稿直接进入发布页，这时不会触发firstRender 回调，所以恢复逻辑需要放在这里
    if (ACCConfigBool(kConfigBool_enable_editor_beauty)) {
        [self.beautyService resumeBeautyEffectFromDraft];
    }
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(nonnull AWEVideoPublishViewModel *)publishModel {
    
    if (ACCConfigBool(kConfigBool_enable_editor_beauty)) {
        NSArray *effectIds = [ACCEditVideoBeautyRestorer effectIdsToDownloadForResume:publishModel];
        return effectIds;
    }
    return @[];
}


#pragma mark - ACCEditVideoBeautyViewControllerDelegate

- (void)applyComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                            ratio:(float)ratio
{
    [self.beautyService updateEffectWithRatio:ratio
                                forEffect:effectWrapper
                      autoRemoveZeroRatio:NO];
}

- (void)selectComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
                             ratio:(float)ratio
                         oldEffect:(AWEComposerBeautyEffectWrapper *)oldEffectWrapper
{
    effectWrapper.currentRatio = ratio;
    // for exclusive category with nil old effect wrapper, we just remove all the effects
    // in this category for safety and ve performance
    if (effectWrapper.categoryWrapper.exclusive && !oldEffectWrapper) {
        [self.beautyService removeComposerBeautyEffects:effectWrapper.categoryWrapper.effects];
    }
    [self.beautyService applyEffect:effectWrapper
               replaceOldEffect:oldEffectWrapper];
    // For non mutually exclusive categories, click none to reapply category
    if (effectWrapper.isNone && !effectWrapper.categoryWrapper.exclusive) {
        [self.beautyService removeComposerBeautyEffects:effectWrapper.categoryWrapper.effects];
    }
}

- (void)deselectComposerBeautyEffect:(AWEComposerBeautyEffectWrapper *)effectWrapper
{
    [self.beautyService removeComposerBeautyEffect:effectWrapper];
}

- (void)selectCategory:(AWEComposerBeautyEffectCategoryWrapper *)categoryWrapper
{
    self.repoBeautyModel.lastSelectBeautyCategoryId = categoryWrapper.category.categoryIdentifier;
}

- (void)composerBeautyViewControllerWillReset
{
}

- (void)composerBeautyViewControllerDidReset
{
    [self.beautyService resetAllComposerBeautyEffectsValueAndRemoveAll];
}

- (void)composerBeautyViewControllerDidSwitch:(BOOL)isOn isManually:(BOOL)isManually
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSDictionary *referExtra = self.publishModel.repoTrack.referExtra;

    params[@"enter_from"] = @"video_edit_page";
    params[@"shoot_way"] = self.publishModel.repoTrack.referString; // referstring
    params[@"creation_id"] = self.publishModel.repoContext.createId;
    params[@"content_source"] = referExtra[@"content_source"];
    params[@"content_type"] = referExtra[@"content_type"];
    params[@"status"] = isOn ? @"enable" : @"disable";
    if (isOn) {
        params[@"enable_by"] = isManually ? @"user" : @"auto"; // 点击任意小项大打开美颜开关
    } else {
        params[@"enable_by"] = @"";
    }
    [ACCTracker() trackEvent:@"enable_beautify" params:params];
}

- (void)didClickSaveButton
{
    [self.beautyService updateDraftBeautyInfo];
    [self saveDraftIfNeed];
    [self trackConfirmEdit];
}

- (void)didClickCancelButton
{
    void (^block)(void) = ^ {
        [self.beautyService resetAllEffectToCurrentDraftInfo];
        [self dismissBeautyPanel];
        [self trackCancelEdit];
    };

    BOOL hasChangeBeauty = [self.beautyService hadChangeBeautyCompareDraft];
    if (hasChangeBeauty) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message: ACCLocalizedString(@"auto_caption_editor_unsave", @"确认不保存修改内容吗？")  preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"dont_safe",@"不保存") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            block();
        }]];

        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {

        }]];
        [ACCAlert() showAlertController:alertController animated:YES];

    } else {
        block();
    }
}


#pragma mark - Track

- (void)trackCancelEdit
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self publishModel].repoTrack.referExtra];
    params[@"enter_from"] = @"video_edit_page";
    [ACCTracker() trackEvent:@"exit_beautify_entrance"
                      params:params
             needStagingFlag:NO];
}

- (void)trackConfirmEdit
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:[self publishModel].repoTrack.referExtra];
    NSMutableString *beautifyNameParentList = [NSMutableString string];
    NSMutableString *beautifyIdParentList = [NSMutableString string];
    NSMutableString *beautifyNameChildList = [NSMutableString string];
    NSMutableString *beautifyIdChildList = [NSMutableString string];
    NSMutableString *beautifyValueList = [NSMutableString string];
    
    void(^appendData)(AWEComposerBeautyEffectWrapper *parent, AWEComposerBeautyEffectWrapper *child) = ^(AWEComposerBeautyEffectWrapper *parent, AWEComposerBeautyEffectWrapper *child) {
      
        if (ACC_FLOAT_EQUAL_ZERO(child.currentRatio)) {
            return;
        }
        IESEffectModel *effect = parent.effect;
        IESEffectModel *childEffect = child.effect ?: effect;
        NSString *appendStr = [NSString stringWithFormat:@"%@,", effect.effectName];
        NSString *appendChildStr = [NSString stringWithFormat:@"%@,", childEffect.effectName];
        NSString *appendId = [NSString stringWithFormat:@"%@,", effect.resourceId];
        NSString *appendChildId = [NSString stringWithFormat:@"%@,", childEffect.resourceId];
        NSString *appendValue = [NSString stringWithFormat:@"%i,", (int)(child.currentSliderValue)];
        [beautifyNameParentList appendString:appendStr];
        [beautifyNameChildList appendString:appendChildStr];
        
        [beautifyIdParentList appendString:appendId];
        [beautifyIdChildList appendString:appendChildId];
        
        [beautifyValueList appendString:appendValue];
    };
    
    for (AWEComposerBeautyEffectCategoryWrapper *categoryWrapper in self.beautyService.composerVM.filteredCategories) {
        if (categoryWrapper.exclusive) {
            appendData(categoryWrapper.selectedEffect, categoryWrapper.selectedEffect);
        } else {
            for (AWEComposerBeautyEffectWrapper *effectWrapper in categoryWrapper.effects) {
                if (effectWrapper.isEffectSet) {
                    appendData(effectWrapper, effectWrapper.appliedChildEffect);
                } else {
                    appendData(effectWrapper, effectWrapper);
                }
            }
        }
    }
    
    params[@"enter_from"] = @"video_edit_page";
    params[@"beautify_name_parent_list"] = beautifyNameParentList;
    params[@"beautify_id_parent_list"] = beautifyIdParentList;
    params[@"beautify_name_child_list"] = beautifyNameChildList;
    params[@"beautify_id_child_list"] = beautifyIdChildList;
    params[@"beautify_value_list"] = beautifyValueList;
    [ACCTracker() trackEvent:@"save_beautify_setting"
                      params:params
             needStagingFlag:NO];
}


@end
