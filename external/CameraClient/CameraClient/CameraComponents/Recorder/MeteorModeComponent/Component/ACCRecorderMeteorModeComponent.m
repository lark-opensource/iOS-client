//
//  ACCRecorderMeteorModeComponent.m
//  CameraClient-Pods-Aweme-CameraResource_douyin
//
//  Created by Chen Long on 2021/4/27.
//

#import "ACCRecorderMeteorModeComponent.h"
#import "AWERepoContextModel.h"
#import <CreationKitInfra/ACCResponder.h>
#import "ACCRecordMeteorModeGuidePanel.h"
#import "ACCBarItemToastView.h"
#import "ACCRecordObscurationGuideView.h"
#import "ACCRecorderMeteorModeViewModel.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import "ACCMeteorModeUtils.h"
#import "AWERepoPropModel.h"
#import "ACCPropViewModel.h"
#import "AWERepoTrackModel.h"
#import "ACCRepoRearResourceModel.h"
#import "ACCRepoRecorderTrackerToolModel.h"
#import "ACCRecorderToolBarDefinesD.h"
#import "ACCToolBarItemView.h"
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarContainerAdapter.h"
#import "ACCToolBarAdapterUtils.h"

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCResourceHeaders.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitRTProtocol/ACCCameraService.h>

@interface ACCRecorderMeteorModeComponent ()
<
ACCRecordSwitchModeServiceSubscriber
>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) ACCRecorderMeteorModeViewModel *viewModel;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;

@property (nonatomic, strong) LOTAnimationView *lottieView;

@property (nonatomic, assign) BOOL isAutoMeteor; // 进入拍摄页自动打开
@property (nonatomic, assign) BOOL hasDisplayAutoMeteor; // 显示自动打开动画

@end

@implementation ACCRecorderMeteorModeComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.switchModeService addSubscriber:self];
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCRecorderMeteorModeServiceProtocol), self.viewModel);
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)loadComponentView
{
    [self.viewContainer.barItemContainer addBarItem:[self barItem]];
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    self.isAutoMeteor = self.repository.repoContext.isMeteorMode;
}

- (void)componentDidAppear
{
    id<ACCBarItemCustomView> barItemCustomView = [self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarMeteorModeContext];
    barItemCustomView.imageName = self.repository.repoContext.isMeteorMode ? @"icon_meteor_mode_on" : @"icon_meteor_mode_off";
    [self p_configBarItemAccessibility];
    
    if (self.isAutoMeteor) {
        [ACCMeteorModeUtils markHasUseMeteorMode];
        if (!self.hasDisplayAutoMeteor) {
            // 播放自动选中动画
            [self p_showSwitchAnimations:YES];
            self.hasDisplayAutoMeteor = YES;
        }
    } else {
        dispatch_block_t dismissBlock = nil;
        if ([ACCToolBarAdapterUtils useToolBarFoldStyle] && [ACCMeteorModeUtils needShowMeteorModeBubbleGuide]) {
            ACCToolBarItemView *itemView = (ACCToolBarItemView *)barItemCustomView;
            [itemView hideLabelWithDuration:0.3];
            dismissBlock = ^{
                [itemView showLabelWithDuration:0.3];
            };
        }
        if (self.repository.repoRecorderTrackerTool.hasAuthority) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[AWERecorderTipsAndBubbleManager shareInstance] showMeteorModeItemGuideIfNeeded:barItemCustomView.barItemButton dismissBlock:dismissBlock];
            });
        }
    }
}

- (ACCBarItem *)barItem {
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCRecorderToolBarMeteorModeContext];
    if (config) {
        ACCBarItem *bar = [[ACCBarItem alloc] init];
        bar.title = @"一闪而过";
        bar.imageName = @"icon_meteor_mode_off";
        bar.selectedImageName = @"icon_meteor_mode_on";
        bar.itemId = ACCRecorderToolBarMeteorModeContext;
        bar.type = ACCBarItemFunctionTypeDefault;
        @weakify(self);
        bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
            @strongify(self);
            [self p_handleClickBarItem];
        };
        bar.needShowBlock = ^BOOL {
            @strongify(self);
            return ![self.cameraService.recorder isRecording];
        };
        [self p_forceInsert];
        return bar;
    } else {
        return nil;
    }
}

- (void)p_forceInsert
{
    if ([ACCToolBarAdapterUtils useAdaptedToolBarContainer]) {
        ACCToolBarContainerAdapter *adapter = (ACCToolBarContainerAdapter *)self.viewContainer.barItemContainer;
        [adapter forceInsertWithBarItemIdsArray:@[[NSValue valueWithPointer:ACCRecorderToolBarMeteorModeContext]]];
    }
}

- (void)p_handleClickBarItem
{
    self.repository.repoContext.isMeteorMode = !self.repository.repoContext.isMeteorMode;
    [self p_showSwitchAnimations:NO];
    
    [ACCMeteorModeUtils markHasUseMeteorMode];

    [self p_configBarItemAccessibility];

    if ([ACCToolBarAdapterUtils useToolBarFoldStyle] && !self.repository.repoContext.isMeteorMode) {
        ACCToolBarItemView *itemView = (ACCToolBarItemView *)[self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarMeteorModeContext];
        [itemView hideLabelWithDuration:0.3];
    }

    [ACCTracker() trackEvent:@"click_meteormode_button" params:@{
        @"enter_from" : self.repository.repoTrack.enterFrom ?: @"",
        @"shoot_way" : self.repository.repoTrack.referString ?: @"",
        @"to_status" : self.repository.repoContext.isMeteorMode ? @"on" : @"off",
        @"creation_id" : self.repository.repoContext.createId ?: @"",
    }];
}

- (void)p_configBarItemAccessibility
{
    BOOL isMeteorModeOn = self.repository.repoContext.isMeteorMode;
    id<ACCBarItemCustomView> itemView = [self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarMeteorModeContext];
    itemView.barItemButton.accessibilityLabel = [NSString stringWithFormat:@"%@%@", @"一闪而过", isMeteorModeOn ? @"已开启" : @"已关闭"];
    itemView.barItemButton.accessibilityTraits = UIAccessibilityTraitButton;
}

- (void)p_showSwitchAnimations:(BOOL)isAutoMeteor
{
    [self.viewModel sendDidChangeMeteorModeSignal:self.repository.repoContext.isMeteorMode];
    
    id<ACCBarItemCustomView> barItemCustomView = [self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarMeteorModeContext];
    barItemCustomView.imageName = self.repository.repoContext.isMeteorMode ? @"icon_meteor_mode_on" : @"icon_meteor_mode_off";
    if (!self.repository.repoContext.isMeteorMode) {
        [self p_showBarItemToast];
        return;
    }
    
    if (self.repository.repoContext.videoType == AWEVideoTypeKaraoke) { // only show toast in Karaoke mode
        [self p_showBarItemToast];
    } else { // Default
        if (![ACCMeteorModeUtils hasUsedMeteorMode]) {
            [self p_showGuidePanel];
        } else {
            if ([self p_hasProp:isAutoMeteor]) {
                [self p_showBarItemToast];
            } else {
                [self p_showObscurationView];
            }
        }
    }
}

- (BOOL)p_hasProp:(BOOL)isAutoMeteor
{
    if ([self propViewModel].currentSticker
        || [self propViewModel].lastClickedEffectModel
        || (isAutoMeteor && self.repository.RepoRearResource.stickerIDArray.count)) {
        return YES;
    } else {
        return NO;
    }
}

- (void)p_showGuidePanel
{
    [ACCRecordMeteorModeGuidePanel showOnView:[ACCResponder topViewController].view
                             withConfirmBlock:nil
                                 dismissBlock:^(ACCRecordMeteorModeGuidePanelDismissScene dismissScene) {
        switch (dismissScene) {
            case ACCRecordMeteorModeGuidePanelDismissSceneClickConfirmButton:
                [self p_trackClickGuidePanelWithClickType:@"start_try"];
                break;
                
            case ACCRecordMeteorModeGuidePanelDismissSceneClickCloseButton:
                [self p_trackClickGuidePanelWithClickType:@"quit"];
                break;
                
            case ACCRecordMeteorModeGuidePanelDismissSceneClickMaskView:
                [self p_trackClickGuidePanelWithClickType:@"other"];
                break;
        }
    }
                                hasBackground:NO];
    
    [ACCTracker() trackEvent:@"flash_cross_introduce" params:@{
        @"enter_from" : self.repository.repoTrack.enterFrom ?: @"",
        @"shoot_way" : self.repository.repoTrack.referString ?: @"",
        @"creation_id" : self.repository.repoContext.createId ?: @"",
    }];
}

- (void)p_trackClickGuidePanelWithClickType:(NSString *)clickType
{
    [ACCTracker() trackEvent:@"click_flash_cross_introduce" params:@{
        @"enter_from" : self.repository.repoTrack.enterFrom ?: @"",
        @"shoot_way" : self.repository.repoTrack.referString ?: @"",
        @"creation_id" : self.repository.repoContext.createId ?: @"",
        @"click_type" : clickType ?: @"",
    }];
}

- (void)p_showObscurationView
{
    BOOL isMeteorModeOn = self.repository.repoContext.isMeteorMode;
    id<ACCBarItemCustomView> barItemCustomView = [self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarMeteorModeContext];
    [ACCRecordObscurationGuideView showGuideTitle:@"一闪而过" description:@"已开启一闪而过，这个作品只能被每个用户查看一次" below:(UIView *)barItemCustomView];
    
    self.lottieView = [LOTAnimationView animationWithFilePath:ACCResourceFile(isMeteorModeOn ? @"acc_bar_item_meteor_mode_open.json" : @"acc_bar_item_meteor_mode_close.json")];
    self.lottieView.frame = [barItemCustomView.barItemButton convertRect:barItemCustomView.barItemButton.bounds toView:self.viewContainer.interactionView];
    [self.viewContainer.interactionView addSubview:self.lottieView];
    [self.lottieView play];
    barItemCustomView.barItemButton.hidden = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.lottieView removeFromSuperview];
        self.lottieView = nil;
        barItemCustomView.barItemButton.hidden = NO;
    });
}

- (void)p_showBarItemToast
{
    BOOL isMeteorModeOn = self.repository.repoContext.isMeteorMode;
    id<ACCBarItemCustomView> barItemCustomView = [self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarMeteorModeContext];
    self.lottieView = [LOTAnimationView animationWithFilePath:ACCResourceFile(isMeteorModeOn ? @"acc_bar_item_meteor_mode_open.json" : @"acc_bar_item_meteor_mode_close.json")];
    self.lottieView.frame = [barItemCustomView.barItemButton convertRect:barItemCustomView.barItemButton.bounds toView:self.viewContainer.interactionView];
    [self.viewContainer.interactionView addSubview:self.lottieView];
    [self.lottieView play];

    dispatch_block_t dismissBlock = nil;
    [ACCBarItemToastView showOnAnchorBarItem:barItemCustomView.barItemButton withContent:isMeteorModeOn ? @"每个人只能查看一次" : @"已关闭" dismissBlock:dismissBlock];

    if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
        ACCToolBarItemView *itemView = (ACCToolBarItemView *)[self.viewContainer.barItemContainer viewWithBarItemID:ACCRecorderToolBarMeteorModeContext];;
        [itemView hideLabelWithDuration:0.3];
        dismissBlock = ^{
            [itemView showLabelWithDuration:0.3];
        };
    }
    
    barItemCustomView.barItemButton.hidden = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.lottieView removeFromSuperview];
        self.lottieView = nil;
        barItemCustomView.barItemButton.hidden = NO;
    });
}

- (ACCRecorderMeteorModeViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCRecorderMeteorModeViewModel.class];
        NSAssert(_viewModel, @"should not be nil");
    }
    return _viewModel;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    [self.viewContainer.barItemContainer updateBarItemWithItemId:ACCRecorderToolBarMeteorModeContext];
}

@end
