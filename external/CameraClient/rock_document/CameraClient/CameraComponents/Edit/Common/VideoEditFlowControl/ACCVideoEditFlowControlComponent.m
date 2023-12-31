//
//  ACCVideoEditFlowControlComponent.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2019/10/23.
//

#import "AWERepoDraftModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoTrackModel.h"
#import "AWERepoPublishConfigModel.h"
#import "AWERepoDuetModel.h"
#import "AWERepoContextModel.h"
#import "ACCVideoEditFlowControlComponent.h"
#import "ACCImageAlbumEditViewModel.h"
#import <CameraClient/ACCEditToPublishRouterCoordinatorProtocol.h>
#import <CreationKitArch/AWEAnimatedMusicCoverButton.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>

#import <CameraClient/ACCConfigKeyDefines.h>
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCComponentManager.h>
#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CameraClient/ACCDraftProtocol.h>
#import "AWEMVTemplateModel.h"
#import "ACCRepoBirthdayModel.h"
#import <CreativeKit/ACCMemoryTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreationKitInfra/ACCAlertProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CameraClient/ACCRepoDraftFeedModelProtocol.h>
#import <CreationKitInfra/ACCConfigManager.h>
#import "ACCConfigKeyDefines.h"
#import "ACCEditorDraftService.h"
#import "ACCVideoEditFlowControlViewModel.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import "ACCPhotoWaterMarkUtil.h"
#import "UIViewController+AWEDismissPresentVCStack.h"
#import "ACCPublishServiceProtocol.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <HTSServiceKit/HTSMessageCenter.h>
#import "ACCActionSheetProtocol.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCMainServiceProtocol.h"
#import "AWERecordInformationRepoModel.h"
#import <CameraClient/ACCIMModuleServiceProtocol.h>
#import "ACCPublishGuideView.h"
#import <CreationKitArch/ACCRepoReshootModel.h>
#import "ACCRepoRedPacketModel.h"
#import "ACCRepoUserIncentiveModelProtocol.h"
#import "ACCRepoUserIncentiveModelProtocol.h"
#import "ACCVideoEditTipsService.h"
#import "ACCVideoEditFlowControlService.h"
#import "ACCSubtitleActionSheetProtocol.h"
#import "ACCEditMusicServiceProtocol.h"
#import "ACCInfoStickerServiceProtocol.h"
#import "ACCPublishStrongPopView.h"
#import "ACCVideoEditTipsDiaryGuideFrequencyChecker.h"
#import <CreationKitInfra/UIView+ACCRTL.h>
#import "ACCRepoQuickStoryModel.h"
#import <CreationKitArch/ACCRepoFlowControlModel.h>
#import "ACCRepoTextModeModel.h"
#import "AWERepoUploadInfomationModel.h"
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoPropModel.h>
#import <CameraClient/AWERepoStickerModel.h>
#import <CameraClient/ACCRepoEditEffectModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/AWEDraftUtils.h>
#import <CreationKitInfra/NSData+ACCAdditions.h>
#import "ACCEditTransitionService.h"
#import <CameraClient/ACCPublishServiceFactoryProtocol.h>
#import "ACCEditClipV1ServiceProtocol.h"
#import "ACCPublishServiceMessage.h"
#import "UIImage+GaussianBlur.h"
#import <CreationKitArch/AWEDraftUtils.h>
#import "ACCToolBarAdapterUtils.h"
#import "AWEPublishFirstFrameTracker.h"
#import "ACCBatchPublishServiceProtocol.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import "ACCVideoEditBottomControlService.h"
#import "ACCRepoActivityModel.h"
#import "AWERepoFlowControlModel.h"
#import <CreationKitInfra/ACCModuleService.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import <CameraClientModel/ACCVideoCanvasType.h>
#import <CameraClient/ACCRepoAudioModeModel.h>
#import "ACCMultiStyleAlertProtocol.h"
#import <CreativeKit/ACCAccessibilityProtocol.h>
#import <CameraClient/ACCDraftSaveLandingProtocol.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCUIReactTrackProtocol.h"
#import "ACCRedPacketAlertProtocol.h"
#import <CameraClient/ACCStudioLiteRedPacket.h>
#import <CameraClient/ACCFlowerRedPacketHelperProtocol.h>
#import <CameraClient/ACCNewActionSheetProtocol.h>

typedef NS_ENUM(NSInteger, AWESubtitleActionSheetButtonType) {
    AWESubtitleActionSheetButtonNormal,
    AWESubtitleActionSheetButtonHighlight,
    AWESubtitleActionSheetButtonSubtitle
};


static const CGFloat kAWEEditNextButtonEdge = 44.f;

@interface ACCVideoEditFlowControlComponent ()<
ACCPublishServiceMessage,
ACCActionSheetDelegate,
ACCVideoEditTipsServiceSubscriber,
ACCVideoEditBottomControlSubscriber,
ACCSubtitleActionSheetDelegate>
@property (nonatomic, strong) ACCAnimatedButton *backButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *publishButton;
@property (nonatomic, strong) UILabel *nextLabel;
@property (nonatomic, strong) UIImageView *nextImageView;
@property (nonatomic, strong) ACCVideoEditFlowControlViewModel *viewModel;

/// 通过设置config展示不同的显示内容
@property (nonatomic, strong) ACCMultiStyleAlertConfigParamsBlock backAlertConfig;
@property (nonatomic, strong) NSObject<ACCMultiStyleAlertProtocol> *backAlert;
@property (nonatomic, strong) id<ACCNewActionSheetProtocol> backActionSheet;

@property (nonatomic, strong) id<ACCPublishServiceProtocol> publishService;
@property (nonatomic, strong) id<ACCBatchPublishServiceProtocol>imageAlbumBatchPublishService;

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsSerivce;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;
@property (nonatomic, weak) id<ACCVideoEditBottomControlService> bottomControlService;
@property (nonatomic, weak) id<ACCInfoStickerServiceProtocol> infoStickerService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCEditClipV1ServiceProtocol> clipServiceV1;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL isViewAppear;
@property (nonatomic, assign) BOOL didIgnoreImageAlbumEditFirstTransformTrack;
@property (nonatomic, assign) BOOL dismissed;
@property (nonatomic, assign) BOOL hasShowedUserIncentiveAlert;
@property (nonatomic, assign) BOOL didResetBackAlertFlag;
/// dismiss时，是否结束整个创作流程
@property (nonatomic, assign, getter=shouldFinishCreateSceneWhenDismiss) BOOL finishCreateSceneWhenDismiss;
@property (nonatomic, strong) void (^finishCreateSceneCompletion)(void);
@property (nonatomic, assign) BOOL ignoreSaveDraftWhenDismiss;
@property (nonatomic, assign) BOOL ignoreDeleteDraftWhenDismiss;
@property (nonatomic, assign) BOOL ignoreCancelBlock;


@end


@implementation ACCVideoEditFlowControlComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, tipsSerivce, ACCVideoEditTipsService)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)
IESAutoInject(self.serviceProvider, bottomControlService, ACCVideoEditBottomControlService)
IESAutoInject(self.serviceProvider, infoStickerService, ACCInfoStickerServiceProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESOptionalInject(self.serviceProvider, clipServiceV1, ACCEditClipV1ServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCVideoEditFlowControlService),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [self.tipsSerivce addSubscriber:self];
    [self.bottomControlService addSubscriber:self];
}

#pragma mark - ACCFeatureComponent protocol

- (void)loadComponentView {
    if (self.viewContainer.containerView.superview) {
        [self.viewContainer.containerView addSubview:self.backButton];
        
        NSString *backTitle = [self editAndPublishViewBackButtonTitle];

        if (backTitle.length) {
            [self.backButton setTitle:backTitle forState:UIControlStateNormal];
            self.backButton.highlightedScale = 1.0f;
        }
        CGFloat topMargin = 30;
        if ([UIDevice acc_isIPhoneX]) {
            if (@available(iOS 11.0, *)) {
                topMargin = ACC_STATUS_BAR_NORMAL_HEIGHT + kYValueOfRecordAndEditPageUIAdjustment;
            }
        }
        
        [self.backButton sizeToFit];
        self.backButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-19, -19, -19, -19);
        CGFloat backButtonWidth = CGRectGetWidth(self.backButton.frame);
        backButtonWidth = MAX(44, backButtonWidth);
        self.backButton.frame = CGRectMake(6, topMargin, backButtonWidth, 44);
    }

    if ([self.controller enableFirstRenderOptimize]) {
        @weakify(self);
        [self.controller.componentManager registerLoadViewCompletion:^{
            @strongify(self);
            [self configBottomViewIfNeeded];
        }];
    } else {
        [self configBottomViewIfNeeded];
    }
}

- (void)componentDidMount {
    if ([self.repository.repoContext.createId length]) {//for track
        [ACCCache() setObject:self.repository.repoContext.createId forKey:@"awestudio_creation_id"];
    }
    
    REGISTER_MESSAGE(ACCPublishServiceMessage, self);
    [self p_bindViewModel];
}

- (void)componentDidUnmount {
    UNREGISTER_MESSAGE(ACCPublishServiceMessage, self);
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)componentWillAppear {
    [self.viewModel fetchUploadParams];
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self.editService.sticker setInfoStickerRestoreMode:VEInfoStickerRestoreMode_NORMALIZED];
}

- (void)componentDidDisappear {
    self.isViewAppear = NO;
}

- (void)componentDidAppear {
    if (self.dismissed) {
        return;
    }
    [self p_updatePublishBtnUI];
    [self hidePublishButtonAndUpdateNextButtonFrameIfNeed];
    [self.bottomControlService updatePanelIfNeeded];
    
    BOOL shouldIgnoreImageAlbumEditFirstTransformTrack = NO;
    // 图集/视频切换是整个VC级别的切换，每次切换会触发Appear，但数据产品要求切换后不要在打"enter_video_edit_page"
    // 但是仅仅是切换的那次不打，之后的Appear事件埋点需要照常打，所以切换后仅仅屏蔽首次Appear的埋点
    // 所以首次Appear且满足切换的flag即切换后的首次Appear，埋点要求比较迷，切换算不算页面切换感觉值得讨论
    if (!self.didIgnoreImageAlbumEditFirstTransformTrack &&
        self.repository.repoImageAlbumInfo.transformContext.isImageAlbumTransformContext &&
        self.repository.repoImageAlbumInfo.transformContext.didTransformedOnce) {
        
        shouldIgnoreImageAlbumEditFirstTransformTrack = YES;
        self.didIgnoreImageAlbumEditFirstTransformTrack = YES;
    }
    
    if (!self.clipServiceV1.isCliping && !shouldIgnoreImageAlbumEditFirstTransformTrack && !self.isViewAppear) {
        self.isViewAppear = YES;
        [self.viewModel trackEnterVideoEditPageEvent];
    }
    
    if (!self.isFirstAppear) {
        self.isFirstAppear = YES;
        
        NSDictionary *toastInfo = ACCConfigDict(kConfigDict_tools_edit_activity_notice_toast);
        if (!ACC_isEmptyDictionary(toastInfo)) {
            NSArray *activityVideoTypes = [toastInfo acc_arrayValueForKey:@"activity_video_type"];
            NSArray *enterFroms = [toastInfo acc_arrayValueForKey:@"enter_from"];
            NSString *notice = [toastInfo acc_stringValueForKey:@"notice"];
            if ([activityVideoTypes containsObject:self.repository.repoContext.activityVideoType] && ![enterFroms containsObject:self.repository.repoTrack.referString] && !ACC_isEmptyString(notice) && self.repository.repoContext.videoSource == AWEVideoSourceRemoteResource) {
                [ACCToast() show:notice];
            }
        }
        
        UIImageView *musicIcon = [self.viewContainer.topRightBarItemContainer viewWithBarItemID:ACCEditToolBarMusicContext].button.imageView;

        // shaking select music
        if (musicIcon) {
            void(^animation)(void) = ^() {
                CGFloat delta = 25.0 / 180.0 * M_PI;
                [CATransaction begin];
                [CATransaction setAnimationTimingFunction:[CAMediaTimingFunction functionWithControlPoints:0.25 :0.1 :0.25 :1]];

                CABasicAnimation *animation = [CABasicAnimation animation];
                animation.duration = 0.2;
                animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
                animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-delta, 0, 0, 1)];
                animation.keyPath = @"transform";
                [musicIcon.layer addAnimation:animation forKey:nil];

                CABasicAnimation *animation2 = [CABasicAnimation animation];
                animation2.beginTime = CACurrentMediaTime() + 0.2;
                animation2.duration = 0.2;
                animation2.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(-delta, 0, 0, 1)];
                animation2.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(delta, 0, 0, 1)];
                animation2.keyPath = @"transform";
                [musicIcon.layer addAnimation:animation2 forKey:nil];

                CABasicAnimation *animation3 = [CABasicAnimation animation];
                animation3.beginTime = CACurrentMediaTime() + 0.4;
                animation3.duration = 0.2;
                animation3.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeRotation(delta, 0, 0, 1)];
                animation3.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
                animation3.keyPath = @"transform";
                [musicIcon.layer addAnimation:animation3 forKey:nil];

                [CATransaction commit];
            };

            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                ACCBLOCK_INVOKE(animation);
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    ACCBLOCK_INVOKE(animation);
                });
            });
        }
    }

    // 弱引导，不与其它气泡互斥
    @weakify(self);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        id<ACCRepoUserIncentiveModelProtocol> incentiveModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoUserIncentiveModelProtocol)];
        if ([self.repository.repoQuickStory shouldBuildQuickStoryPanel] && self.repository.repoContext.videoType != AWEVideoTypeNewYearWish && ![self.repository.repoRecordInfo shouldForbidCommerce] && !incentiveModel.shouldShowEditIncentiveBubble && ![[self publishModel].repoUploadInfo.extraDict acc_boolValueForKey:@"is_from_circle_page"]) {
            if (![self.bottomControlService enabled]) {
                [ACCPublishGuideView showAnimationIn:self.publishButton.titleLabel enterFrom:self.repository.repoTrack.enterFrom];
            }
        }
    });
    
    if (ACCConfigEnum(kConfigInt_backup_popup_style, ACCBackupEditsPopupStyle) != ACCBackupEditsPopupStyleDefault
        || ACCConfigBool(kConfigBool_save_draft_after_cancel_continue_edit)
        || ACCConfigBool(ACCConfigBool_meteor_mode_on)) {
        @weakify(self);
        if ((!self.repository.repoPublishConfig.coverImage && !self.repository.repoPublishConfig.backupCover)
            || !self.repository.repoPublishConfig.meteorModeCover) {
            if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
                [self.editService.captureFrame getProcessedPreviewImageAtIndex:0 preferredSize:CGSizeZero compeletion:^(UIImage * _Nonnull image, NSInteger index) {
                    @strongify(self);
                    [self p_saveBackupCover:image];
                }];
            } else {
                NSString *blurCoverFilePath = [AWEDraftUtils generateMeteorModeCoverPathFromTaskID:self.repository.repoDraft.taskID];
                [self.editService.captureFrame getProcessedPreviewImageAtTime:0 preferredSize:CGSizeZero compeletion:^(UIImage * _Nonnull image, NSTimeInterval atTime) {
                    @strongify(self);
                    [self p_saveBackupCover:image];
                    if (ACCConfigBool(ACCConfigBool_meteor_mode_on)) {
                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                            // generate a blur image
                            UIImage *blurImage = [image acc_applyGaussianBlur:40];
                            
                            // write to file
                            NSData *data = UIImagePNGRepresentation(blurImage);
                            [data acc_writeToFile:blurCoverFilePath atomically:YES];
                            
                            // assign value
                            acc_infra_main_async_safe(^{
                                @strongify(self);
                                self.repository.repoPublishConfig.meteorModeCover = blurImage;
                            });
                        });
                    }
                }];
            }
        }
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        @strongify(self);
        [self logNextButton];
    });

    if (!self.viewModel.originalStickerCount) {
        let stickerService = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
        self.viewModel.originalStickerCount = @(stickerService.stickerCount);
    }

    if (!ACCConfigBool(kConfigBool_edit_view_photo_ignore_metadata)) {
        [self.repository.repoUploadInfo updateImageSourceInfoIfNeeded];
    }

    if ([ACCToolBarAdapterUtils useToolBarFoldStyle]) {
        [self.viewContainer.topRightBarItemContainer resetUpBarContentView];
    }
}

- (void)p_bindViewModel
{
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        return;
    }
    @weakify(self);
    [[self tipsSerivce].showQuickPublishBubbleSignal.deliverOnMainThread subscribeNext:^(NSNumber *x) {
        @strongify(self);
        if (self.repository.repoDraft.isBackUp || self.repository.repoDraft.isDraft) {
            return;
        }
        
        BOOL isRedPack = [ACCStudioLiteRedPacket() isLiteRedPacketVideo:[self publishModel]];
        if (isRedPack) {
            return;
        }
        
        UIButton *publishButton = nil;
        if (self.publishButton.alpha > 0 && !self.publishButton.hidden) {
            publishButton = self.publishButton;
        }
        if ([self.bottomControlService enabled]) {
            publishButton = [self.bottomControlService publishButton];
        }
        if (!publishButton) {
            return;
        }

        AWERecordInformationRepoModel *repoRecordInfo = self.repository.repoRecordInfo;

        if ([x boolValue] && [self.repository.repoQuickStory shouldBuildQuickStoryPanel] && ![repoRecordInfo shouldForbidCommerce] && ![[self publishModel].repoUploadInfo.extraDict acc_boolValueForKey:@"is_from_circle_page"] && ![self.viewModel isFlowerRedpacketOneButtonMode]) {
            // 部分路径不依赖 p_shouldDisableNext，直接禁用了 nextButton
            UIButton *nextButton = [self p_shouldDisableNext] || self.nextButton.alpha < 1 ? nil : self.nextButton;
            
            NSMutableArray *buttons = [NSMutableArray array];
            if ([self.bottomControlService enabled]) {
                [buttons acc_addObjectsFromArray:[self.bottomControlService allButtons]];
            } else {
                [buttons acc_addObject:nextButton];
            }
            
            [ACCPublishGuideView showGuideIn:publishButton.superview under:publishButton then:buttons dismissBlock:^{
                @strongify(self);
                [self.viewModel notifyDidQuickPublishGuideDismiss];
                [ACCCache() setBool:YES forKey:kACCImageAlbumEditDiaryGuideDisappearKey];
            }];
            self.viewModel.isQuickPublishBubbleShowed = YES;

            [ACCVideoEditTipsDiaryGuideFrequencyChecker markGuideAsTriggeredWithKey:kAWENormalVideoEditQuickPublishGuideTipShowDateKey];

            [ACCTracker() trackEvent:@"fast_shoot_bubble_show" params:@{
                @"enter_from": self.repository.repoTrack.enterFrom ?: @"",
                @"intro_type": @4,
            }];
        }
    }];
    
    [self.viewModel.publishPrivateWorkSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self publishDailyPrivateWork];
    }];
    
    [[[self musicService] didUpdateChallengeModelSignal].deliverOnMainThread subscribeNext:^(id<ACCMusicModelProtocol>  _Nullable x) {
        @strongify(self);
        //reuse componentDidAppear logic
        [self p_updatePublishBtnUI];
        [self hidePublishButtonAndUpdateNextButtonFrameIfNeed];
        [self.bottomControlService updatePanelIfNeeded];
    }];
}

- (void)configBottomViewIfNeeded
{
    if ([self.bottomControlService enabled]) {
        [self.bottomControlService updatePublishButtonTitle:[self quickPublishText]];
        [self p_updatePublishBtnUI];
        [self hidePublishButtonAndUpdateNextButtonFrameIfNeed];
        [self.bottomControlService updatePanelIfNeeded];
    } else if (self.repository.repoQuickStory.shouldBuildQuickStoryPanel || self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        [self buildQuickStoryBottomPanel];
    } else {
        [self.viewContainer.containerView addSubview:self.nextButton];
        [self configNextButton];
    }
}

#pragma mark - 

- (void)configNextButton
{
    if ([UIDevice acc_screenWidthCategory] == ACCScreenWidthCategoryiPhone5) {
        CGFloat nextButtonW = kAWEEditNextButtonEdge;
        CGFloat nextButtonH = kAWEEditNextButtonEdge;
        CGFloat nextButtonX = CGRectGetMaxX(self.viewContainer.containerView.frame) - 16 - nextButtonW;
        CGFloat nextButtonY = 0.f;
        if (self.viewContainer.bottomBarItemContainer.barItemContentView.acc_height > 0) {
            nextButtonY = self.viewContainer.bottomBarItemContainer.barItemContentView.center.y - nextButtonH / 2.0;
        } else {
            nextButtonY = CGRectGetMaxY(self.viewContainer.containerView.frame) - 22.f - ACC_IPHONE_X_BOTTOM_OFFSET - nextButtonH;
        }
        self.nextButton.frame = CGRectMake(nextButtonX, nextButtonY, nextButtonW, nextButtonH);
        self.nextButton.layer.cornerRadius = kAWEEditNextButtonEdge / 2;
        [self.viewContainer.containerView addSubview:self.nextImageView];
        self.nextImageView.center = self.nextButton.center;
    } else {
        [self.nextButton addSubview:self.nextLabel];

        [self.nextLabel sizeToFit];
        CGFloat nextLabelW = CGRectGetWidth(self.nextLabel.frame);
        CGFloat buttonTitleInset = 12;
        CGFloat nextButtonW = nextLabelW + buttonTitleInset * 2;
        if (nextButtonW < 69) {
            nextButtonW = 69;
        } else if (nextButtonW > 100) {
            nextButtonW = 100 ;
        }
        CGFloat nextButtonX = CGRectGetMaxX(self.viewContainer.containerView.frame) - 16 - nextButtonW;
        CGFloat nextButtonH = 36;
        CGFloat nextButtonY = 0;
        if (self.viewContainer.bottomBarItemContainer.barItemContentView.acc_height > 0) {
            nextButtonY =  self.viewContainer.bottomBarItemContainer.barItemContentView.center.y - nextButtonH / 2.0;
        } else {
            nextButtonY = CGRectGetMaxY(self.viewContainer.containerView.frame) - 31.5 - ACC_IPHONE_X_BOTTOM_OFFSET - nextButtonH;
        }
        self.nextButton.frame = CGRectMake(nextButtonX, nextButtonY, nextButtonW, nextButtonH);
        CGFloat acutalInset = (nextButtonW - nextLabelW) / 2;
        self.nextLabel.frame = CGRectMake(acutalInset, 0, nextLabelW, nextButtonH);
    }
}

- (void)buildQuickStoryBottomPanel
{
    if (self.publishButton.superview) {
        return;
    }
    [self.viewContainer.containerView addSubview:self.nextButton];
    if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) == ACCStoryEditorOptimizeTypeA || self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        [self.nextButton addSubview:self.nextLabel];
        self.nextButton.layer.cornerRadius = 2;

        [self.nextLabel sizeToFit];
        [self.viewContainer.containerView addSubview:self.publishButton];
        
        [self p_updatePublishBtnAndNextBtnUIToOriginStyle];
        
        [self.publishButton.titleLabel setFont:[ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium]];
        [self.publishButton setTitleColor:ACCResourceColor(ACCColorTextReverse) forState:UIControlStateNormal];

        [self.publishButton setTitle:[self quickPublishText] forState:UIControlStateNormal];

        [self.publishButton setImage:ACCResourceImage(@"ic_edit_publish_btn") forState:UIControlStateNormal];
        self.publishButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 4);
    }
    
    [self p_updatePublishBtnUI];
    [self hidePublishButtonAndUpdateNextButtonFrameIfNeed];
}

- (NSString *)quickPublishText
{
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        return @"发布心愿";
    }
    if ([self p_isImageAlbumBatchStoryPublishContext]) {
        return [NSString stringWithFormat:@"发日常(%i)", (int)[self.repository.repoImageAlbumInfo imageCount]];
    }
    switch (ACCConfigInt(kConfigInt_edit_diary_button_text)) {
        case 1:
            return @"日常";
        case 2:
            return @"发日常";
        default:
            return ACCConfigString(kConfigString_edit_post_direct_text);
    }
}

- (void)p_updatePublishBtnUI
{
    if ([self p_shouldDisableNext]) {
        [self.bottomControlService hideNextButton];
        BOOL isBirthdayPost = self.repository.repoBirthday.isBirthdayPost;
        BOOL isAvatarPost = self.publishModel.repoQuickStory.isAvatarQuickStory;
        BOOL isBackgroundPost = self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeChangeBackground;
        BOOL isNewCityPost = self.repository.repoQuickStory.isNewCityStory;
        BOOL isMuiscStory = self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory;
        // 是否是社交分享类，包括分享到日常，详细可参考 https://bytedance.feishu.cn/docs/doccn9oXk9dTlwdz1bOKcqHdedc
        BOOL isShare = [self.repository.repoTrack.contentType isEqual:@"share"];
        BOOL isNewYearWish = self.repository.repoContext.videoType == AWEVideoTypeNewYearWish;
        BOOL isFlowerRedpacketOneBtnMode = [self.viewModel isFlowerRedpacketOneButtonMode];

        if (ACCConfigBool(kConfigBool_edit_page_button_style) || isBirthdayPost || isAvatarPost || isBackgroundPost || isMuiscStory || isNewCityPost || isNewYearWish || isFlowerRedpacketOneBtnMode || isShare) {
            CGRect frame = self.publishButton.frame;
            frame.origin.x = 6;
            frame.size.width = CGRectGetWidth(self.viewContainer.containerView.frame) - 6 * 2;
            self.publishButton.frame = frame;
            self.nextButton.alpha = 0;
            self.nextLabel.alpha = 0;

            NSString *title = [self quickPublishText];
            if (isNewYearWish) {
                title = @"发布心愿";
                self.publishButton.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
                [self.publishButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [self.publishButton setImage:nil forState:UIControlStateNormal];
            } else if (isBirthdayPost || isNewCityPost) {
                title = [self editPublishOneButtonText];
            } else if (isAvatarPost) {
                title = @"更换头像并发布日常";
            } else if (isBackgroundPost) {
                title = @"换背景并发日常";
            } else if (isFlowerRedpacketOneBtnMode) {
                NSString *flowerRedpacketOneBtnTitle = [ACCFlowerRedPacketHelper() flowerRedPacketActivityPublishBtnTitle];
                if (!ACC_isEmptyString(flowerRedpacketOneBtnTitle)) {
                    title = flowerRedpacketOneBtnTitle;
                }
                // UED坚持春节场景发日常按钮红色，喜庆一点？
                self.publishButton.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
                [self.publishButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [self.publishButton setImage:ACCResourceImage(@"ic_edit_publish_btn_red") forState:UIControlStateNormal];
            }
            else if (isShare) {
                title = @"转发到日常";
            }

            [self.publishButton setTitle:title forState:UIControlStateNormal];
            [self.bottomControlService updatePublishButtonTitle:title];

        } else {
            if ([self.nextButton isKindOfClass:[ACCAnimatedButton class]]) {
                ((ACCAnimatedButton *)self.nextButton).downgrade = YES;
            }
            self.nextButton.alpha = 0.34;
            self.nextLabel.alpha = 0.34;
        }
    } else if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) == ACCStoryEditorOptimizeTypeA) {
        [self p_updatePublishBtnAndNextBtnUIToOriginStyle];
    }

    [self.viewModel notifyDidUpdatePublishButton:self.publishButton nextButton:self.nextButton];
}

- (NSString *)editPublishOneButtonText
{
    switch (ACCConfigInt(kConfigInt_edit_diary_button_text)) {
        case 1:
            return @"日常";
        case 2:
            return @"发日常";
        default:
            return ACCConfigString(kConfigString_edit_post_button_default_text);
    }
}

- (void)p_updatePublishBtnAndNextBtnUIToOriginStyle
{
    CGFloat leftAndRightPadding = 6;
    CGFloat midPadding = 6;
    CGFloat buttonWidth = (CGRectGetWidth(self.viewContainer.containerView.frame) - leftAndRightPadding * 2 - midPadding) / 2;

    CGFloat buttonHeight = 44.f;
    CGFloat originY = ACC_SCREEN_HEIGHT - ACC_IPHONE_X_BOTTOM_OFFSET - 8 - buttonHeight;
    if ([UIDevice acc_isIPhoneX]) {
        originY += 8;
    }

    self.publishButton.frame = CGRectMake(leftAndRightPadding, originY, buttonWidth, buttonHeight);
    
    self.nextButton.frame = CGRectMake(CGRectGetMaxX(self.publishButton.frame) + midPadding, originY, buttonWidth, buttonHeight);
    self.nextLabel.center = CGPointMake(self.nextButton.acc_width / 2, self.nextButton.acc_height / 2);
    if ([self.nextButton isKindOfClass:[ACCAnimatedButton class]]) {
        ((ACCAnimatedButton *)self.nextButton).downgrade = NO;
    }
    self.nextButton.alpha = 1;
    self.nextLabel.alpha = 1;
}

- (BOOL)p_disableNextBtn
{
    if (ACCConfigInt(kConfigInt_editor_toolbar_optimize) != ACCStoryEditorOptimizeTypeA) {
        return NO;
    }
    
    if (self.repository.repoContext.editPageBottomButtonStyle == ACCEditPageBottomButtonStyleNoNext) {
        return YES;
    }
    
    // fragment携带参数
    for (AWEVideoFragmentInfo *fragmentInfo in self.repository.repoVideoInfo.fragmentInfo.copy) {
        if (fragmentInfo.editPageButtonStyle == 1) {
            return YES;
        }
    }
    if (self.viewModel.inputData.publishModel.repoContext.isQuickStoryPictureVideoType &&
        self.repository.repoRecordInfo.pictureToVideoInfo.editPageButtonStyle == 1) {
        return YES;
    }
    
    if (self.repository.repoBirthday.isBirthdayPost) {
        return YES;
    }
    if (ACCConfigBool(kConfigBool_subtab_restrict_publish_type)) {
        AWEVideoRecordButtonType videoButtonType = self.viewModel.inputData.publishModel.repoFlowControl.videoRecordButtonType;
        return self.viewModel.inputData.publishModel.repoTextMode.isTextMode ||
        // unknown 用于区分拍照
        (self.viewModel.inputData.publishModel.repoContext.isQuickStoryPictureVideoType && videoButtonType == AWEVideoRecordButtonTypeUnknown);
    }
    return NO;
}

- (void)hidePublishButtonAndUpdateNextButtonFrameIfNeed
{
    [self forbidCommerce];
    [self shootHomeUpdateNexBtnIfNeeded];
    [self liteRedPackUpdateNextButtonIfNeeded];
    [self updateFlowerNextButtonTextIfNeed];
    if (self.repository.repoContext.editPageBottomButtonStyle == ACCEditPageBottomButtonStyleOnlyNext) {
        [self hidePublishButtonAndUpdateNextButtonFrame];
    }
}

- (void)forbidCommerce
{
    // 理论上不会同时配，PM确认春节优先级最高
    if ([self.viewModel isFlowerRedpacketOneButtonMode]) {
        return;
    }
    AWERecordInformationRepoModel *repoRecordInfo = self.repository.repoRecordInfo;
    const BOOL forbidCommerce = [repoRecordInfo shouldForbidCommerce] || ([[self publishModel].repoUploadInfo.extraDict acc_boolValueForKey:@"is_from_circle_page"]);
    if (forbidCommerce) {
        id <ACCRepoDraftFeedModelProtocol> repoDraftFeed = [self.repository extensionModelOfProtocol:@protocol(ACCRepoDraftFeedModelProtocol)];
        repoDraftFeed.quickPublishEnabled = @(NO); // save into draft
        [self.bottomControlService hidePublishButton];
    }
    
    if (forbidCommerce && [self.repository.repoQuickStory shouldBuildQuickStoryPanel]) {

        self.nextButton.alpha = 1;
        self.nextLabel.alpha = 1;
        self.publishButton.hidden = YES;
        CGRect frame = self.nextButton.frame;
        frame.origin.x = 6;
        frame.size.width = CGRectGetWidth(self.viewContainer.containerView.frame) - 6 * 2;
        self.nextButton.frame = frame;
        self.nextLabel.center = CGPointMake(self.nextButton.acc_width / 2, self.nextButton.acc_height / 2);
    } else {
        self.publishButton.hidden = NO;
    }
}

// TC21 - 发布 POI 位置视频，屏蔽发布日记按钮，复用商业化挑战（forbidCommerce）相关逻辑
- (void)shootHomeUpdateNexBtnIfNeeded
{
    if ([self.viewModel isFlowerRedpacketOneButtonMode]) {
        return;
    }
    if ([self.repository.repoTrack.referString isEqualToString:@"tc_shoot_home_poi"]) {
        [self hidePublishButtonAndUpdateNextButtonFrame];
    }
}

- (void)liteRedPackUpdateNextButtonIfNeeded
{
    if ([self.viewModel isFlowerRedpacketOneButtonMode]) {
        return;
    }

    BOOL isRedPack = [ACCStudioLiteRedPacket() isLiteRedPacketVideo:[self publishModel]];

    if (isRedPack) {
        [self hidePublishButtonAndUpdateNextButtonFrame];
    }
}

- (void)updateFlowerNextButtonTextIfNeed
{
    NSString *flowerAwardTitle = [self.viewModel nextButtonTitleForFlowerAwardIfEnable];
    if (!ACC_isEmptyString(flowerAwardTitle)) {
        self.nextLabel.text = flowerAwardTitle;
        self.nextButton.accessibilityLabel = flowerAwardTitle;
    } else {
        self.nextLabel.text = ACCLocalizedString(@"common_next", @"下一步");
        self.nextButton.accessibilityLabel = ACCLocalizedString(@"common_next", @"下一步");
    }
}

- (BOOL)p_shouldDisableNext
{
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        return YES;
    }
    
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        return YES;
    }
    
    // 规避快拍反转实验x
    if (!ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        return NO;
    }
    
    if ([self.viewModel isFlowerRedpacketOneButtonMode]) {
        return YES;
    }

    AWERecordInformationRepoModel *repoRecordInfo = self.repository.repoRecordInfo;
    
    if ([repoRecordInfo shouldForbidCommerce]) {
        return NO;
    }
    
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory ) {
        return YES;
    }

    NSString *referer = self.repository.repoTrack.referString;
    
    //首页左上角及右滑进入不限制
    BOOL familiarRestrict = (([referer isEqualToString:@"diary_shoot"] || [referer isEqualToString:@"slide_shoot"]) && ACCConfigBool(kConfigBool_restrict_familiar_publish_style));
    if (ACCConfigBool(kConfigInt_enable_homepage_left_extension) || ACCConfigBool(kConfigInt_enable_record_left_slide_dismiss)) {
        familiarRestrict = NO;
    }

    return [referer isEqualToString:@"fast_shoot_label"] ||
           [referer isEqualToString:@"fast_folder_finish"] ||
           [referer isEqualToString:@"fast_shoot_publish"] ||
           [referer isEqualToString:@"fast_record_day"] ||
           [referer isEqualToString:@"fast_shoot_start"] ||
           [referer isEqualToString:@"profile_cover"] ||
           [referer isEqualToString:@"self_share"] ||
           familiarRestrict ||
           (![repoRecordInfo shouldForbidCommerce] && [self p_disableNextBtn]) ||
           [referer isEqualToString:@"profile_photo"] ||
           self.repository.repoQuickStory.isAvatarQuickStory ||
           [referer isEqualToString:@"city_story"] ||
           [referer isEqualToString:@"coin_task"] ||
           [self p_disableNextBtn];
}

- (void)logNextButton
{
    NSMutableArray *log = [NSMutableArray array];
    AWERecordInformationRepoModel *repoRecordInfo = self.repository.repoRecordInfo;
    
    UIButton *nextButton = [self.bottomControlService enabled] ? [self.bottomControlService nextButton] : self.nextButton;
    UIButton *publishButton = [self.bottomControlService enabled] ? [self.bottomControlService publishButton] : self.publishButton;
    AWELogToolInfo2(@"next_button", AWELogToolTagEdit,
                    @"nextButton.alpha %.2f, "
                    @"publishButton.hidden %d, "
                    @"storyTab %d, "
                    @"forbidCommerce %d, "
                    @"extra_game_launch_from %@, "
                    @"referString %@, "
                    @"restrictFamiliarPublishStyle %d, "
                    @"disableNextBtn %d, "
                    @"editPageButtonStyle %d, "
                    @"subtabRestrictPublishType %d, "
                    @"videoRecordButtonType %d, "
                    @"%@",
                    nextButton.alpha,
                    publishButton.hidden,
                    ACCConfigBool(kConfigBool_enable_story_tab_in_recorder),
                    [repoRecordInfo shouldForbidCommerce:log],
                    [[self publishModel].repoUploadInfo.extraDict acc_stringValueForKey:@"extra_game_launch_from"],
                    self.repository.repoTrack.referString,
                    ACCConfigBool(kConfigBool_restrict_familiar_publish_style),
                    [self p_disableNextBtn],
                    self.repository.repoContext.editPageBottomButtonStyle,
                    ACCConfigBool(kConfigBool_subtab_restrict_publish_type),
                    self.viewModel.inputData.publishModel.repoFlowControl.videoRecordButtonType,
                    [log componentsJoinedByString:@", "]
                    );

}

- (NSString *)editAndPublishViewBackButtonTitle
{
    if (self.repository.repoDraft.isDraft &&
        !self.repository.repoContext.enterFromShoot &&
        ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) &&
        ACCConfigInt(kConfigInt_creation_draft_edit_back_click_with_action_sheet) > 0) {
        return @"";
    }
    
    if (self.repository.repoContext.isMVVideo && (self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp)) {
        return ACCLocalizedString(@"tool_photo_movie_give_up", @"放弃编辑");
    }
    if (self.repository.repoDraft.isDraft) {
        BOOL isOldDuet = [self.publishModel.repoDuet isOldDuet];

        if (isOldDuet) {
            return ACCLocalizedString(@"tool_photo_movie_give_up", @"放弃编辑");
        }
        
        if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeChangeBackground || self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
            return ACCLocalizedString(@"tool_photo_movie_give_up", @"放弃发布");
        }
        if (self.repository.repoContext.videoSource == AWEVideoSourceCapture) {
            if (self.repository.repoFlowControl.videoRecordButtonType == AWEVideoRecordButtonTypeStory) {
                return ACCLocalizedString(@"creation_edit_back_reshoot", @"重新拍摄");
            }
            if (self.repository.repoContext.videoType == AWEVideoTypePhotoToVideo) {
                return ACCLocalizedString(@"creation_picdraft_edit", @"Retake a photo");
            }
            if (self.repository.repoContext.videoType != AWEVideoType2DGame) {
                return ACCLocalizedString(@"continue_record",@"继续拍摄");
            }
        }
    }
    return @"";
}

- (void)backClicked
{
    [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickBackInEdit];
    [self backClicked:@"left_corner"];
}

// 返回 YES: 当前页面立刻返回 (dismiss or pop)
// 返回  NO: 需展示各种弹窗等
- (BOOL)backClicked:(NSString *)enterMethod
{
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_method"] = enterMethod;
    params[@"shoot_way"] = self.repository.repoTrack.referString;
    params[@"creation_id"] = self.repository.repoContext.createId;
    params[@"content_source"] = self.repository.repoTrack.referExtra[@"content_source"];
    params[@"content_type"] = self.repository.repoTrack.referExtra[@"content_type"];
    params[@"is_multi_content"] = self.repository.repoTrack.mediaCountInfo[@"is_multi_content"];
    [ACCTracker() trackEvent:@"close_video_edit_page" params:params];

    if (!self.isMounted) {
        return YES;
    }
    if (self.repository.repoDraft.originalDraft &&
        !self.repository.repoDraft.originalDraft.backup &&
        self.repository.repoContext.videoSource == AWEVideoSourceCapture) {
        [ACCTracker() trackEvent:@"edit"
                           label:@"draft"
                           value:nil
                           extra:nil
                      attributes:nil];
    }
    
    if ([self p_showRedpackDraftAlertIfNeeded]) {
        return NO;
    }

    if ([self p_showBackAlertForDraftIfNeeded]) {
        return NO;
    }

    if ([self p_showBackAlertIfNeeded]) {
        return NO;
    }
    
    BOOL isNeedAlert = [self p_isNeedAlertForBackToShoot];
    return [self backToShootNeedAlert:isNeedAlert];
}

- (BOOL)p_isNeedAlertForBackToShoot
{
    BOOL isNeedAlert = YES;

    if (self.publishModel.repoQuickStory.isAvatarQuickStory ||
        self.publishModel.repoQuickStory.isProfileBgStory ||
        self.publishModel.repoQuickStory.isNewCityStory) {
        isNeedAlert = NO;
    }
    
    if ([self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory ||
        [self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo) {
        isNeedAlert = NO;
    }
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        isNeedAlert = NO;
    }
    
    if (self.publishModel.repoImageAlbumInfo.isImageAlbumEdit && !self.viewModel.isVideoEdited) {
        isNeedAlert = NO;
    }
    
    if (self.publishModel.repoContext.videoType == AWEVideoTypeNewYearWish) {
        isNeedAlert = NO;
    }

    // 相册 & (单选视频导入 || 上传合拍单段导入) & 未编辑 & 非生日
    if (self.repository.repoContext.videoSource == AWEVideoSourceAlbum && self.repository.repoUploadInfo.selectedUploadAssets.count == 1 && !self.viewModel.isVideoEdited &&
        !self.repository.repoBirthday.isBirthdayPost) {
        //
        isNeedAlert = NO;
    }

    return isNeedAlert;
}


- (id<ACCPublishServiceProtocol>)recreatePublishServiceIfNeeded
{
    if (self.publishService == nil) {
        self.publishService = [ACCPublishServiceFactory() build];
        self.publishService.publishModel = [self publishModel];
        self.publishService.editService = self.editService;
        self.publishService.uploadParamsCache = self.viewModel.uploadParamsCache;
    }
    return self.publishService;
}


- (BOOL)backToShootNeedAlert:(BOOL)needAlert
{
    // tell subscribers that the app will go back to the record view from the edit view.
    [[self viewModel] notifyWillGoBackToRecordPage];
    
    if (ACCConfigBool(kConfigBool_edit_flow_refactor)) {
        return [self backToShootNeedAlertPlanB:needAlert];
    }
    @weakify(self);
    // 吃水果小游戏
    if ((self.repository.repoGame.gameType != ACCGameTypeNone)&& !self.repository.repoDraft.isDraft && !self.repository.repoDraft.isBackUp) {
        dispatch_block_t confirmBlock = ^{
            @strongify(self);
            NSMutableDictionary *attributes = [self.repository.repoTrack.referExtra mutableCopy];
            [attributes addEntriesFromDictionary:@{
                                                   @"to_status" : @"confirm",
                                                   @"prop_id" : self.repository.repoVideoInfo.fragmentInfo.firstObject.stickerId ? : @""
                                                   }];
            [ACCTracker() trackEvent:@"back_to_shoot_confirm" params:attributes needStagingFlag:NO];

            [self dismissHandler];
            [self dismissViewController:nil];
        };
        if (!needAlert) {
            ACCBLOCK_INVOKE(confirmBlock);
            return YES;
        }
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle: ACCLocalizedString(@"av_sticker_game_clear_score_Confirmation", @"确认返回吗？")  message: ACCLocalizedString(@"av_sticker_game_clear_score",@"确认返回吗？返回后将取消本次得分") preferredStyle:UIAlertControllerStyleAlert];

        [alertController addAction:[UIAlertAction actionWithTitle: ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            NSMutableDictionary *attributes = [self.repository.repoTrack.referExtra mutableCopy];
            [attributes addEntriesFromDictionary:@{
                @"to_status" : @"cancel",
                @"prop_id" : self.repository.repoVideoInfo.fragmentInfo.firstObject.stickerId ? : @""
            }];
            [ACCTracker() trackEvent:@"back_to_shoot_confirm" params:attributes needStagingFlag:NO];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle: ACCLocalizedCurrentString(@"confirm")  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ACCBLOCK_INVOKE(confirmBlock);
        }]];
        
        [ACCAlert() showAlertController:alertController animated:YES];
        return NO;
    }

    // mv类型的草稿或备份,以及旧合拍
    // 在编辑页点击返回按钮后，直接dismiss这个navController，而不是popViewController
    BOOL isOldDuet = [self.publishModel.repoDuet isOldDuet];
    if (self.repository.repoContext.isMVVideo || isOldDuet) {
        if (self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp) {
            dispatch_block_t confirmBlock = ^{
                @strongify(self);
                [self dismissHandler];
                [self dismissViewController:^{
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [ACCDraft() clearAllEditBackUps];
                    });
                }];
            };
            if (!needAlert) {
                ACCBLOCK_INVOKE(confirmBlock);
                return YES;
            }
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message: ACCLocalizedString(@"com_mig_quit_editing_654qhf", @"是否放弃此次编辑？")  preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ACCBLOCK_INVOKE(confirmBlock);
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
            [ACCAlert() showAlertController:alertController animated:YES];
        } else {
            dispatch_block_t confirmBlock = ^{
                @strongify(self);
                [self dismissHandler];
                [self dismissViewController:nil];

                if (self.repository.repoBirthday.isBirthdayPost) {
                    [ACCDraft() deleteDraftWithID:self.repository.repoDraft.taskID];
                    [ACCLoading() dismissWindowLoading]; // 下载模版无法取消，仅 UI dismiss
                }
            };
            if (!needAlert) {
                ACCBLOCK_INVOKE(confirmBlock);
                return YES;
            }
            NSString *title =  ACCLocalizedCurrentString(@"com_mig_your_current_edits_will_be_discarded");
            NSString *message = ACCLocalizedCurrentString(@"com_mig_discard");
            NSString *confirmTitle = ACCLocalizedCurrentString(@"confirm");
            if (self.repository.repoBirthday.isBirthdayPost) {
                title = ACCLocalizedCurrentString(@"退出后，可以在个人主页继续查看祝福视频");
                message = nil;
                confirmTitle = ACCLocalizedCurrentString(@"退出");

                [ACCTracker() trackEvent:@"click_birthday_exit" params:@{
                    @"shoot_way": @"happy_birthday",
                    @"shoot_enter_from": self.repository.repoUploadInfo.extraDict[@"shoot_enter_from"] ?: @"",
                }];
            }
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                ACCBLOCK_INVOKE(confirmBlock);
            }]];
            [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
            [ACCAlert() showAlertController:alertController animated:YES];
        }
        
        return NO;
    }
    
    // 如果是从相册上传的 / 从服务端下载的视频 / 是吃水果小游戏草稿或备份
    if (self.repository.repoContext.videoSource == AWEVideoSourceAlbum || self.repository.repoContext.videoSource == AWEVideoSourceRemoteResource ||
        (self.repository.repoGame.gameType != ACCGameTypeNone)) {
        dispatch_block_t confirmBlock = ^{
            [self dismissHandler];
            [self dismissViewController:nil];
            [ACCDraft() clearAllEditBackUps];
        };
        if (!needAlert) {
            ACCBLOCK_INVOKE(confirmBlock);
            return YES;
        }
        BOOL isDraft = self.repository.repoDraft.isDraft;
        NSString *title = ACCLocalizedString(@"video_uneditable_hint_for_multi_cut",@"返回上一步会丢失当前效果，是否返回？");
        if (self.repository.repoContext.videoType == AWEVideoTypePhotoMovie) {
            title = ACCLocalizedCurrentString(@"com_mig_your_current_edits_will_be_discarded");
        }
        
        NSString *message = nil;
        if (self.repository.repoContext.videoType == AWEVideoTypePhotoMovie) {
            message = ACCLocalizedCurrentString(@"com_mig_discard");
        }
        
        if (isDraft) {
            title = ACCLocalizedCurrentString(@"com_mig_quit_editing");
            message = nil;
        }
        NSString *confirmTitle = ACCLocalizedCurrentString(@"confirm");
        if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeChangeBackground || 
            self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
            title = @"确认退出发布？";
            confirmTitle = @"退出发布";
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            ACCBLOCK_INVOKE(confirmBlock);
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
        [ACCAlert() showAlertController:alertController animated:YES];
    } else { // 拍摄的视频返回
        AWERepoPublishConfigModel *configRepo = self.repository.repoPublishConfig;
        configRepo.dynamicCoverStartTime = 0;
        configRepo.coverTitleSelectedId = nil;
        configRepo.coverTitleSelectedFrom = nil;
        configRepo.coverImage = nil;
        configRepo.coverTextModel = nil;
        configRepo.coverTextImage = nil;
        configRepo.cropedCoverImage = nil;
        configRepo.coverCropOffset = CGPointZero;
        self.repository.repoProp.totalStickerSavePhotos = [self.repository.repoReshoot getStickerSavePhotoCount];
        
        BOOL isNeedDeleteQuickStoryBackupDraft = ACCConfigBool(kConfigBool_delete_quick_story_backup_draft)
                                    && (!self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp)
                                    && self.repository.repoFlowControl.modeId == ACCRecordModeStory
                                    && !self.ignoreDeleteDraftWhenDismiss;
        
        void(^dismissViewControllerBlk)(void) = ^{
            @strongify(self);
            // 删除快拍模式 backup 草稿
            // 解决 https://bits.bytedance.net/meego/aweme/issue/detail/2645784?parentUrl=%2Faweme%2FissueView%2FtC1SqF8d4R%3Ffop%3Dand 问题
            if (isNeedDeleteQuickStoryBackupDraft) {
                [ACCDraft() deleteDraftWithID:self.repository.repoDraft.taskID];
            }
            
            [self dismissViewController:nil];
        };
        
        if ([[self viewModel] isVideoEdited]) {
            dispatch_block_t confirmBlock = ^{
                @strongify(self);
                [self.repository.repoVideoInfo.video clearAllEffectAndTimeMachine];
                [self.publishModel.repoEditEffect.displayTimeRanges removeAllObjects];
                self.editService.preview.hasEditClip = NO;
                self.repository.repoVideoInfo.video.importTransform = CGAffineTransformIdentity;
                self.repository.repoVideoInfo.video.assetRotationsInfo = @{};
                self.repository.repoVideoInfo.video.videoTimeClipInfo = @{};
                self.repository.repoSticker.interactionStickers = nil;
                [self dismissHandler];
                
                [self.viewModel notifyDataClearForBackup];

                if (!self.publishModel.repoQuickStory.isAvatarQuickStory
                    && !self.publishModel.repoQuickStory.isNewCityStory
                    && !self.ignoreSaveDraftWhenDismiss
                    && !isNeedDeleteQuickStoryBackupDraft) {
                    [ACCDraft() saveDraftWithPublishViewModel:self.publishModel
                                                           video:self.repository.repoVideoInfo.video
                                                          backup:!self.repository.repoDraft.originalDraft
                                                      completion:^(BOOL success, NSError *error) {}];
                }
                
                ACCBLOCK_INVOKE(dismissViewControllerBlk);
            };
            if (!needAlert) {
                ACCBLOCK_INVOKE(confirmBlock);
                return YES;
            }
            
            self.backActionSheet = ACCNewActionSheet();
            [self.backActionSheet addActionWithTitle:@"清空内容并返回" subtitle:nil highlighted:YES handler:^{
                ACCBLOCK_INVOKE(confirmBlock);
            }];
            [self.backActionSheet show];
        } else {
            [self dismissHandler];
            ACCBLOCK_INVOKE(dismissViewControllerBlk);
            return YES;
        }
    }
    return NO;
}

- (void)trackGameExitActionWithStatus:(nonnull NSString *)status
{
    NSMutableDictionary *attributes = [self.repository.repoTrack.referExtra mutableCopy];
    [attributes addEntriesFromDictionary:@{
                                           @"to_status" : status,
                                           @"prop_id" : self.repository.repoVideoInfo.fragmentInfo.firstObject.stickerId ? : @""
                                           }];
    [ACCTracker() trackEvent:@"back_to_shoot_confirm" params:attributes needStagingFlag:NO];
}

- (BOOL)backToShootNeedAlertPlanB:(BOOL)needAlert
{
    if (!needAlert) {
        [self goback];
        return YES;
    }
    
    // 吃水果小游戏已经退出历史舞台了，那么问题来了，其他的gameType，是否也需要加这个通用的拦截，先加着吧
    // 吃水果小游戏
    if (self.repository.repoGame.gameType != ACCGameTypeNone && !self.repository.repoDraft.isDraft && !self.repository.repoDraft.isBackUp) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:ACCLocalizedString(@"av_sticker_game_clear_score_Confirmation", @"确认返回吗？") message:ACCLocalizedString(@"av_sticker_game_clear_score", @"确认返回吗？返回后将取消本次得分") preferredStyle:UIAlertControllerStyleAlert];
        @weakify(self);
        [alertController addAction:[UIAlertAction actionWithTitle: ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self trackGameExitActionWithStatus:@"cancel"];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle: ACCLocalizedCurrentString(@"confirm")  style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self trackGameExitActionWithStatus:@"confirm"];
            [self goback];
        }]];
        [ACCAlert() showAlertController:alertController animated:YES];
    } else if (self.repository.repoContext.isMVVideo || [self.publishModel.repoDuet isOldDuet]) {
        // mv类型的草稿或备份
        // 在编辑页点击返回按钮后，直接dismiss这个navController，而不是popViewController

        NSString *title =  ACCLocalizedCurrentString(@"com_mig_your_current_edits_will_be_discarded");
        NSString *message = ACCLocalizedCurrentString(@"com_mig_discard");
        NSString *confirmTitle = ACCLocalizedCurrentString(@"confirm");
        if (self.repository.repoDraft.isBackUp || self.repository.repoDraft.isDraft) {
            title = ACCLocalizedString(@"com_mig_quit_editing_654qhf", @"是否放弃此次编辑？");
            message = nil;
        } else if (self.repository.repoBirthday.isBirthdayPost) {
            title = ACCLocalizedCurrentString(@"退出后，可以在个人主页继续查看祝福视频");
            message = nil;
            confirmTitle = ACCLocalizedCurrentString(@"退出");

            [ACCTracker() trackEvent:@"click_birthday_exit" params:@{
                @"shoot_way": @"happy_birthday",
                @"shoot_enter_from": self.repository.repoUploadInfo.extraDict[@"shoot_enter_from"] ?: @"",
            }];
        }
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        @weakify(self);
        [alertController addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self goback];
        }]];
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:nil]];
        [ACCAlert() showAlertController:alertController animated:YES];
    } else if (self.repository.repoContext.videoSource == AWEVideoSourceAlbum || (self.repository.repoGame.gameType != ACCGameTypeNone)) {
        // 如果是从相册上传的 / 是吃水果小游戏草稿或备份
        BOOL isDraft = self.repository.repoDraft.isDraft;
        NSString *title = ACCLocalizedString(@"video_uneditable_hint_for_multi_cut", @"返回上一步会丢失当前效果，是否返回？");
        if (self.repository.repoContext.videoType == AWEVideoTypePhotoMovie) {
            title = ACCLocalizedCurrentString(@"com_mig_your_current_edits_will_be_discarded");
        }
        
        NSString *message = nil;
        if (self.repository.repoContext.videoType == AWEVideoTypePhotoMovie) {
            message = ACCLocalizedCurrentString(@"com_mig_discard");
        }
        
        if (isDraft) {
            title = ACCLocalizedCurrentString(@"com_mig_quit_editing");
            message = nil;
        }
        NSString *confirmTitle = ACCLocalizedCurrentString(@"confirm");
        if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeChangeBackground || 
            self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
            title = @"确认退出发布？";
            confirmTitle = @"退出发布";
        }
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
        @weakify(self);
        [alertController addAction:[UIAlertAction actionWithTitle:confirmTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            @strongify(self);
            [self goback];
        }]];
        
        [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
        [ACCAlert() showAlertController:alertController animated:YES];
    } else { // 拍摄的视频返回

        if ([[self viewModel] isVideoEdited]) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:ACCLocalizedCurrentString(@"com_mig_return_to_shooting_page_will_discard_all_the_edits_continue")  preferredStyle:UIAlertControllerStyleAlert];
            @weakify(self);
            [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedString(@"btn_continue",@"继续") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                @strongify(self);
                [self goback];
            }]];
            
            [alertController addAction:[UIAlertAction actionWithTitle:ACCLocalizedCurrentString(@"cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}]];
            [ACCAlert() showAlertController:alertController animated:YES];
        } else {
            [self goback];
            return YES;
        }
    }
    return NO;
}

// 集中判断 animated、抽取 ACCMemoryTrack
- (void)dismissViewController:(dispatch_block_t)done
{
    BOOL isStory = ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) && self.publishModel.repoFlowControl.videoRecordButtonType == AWEVideoRecordButtonTypeStory;
    BOOL isText = self.publishModel.repoFlowControl.videoRecordButtonType == AWEVideoRecordButtonTypeText;
    BOOL isSubPicture = ACCConfigBool(kConfigBool_integrate_quick_shoot_subtab) && self.publishModel.repoContext.videoType == AWEVideoTypeQuickStoryPicture;
    BOOL isSegment = [self p_isSegment];
    BOOL isLivePhoto = self.publishModel.repoFlowControl.videoRecordButtonType == AWEVideoRecordButtonTypeLivePhoto;
    BOOL animated = !(isStory || isText || isSubPicture || isSegment || isLivePhoto);

    if (self.publishModel.repoContext.videoSource == AWEVideoSourceAlbum && ACCConfigBool(kConfigBool_skip_clip_from_album_to_edit)) {
        animated = NO;
    }

    if (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) && ACCConfigBool(kConfigBool_creation_draft_feed_enabled)) {
        if (self.repository.repoDraft.isDraft && !self.repository.repoDraft.isBackUp) {
            [self.editService.preview pause];
            animated = YES;
        }
    }
    
    if (self.containerViewController.navigationController.viewControllers.firstObject == self.containerViewController || self.shouldFinishCreateSceneWhenDismiss) {
        UIViewController *vc = self.shouldFinishCreateSceneWhenDismiss ? self.containerViewController.acc_rootPresentingViewController : self.containerViewController.navigationController;
        [vc dismissViewControllerAnimated:animated completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [ACCMemoryTrack() finishScene:kAWEStudioSceneCreate withKey:kAWEStudioSceneCreate info:nil];
            });
            ACCBLOCK_INVOKE(done);
            ACCBLOCK_INVOKE(self.finishCreateSceneCompletion);
        }];
    } else {
        [self.containerViewController.navigationController popViewControllerAnimated:animated];
    }
}

- (BOOL)p_isSegment
{
    AWEVideoRecordButtonType videoRecordButtonType = self.publishModel.repoFlowControl.videoRecordButtonType;
    return (videoRecordButtonType == AWEVideoRecordButtonTypeMixHoldTap ||
            videoRecordButtonType == AWEVideoRecordButtonTypeMixHoldTap15Seconds ||
            videoRecordButtonType == AWEVideoRecordButtonTypeMixHoldTap60Seconds ||
            videoRecordButtonType == AWEVideoRecordButtonTypeMixHoldTapLongVideo ||
            videoRecordButtonType == AWEVideoRecordButtonTypeMixHoldTap3Minutes);
}

- (void)goback
{
    [self dismissHandler];
    [self.viewModel notifyDataClearForBackup];
    [[self viewModel] clearBeforeBack];
    [self dismissViewController:nil];

    if (self.repository.repoContext.isMVVideo && (self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp)) {
        if (self.repository.repoBirthday.isBirthdayPost) {
            [ACCDraft() deleteDraftWithID:self.repository.repoDraft.taskID];
            [ACCLoading() dismissWindowLoading]; // 下载模版无法取消，仅 UI dismiss
        }
    }
}

- (void)dismissHandler
{
    [self.viewModel trackPlayPerformanceWithNextActionName:@"exit_edit"];
    [self.stickerService dismissPreviewEdge];
    [self removePreUploadingTaskWhenQuit];

    UIViewController *controller = self.containerViewController;
    if ([controller conformsToProtocol:@protocol(ACCComponentController)] && [controller respondsToSelector:@selector(close)]) {
        [(id<ACCComponentController>)controller close];
    }

    if (!self.ignoreCancelBlock && self.viewModel.inputData.cancelBlock) {
        self.viewModel.inputData.cancelBlock();
    }
    // remove composer cache back to record
    [self.editService.effect removeComposerNodes];
}

// 静默上传
- (void)removePreUploadingTaskWhenQuit
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if (self.containerViewController.navigationController) {
        [self.containerViewController.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj respondsToSelector:@selector(removePreUploadingTask)]) {
                [obj performSelector:@selector(removePreUploadingTask)];
                *stop = YES;
            }
        }];
    }
#pragma clang diagnostic pop
}

#pragma mark - 下一步

- (void)nextButtonClicked
{
    [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickNextInEdit];
    if (![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin]) {
        @weakify(self);
         [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
            @strongify(self);
            if(success){
                [self p_origNextButtonClicked];
            }
        } withTrackerInformation:@{@"enter_from":@"video_edit_page"}];
    } else {
        [self p_origNextButtonClicked];
    }
}

- (void)p_origNextButtonClicked
{
    if (!self.isMounted) {
        return;
    }
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCMainServiceProtocol) isTeenModeEnabled]) {
        [ACCToast() show:@"儿童/青少年模式开启中，无法发布视频"];
        return;
    }
    if ([self.repository.repoTrack.referString isEqualToString:@"coin_task"]) {
        [ACCToast() show:@"发布非日常作品无法完成任务"];
    }
    if ([self p_shouldDisableNext]) {
        [ACCToast() show:ACCConfigString(kConfigString_disable_edit_next_toast)];
        return;
    }

    if ([self showUserIncentiveAlert]) {
        return;
    }
    [[AWEPublishFirstFrameTracker sharedTracker] eventBegin:kAWEPublishEventFirstFrame];
    [self updateSecurityFramesConfigIfNeeded];
    [self updateRecommendedAICoverTimeIfNeeded];

    if ([ACCToolBarAdapterUtils useAdaptedToolBarContainer]) {
        [self.viewContainer.topRightBarItemContainer resetUpBarContentView];
    } else {
        [self.viewContainer.topRightBarItemContainer resetFoldState];
    }

    NSMutableDictionary *attributes = [self.viewModel extraAttributes];
    if (self.repository.repoTrack.referExtra) {
        [attributes addEntriesFromDictionary:self.repository.repoTrack.referExtra];
    }
    
    [ACCTracker() trackEvent:@"next"
                        label:@"mid_page"
                        value:nil
                        extra:nil
                   attributes:attributes];
    //IM next埋点
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCIMModuleServiceProtocol) isPublishAtMentionWithRepository:self.repository]) {
        [ACCTracker() trackEvent:@"share_after_publish_mention" params:@{@"event_type" : @"next"}];
    }
    
    [self.viewModel trackPlayPerformanceWithNextActionName:@"go_publish"];
    
    [self jumpToPublishViewController];
    
    if (self.repository.repoContext.videoType == AWEVideoTypePhotoToVideo
        && self.repository.repoUploadInfo.toBeUploadedImage
        && ACCConfigBool(kConfigBool_new_capture_photo_autosave_watermark_image)
        && [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusAuthorized
        && !self.repository.repoVideoInfo.capturedPhotoWithWatermark
        && !(self.repository.repoVideoInfo.canvasType != ACCVideoCanvasTypeNone && self.repository.repoContext.videoSource == AWEVideoSourceAlbum)) {
        @weakify(self);
        [ACCPhotoWaterMarkUtil acc_addWaterMarkForSourceImage:self.repository.repoUploadInfo.toBeUploadedImage
                                                   completion:^(UIImage * _Nonnull combinedImage) {
            @strongify(self);
            self.repository.repoVideoInfo.capturedPhotoWithWatermark = combinedImage;
        }];
    }
}

- (BOOL)showUserIncentiveAlert
{
    if (self.hasShowedUserIncentiveAlert) {
        return NO;
    }
    id<ACCRepoUserIncentiveModelProtocol> userIncentiveModel = [self.repository extensionModelOfProtocol:@protocol(ACCRepoUserIncentiveModelProtocol)];
    if (ACC_isEmptyString(userIncentiveModel.motivationTaskID)) {
        return NO;
    }
    NSString *reward = [userIncentiveModel motivationTaskReward];
    if (ACC_isEmptyString(reward)) {
        return NO;
    }
    BOOL shouldShowAlert = NO;
    NSString *alertDescription = @"";
    AWERecordInformationRepoModel *repoRecordInfo = self.repository.repoRecordInfo;
    switch (userIncentiveModel.motivationTaskType) {
        case ACCPostTaskTypeUGCPostProp: {
            __block BOOL hasAppliedProp = NO;
            if (self.repository.repoContext.videoType == AWEVideoTypeQuickStoryPicture ||
                self.repository.repoContext.videoType == AWEVideoTypePicture) {
                hasAppliedProp = !ACC_isEmptyString(repoRecordInfo.pictureToVideoInfo.propID);
            } else {
                [self.repository.repoVideoInfo.fragmentInfo enumerateObjectsUsingBlock:^(AWEVideoFragmentInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                    if (!ACC_isEmptyString(obj.stickerId)) {
                        hasAppliedProp = YES;
                        *stop = YES;
                    }
                }];
            }
            shouldShowAlert = !hasAppliedProp;
            alertDescription = @"作品未添加道具，将无法获得";
        }
            break;
        case ACCPostTaskTypeUGCPostUpload: {
            if (self.repository.repoContext.videoSource != AWEVideoSourceAlbum) {
                shouldShowAlert = YES;
            }
            alertDescription = @"未从相册上传作品，将无法获得";
        }
            break;
        case ACCPostTaskTypeUGCPostMV: {
            if (self.repository.repoContext.videoType != AWEVideoTypeMV) {
                shouldShowAlert = YES;
            }
            alertDescription = @"未使用影集发布作品，将无法获得";
        }
            break;
        default:
            break;
    }

    if (shouldShowAlert) {
        alertDescription = [alertDescription stringByAppendingString:reward];
        [ACCAlert() showAlertWithTitle:@"提示"
                           description:alertDescription
                                 image:nil
                     actionButtonTitle:@"好的"
                     cancelButtonTitle:nil
                           actionBlock:nil
                           cancelBlock:nil];
        self.hasShowedUserIncentiveAlert = YES;
        [ACCTracker() trackEvent:@"notice_window_show" params:@{
            @"enter_from" : self.repository.repoTrack.enterFrom ?: @"",
            @"shoot_way" : self.repository.repoTrack.referString ?: @"",
            @"creation_id" : self.repository.repoContext.createId ?: @"",
        }];
    }

    return shouldShowAlert;
}

- (UIViewController *)rootPresentingViewController
{
    UIViewController *presentingViewController = ((UIViewController*)self.controller).presentingViewController;

    while (presentingViewController.acc_stuioTag != AWEStudioTaskFlowPresentingVCTag &&
           presentingViewController.acc_stuioTag != 500 && // 小程序tag 防止小程序发布视频退出小程序
           presentingViewController.presentingViewController) {
        presentingViewController = presentingViewController.presentingViewController;
    }

    // isCloseMP == YES 关闭小程序
    if (presentingViewController.acc_stuioTag == 500 && self.repository.repoContext.isCloseMP) {
        presentingViewController = presentingViewController.presentingViewController;
    }
    
    if ([self.repository.repoTrack.referString isEqualToString:@"inspiration_page"]) {
        // 不保留相机
        while (presentingViewController.presentingViewController) {
            presentingViewController = presentingViewController.presentingViewController;
        }
    }

    return presentingViewController;
}

- (void)jumpToPublishViewController
{
    [self.viewModel notifyWillEnterPublishPage];
    [self.viewModel trackWhenGotoPublish];// Take track behind signal, to fix track legacy bugs

    VEInfoStickerRestoreMode mode = VEInfoStickerRestoreMode_NORMALIZED;
    CGSize originalPlayerFrame = self.editService.mediaContainerView.originalPlayerFrame.size;
    CGSize editPlayerFrame = self.editService.mediaContainerView.editPlayerFrame.size;
    BOOL isEditSizeEqualToVideoSize = CGSizeEqualToSize(originalPlayerFrame,
                                                        editPlayerFrame);
    if (!isEditSizeEqualToVideoSize && [self.stickerService isAllInfoStickersInPlayer]) {
        // 横屏视频（或者说编辑页上下有黑边的视频），并且所有信息化贴纸都在内部，即发布时合成不会填充黑边
        mode = VEInfoStickerRestoreMode_CROP_NORMALIZED;
        AWELogToolInfo2(@"resolution", AWELogToolTagEdit, @"[Pin]originalPlayerFrame:%@, editPlayerFrame:%@",NSStringFromCGSize(originalPlayerFrame), NSStringFromCGSize(editPlayerFrame));
    }
    [self.editService.sticker setInfoStickerRestoreMode:mode];
    
    let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
    NSAssert(draftService, @"should not be nil");
    [draftService saveDraftEnterNextVC];
    
    [self.editService.preview pause];

    acc_dispatch_main_async_safe((^{
        let coordinator = IESAutoInline(self.serviceProvider, ACCEditToPublishRouterCoordinatorProtocol);
        coordinator.sourceViewController = self.containerViewController;
        ACCPublishViewControllerInputData *inputData = [[ACCPublishViewControllerInputData alloc] init];
        // AME-62681,从编辑页进入发布页时，如果做了修改，封面图不会相应更新，做一次清空封面图处理，封面图为空时，在发布页会重新生成封面图。
        self.repository.repoPublishConfig.coverImage = nil;
        inputData.publishModel = self.publishModel;
        inputData.editService = self.editService;
        inputData.uploadParamsCache = self.viewModel.uploadParamsCache;
        coordinator.targetViewControllerInputData = inputData;
        [coordinator routeWithAnimated:YES completion:nil];
        [self.transitionService setPreviousPage:@"publish"];
    }));
}

- (void)updateRecommendedAICoverTimeIfNeeded
{
    if (self.repository.repoVideoInfo.video.effect_timeMachineType != HTSPlayerTimeMachineNormal) {
        self.repository.repoPublishConfig.recommendedAICoverTime = @(0);
        return;
    }
    if (!self.repository.repoPublishConfig.recommendedAICoverTime) {
        self.repository.repoPublishConfig.recommendedAICoverTime = @(0);
    }
}

- (void)updateSecurityFramesConfigIfNeeded
{
    [self.publishModel.repoVideoInfo updateFragmentInfo];
}

#pragma mark - Publish
- (void)p_publishNormalVideo
{
    [self p_publishNormalVideo:NO];
}

- (void)p_publishNormalVideo:(BOOL)skipCover
{
    self.publishService = [ACCPublishServiceFactory() build];
    self.publishService.publishModel = [self publishModel];
    self.publishService.editService = self.editService;
    self.publishService.uploadParamsCache = self.viewModel.uploadParamsCache;
    [self.publishService publishNormalVideo:skipCover];
}

- (void)p_generateCoverAndSaveDraft
{
    self.publishService = [ACCPublishServiceFactory() build];
    self.publishService.publishModel = [self publishModel];
    self.publishService.editService = self.editService;
    self.publishService.uploadParamsCache = self.viewModel.uploadParamsCache;
    [self.publishService generateCoverAndSave:NO completion:^(NSError * _Nullable error) {
        AWELogToolError2(@"edit", AWELogToolTagDraft, @"Presave draft with error %@", error);
    }];
}

- (void)publishButtonClicked
{
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        [self publishWishWork];
        return;
    }
    [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickPublishDaily];
    [self publishDailyWork];
}

- (void)publishWishWork
{
    if (![self.repository.repoActivity dataValid]) {
        [ACCToast() show:@"还没有输入心愿"];
    } else {
        self.repository.repoPublishConfig.saveToAlbum = NO;
        [self.viewModel notifyWillDirectPublish];
        id<ACCPublishServiceProtocol> publishService = [ACCPublishServiceFactory() build];
        publishService.publishModel = [self publishModel];
        publishService.editService = self.editService;
        publishService.uploadParamsCache = self.viewModel.uploadParamsCache;
        publishService.shouldPreservePublishTitle = [self publishModel].repoDuet.isDuet;
        [publishService publishNormalVideo];
    }
}

- (void)publishDailyPrivateWork
{
    self.repository.repoContext.isPrivateDailyType = YES;
    [self publishDailyWork];
}

- (void)publishDailyWork
{
    if (!self.isMounted) {
        return;
    }

    if ([self showUserIncentiveAlert]) {
        self.repository.repoContext.isPrivateDailyType = NO;
        return;
    }

    if (ACCConfigInt(kConfigInt_edit_diary_strong_guide_style) == ACCEditDiaryStrongGuideStylePop && [ACCVideoEditTipsDiaryGuideFrequencyChecker shouldShowGuideWithKey:kAWENormalVideoEditQuickPublishDidTapDateKey frequency:ACCConfigInt(kConfigInt_edit_diary_strong_guide_frequency)]) {
        [ACCTracker() trackEvent:@"fast_shoot_bubble_show" params:@{
            @"enter_from": self.repository.repoTrack.enterFrom ?: @"",
            @"intro_type": @3,
        }];
        @weakify(self);
        [ACCPublishStrongPopView showInView:self.containerViewController.view publishBlock:^{
            @strongify(self);
            [self publishModel].repoTrack.enterFrom = @"fast_shoot_bubble_show";
            [self publishImpl];
        }];
    } else {
        [self publishImpl];
    }

    [ACCVideoEditTipsDiaryGuideFrequencyChecker markGuideAsTriggeredWithKey:kAWENormalVideoEditQuickPublishDidTapDateKey];
}

- (BOOL)p_isImageAlbumBatchStoryPublishContext
{
    return [ACCBatchPublishService() enableImageAlbumBatchStoryPublish:self.repository];
}

// 发布为图集多段日常
- (void)p_batchPublishImageAlbumStory
{
    self.imageAlbumBatchPublishService = ACCBatchPublishService();
    [self.imageAlbumBatchPublishService publishImageAlbumBatchStoryWithPublishModel:self.repository uploadParamsCache:self.viewModel.uploadParamsCache];
}

- (void)publishImpl
{
    if ([self p_isImageAlbumBatchStoryPublishContext]) {
        [self p_batchPublishImageAlbumStory];
        return;
    }
    
    @weakify(self);
    __auto_type publishBlock = ^(NSString *avatarUrl) {
        @strongify(self);
        [self updateSecurityFramesConfigIfNeeded];
        [self updateRecommendedAICoverTimeIfNeeded];

        BOOL shouldPreservePublishTitle =self.repository.repoDuet.isDuet;
        AWERepoStickerModel *repoSticker = self.repository.repoSticker;
        
        shouldPreservePublishTitle |= [repoSticker containsStickerType:AWEInteractionStickerTypeComment];
        self.publishService = [ACCPublishServiceFactory() build];
        self.publishService.publishModel = [self publishModel];
        if (avatarUrl.length > 0) {
            self.publishService.publishModel.repoUploadInfo.extraDict[@"origin_avatar_uri"] = avatarUrl;

            NSData *data = nil;
            if (self.publishModel.repoQuickStory.isProfileBgStory) {
                data = [NSJSONSerialization dataWithJSONObject:@[@{@"biz": @2, @"content": avatarUrl}] options:0 error:NULL];
            }
            if (data && !self.publishModel.repoPublishConfig.unmodifiablePublishParams[@"related_review_content"]) {
                NSMutableDictionary *publishParam = self.publishModel.repoPublishConfig.unmodifiablePublishParams.mutableCopy?:@{}.mutableCopy;
                publishParam[@"related_review_content"] = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                self.publishModel.repoPublishConfig.unmodifiablePublishParams = publishParam;
            }
        }
        self.publishService.editService = self.editService;
        self.publishService.uploadParamsCache = self.viewModel.uploadParamsCache;
        self.publishService.shouldPreservePublishTitle = shouldPreservePublishTitle;
        [self.publishService publishQuickStory];
    };

    if (self.publishModel.repoQuickStory.beforeEditPublish) {
        self.publishModel.repoQuickStory.beforeEditPublish(^(NSString *avatarUrl) {
            publishBlock(avatarUrl);
        });
    } else {
        publishBlock(nil);
    }
}

#pragma mark - Publish Message

- (void)p_dismissSelf:(BOOL)userDefaultAnimation
{
    if (self.dismissed) {
        return;
    }
    
    self.dismissed = YES;

    if ([[self publishModel].repoUploadInfo.extraDict acc_boolValueForKey:@"publish_back_to_game"]) {
        [self dismissViewController:nil];
    } else if (userDefaultAnimation) {
        [[self rootPresentingViewController] dismissViewControllerAnimated:YES completion:nil];
    } else {
        [[self rootPresentingViewController] dismissViewControllerAnimated:NO completion:nil];
    }
}

- (void)publishServiceTaskWillAppend {
    acc_dispatch_main_async_safe(^{
        if ([self p_isImageAlbumBatchStoryPublishContext]) {
            // 非多发在task开始的时候回释放
            [self.editService.imageAlbumMixed releasePlayer];
        }
        [self p_dismissSelf:YES];
        
    });
}

- (void)publishServiceDraftDidSave {
    acc_dispatch_main_async_safe(^{
        [self.rootPresentingViewController dismissViewControllerAnimated:YES completion:^{
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
               [ACCMemoryTrack() finishScene:kAWEStudioSceneCreate withKey:kAWEStudioSceneCreate info:nil];
            });
        }];
    });
}

#pragma mark - private methods

//DRY原则：抽离公共实现，隐藏发布按钮，调整下一步按钮占满底部区域：
- (void)hidePublishButtonAndUpdateNextButtonFrame
{
    if ([self.viewModel isFlowerRedpacketOneButtonMode]) {
        return;
    }
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        return;
    }
    self.nextButton.alpha = 1;
    self.nextLabel.alpha = 1;
    self.publishButton.hidden = YES;
    CGRect frame = self.nextButton.frame;
    frame.origin.x = 6;
    frame.size.width = CGRectGetWidth(self.viewContainer.containerView.frame) - 6 * 2;
    self.nextButton.frame = frame;
    self.nextLabel.center = CGPointMake(self.nextButton.acc_width / 2, self.nextButton.acc_height / 2);
    
    [self.bottomControlService hidePublishButton];
}

- (void)p_saveBackupCover:(UIImage *)image
{
    self.repository.repoPublishConfig.backupCover = image;
    self.repository.repoPublishConfig.backupCoverPath = [AWEDraftUtils generateBackupCoverPathFromTaskID:self.repository.repoDraft.taskID];
    NSData *coverData = UIImageJPEGRepresentation(image, 0.35);
    [coverData acc_writeToFile:self.repository.repoPublishConfig.backupCoverPath atomically:YES];
}

/// 结束创作流程 （dismiss,非pop返回）
- (void)p_finishCreateScene
{
    self.finishCreateSceneWhenDismiss = YES;
    [self backToShootNeedAlert:NO];
}

/// 春节红包草稿返回异化
- (BOOL)p_showRedpackDraftAlertIfNeeded
{
    // 点击的埋点实现
    @weakify(self);
    void (^track_clickTypeImpl)(NSString *type) = ^(NSString *type) {
        @strongify(self);
        NSMutableDictionary *params = [self p_commonTrackInfoForDraft];
        params[@"click_type"] = type;
        [ACCTracker() trackEvent:@"draft_return_sheet_click" params:[params copy]];
    };
    
    // back up不弹
    if (!self.repository.repoDraft.isDraft ||
        self.repository.repoDraft.isBackUp ||
        !self.repository.repoRedPacket.didBindRedpacketInfo) {
        return NO;
    }
    
    NSString *desc = self.repository.repoRedPacket.isBindCashRedpacketInfo?@"视频将存入草稿箱，未发布的现金红包将在24小时内发起退款" :@"视频将存入草稿箱，拜年红包仅活动期间可用";
    
    [ACCRedPacketAlert() showAlertWithTitle:@"是否退出编辑" description:desc image:nil actionButtonTitle:@"确定" cancelButtonTitle:@"取消" actionBlock:^{
        @strongify(self);
        track_clickTypeImpl(@"return");
        [self p_saveOriginalDraftThenFinishCreateScene];
    } cancelBlock:^{
        track_clickTypeImpl(@"cancel");
    }];
    
    return YES;
}


#pragma mark 挽留弹窗（草稿）

/// 草稿路径下，显示挽留弹窗
- (BOOL)p_showBackAlertForDraftIfNeeded
{
    if (self.repository.repoContext.enterFromShoot || !self.repository.repoDraft.isDraft || self.repository.repoDraft.isBackUp) {
        return NO;
    }
    
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        return NO;
    }
    // 转发到日常场景去除挽留弹窗 （场景：在发布过程中，取消发布）
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory ||
        self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory ||
        self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo) {
        return NO;
    }

    if (!ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        return NO;
    }
    if (ACCConfigInt(kConfigInt_creation_draft_edit_back_click_with_action_sheet) <= 0) {
        return NO;
    }

    [self.viewModel notifyShouldSynchronizeRepository];

    BOOL isDraftEdited = [self.viewModel isDraftEdited];

    const AWEVideoType videoType = self.repository.repoContext.videoType;
    BOOL isShowAlertWithoutEdited = self.repository.repoContext.videoSource == AWEVideoSourceCapture
                                       && videoType != AWEVideoType2DGame
                                       && videoType != AWEVideoTypeMV
                                       && (ACCConfigInt(kConfigInt_creation_draft_edit_back_click_with_action_sheet) > 1 || [self p_isSegment]);
    BOOL shouldAlert = isDraftEdited || isShowAlertWithoutEdited;
    
    if (!shouldAlert) {
        // 保存原草稿并结束创作 (返回至草稿列表)
        [self p_saveOriginalDraftThenFinishCreateScene];
        return YES;
    }
    
    // 显示弹窗
    [ACCTracker() trackEvent:@"draft_return_sheet_show" params:[[self  p_commonTrackInfoForDraft] copy]];
    self.backAlertConfig = [self p_draftBackAlertConfig];
    [self.backAlert show];
 
    return YES;
}

/// 草稿挽留弹窗配置
- (ACCMultiStyleAlertConfigParamsBlock)p_draftBackAlertConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseParamsProtocol> params){
        @strongify(self);
        // 弹窗配置
        //  Popover弹窗差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertPopoverParamsProtocol, ^{
            params.alignmentMode = UIControlContentHorizontalAlignmentLeft;
            params.sourceView = self.backButton;
            params.sourceRect = self.backButton.bounds;
            params.fixedContentWidth = 160;
        });
        
        //  Alert差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertNormalParamsProtocol, ^{
            params.title = @"放弃本次修改吗？";
            params.isButtonAlignedVertically = YES;
        });
        
        
        // 点击的埋点实现
        void (^track_clickTypeImpl)(NSString *type) = ^(NSString *type) {
            @strongify(self);
            NSMutableDictionary *params = [self p_commonTrackInfoForDraft];
            params[@"click_type"] = type;
            [ACCTracker() trackEvent:@"draft_return_sheet_click" params:[params copy]];
        };
        
        BOOL isAlert = [params conformsToProtocol:@protocol(ACCMultiStyleAlertNormalParamsProtocol)];
        
        // 取消修改
        [params addAction:^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
                action.image = ACCResourceImage(@"ic_actionlist_block_red");
            });
            action.title = isAlert ? @"放弃" : @"放弃修改";
            action.actionStyle = ACCMultiStyleAlertActionStyleHightlight;
            action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                @strongify(self);
                track_clickTypeImpl(@"return");
                [self p_saveOriginalDraftThenFinishCreateScene];
            };
        }];
        
        // 保存修改
        [params addAction:^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
                action.image = ACCResourceImage(@"ic_actionlist_draft");
            });
            action.title = isAlert ? @"保存" : @"保存修改";
            action.actionStyle = ACCMultiStyleAlertActionStyleNormal;
            action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                @strongify(self);
                track_clickTypeImpl(@"save_and_return");
                [self p_saveCurrentDraftThenFinishCreateScene];
            };
        }];
        // 继续拍摄 (分段拍场景下)
        if([self p_isSegment]) {
            [params addAction:^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
                    action.image = ACCResourceImage(@"ic_actionlist_retry");
                });
                action.title = @"继续拍摄";
                action.actionStyle = ACCMultiStyleAlertActionStyleNormal;
                action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                    @strongify(self);
                    track_clickTypeImpl(@"shoot");
                    [self p_backToShootForDraft];
                };
            }];
        }
        // 取消
        BOOL isSheet = [params conformsToProtocol:@protocol(ACCMultiStyleAlertSheetParamsProtocol)];
        if (isSheet || isAlert) {
            [params addAction:^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                action.title = @"取消";
                action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
                    @strongify(self);
                    track_clickTypeImpl(@"cancel");
                    [self.backAlert dismiss];
                };
            }];
        }
    };
}

/// 通用埋点信息
- (NSMutableDictionary *)p_commonTrackInfoForDraft
{
    NSMutableDictionary *params = [self.repository.repoTrack.referExtra mutableCopy];
    params[@"tab_name"] = self.repository.repoTrack.tabName;
    params[@"is_multi_content"] = self.repository.repoTrack.mediaCountInfo[@"is_multi_content"];
    params[@"enter_from"] = @"video_edit_page";
    params[@"is_edited"] = [self.viewModel isDraftEdited] ? @(1) : @(0);
    return params;
}

/// 保存原草稿并退出创作
- (void)p_saveOriginalDraftThenFinishCreateScene
{
    @weakify(self);
    [self p_saveOriginalDraftWithCompletion:^(BOOL success, NSError *error) {
        @strongify(self);
        if (error) {
            AWELogToolError2(@"draft", AWELogToolTagEdit, @"save draft model %@", error);
        }
        [self p_finishCreateSceneForDraft];
    }];
}

/// 保存当前草稿并退出创作
- (void)p_saveCurrentDraftThenFinishCreateScene
{
    @weakify(self);
    [self p_saveCurrentDraftWithCompletion:^(BOOL success, NSError *error) {
        @strongify(self);
        if (error) {
            AWELogToolError2(@"draft", AWELogToolTagEdit, @"save draft model %@", error);
        }
        [self p_finishCreateSceneForDraft];
    }];
}

/// 尝试保存原草稿
- (void)p_saveOriginalDraftWithCompletion: (void(^ _Nullable)(BOOL success, NSError *error))completion
{
    AWEVideoPublishViewModel *model = self.viewModel.inputData.publishModel.repoDraft.originalModel;
    id<ACCDraftModelProtocol, ACCPublishRepository> originalDraft = self.viewModel.inputData.publishModel.repoDraft.originalDraft;
    ACCEditVideoData *video = model.repoVideoInfo.video;
    @weakify(self);
    if (model && originalDraft) {
        [ACCDraft() saveDraftWithPublishViewModel:model video:video backup:NO presaveHandler:^(id<ACCDraftModelProtocol> draft) {
            if (originalDraft.saveDate != nil) {
                draft.saveDate = originalDraft.saveDate;
            }
        } completion:^(BOOL success, NSError *error) {
            acc_infra_main_async_safe(^{
                @strongify(self);
                if (success) {
                    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                    userInfo[[ACCDraft() draftIDKey]] = self.repository.repoDraft.taskID;
                    [center postNotificationName:[ACCDraft() draftUpdateNotificationName] object:nil userInfo:userInfo];
                }
                
                ACCBLOCK_INVOKE(completion, success, error);
            });
        }];
    } else {
        ACCBLOCK_INVOKE(completion, YES, nil);
    }
}

/// 尝试保存当前草稿
- (void)p_saveCurrentDraftWithCompletion: (void(^ _Nullable)(BOOL success, NSError *error))completion
{
    [self.viewModel notifyWillEnterPublishPage];
    
    VEInfoStickerRestoreMode mode = VEInfoStickerRestoreMode_NORMALIZED;
    CGSize originalPlayerFrame = self.editService.mediaContainerView.originalPlayerFrame.size;
    CGSize editPlayerFrame = self.editService.mediaContainerView.editPlayerFrame.size;
    BOOL isEditSizeEqualToVideoSize = CGSizeEqualToSize(originalPlayerFrame,
                                                        editPlayerFrame);
    if (!isEditSizeEqualToVideoSize && [self.stickerService isAllInfoStickersInPlayer]) {
        mode = VEInfoStickerRestoreMode_CROP_NORMALIZED;
    }
    [self.editService.sticker setInfoStickerRestoreMode:mode];
    @weakify(self);
    [ACCDraft() updateCoverImageWithViewModel:self.publishModel editService:self.editService completion:^(NSError * _Nonnull error) {
        if (error) {
            AWELogToolError2(@"draft", AWELogToolTagEdit, @"save draft cover %@", error);
        }
        void(^completionInternal)(BOOL success, NSError *error) = ^(BOOL success, NSError *error) {
            acc_infra_main_async_safe(^{
                @strongify(self);
                if (success) {
                    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
                    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
                    userInfo[[ACCDraft() draftIDKey]] = self.repository.repoDraft.taskID;
                    userInfo[[ACCDraft() draftShouldScrollToTopKey]] = @(YES);
                    [center postNotificationName:[ACCDraft() draftUpdateNotificationName] object:nil userInfo:userInfo];
                }
                ACCBLOCK_INVOKE(completion, success, error);
            });
        };
        @strongify(self);
        [ACCDraft() saveDraftWithPublishViewModel:self.publishModel
                                            video:self.repository.repoVideoInfo.video
                                           backup:NO
                                       completion:completionInternal];
    }];
}

/// 返回至拍摄页 (草稿使用)
- (void)p_backToShootForDraft
{
    self.ignoreSaveDraftWhenDismiss = YES;
    [self backToShootNeedAlert:NO];
}

/// 退出创作(草稿使用)
- (void)p_finishCreateSceneForDraft
{
    self.ignoreSaveDraftWhenDismiss = YES;
    [self p_finishCreateScene];
}

#pragma mark 挽留弹窗

/// 显示挽留弹窗（发日常、存草稿）
- (BOOL)p_showBackAlertIfNeeded
{
    // 若存在相关业务功能要显示，则显示弹窗
    NSArray <ACCMultiStyleAlertConfigActionBlock> *businessActionConfigs = [self p_businessActionConfigs];
    
    if (businessActionConfigs.count > 0 || [self p_needForceShowBackAlert]) {
        [self p_resetBackAlertTypeIfNeed];
        self.backAlertConfig = [self p_combineBackAlertConfigsWithBusinessConfigs:businessActionConfigs];
        [self.backAlert show];
        NSMutableDictionary *params = self.repository.repoTrack.referExtra.mutableCopy;
        params[@"tab_name"] = self.repository.repoTrack.tabName;
        params[@"enter_from"] = @"video_edit_page";
        params[@"enter_method"] = [self.viewModel isVideoEdited] ? @"2" : @"3";
        params[@"with_daily_button"] = [self p_shouldShowQuickPublishAction] ? @"1" : @"0";
        params[@"with_save_draft_button"] = [self p_shouldShowSaveDraftAction] ? @"1" : @"0";
        params[@"sheet_type"] = self.backAlert.trackerType;
        [ACCTracker() trackEvent:@"return_sheet_show" params:params];
        return YES;
    }
    return NO;
}

// 问题是alert是懒加载，现在有需要中途换样式的场景，所以需要reset一下
// 实际上每次show之前reset下没问题，但因为灰度所以先放在业务里判断
- (void)p_resetBackAlertTypeIfNeed
{
    // 现金红包需要强制使用底部弹窗
    BOOL needReset = NO;
    
    if (self.repository.repoRedPacket.isBindCashRedpacketInfo &&
        ![self.backAlert.params conformsToProtocol:@protocol(ACCMultiStyleAlertSheetParamsProtocol)]) {
        needReset = YES;
        self.didResetBackAlertFlag = YES;
    } else if (!self.repository.repoRedPacket.isBindCashRedpacketInfo &&
               self.didResetBackAlertFlag) {
        // 解绑红包且reset过则重置回之前的
        self.didResetBackAlertFlag = NO;
        needReset = YES;
    }
    
    if (needReset) {
        self.backAlert = nil; // reset
    }
}

- (BOOL)p_needForceShowBackAlert
{
    if (self.repository.repoRedPacket.isBindCashRedpacketInfo) {
        return YES;
    }
    return NO;
}

/// 根据业务功能配置，组合为整个弹窗配置
- (ACCMultiStyleAlertConfigParamsBlock)p_combineBackAlertConfigsWithBusinessConfigs:(NSArray <ACCMultiStyleAlertConfigActionBlock>*)businessActionConfigs
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseParamsProtocol> params) {
        @strongify(self);
        ACCMultiStyleAlertConfigParamsBlock configWithoutAction = [self p_alertConfigWithoutAction];
        ACCBLOCK_INVOKE(configWithoutAction, params);
        
        // 组装actions
        NSMutableArray <ACCMultiStyleAlertConfigActionBlock> *actionConfigs = [NSMutableArray array];
        // 清空并返回
        [actionConfigs acc_addObject:[self p_clearAndReturnActionConfig]];
        if (businessActionConfigs.count > 0) {
            [actionConfigs acc_addObjectsFromArray:businessActionConfigs];
        }
        // 取消
        BOOL isSheet = [params conformsToProtocol:@protocol(ACCMultiStyleAlertSheetParamsProtocol)];
        BOOL isAlert = [params conformsToProtocol:@protocol(ACCMultiStyleAlertNormalParamsProtocol)];
        if (isSheet || isAlert) {
            [actionConfigs acc_addObject:[self p_cancelActionConfig]];
        }
        
        for (ACCMultiStyleAlertConfigActionBlock actionConfig in actionConfigs) {
            [params addAction:actionConfig];
        }
    };
}
/// 挽留弹窗配置（除Actions以外）
- (ACCMultiStyleAlertConfigParamsBlock)p_alertConfigWithoutAction
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseParamsProtocol> params){
        @strongify(self);
        //  Popover弹窗差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertPopoverParamsProtocol, ^{
            params.alignmentMode = UIControlContentHorizontalAlignmentLeft;
            params.sourceView = self.backButton;
            params.sourceRect = self.backButton.bounds;
            params.fixedContentWidth = 160;
        });
        
        //  Alert差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertNormalParamsProtocol, ^{
            BOOL isKaraoke = self.repository.repoContext.videoType == AWEVideoTypeKaraoke;
            params.title = isKaraoke ? @"清空效果并继续演唱吗？" : @"返回并清空内容吗？";
            params.isButtonAlignedVertically = YES;
        });
        
        //  action sheet 差异点
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(params, ACCMultiStyleAlertSheetParamsProtocol, ^{
            if (self.repository.repoRedPacket.isBindCashRedpacketInfo) {
                params.title = @"现金红包将在24小时内发起退款";
            }
        });
    };
}

/// 挽留弹窗业务功能 （后续需增加其他业务，直接往内部塞）
- (NSArray <ACCMultiStyleAlertConfigActionBlock>*)p_businessActionConfigs
{
    NSMutableArray <ACCMultiStyleAlertConfigActionBlock> *configs = [NSMutableArray array];
    // 存草稿
    if ([self p_shouldShowSaveDraftAction]) {
        [configs acc_addObject:[self p_saveDraftActionConfig]];
    }
    // 发日常
    if ([self p_shouldShowQuickPublishAction]) {
        [configs acc_addObject:[self p_quickPublishActionConfig]];
    }
    return [configs copy];
}

/// 存草稿功能
- (ACCMultiStyleAlertConfigActionBlock)p_saveDraftActionConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
            action.image = ACCResourceImage(@"ic_actionlist_draft");
        });
        action.title = @"存草稿";
        action.actionStyle = ACCMultiStyleAlertActionStyleNormal;
        
        dispatch_block_t saveDraftWithLogin = ^{
            @strongify(self);
            
            // 修复发布时，由于step问题，导致个人页草稿被过滤，显示不出来问题，具体可查看p_conditionIgnorePublishTask:方法。
            self.publishModel.repoFlowControl.step = AWEPublishFlowStepPublish;
            
            [ACCTracker() trackEvent:@"return_sheet_save_draft" params:[self p_commonBackAlertActionTrackInfo]];
            UIView<ACCProcessViewProtcol> *loadingView = [ACCLoading() showProgressOnView:[UIApplication sharedApplication].delegate.window title:@"保存中" animated:YES type:ACCProgressLoadingViewTypeNormal];
            [self p_saveCurrentDraftWithCompletion:^(BOOL success, NSError *error) {
                @strongify(self);
                [loadingView dismissWithAnimated:NO];
                if (success) {
                    [ACCDraft() trackSaveDraftWithViewModel:self.repository from:@"video_edit_page"];
                    
                    NSString *content = @"已保存至个人主页草稿箱";
                    if (ACCConfigInt(kConfigInt_enable_draft_tab_experiment) == ACCUserHomeProfileSubTabStyle) {
                        NSInteger counter = [ACCCache() integerForKey:[NSString stringWithFormat:@"ACCDraftSaveCounter%@", [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID]] ?: 0;
                        content = counter == 0? @"已保存至个人主页草稿箱，卸载抖音将会丢失草稿箱" : content;
                        [ACCCache() setInteger:counter+1 forKey:[NSString stringWithFormat:@"ACCDraftSaveCounter%@", [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID]];
                    }
                    [ACCToast() show:content onView:[UIApplication sharedApplication].delegate.window];
                    [ACCAccessibility() postAccessibilityNotification:UIAccessibilityScreenChangedNotification argument:content];
                    // 震动一下
                    [ACCTapticEngineManager notifySuccess];
                    // 修复快拍返回，触发删除草稿问题
                    self.ignoreDeleteDraftWhenDismiss = YES;
                    // 修复一键成片返回，删除草稿问题与开方平台调用编辑页存草稿后，无法弹出alert问题
                    self.ignoreCancelBlock = YES;
                    
                    self.finishCreateSceneCompletion = ^{
                        // 存草稿后，landing到个人草稿箱界面
                        if (ACCConfigBool(kConfigBool_enable_draft_save_landing_tab)) {
                            [ACCDraftSaveLandingService() transferToUserProfileWithParam:@{@"landing_tab" : @"drafts"}];
                        }
                    };
                    
                    [self p_finishCreateSceneForDraft];
                 
                    [ACCTracker() trackEvent:@"save_draft_box_show" params:@{ @"enter_from" : @"video_edit_page" }];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAWEStudioDraftRecordSavedModififedVideo object:nil];
                }else {
                    NSString *msg = @"保存失败";
                    if ([error.domain isEqual:NSCocoaErrorDomain] && error.code == NSFileWriteOutOfSpaceError) {
                        msg = ACCLocalizedString(@"disk_full", @"磁盘空间不足，请清理缓存后重试");
                    }
                    [ACCToast() show:msg];
                    [ACCAccessibility() postAccessibilityNotification:UIAccessibilityScreenChangedNotification argument:msg];
                    [ACCTapticEngineManager notifyFailure];
                    AWELogToolError2(@"draft", AWELogToolTagEdit, @"save draft model %@", error);
                    NSMutableDictionary *trackerInfo = [[self.repository.repoTrack referExtra] mutableCopy];
                    trackerInfo[@"enter_from"] = @"video_edit_page";
                    [ACCTracker() trackEvent:@"save_draft_fail" params:trackerInfo];
                }
            }];
        };
        
        action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) requireLogin:^(BOOL success) {
                if (success) {
                    saveDraftWithLogin();
                }
            }];
        } ;
    };
}

/// 发日常功能
- (ACCMultiStyleAlertConfigActionBlock)p_quickPublishActionConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
            action.image = ACCResourceImage(@"ic_actionlist_send");
        });
        action.title = @"发日常";
        action.actionStyle = ACCMultiStyleAlertActionStyleNormal;
        action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            @strongify(self);
            if ([self p_isImageAlbumBatchStoryPublishContext]) {
                [ACCTracker() trackEvent:@"return_sheet_publish" params:[self p_commonBackAlertActionTrackInfo]];
                [self p_batchPublishImageAlbumStory];
                return;
            }
            
            BOOL shouldPreservePublishTitle = self.repository.repoDuet.isDuet;
            
            self.publishService = [ACCPublishServiceFactory() build];
            self.publishService.publishModel = [self publishModel];
            self.publishService.editService = self.editService;
            self.publishService.uploadParamsCache = self.viewModel.uploadParamsCache;
            self.publishService.shouldPreservePublishTitle = shouldPreservePublishTitle;
            [self.publishService publishQuickStory];
            [ACCTracker() trackEvent:@"return_sheet_publish" params:[self p_commonBackAlertActionTrackInfo]];
        };
    };
}

/// 清空功能
- (ACCMultiStyleAlertConfigActionBlock)p_clearAndReturnActionConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
        @strongify(self);
        ACC_MULTI_ALERT_PROTOCOL_DIFF_PART(action, ACCMultiStyleAlertPopoverActionProtocol, ^{
            action.image = ACCResourceImage(@"ic_actionlist_delete_red");
        });
        
        BOOL isSheet = [action conformsToProtocol:@protocol(ACCMultiStyleAlertSheetActionProtocol)];
        BOOL isAlert = [action conformsToProtocol:@protocol(ACCMultiStyleAlertNormalActionProtocol)];
        
        NSString *title = nil;
        if(isSheet) {
            BOOL isKaraoke = self.repository.repoContext.videoType == AWEVideoTypeKaraoke;
            title = isKaraoke ? @"清空效果并继续演唱" : @"清空内容并返回";
        }else if(isAlert) {
            title = @"清空";
        }else {
            // 气泡
            title = @"清空内容";
        }
        action.title = title;
        action.actionStyle = ACCMultiStyleAlertActionStyleHightlight;
        action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            @strongify(self);
            [self backToShootNeedAlert:NO];
        };
    };
}

/// cancel功能 (气泡样式，不需要添加取消)
- (ACCMultiStyleAlertConfigActionBlock)p_cancelActionConfig
{
    @weakify(self);
    return ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
        action.title = @"取消";
        action.eventBlock = ^(id<ACCMultiStyleAlertBaseActionProtocol>  _Nonnull action) {
            @strongify(self);
            [self.backAlert dismiss];
        };
    };
}

/// 公用的挽留弹窗Action埋点信息
- (NSDictionary *)p_commonBackAlertActionTrackInfo
{
    NSMutableDictionary *trackerParams = self.repository.repoTrack.referExtra.mutableCopy;
    trackerParams[@"tab_name"] = self.repository.repoTrack.tabName;
    trackerParams[@"enter_from"] = @"video_edit_page";
    trackerParams[@"enter_method"] = [self.viewModel isVideoEdited] ? @"2" : @"3";
    trackerParams[@"sheet_type"] = self.backAlert.trackerType;
    trackerParams[@"is_fast_shoot"] = @"1";
    return [trackerParams copy];
}

/// 过滤显示选项的基本用例，若为NO，则直接不用显示 (目前只给发日常和存草稿使用)
- (BOOL)p_filterBaseCaseForShowAction
{
    if ([self.repository.repoQuickStory shouldDisableQuickPublishActionSheet]) {
        return NO;
    }
    
    if (self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
        return NO;
    }
    
    if (self.repository.repoDraft.isDraft && !self.repository.repoContext.enterFromShoot) {
        return NO;
    }
    
    if (self.publishModel.repoQuickStory.isAvatarQuickStory ||
        self.publishModel.repoQuickStory.isNewCityStory) {
        return NO; //头像发布日常不挽留
    }
    if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeChangeBackground || self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        return NO;
    }
    if (self.repository.repoBirthday.isBirthdayPost) {
        return NO;
    }
    if ([self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory ||
        [self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo)
    {
        return NO;
    }
    // 吃水果小游戏
    if (self.repository.repoGame.gameType != ACCGameTypeNone) {
        return NO;
    }
    
    //圈内投稿，不显示发日常
    BOOL isFromCirclePage = [[self publishModel].repoUploadInfo.extraDict acc_boolValueForKey:@"is_from_circle_page"]
    || [ACCStudioLiteRedPacket() isLiteRedPacketVideo:self.repository];
    if (isFromCirclePage) {
        return NO;
    }
    return YES;
}

/// 是否显示发日常选项
- (BOOL)p_shouldShowQuickPublishAction
{
    if (![self p_filterBaseCaseForShowAction]) {
        return NO;
    }
    
    if (![[self viewModel] isVideoEdited]) {
        // 未编辑
        
        // 现状线上有弹窗场景(目前只有mv场景(包括模板、一键成片等)、图片转视频场景)
        // 在编辑页点击返回按钮后，直接dismiss这个navController，而不是popViewController
        BOOL isSpecialScene = self.repository.repoContext.isMVVideo || self.repository.repoContext.videoType == AWEVideoTypePhotoToVideo;
        if (isSpecialScene && (ACCConfigInt(kConfigInt_creative_edit_before_editing_beg_for_stay_option_for_special) & ACCRecordEditBegForStayOptionQuickPublish)) {
            return YES;
        }
        return  ACCConfigInt(kConfigInt_creative_edit_before_editing_beg_for_stay_option) & ACCRecordEditBegForStayOptionQuickPublish;
    }
    // 已编辑
    return ACCConfigInt(kConfigInt_creative_edit_after_editing_beg_for_stay_option) & ACCRecordEditBegForStayOptionQuickPublish;
}

/// 是否显示存草稿选项 (存草稿目前与发日常强相关，基本判断（baseCase）与发日常一致)
- (BOOL)p_shouldShowSaveDraftAction
{
    if (![self p_filterBaseCaseForShowAction]) {
        return NO;
    }
    
    if (![[self viewModel] isVideoEdited]) {
        // 未编辑
        
        // 分段拍
        if ([self p_isSegment]) {
            return NO;
        }
        // 单张图片、单段视频上传维持现状，编辑前不做返回挽留
        if (self.repository.repoContext.videoSource == AWEVideoSourceAlbum && self.repository.repoUploadInfo.selectedUploadAssets.count == 1) {
            return NO;
        }
        
        // 现状线上有弹窗场景(目前只有mv场景(包括模板、一键成片等)、图片转视频场景)
        // 在编辑页点击返回按钮后，直接dismiss这个navController，而不是popViewController
        BOOL isSpecialScene = self.repository.repoContext.isMVVideo || self.repository.repoContext.videoType == AWEVideoTypePhotoToVideo;
        if (isSpecialScene && (ACCConfigInt(kConfigInt_creative_edit_before_editing_beg_for_stay_option_for_special) & ACCRecordEditBegForStayOptionSaveDraft)) {
            return YES;
        }
        
        // 除上述场景外，现状线上无弹窗场景
        return ACCConfigInt(kConfigInt_creative_edit_before_editing_beg_for_stay_option) & ACCRecordEditBegForStayOptionSaveDraft;
    }
    // 已编辑
    return ACCConfigInt(kConfigInt_creative_edit_after_editing_beg_for_stay_option) & ACCRecordEditBegForStayOptionSaveDraft;
}

#pragma mark - Getter & Setter

- (ACCAnimatedButton *)backButton
{
    if (!_backButton) {
        _backButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeScale];
        UIImage *image = ACCResourceImage(@"icon_camera_back");
        if ([ACCRTL() isRTL]) {
            image = [UIImage imageWithCGImage:image.CGImage scale:image.scale orientation:UIImageOrientationDown];
        }
        [_backButton setImage:image forState:UIControlStateNormal];
        _backButton.titleLabel.font = [ACCFont() acc_systemFontOfSize:15];
        [_backButton setTitleColor:ACCResourceColor(ACCUIColorConstBGContainer4) forState:UIControlStateNormal];
        _backButton.accrtl_viewType = ACCRTLViewTypeNormal;
        _backButton.titleLabel.layer.shadowColor = [ACCResourceColor(ACCUIColorConstBGInverse) colorWithAlphaComponent:0.2].CGColor;
        _backButton.titleLabel.layer.shadowOpacity = 1.0f;
        _backButton.titleLabel.layer.shadowOffset = CGSizeMake(0, 2);
        _backButton.titleLabel.layer.shadowRadius = 6;
        _backButton.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        [_backButton setContentCompressionResistancePriority:UILayoutPriorityRequired - 1 forAxis:UILayoutConstraintAxisHorizontal];
        [_backButton addTarget:self action:@selector(backClicked) forControlEvents:UIControlEventTouchUpInside];
        _backButton.accessibilityLabel = ACCLocalizedCurrentString(@"back_confirm");
    }
    return _backButton;
}

- (UIButton *)nextButton
{
    if (!_nextButton) {
        _nextButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        _nextButton.layer.cornerRadius = 2.0;
        _nextButton.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
        [_nextButton addTarget:self action:@selector(nextButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        _nextButton.accessibilityLabel = ACCLocalizedString(@"common_next", @"下一步");
        NSString *flowerAwardTitle = [self.viewModel nextButtonTitleForFlowerAwardIfEnable];
        if (!ACC_isEmptyString(flowerAwardTitle)) {
            _nextButton.accessibilityLabel = flowerAwardTitle;
        }
    }

    return _nextButton;
}

- (UIButton *)publishButton
{
    if (!_publishButton) {
        _publishButton = [[ACCAnimatedButton alloc] initWithType:ACCAnimatedButtonTypeAlpha];
        _publishButton.layer.cornerRadius = 2;
        _publishButton.backgroundColor = ACCResourceColor(ACCUIColorConstTextInverse);
        [_publishButton addTarget:self action:@selector(publishButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    }
    return _publishButton;
}

- (UILabel *)nextLabel
{
    if (!_nextLabel) {
        _nextLabel = [[UILabel alloc] init];
        _nextLabel.font = [ACCFont() acc_systemFontOfSize:15 weight:ACCFontWeightMedium];
        _nextLabel.text = ACCLocalizedString(@"common_next", @"下一步");
        NSString *flowerAwardTitle = [self.viewModel nextButtonTitleForFlowerAwardIfEnable];
        if (!ACC_isEmptyString(flowerAwardTitle)) {
            _nextLabel.text = flowerAwardTitle;
        }
        _nextLabel.lineBreakMode = NSLineBreakByTruncatingTail;
        _nextLabel.textColor = ACCResourceColor(ACCColorConstTextInverse);
        _nextLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _nextLabel;
}

- (UIImageView *)nextImageView
{
    if (!_nextImageView) {
        _nextImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 24, 24)];
        _nextImageView.backgroundColor = [UIColor clearColor];
        _nextImageView.image = ACCResourceImage(@"icEditNext");
        if ([ACCRTL() isRTL]) {
            _nextImageView.transform = CGAffineTransformRotate(CGAffineTransformIdentity, M_PI);
        }
    }
    return _nextImageView;
}

- (ACCVideoEditFlowControlViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self getViewModel:ACCVideoEditFlowControlViewModel.class];
    }
    return _viewModel;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return self.viewModel.inputData.publishModel;
}

- (UIViewController *)containerViewController
{
    if ([self.controller isKindOfClass:[UIViewController class]]) {
        return (UIViewController *)self.controller;
    }
    NSAssert(nil, @"exception");
    return nil;
}

-(id<ACCStickerServiceProtocol>)stickerService
{
    let service = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
    NSAssert(service, @"should not be nil");
    return service;
}


- (id<ACCMultiStyleAlertProtocol>)backAlert
{
    if (!_backAlert) {
        @weakify(self);
        Protocol *paramsProtocol = ACCMultiStyleAlertParamsProtocol(ACCConfigInt(kConfigInt_creative_edit_record_beg_for_stay_prompt_style));
        // 线上默认是Sheet
        if (!paramsProtocol) paramsProtocol = @protocol(ACCMultiStyleAlertSheetParamsProtocol);
        
        /// 现金红包需要固定action sheet的样式，因为气泡等不能兼容
        if ([self.repository.repoRedPacket isBindCashRedpacketInfo]) {
            paramsProtocol = @protocol(ACCMultiStyleAlertSheetParamsProtocol);
        }
        
        _backAlert = [ACCMultiStyleAlert() initWithParamsProtocol:paramsProtocol configBlock:^(id<ACCMultiStyleAlertBaseParamsProtocol> _Nonnull params) {
            @strongify(self);
            // 每次显示需实时更新数据
            params.reconfigBeforeShow = YES;
            ACCBLOCK_INVOKE(self.backAlertConfig, params);
        }];
    }
    return _backAlert;
}

#pragma mark - ACCVideoEditTipsServiceSubscriber

- (void)tipService:(id<ACCVideoEditTipsService>)tipService didShowFunctionBubbleWithFunctionType:(AWEStudioEditFunctionType)type
{
    if (type == AWEStudioEditFunctionPublishButton) {
        [ACCTracker() trackEvent:@"fast_shoot_bubble_show" params:@{
            @"enter_from": @"video_edit_page",
            @"shoot_way": self.repository.repoTrack.referString ?: @"",
        }];
    }
}

#pragma mark - ACCVideoEditBottomControlSubscriber

- (void)editBottomPanelDidTapType:(ACCVideoEditFlowBottomItemType)type
{
    if (type == ACCVideoEditFlowBottomItemPublish || type == ACCVideoEditFlowBottomItemPublishWish) {
        [self publishButtonClicked];
    } else if (type == ACCVideoEditFlowBottomItemNext) {
        [self nextButtonClicked];
    }
}

@end
