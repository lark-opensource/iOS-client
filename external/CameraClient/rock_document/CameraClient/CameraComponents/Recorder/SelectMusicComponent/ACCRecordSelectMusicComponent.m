//
//  ACCRecordSelectMusicComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liuqing on 2020/3/31.
//

#import "AWERepoMusicModel.h"
#import "AWERepoFlowControlModel.h"
#import "AWERepoPropModel.h"
#import "AWERepoContextModel.h"
#import "ACCRecordSelectMusicComponent.h"
#import "ACCRecordSelectMusicServiceImpl.h"
#import "AWEScrollStringButton.h"
#import "AWERecorderTipsAndBubbleManager.h"
#import <CreationKitInfra/ACCResponder.h>
#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCAPPSettingsProtocol.h"
#import "UIViewController+AWEDismissPresentVCStack.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCSelectMusicInputData.h"
#import "ACCSelectMusicStudioParamsProtocol.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCTransitioningDelegateProtocol.h"
#import "ACCViewControllerProtocol.h"
#import "ACCEffectControlGameViewModel.h"
#import "ACCPropViewModel.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import "ACCFriendsServiceProtocol.h"
#import <CreationKitInfra/ACCTapticEngineManager.h>
#import "AWECameraContainerIconManager.h"
#import "ACCToolBarAdapterUtils.h"

#import "ACCRecordFlowService.h"
#import "ACCRepoRecorderTrackerToolModel.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import "ACCRecordPropService.h"
#import "ACCPropRecommendMusicView.h"
#import "AWERepoTrackModel.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoGameModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CameraClient/ACCMusicModelProtocolD.h>
#import <CreativeKit/UIFont+ACCAdditions.h>
#import <CameraClient/ACCKaraokeService.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CameraClient/ACCRecordMode+LiteTheme.h>
#import "IESEffectModel+ACCRedpacket.h"
#import "ACCScanService.h"
#import "ACCFlowerService.h"

@interface ACCRecordSelectMusicComponent () <
ACCCameraLifeCircleEvent,
ACCRecordFlowServiceSubscriber,
ACCRecordSwitchModeServiceSubscriber,
ACCRecordPropServiceSubscriber,
ACCRecorderViewContainerItemsHideShowObserver,
ACCKaraokeServiceSubscriber,
ACCScanServiceSubscriber,
ACCFlowerServiceSubscriber>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) UIView<ACCLoadingViewProtocol> *loadingView;

@property (nonatomic, strong) ACCRecordSelectMusicServiceImpl *musicService;
@property (nonatomic, weak) UIViewController *selectMusicVC;
@property (nonatomic, strong) id <UIViewControllerTransitioningDelegate, ACCInteractiveTransitionProtocol> transitionDelegate;
@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, assign) BOOL hasUsedFeedMusic;
@property (nonatomic, assign) BOOL hasCancelUsedFeedMusic;
@property (nonatomic, assign) AWERecordMusicSelectSource savedMusicSource;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) UIView<ACCScrollStringButtonProtocol> *selectMusicButton;
@property (nonatomic, strong) UIButton *singMusicButton;
@property (nonatomic, strong) IESEffectModel *reusedFeedSticker;
@property (nonatomic, assign) HTSAudioRange clipAudioRange;

@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCRecordPropService> propService;
@property (nonatomic, weak) id<ACCKaraokeService> karaokeService;
@property (nonatomic, weak) id<ACCScanService> scanService;
@property (nonatomic, weak) id<ACCFlowerService> flowerService;
@property (nonatomic, assign) BOOL isSelectMusicDisable;
@property (nonatomic, strong) id<ACCMusicModelProtocol> weakBindMusic;
@property (nonatomic, assign) NSUInteger weakBindSegmentCount;

@property (nonatomic, strong) UITapGestureRecognizer *tapGes;
@end

@implementation ACCRecordSelectMusicComponent

@synthesize selectMusicButton = _selectMusicButton;

IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, propService, ACCRecordPropService)

IESOptionalInject(self.serviceProvider, karaokeService, ACCKaraokeService)

#pragma mark - Life Cycle

- (void)loadComponentView
{
    if ([self.musicService supportSelectMusic]) {
        @weakify(self);
        [[self.musicService.musicCoverSignal deliverOnMainThread] subscribeNext:^(ACCRecordSelectMusicCoverInfo * _Nullable x) {
            @strongify(self);
            if (![self.musicService supportSelectMusic]) {
                return;
            }
            self.selectMusicButton.shouldAnimate = x.hasMusic;
            CGFloat margin = [ACCToolBarAdapterUtils useToolBarFoldStyle] ? 98 : 84;
            CGFloat maxWidth = MIN(300, CGRectGetWidth([UIScreen mainScreen].bounds) - margin * 2);
            id<ACCMusicModelProtocolD> music = (id<ACCMusicModelProtocolD>)self.repository.repoMusic.music;
            if (music.karaoke) {
                maxWidth -= 54;
            }
            [self.selectMusicButton configWithImage:x.image title:x.title hasMusic:x.hasMusic maxButtonWidth:maxWidth];
            if (!x.hasMusic) {
                [self.selectMusicButton stopAnimation];
            }
            [self ACC_updateLayout];
        }];
        [self addSelectMusicButtonIfNeeded];
        [self.selectMusicButton addTarget:self action:@selector(showSelectMusicViewController)];
        [self configSelectMusicButtonEnable];
        [self.selectMusicButton showLabelShadow];
        [self.musicService refreshMusicCover];
    }
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    self.musicService.inputData.publishModel.repoRecorderTrackerTool.musicID = self.musicService.inputData.publishModel.repoMusic.music.musicID;
    [self p_readExistData];
    [self observeNotification];
    [self bindViewModel];
    HTSAudioRange range = {0};
    self.clipAudioRange = range;
}

- (void)componentWillAppear
{
    if (self.isFirstAppear) {
        if (![self.controller enableFirstRenderOptimize]) {
            [self loadComponentView];
        }
        if ([self.musicService supportSelectMusic]) {
            if (self.musicService.publishModel.repoMusic.music) {
                if (self.cameraService.cameraHasInit) {
                    [self.cameraService.effect muteEffectPropBGM:YES];
                }
            }
        }
    }
}

- (void)componentDidAppear
{
    if (self.cameraService.cameraHasInit) {
        [self.cameraService.effect acc_playMusicIfNotBeingFobbidden];
    }
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
        [self.musicService startReuseFeedMusicFlowIfNeed];
    }
    
    [self.selectMusicButton startAnimation];
    
    if (!self.musicService.hasSelectedMusic && self.musicService.publishModel.repoMusic.music == nil) {
        if (self.weakBindMusic) {
            if (ACCConfigBool(kConfigBool_recorder_auto_use_effect_recommend_music)) {
                [self autoApplyWeakBindMusic:self.weakBindMusic];
            } else if (ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music)) {
                self.repository.repoMusic.weakBindMusic = self.weakBindMusic;
            }
        }
        return;
    }
    
    [self.musicService refreshMusicCover];
    
    [self updateMusicSelectView];
}

- (void)componentDidDisappear
{
    [self.cameraService.effect acc_changeMusicPropPlayStatus:NO];
}

- (void)componentDidUnmount
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)updateMusicSelectView
{
    [self updateSelectMusicEnable];
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)didTapOnCancelFeedMusicButton
{
    [self.musicService handleCancelMusic:self.musicService.inputData.publishModel.repoMusic.music];
    if (!self.hasCancelUsedFeedMusic) {
        NSMutableDictionary *temp = [self.musicService.publishModel.repoTrack.referExtra mutableCopy];
        temp[@"with_prop"] = self.reusedFeedSticker ? @"1" : @"0";
        if (temp[@"reuse_prop_music"]) {
            [temp removeObjectForKey:@"reuse_prop_music"];
        }
        [ACCTracker() trackEvent:@"cancel_same_prop_music" params:temp.copy needStagingFlag:NO];
        self.hasCancelUsedFeedMusic = YES;
        if (self.reusedFeedSticker) {
            [[self propViewModel].stickerFeatureManager clearStickerAllEffect];
        }
    }
    [self updateMusicSelectButtonWithShowCloseButton:NO];
}

- (void)didClickCloseButtonOnMusicButton
{
    [ACCTapticEngineManager tap];
    NSMutableDictionary *trackInfo = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    trackInfo[@"music_id"] = self.repository.repoMusic.music.musicID;
    trackInfo[@"enter_from"] = @"video_shoot_page";
    trackInfo[@"enter_method"] = @"click_outer_cross";
    
    if ([self.repository.repoMusic.music.musicID isEqual:self.weakBindMusic.musicID]) {
        self.weakBindMusic = nil;
    }
    [self.musicService handleCancelMusic:self.repository.repoMusic.music muteBGM:NO trackInfo:trackInfo];
    
    [self ACC_updateLayout];
}

- (void)updateMusicSelectButtonWithShowCloseButton:(BOOL)showCloseButton
{
    if (!showCloseButton) {
        [self.selectMusicButton removeFromSuperview];
        [self addSelectMusicButtonIfNeeded];
        [self ACC_updateLayout];
    }
}

- (void)updateSelectMusicAndSingMusicButton
{
    [self ACC_updateLayout]; // width of invisible buttons will be set to 0.
    BOOL hideSelectMusic = [self shouldHideSelectMusicButton];
    self.isSelectMusicDisable = hideSelectMusic;
    BOOL hideSingMusic = [self shouldHideSingMusicButton];
    [self updateView:self.selectMusicButton Hidden:hideSelectMusic duration:0];
    [self updateView:self.singMusicButton Hidden:hideSingMusic duration:0];
}

- (void)updateView:(UIView *)selectMusicView Hidden:(BOOL)hidden duration:(CGFloat)duration
{
    if (!selectMusicView) {
        return;
    }
    if (duration > 0) {
        if (hidden) {
            [selectMusicView acc_fadeHiddenDuration:duration];
        } else {
            [selectMusicView acc_fadeShowWithDuration:duration];
        }
    } else {
        if (hidden) {
            [selectMusicView acc_fadeHidden];
        } else {
            [selectMusicView acc_fadeShow];
        }
    }
}

#pragma mark - Action

- (void)showSelectMusicViewController
{
    if (!self.isMounted) {
        return;
    }
    // 埋点 - "选择音乐"置灰后，点击上报
    if (!self.selectMusicButton.acc_enabled) {
        [self.musicService trackChangeMusic:NO];
        return;
    }
    [ACCMonitor() startTimingForKey:@"show_select_music_view"];
    [self.musicService trackChangeMusic:YES];
    [[AWERecorderTipsAndBubbleManager shareInstance] removeBubbleAndHintIfNeeded];
    
    HTSAudioRange range = {0};
    self.clipAudioRange = range;

    @weakify(self);
    void (^pickMusicCompletion)(id<ACCMusicModelProtocol>, NSError *) = ^(id<ACCMusicModelProtocol> _Nullable music, NSError * _Nullable error) {
        @strongify(self);
        [self.musicService handlePickMusic:music error:error completion:^{
            acc_dispatch_main_async_safe(^{
                @strongify(self);
                if (self.clipAudioRange.length != 0) {
                    self.musicService.publishModel.repoMusic.audioRange = self.clipAudioRange;
                    [self p_changeMusicStartTime];
                }
                [self.selectMusicVC.presentingViewController acc_dismissModalStackAnimated:YES completion:nil];
                self.selectMusicVC = nil;
            });
        }];
    };
    
    void (^cancelMusicCompletion)(id<ACCMusicModelProtocol>) = ^(id<ACCMusicModelProtocol> music) {
        @strongify(self);
        [self.musicService handleCancelMusic:music];
        [self updateMusicSelectButtonWithShowCloseButton:NO];
        if ([music.musicID isEqual:self.weakBindMusic.musicID]) {
            self.weakBindMusic = nil;
        }
    };
    
    ACCSelectMusicInputData *inputData = [[ACCSelectMusicInputData alloc] init];
    inputData.publishModel = self.repository;
    inputData.challenge = self.musicService.publishModel.repoChallenge.challenge;
    inputData.audioRange = self.musicService.publishModel.repoMusic.audioRange;
    inputData.sceneType = ACCMusicEnterScenceTypeRecorder;
    inputData.useSuggestClipRange = self.musicService.publishModel.repoMusic.useSuggestClipRange;
    inputData.enableMusicLoop = self.repository.repoMusic.enableMusicLoop;
    NSMutableDictionary *clipInfo = self.musicService.publishModel.repoTrack.referExtra.mutableCopy;
    clipInfo[@"music_edited_from"] = @"shoot_change_music";
    inputData.clipTrackInfo = clipInfo.copy;
    inputData.enableClipBlock = ^BOOL(id<ACCMusicModelProtocol> _Nonnull music) {
        @strongify(self);
        let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
        AVAsset *asset = [AVURLAsset assetWithURL:music.loaclAssetUrl ?: [NSURL URLWithString:@""]];
        BOOL canBeClip = CMTimeGetSeconds(asset.duration) > [config standardVideoMaxSeconds] + 1;
        if (music.shootDuration.integerValue > 0) {
            let configService = IESAutoInline(self.serviceProvider, ACCRecordConfigService);
            canBeClip = [configService videoMaxDuration] <= music.shootDuration.floatValue || ([configService videoMaxDuration] > music.shootDuration.floatValue &&  music.auditionDuration.floatValue > music.shootDuration.floatValue);
            if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) != ACCMusicLoopModeOff) {
                canBeClip = YES;
            }
        }
        return canBeClip && music != nil && !self.publishModel.repoReshoot.isReshoot && self.flowService.videoSegmentsCount == 0;
    };
    inputData.didClipWithRange = ^(HTSAudioRange range, NSString *musicEditedFrom, BOOL enableMusicLoop, NSInteger repeatCount) {
        @strongify(self);
        self.repository.repoMusic.enableMusicLoop = enableMusicLoop;
        self.clipAudioRange = range;
        self.musicService.publishModel.repoMusic.musicEditedFrom = musicEditedFrom;
    };
    inputData.didSuggestClipRangeChange = ^(BOOL selected) {
        @strongify(self);
        self.musicService.publishModel.repoMusic.useSuggestClipRange = selected;
    };
    inputData.setForbidSimultaneousScrollViewPanGesture = ^(BOOL forbid) {
        @strongify(self);
        self.transitionDelegate.swipeInteractionController.forbidSimultaneousScrollViewPanGesture = forbid;
    };
    
    let selectMusicObj = IESAutoInline(ACCBaseServiceProvider(), ACCSelectMusicProtocol);
    UIViewController<ACCSelectMusicComponetCommonProtocol> *assSelectMusicVC = [selectMusicObj selectMusicPageWithInputData:inputData pick:pickMusicCompletion cancel:cancelMusicCompletion];
    if ([assSelectMusicVC conformsToProtocol:@protocol(ACCSelectMusicStudioParamsProtocol)]) {
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).propBindMusicIdArray = [self propRecommendMusicWithCurrentEffectID];
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).propId = self.musicService.currentSticker.effectIdentifier;
        if ([self.musicService.currentSticker isMultiSegProp]) {
            ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).isFixDurationMode = YES;
            ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).fixDuration = self.musicService.currentSticker.clipsArray.lastObject.end;
        }
        
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).previousPage = @"video_shoot_page";
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).sameStickerMusic = self.musicService.sameStickerMusic;
        let userService = IESAutoInline(self.serviceProvider, ACCUserServiceProtocol);
        if ([userService isChildMode]) {
            ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).shouldHideCellMoreButton = YES;
        }
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).selectedMusic = inputData.publishModel.repoMusic.music;
        BOOL shouldHideMusicSelectedView = [self shouldHideMusicSelectView];
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).shouldHideCancelButton = shouldHideMusicSelectedView;
    }
    
    assSelectMusicVC.recordServerMode = self.switchModeService.currentRecordMode.serverMode;
    assSelectMusicVC.recordMode = self.switchModeService.currentRecordMode.modeId;
    self.selectMusicVC = assSelectMusicVC;

    [self.cameraService.effect acc_retainForbiddenMusicPropPlayCount];
    
    [self.transitionDelegate.swipeInteractionController wireToViewController:assSelectMusicVC];
    
    UINavigationController *navigationController = [ACCViewControllerService() createCornerBarNaviControllerWithRootVC:assSelectMusicVC];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    navigationController.transitioningDelegate = self.transitionDelegate;
    navigationController.modalPresentationCapturesStatusBarAppearance = YES;
    [self.viewController presentViewController:navigationController animated:YES completion:nil];
    [self.musicService showSelectMusicPanel];
}

#pragma mark - Private
- (void)observeNotification
{
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onAppDidBecomeActive) name:UIApplicationDidBecomeActiveNotification object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(onAppWillResignActive) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)onAppDidBecomeActive
{
    if (!self.isMounted) {
        return;
    }
    if ([ACCResponder topViewController] == [self viewController]) {
        [self.musicService startBGMIfNeeded];
    }
}

- (void)onAppWillResignActive
{
    if (self.cameraService.cameraHasInit) {
        [self.cameraService.effect pauseEffectPropBGM:IESEffectBGMTypeNormal];
    }
}

- (void)bindViewModel
{
    [self.propService addSubscriber:self];
    [self.karaokeService addSubscriber:self];
    @weakify(self);
    [[[[self.musicService.musicCoverSignal deliverOnMainThread] take:1] filter:^BOOL(ACCRecordSelectMusicCoverInfo * _Nullable value) {
        return value.hasMusic;
    }] subscribeNext:^(ACCRecordSelectMusicCoverInfo * _Nullable x) {
        @strongify(self);
        if (self.musicService.publishModel.repoChallenge.challenge.isCommerce) {
            [ACCMonitor() trackService:@"autoselected_music_monitor"
                                        attributes:@{
                                            @"shoot_way" : @"challenge",
                                            @"challenge_id" : self.musicService.publishModel.repoChallenge.challenge.itemID ?: @"",
                                            @"music_id_to_bind" : self.musicService.publishModel.repoMusic.music.musicID ?: @"",
                                        }];
        }
    }];
    
    [[self.musicService.selectMusicAnimationSignal deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.boolValue) {
            [self.selectMusicButton startAnimation];
        } else {
            [self.selectMusicButton stopAnimation];
        }
    }];
    
    [[self.musicService.bindMusicErrorSignal deliverOnMainThread] subscribeNext:^(NSError * _Nullable x) {
        @strongify(self);
        if ([ACCAPPSettings() needShowErrorDescription:x]) {
            [ACCToast() showError:x.localizedDescription];
        } else {
            [ACCToast() showNetWeak];
        }
        [self.musicService refreshMusicCover];
    }];

    [[self.musicService.musicTipSignal deliverOnMainThread] subscribeNext:^(ACCRecordSelectMusicTipType  _Nullable x) {
        @strongify(self);
        RACTupleUnpack(NSString *tip, NSNumber *isFirstEmbed) = x;
        if (tip.length) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(isFirstEmbed.boolValue ? 1.f:0.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self addSelectMusicButtonIfNeeded];
                UIView *selectButtonOrContainerView = self.selectMusicButton;
                [[AWERecorderTipsAndBubbleManager shareInstance] showMusicTimeBubbleWithPublishModel:self.musicService.publishModel
                  forView:selectButtonOrContainerView
                bubbleStr:tip];
            });
        } else {
            [[AWERecorderTipsAndBubbleManager shareInstance] removeMusicBubble];
        }
    }];
    
    [[self.musicService.muteTipSignal deliverOnMainThread] subscribeNext:^(NSString * _Nullable x) {
        [ACCToast() show:x onView:[ACCResponder topViewController].view];
    }];
    
    [self.musicService.downloadMusicForStickerSignal.deliverOnMainThread subscribeNext:^(NSError * _Nullable x) {
        @strongify(self);
        [self finishDownloadingPropRecommendMusicWithError:x];
    }];
    [self.musicService.pickMusicSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self updateSelectMusicAndSingMusicButton];
    }];
    [self.musicService.cancelMusicSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self updateSelectMusicAndSingMusicButton];
    }];
    
    //ar - back to record sginal from game
    [[self effectGameViewModel].didbackToRecordSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.musicService refreshMusicCover];
    }];
    
    //prop
    [[self propViewModel].didSetCurrentStickerSignal.deliverOnMainThread subscribeNext:^(ACCRecordSelectEffectPack _Nullable x) {
        @strongify(self);
        [self p_currentSelectEffectPack:x];
        IESEffectModel *sticker = x.first;
        NSNumber *isPropPanelDismiss = x.third;
        if ([isPropPanelDismiss boolValue] && !ACCConfigBool(kConfigBool_recorder_auto_use_effect_recommend_music) && !ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music)) { //If effect is applied when downloaded with prop panel being dismissed, current music bubble should be cancelled and show the new one.
            [self dismissPropRecommendMusic];
            [self showMusicBubbleForPropRecommendationWithEffectID:sticker.effectIdentifier];
        }
        self.publishModel.repoProp.propBindMusicIDArray = [self propRecommendMusicWithCurrentEffectID];
    }];
    [[[[self propViewModel].didApplyStickerSignal deliverOnMainThread] filter:^BOOL(ACCDidApplyEffectPack  _Nullable value) {
        return value.second.boolValue;
    }] subscribeNext:^(ACCDidApplyEffectPack  _Nullable x) {
        @strongify(self);
        IESEffectModel *sticker = x.first;
        if (ACCConfigBool(kConfigBool_recorder_auto_use_effect_recommend_music) || ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music)) {
            [self handleAutoApplyWeakBindMusicForEffect:sticker.effectIdentifier];
        }
    }];
    [[self propViewModel].pickForceBindMusicSignal.deliverOnMainThread subscribeNext:^(ACCPickForceBindMusicPack _Nullable x) {
        @strongify(self);
        [self p_pickForceBindMusicPack:x];
        [self updateMusicSelectView];
    }];
    [[self propViewModel].cancelForceBindMusicSignal.deliverOnMainThread subscribeNext:^(id<ACCMusicModelProtocol> musicModel) {
        @strongify(self);
        [self.musicService cancelForceBindMusic:musicModel];
    }];
    [[self propViewModel].panelDisplayStatusSignal subscribeNext:^(NSNumber*  _Nullable x) {
        ACCPropPanelDisplayStatus status = x.integerValue;
        @strongify(self);
        if (status == ACCPropPanelDisplayStatusDismiss && !ACCConfigBool(kConfigBool_recorder_auto_use_effect_recommend_music) && !ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music) ) {
            [self showMusicBubbleForPropRecommendationWithEffectID:self.musicService.currentSticker.effectIdentifier];
        }
    }];
    
    [self.viewContainer addObserver:self];

    [RACObserve(self.cameraService.recorder, recorderState).deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        ACCCameraRecorderState state = x.integerValue;
        switch (state) {
            case ACCCameraRecorderStateNormal:
                if (self.viewContainer.isShowingPanel) {
                    [self updateSelectMusicAndSingMusicButton];
                }
                break;
            case ACCCameraRecorderStatePausing:
                if (AWEVideoTypePhotoToVideo != self.musicService.inputData.publishModel.repoContext.videoType &&
                    self.musicService.inputData.publishModel.repoGame.gameType == ACCGameTypeNone  &&
                    !self.viewContainer.isShowingPanel &&
                    self.switchModeService.currentRecordMode.modeId != ACCRecordModeTakePicture) {
                    [self updateSelectMusicAndSingMusicButton];
                }
                break;
            case ACCCameraRecorderStateRecording:
            {
                [self updateSelectMusicAndSingMusicButton];
                break;
            }
            default:
                break;
        }
    }];
    
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) shouldShowCloseButtonOnMusicButton]) {
        [[RACSignal merge:@[
            [RACObserve(self.publishModel.repoMusic, music) distinctUntilChanged],
            [RACObserve(self.selectMusicButton, acc_enabled) distinctUntilChanged],
            [RACObserve(self.musicService, currentSticker) distinctUntilChanged],
        ]] subscribeNext:^(id  _Nullable x) {
            @strongify(self);
            BOOL shouldHideCloseButton = [self shouldHideMusicSelectView];
            if (self.publishModel.repoMusic.music && self.selectMusicButton.acc_enabled && !self.publishModel.repoDuet.isDuet && !shouldHideCloseButton) {
                [self.selectMusicButton showCloseButton];
            } else {
                [self.selectMusicButton hideCloseButton];
            }
            [self ACC_updateLayout];
        }];
    }
}

//when other component send signal in componentDidMount,this component's componentDidMount hasn't excute, so need read exist data;
- (void)p_readExistData
{
    if ([self propViewModel].currentSelectEffectPack) {
        [self p_currentSelectEffectPack:[self propViewModel].currentSelectEffectPack];
    }
    if ([self propViewModel].pickForceBindMusicPack) {
        [self p_pickForceBindMusicPack:[self propViewModel].pickForceBindMusicPack];
    }
    self.selectMusicButton.shouldAnimate = self.repository.repoMusic.music != nil;
}

- (void)p_currentSelectEffectPack:(ACCRecordSelectEffectPack _Nullable)pack
{
    IESEffectModel *sticker = pack.first;
    [self.musicService updateCurrentSticker:sticker];
}

- (void)p_pickForceBindMusicPack:(ACCPickForceBindMusicPack _Nullable)pack
{
    RACTupleUnpack(id<ACCMusicModelProtocol> musicModel,NSNumber *isForceBind, NSError *musicError) = pack;
    [self.musicService pickForceBindMusic:musicModel isForceBind:isForceBind.boolValue error:musicError];
}

- (void)addSelectMusicButtonIfNeeded
{
    if (![self shouldKeepMusicButton]) {
        return;
    }
    if (ACCConfigBool(kConfigBool_karaoke_entrance_after_select_music)) {
        [self.viewContainer.interactionView addSubview:self.singMusicButton];
    }
    if (self.selectMusicButton.superview == nil) {
        UIView *closeView = [self.viewContainer.layoutManager viewForType:ACCViewTypeClose];
        [self.viewContainer.interactionView insertSubview:self.selectMusicButton belowSubview:closeView];
        [self ACC_updateLayout];
    }
}

- (void)ACC_updateLayout
{
    CGFloat topInset = 20;
    if ([UIDevice acc_isIPhoneX]) {
        if (@available(iOS 11.0, *)) {
            topInset = ACC_STATUS_BAR_NORMAL_HEIGHT + kYValueOfRecordAndEditPageUIAdjustment;
        }
    }
    // back button centerY
    CGFloat centerX = self.viewContainer.interactionView.acc_width / 2;
    BOOL hide1 = [self shouldHideSelectMusicButton];
    BOOL hide2 = [self shouldHideSingMusicButton];
    CGFloat w1 = hide1 ? 0 : self.selectMusicButton.buttonWidth;
    CGFloat w2 = hide2 ? 0 : 50;
    CGFloat p = 8;
    CGFloat left1 = (2 * centerX - w1 - w2 - p) / 2;
    CGFloat left2 = left1 + w1 + p;
    CGFloat centerY = topInset + 44 / 2;
    self.selectMusicButton.acc_size = CGSizeMake(w1, 40);
    self.selectMusicButton.center = CGPointMake(left1 + w1/2, centerY);
    self.singMusicButton.acc_size = CGSizeMake(w2, 32);
    self.singMusicButton.center = CGPointMake(left2 + w2/2, centerY);
}

- (void)configSelectMusicButtonEnable
{
    if (self.musicService.inputData.publishModel.repoReshoot.isReshoot) {
        self.selectMusicButton.acc_enabled = NO;
    }
    if (AWEVideoTypePhotoToVideo == self.musicService.publishModel.repoContext.videoType) {
        [self updateSelectMusicAndSingMusicButton];
    }
}

- (void)updateSelectMusicEnable
{
    NSUInteger segmentCount = [self publishModel].repoVideoInfo.fragmentInfo.count;
    BOOL enabled = segmentCount == 0 && !self.musicService.inputData.publishModel.repoReshoot.isReshoot;
    self.selectMusicButton.acc_enabled = enabled;
    self.singMusicButton.titleLabel.alpha = enabled ? 1.0 : 0.4;
    self.singMusicButton.userInteractionEnabled = enabled;
    if (self.hasUsedFeedMusic && self.selectMusicButton.hasMusic) {
        [self updateMusicSelectButtonWithShowCloseButton:enabled];
    }
}

- (void)p_changeMusicStartTime
{
    AVAsset *innerAsset = self.musicService.publishModel.repoMusic.bgmAsset;
    CGFloat duration = CMTimeGetSeconds(innerAsset.duration);
    CGFloat clipDuration = duration - self.musicService.publishModel.repoMusic.audioRange.location;
    
    AWERepoMusicModel *repoMusic = self.repository.repoMusic;
    if ([repoMusic shouldReplaceClipDurationWithMusicShootDuration:clipDuration]) {
        clipDuration = [repoMusic.music.shootDuration floatValue];
    }

    [self.cameraService.recorder changeMusicStartTime:self.musicService.publishModel.repoMusic.audioRange.location clipDuration:clipDuration];
}

- (BOOL)shouldHideMusicSelectView
{
    if ([self.musicService.currentSticker isTypeMusicBeat] && ![self.musicService.currentSticker allowMusicBeatCancelMusic]) {
        return YES;
    }
    
    if ([self.musicService.currentSticker acc_isCannotCancelMusic]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - public

#pragma mark - Sing Music

- (void)clickedsingMusicButton:(UIButton *)button
{
    if (self.singMusicButton.selected) {
        [self.karaokeService exitKaraokeWorkflow];
    } else {
        AWERepoMusicModel *repoMusic = self.repository.repoMusic;
        id<ACCMusicModelProtocolD> music = (id<ACCMusicModelProtocolD>)repoMusic.music;
        music.musicSelectedFrom = repoMusic.musicSelectedFrom;
        if ([music.karaoke.musicIDStr isEqualToString:music.musicID]) {
            [self triggerKaraokeProcessWithMusic:music karaokeMusic:music];
        } else {
            // if these ids are not equal, we need to request the real karaoke music
            [ACCLoading() showWindowLoadingWithTitle:(@"加载中...") animated:YES];
            [ACCVideoMusic() requestMusicItemWithID:music.karaoke.musicIDStr additionalParams:@{@"scene" : @204} completion:^(id<ACCMusicModelProtocol>  _Nonnull model, NSError * _Nonnull error) {
                [ACCLoading() dismissWindowLoadingWithAnimated:YES];
                id<ACCMusicModelProtocolD> realMusic = (id<ACCMusicModelProtocolD>)model;
                if (!realMusic || ![realMusic.musicID isEqualToString:realMusic.karaoke.musicIDStr]) {
                    [ACCToast() show:@"加载失败"];
                }
                realMusic.musicSelectedFrom = music.musicSelectedFrom;
                [self triggerKaraokeProcessWithMusic:music karaokeMusic:realMusic];
            }];
        }
    }
}

- (void)triggerKaraokeProcessWithMusic:(id<ACCMusicModelProtocolD>)music karaokeMusic:(id<ACCMusicModelProtocolD>)karaokeMusic
{
    [UIView animateWithDuration:0.3 animations:^{
        self.selectMusicButton.alpha = 0;
        self.singMusicButton.alpha = 0;
    } completion:^(BOOL finished) {
        self.selectMusicButton.hidden = YES;
        self.singMusicButton.hidden = YES;
        self.savedMusicSource = self.repository.repoMusic.musicSelectFrom;
        id<ACCRepoKaraokeModelProtocol> repoKaraoke = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
        [repoKaraoke setTrackParam:@"sing_along" forKey:@"pop_music_method"];
        BOOL useLightning = self.switchModeService.currentRecordMode.modeId == ACCRecordModeStory;
        @weakify(self);
        NSDictionary *params = @{
            kAWEKaraokeWorkflowMusic : karaokeMusic,
            kAWEKaraokeWorkflowMusicSource : @(ACCKaraokeMusicSourceRecordSelectMusic),
            kAWEKaraokeWorkflowUseLightning : @(useLightning),
            kAWEKaraokeWorkflowReturnBlock : ^{
                @strongify(self);
                [self.cameraService.cameraControl startVideoCapture];
                    self.repository.repoMusic.musicSelectFrom = self.savedMusicSource;
                self.repository.repoMusic.music = music;
                [self.musicService refreshMusicCover];
                [self.selectMusicButton startAnimation];
                [self.musicService pickMusic:music complete:nil];
                [self trackCancelSingleSongWithMusic:music];
            },
        };
        [self.karaokeService startKaraokeWorkflowWithParams:params];
    }];
    acc_dispatch_queue_async_safe(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableDictionary *params = [self.repository.repoTrack.referExtra mutableCopy];
        params[@"tab_name"] = self.repository.repoTrack.tabName;
        params[@"music_id"] = karaokeMusic.musicID;
        params[@"pop_music_id"] = karaokeMusic.karaoke.karaokeIDStr;
        [ACCTracker() trackEvent:@"click_sing_along" params:params];
    });
}

- (void)trackCancelSingleSongWithMusic:(id<ACCMusicModelProtocolD>)music
{
    if (self.karaokeService.musicSource != ACCKaraokeMusicSourceRecordSelectMusic) {
        return;
    }
    NSMutableDictionary *params = [self.repository.repoTrack.referExtra mutableCopy];
    id<ACCRepoKaraokeModelProtocol> repoKaraoke = [self.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    [params addEntriesFromDictionary:repoKaraoke.trackParams];
    params[@"enter_method"] = repoKaraoke.trackParams[@"pop_music_return_method"];
    [ACCTracker() trackEvent:@"cancel_sing_along" params:params];
}

- (UIButton *)singMusicButton
{
    if (!_singMusicButton) {
        UIButton *button = [[UIButton alloc] initWithFrame:CGRectZero];
        [button setTitle:@"跟唱" forState:UIControlStateNormal];
        button.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.6];
        button.layer.cornerRadius = 16;
        button.titleLabel.font = [UIFont acc_systemFontOfSize:13.0 weight:ACCFontWeightMedium];
        [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
        [button addTarget:self action:@selector(clickedsingMusicButton:) forControlEvents:UIControlEventTouchUpInside];
        _singMusicButton = button;
    }
    return _singMusicButton;
}

#pragma mark - Prop recommend music

- (void)showMusicBubbleForPropRecommendationWithEffectID:(NSString *)effectID
{
    if (!effectID) {
        return;
    }
    if ([self shouldForbidMusicBubble]) {
        return;
    }
    UIView *targetView = self.selectMusicButton;
    ACCPropRecommendMusicReponseModel *responseModel = [self.propService recommemdMusicListForPropID:effectID];
    id<ACCMusicModelProtocol> bubbleMusic = responseModel.weakBindMusic;
    if (ACCConfigEnum(kConfigInt_recommend_music_by_effect, ACCRecommendMusicByProp) > ACCRecommendMusicByPropA && !bubbleMusic) {
        bubbleMusic = ACC_isEmptyArray(responseModel.recommendMusicList) ? nil : responseModel.recommendMusicList.firstObject;
    }
    if (bubbleMusic) {
        if (!self.tapGes) {
            [self addGestureForMusicBubble];
        }
        [self.cameraService.effect muteEffectPropBGM:YES];
        self.tapGes.enabled = YES;
        self.musicService.propRecommendMusic = bubbleMusic;
        NSString *bubbleTitle = responseModel.bubbleTitle;
        ACCPropRecommendMusicView *contentView = [[ACCPropRecommendMusicView alloc] initWithFrame:CGRectMake(0, 0, 244, 52)];
        [contentView.confirmButton addTarget:self action:@selector(downloadAndUseCurrentPropRecommendedMusic) forControlEvents:UIControlEventTouchUpInside];
        @weakify(self);
        @weakify(contentView);
        [ACCWebImage() requestImageWithURLArray:bubbleMusic.thumbURL.URLList completion:^(UIImage *image, NSURL *url, NSError *error) {
            if (error) {
                AWELogToolError(AWELogToolTagMusic, @"Request image error. %@", error);
                return;
            }
            if (!image || !url) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                @strongify(self);
                [contentView updateWithMusicModel:bubbleMusic bubbleTitle:bubbleTitle Image:image creationID:self.musicService.publishModel.repoContext.createId];
                [[AWERecorderTipsAndBubbleManager shareInstance] showPropRecommendMusicBubbleForTargetView:targetView
                                                                                                     music:self.musicService.propRecommendMusic
                                                                                              publishModel:self.musicService.publishModel
                                                                                                 direction:ACCBubbleDirectionDown
                                                                                               contentView:contentView
                                                                                             containerView:self.viewContainer.interactionView
                                                                                     withDismissCompletion:^{
                    @strongify(self);
                    @strongify(contentView);
                    self.tapGes.enabled = NO;
                    [self.cameraService.effect muteEffectPropBGM:NO];
                    [contentView viewDidDismissEvent];
                }];
            });
        }];
    }
}

- (BOOL)shouldForbidMusicBubble
{
    //Ban music bubble if music already exists.
    return !self.switchModeService.currentRecordMode.isVideo || self.switchModeService.currentRecordMode.modeId == ACCRecordModeKaraoke ||
    [ACCPropRecommendMusicReponseModel shouldForbidRequestRecommendMusicInfoWithEffectModel:[self propViewModel].currentSticker] ||
    self.musicService.publishModel.repoVideoInfo.fragmentInfo.count > 0 ||
    self.musicService.publishModel.repoMusic.music != nil ||
    ![self.musicService supportSelectMusic] ||
    !self.selectMusicButton.acc_enabled ||
    ![self shouldKeepMusicButton];
}

- (void)downloadAndUseCurrentPropRecommendedMusic
{
    if (!self.loadingView) {
        self.loadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:[[UIApplication sharedApplication].delegate window]];
    }
    [self.musicService downloadPropRecommendedMusic];
}

- (void)finishDownloadingPropRecommendMusicWithError:(NSError *)error
{
    if (self.loadingView) {
        [self.loadingView dismissWithAnimated:YES];
        self.loadingView = nil;
    }
    
    // do not apply any prop music in karaoke mode
    if (self.switchModeService.currentRecordMode.modeId == ACCRecordModeKaraoke || self.karaokeService.inKaraokeRecordPage) {
        return;
    }
    
    @weakify(self);
    if (ACCConfigBool(kConfigBool_recorder_auto_use_effect_recommend_music)) {
        self.selectMusicButton.enableImageRotation = NO;
        [self.musicService handleAutoSelectWeakBindMusic:self.musicService.propRecommendMusic error:error completion:^{
            @strongify(self);
            if (!error) {
                self.musicService.publishModel.repoMusic.musicSelectedFrom = @"prop_music_recommended";
                acc_dispatch_main_async_safe(^{
                    [self.selectMusicButton startAnimation];
                    [self.cameraService.effect muteEffectPropBGM:YES];
                    [self updateMusicSelectView];
                });
            }
        }];
        return;
    }

    [self.musicService handlePickMusic:self.musicService.propRecommendMusic error:error completion:^{
        @strongify(self);
        if (error) {
            [self dismissPropRecommendMusic];
            return;
        }
        self.musicService.publishModel.repoMusic.musicSelectedFrom = @"prop_music_recommended";
        [ACCTracker() track:@"click_music_popup_use" params:@{@"enter_from" : @"video_shoot_page",
                                                              @"music_id" : self.musicService.publishModel.repoMusic.music.musicID ? : @"",
                                                              @"creation_id" : self.musicService.publishModel.repoContext.createId ? : @""
        }];
        
        acc_dispatch_main_async_safe(^{
            [self.selectMusicButton startAnimation];
            [self dismissPropRecommendMusic];
            [self.cameraService.effect muteEffectPropBGM:YES];
            [self updateMusicSelectView];
        });
    }];
}

- (void)dismissPropRecommendMusic
{
    [[AWERecorderTipsAndBubbleManager shareInstance] removePropRecommendMusicBubble];
}

- (void)addGestureForMusicBubble
{
    self.tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissPropRecommendMusic)];
    self.tapGes.enabled = NO;
    [self.viewContainer.interactionView addGestureRecognizer:self.tapGes];
}

- (NSArray<NSString *> *)propRecommendMusicWithCurrentEffectID
{
    if (ACCConfigEnum(kConfigInt_recommend_music_by_effect, ACCRecommendMusicByProp) <= ACCRecommendMusicByPropA) {
        return self.musicService.currentSticker.musicIDs;
    }
    __block NSMutableArray<NSString *> *musicIDs = [self.musicService.currentSticker.musicIDs mutableCopy];
    if (!musicIDs) {
        musicIDs = [[NSMutableArray alloc] init];
    }
    ACCPropRecommendMusicReponseModel *responseModel = [self.propService recommemdMusicListForPropID:self.musicService.currentSticker.effectIdentifier];
    if (responseModel && !ACC_isEmptyArray(responseModel.recommendMusicList)) {
        [responseModel.recommendMusicList enumerateObjectsUsingBlock:^(id<ACCMusicModelProtocol> _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if (obj.musicID != nil && ![musicIDs containsObject:obj.musicID]) {
                [musicIDs addObject:obj.musicID];
            }
        }];
    }
    return [musicIDs copy];
}

- (void)handleAutoApplyWeakBindMusicForEffect:(NSString *)effectID
{
    if (self.repository.repoMusic.music
        || self.repository.repoMusic.musicSelectFrom != AWERecordMusicSelectSourceUnSelected
        || self.publishModel.repoDuet.isDuet) {
        return;
    }
    ACCPropRecommendMusicReponseModel *responseModel = [self.propService recommemdMusicListForPropID:effectID];
    id<ACCMusicModelProtocol> music = responseModel.weakBindMusic;
    if (ACCConfigEnum(kConfigInt_recommend_music_by_effect, ACCRecommendMusicByProp) > ACCRecommendMusicByPropA && !music) {
        music = ACC_isEmptyArray(responseModel.recommendMusicList) ? nil : responseModel.recommendMusicList.firstObject;
    }
    BOOL hasOnePiece = self.flowService.videoSegmentsCount > 0;
    if (ACCConfigBool(kConfigBool_recorder_auto_use_effect_recommend_music) && !hasOnePiece) {
        [self autoApplyWeakBindMusic:music];
        self.weakBindMusic = music;
    } else if (ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music) && !self.repository.repoMusic.weakBindMusic) {
        // 使用道具拍摄后才向repomusic中写入weakbindmusic
        self.weakBindMusic = music;
    }
}

- (void)autoApplyWeakBindMusic:(id<ACCMusicModelProtocol>)music
{
    if (!music) {
        return;
    }
    UIImage *image = [AWECameraContainerIconManager selectMusicButtonLoadingImage];
    [self.selectMusicButton configWithImage:image title:@"配乐中" hasMusic:NO];
    self.selectMusicButton.enableImageRotation = YES;
    [self ACC_updateLayout];
    self.musicService.propRecommendMusic = music;
    [self downloadAndUseCurrentPropRecommendedMusic];
}

#pragma mark - Getter

- (UIView<ACCScrollStringButtonProtocol> *)selectMusicButton
{
    if (!_selectMusicButton) {
        _selectMusicButton = (UIView<ACCScrollStringButtonProtocol> *)[[AWEScrollStringButton alloc] init];
        [_selectMusicButton.closeButton addTarget:self action:@selector(didClickCloseButtonOnMusicButton) forControlEvents:UIControlEventTouchUpInside];
        _selectMusicButton.enableConstantSpeed = YES;
        _selectMusicButton.closeButton.isAccessibilityElement = YES;
        _selectMusicButton.closeButton.accessibilityLabel = @"取消选择的音乐";
        _selectMusicButton.closeButton.accessibilityTraits = UIAccessibilityTraitButton;
        [self.viewContainer.layoutManager addSubview:_selectMusicButton viewType:ACCViewTypeSelectMusic];
    }
     return _selectMusicButton;
}

- (ACCRecordSelectMusicServiceImpl *)musicService
{
    if (!_musicService) {
        _musicService = [self.modelFactory createViewModel:[ACCRecordSelectMusicServiceImpl class]];
    }
    return _musicService;
}

//new game
-(ACCEffectControlGameViewModel *)effectGameViewModel
{
    ACCEffectControlGameViewModel *gameVM = [self getViewModel:ACCEffectControlGameViewModel.class];
    NSAssert(gameVM, @"should not be nil");
    return gameVM;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (id<UIViewControllerTransitioningDelegate, ACCInteractiveTransitionProtocol>)transitionDelegate
{
    if (!_transitionDelegate) {
        _transitionDelegate = [IESAutoInline(self.serviceProvider, ACCTransitioningDelegateProtocol) modalTransitionDelegate];
    }
    return _transitionDelegate;
}

- (UIViewController *)viewController
{
    if ([self.controller isKindOfClass:UIViewController.class]) {
        return (UIViewController *)(self.controller);
    }
    
    return nil;
}

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCRecordSelectMusicService), self.musicService);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registDurationHandler:self.musicService];
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registAudioHandler:self.musicService];
    [self.cameraService addSubscriber:self];
    [self.flowService addSubscriber:self];
    [self.switchModeService addSubscriber:self];
    self.scanService = IESAutoInline(serviceProvider, ACCScanService);
    [self.scanService addSubscriber:self];
    self.flowerService = IESAutoInline(serviceProvider, ACCFlowerService);
    [self.flowerService addSubscriber:self];
}

- (AWEVideoPublishViewModel *)publishModel
{
    return self.musicService.inputData.publishModel;
}

- (AVAsset *)musicAsset
{
    AVAsset *asset = self.publishModel.repoMusic.bgmAsset;
    return asset;
}

- (BOOL)shouldKeepMusicButton
{
    if (self.publishModel.repoContext.isIMRecord) {
        return NO;
    }
    return YES;
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidRemoveLastSegment:(BOOL)isReactHasMerge
{
    if (isReactHasMerge) {
        [self.musicService removeFrames:YES];
    }
    [self updateSelectMusicEnable];
    if (self.weakBindSegmentCount >= self.flowService.videoSegmentsCount + 1) {
        self.weakBindMusic = nil;
        self.repository.repoMusic.weakBindMusic = nil;
    }
}

- (void)flowServiceDidRemoveAllSegment
{
    [self.musicService removeFrames:NO];
    [self updateSelectMusicEnable];
}

- (void)flowServiceDidMarkDuration:(CGFloat)duration
{
    [self updateSelectMusicEnable];
    if (ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music)) {
        if (self.weakBindMusic && !self.repository.repoMusic.weakBindMusic) {
            self.weakBindSegmentCount = self.flowService.videoSegmentsCount;
            self.repository.repoMusic.weakBindMusic = self.weakBindMusic;
        }
    }
}

- (void)flowServiceDidTakePicture:(UIImage *)image error:(NSError *)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"Take picture failed. %@", error);
        return;
    }
    
    acc_dispatch_main_async_safe(^{
        if (ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music)) {
            self.weakBindMusic = self.repository.repoMusic.weakBindMusic;
            self.repository.repoMusic.weakBindMusic = nil;
        }
    });
}

#pragma mark - ACCKaraokeServiceSubscriber

- (void)karaokeService:(id<ACCKaraokeService>)service inKaraokeRecordPageDidChangeFrom:(BOOL)prevState to:(BOOL)state
{
    [self updateSelectMusicAndSingMusicButton];
}

#pragma mark - ACCFlowerServiceSubscriber

- (void)flowerServiceDidEnterFlowerMode:(id<ACCFlowerService>)service
{
    [self updateSelectMusicAndSingMusicButton];
}

- (void)flowerServiceDidLeaveFlowerMode:(id<ACCFlowerService>)service
{
    [self updateSelectMusicAndSingMusicButton];
}

- (void)flowerServiceDidChangeFromItem:(ACCFlowerPanelEffectModel *)prevItem toItem:(ACCFlowerPanelEffectModel *)item
{
    [self updateSelectMusicAndSingMusicButton];
}

#pragma mark - ACCScanServiceSubscriber

- (void)scanService:(id<ACCScanService>)scanService didSwitchModeFrom:(ACCScanMode)oldMode to:(ACCScanMode)mode
{
    [self updateSelectMusicAndSingMusicButton];
}

#pragma mark - ACCCameraLifeCircleEvent
- (void)onCreateCameraCompleteWithCamera:(id<ACCCameraService>)cameraService
{
    //恢复音乐裁剪选择的位置
    NSURL *audioURL = self.publishModel.repoMusic.music.loaclAssetUrl;
    if (audioURL && [cameraService.recorder respondsToSelector:@selector(setMusicWithURL:repeat:completion:)]) {
        HTSAudioRange range = {0};
        range.location = self.publishModel.repoMusic.audioRange.location;
        range.length = self.publishModel.repoContext.maxDuration;

        __block CGFloat clipDuration = self.publishModel.repoContext.maxDuration;
        @weakify(self);
        void(^block)(void) = ^{
            @strongify(self);
            AVAsset *innerAsset = [self musicAsset];
            if (innerAsset && CMTIME_IS_VALID(innerAsset.duration) && CMTimeGetSeconds(innerAsset.duration) > 0) {
                CGFloat duration = CMTimeGetSeconds(innerAsset.duration);
                clipDuration = MIN(clipDuration, duration - range.location);
            }

            if ([cameraService.recorder respondsToSelector:@selector(changeMusicStartTime:clipDuration:)]) {
                if ([self.repository.repoMusic shouldReplaceClipDurationWithMusicShootDuration:clipDuration]) {
                    clipDuration = [self.repository.repoMusic.music.shootDuration floatValue];
                }
                [cameraService.recorder changeMusicStartTime:range.location clipDuration:clipDuration];
            }
            let configService = IESAutoInline(self.serviceProvider, ACCRecordConfigService);
            // fix publishModel maxduration need update after auth approve
            [configService configPublishModelMaxDurationAfterCameraSetMusic];
            NSString *logString = [NSString stringWithFormat:@"create camera setMusicWithURL, asset exist:%@, asset duration: %lf, music loaclAssetUrl:%@, enableLVAudioFrame: %@", innerAsset ? @"YES" : @"NO", CMTimeGetSeconds(innerAsset.duration), audioURL, @"YES"];
            AWELogToolWarn2(@"camera setMusicWithURL", AWELogToolTagRecord, @"%@", logString);

            AVAsset *bgmAsset = self.publishModel.repoVideoInfo.video.audioAssets.firstObject;
            self.publishModel.repoMusic.bgmAsset = bgmAsset;
            if (bgmAsset) {
                self.publishModel.repoMusic.bgmClipRange = [self.publishModel.repoVideoInfo.video acc_safeAudioTimeClipInfo:bgmAsset];
            }

            [self.cameraService.effect acc_propPlayMusic:self.cameraService.effect.currentSticker];
        };
        AVAsset *audioAsset = cameraService.recorder.videoData.audioAssets.firstObject;
        if (audioAsset && [audioAsset isKindOfClass:AVURLAsset.class] && [audioURL isEqual:[(AVURLAsset *)audioAsset URL]]) {
            block();
        } else {
            BOOL shouldRepeat = self.repository.repoProp.isMultiSegPropApplied || [self.repository.repoMusic shouldEnableMusicLoop:[IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol) videoMaxSeconds]];
            [cameraService.recorder setMusicWithURL:audioURL repeat:shouldRepeat completion:block];
        }
    }
}

- (void)cameraService:(id<ACCCameraService>)cameraService startRecordWithError:(NSError *)error
{
    if (error) {
        AWELogToolError(AWELogToolTagRecord, @"Start record failed. %@", error);
    }
    [self.musicService switchAIRecordFrameTypeIfNeeded];
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    BOOL isModeAlways15Seconds = (oldMode.modeId == ACCRecordModeMixHoldTap15SecondsRecord && mode.isStoryStyleMode) || (mode.modeId == ACCRecordModeMixHoldTap15SecondsRecord && oldMode.isStoryStyleMode);
    BOOL isDraftOrReshoot = self.musicService.inputData.publishModel.repoDraft.isDraft || self.musicService.inputData.publishModel.repoReshoot.isReshoot;
    if (mode.lengthMode != ACCRecordLengthModeUnknown && !isDraftOrReshoot && !self.isFirstAppear && !isModeAlways15Seconds) {
        // 如果有剪切过音乐，且不是快拍 <-> 分段拍15秒，切换底部tab则重置
        [self.musicService updateAudioRangeWithStartLocation:0];
    }
    if ([self.repository.repoMusic shouldEnableMusicLoop:[IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol) videoMaxSeconds]] && self.repository.repoMusic.music.loaclAssetUrl) {
        [self.cameraService.recorder setMusicWithURL:self.repository.repoMusic.music.loaclAssetUrl repeat:YES];
    }
    [self updateSelectMusicAndSingMusicButton];
}

#pragma mark - ACCRecordPropServiceSubscriber

- (void)propServiceWillApplyProp:(IESEffectModel *)prop propSource:(ACCPropSource)propSource
{
    // deselect Auto applied weak bind music
    if (propSource == ACCPropSourceKeepWhenEdit) {
        return;
    }
    BOOL hasOnePiece = self.flowService.videoSegmentsCount > 0;
    if (hasOnePiece) {
        return;
    }
    if (ACCConfigBool(kConfigBool_recorder_auto_use_effect_recommend_music)) {
        if (self.repository.repoMusic.musicSelectFrom == AWERecordMusicSelectSourceRecommendAutoApply) {
            [self.musicService handleCancelMusic:self.repository.repoMusic.music];
        }
    } else if (ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music)) {
        self.weakBindMusic = nil;
        self.repository.repoMusic.weakBindMusic = nil;
    }
}

/// 这个方法后续会替换 pickForceBindMusicSignal cancelForceBindMusicSignal 这两个 Signal
- (void)propServiceDidSelectForceBindingMusic:(id<ACCMusicModelProtocol>)music oldMusic:(id<ACCMusicModelProtocol>)oldMusic
{
    if (music && self.switchModeService.currentRecordMode.modeId != ACCRecordModeKaraoke) { // Do not apply user-selected music in karaoke mode, or the bgm would be a mess.
        [self.musicService pickForceBindMusic:music isForceBind:YES error:nil];
        [self updateMusicSelectView];
    } else {
        [self.musicService cancelForceBindMusic:oldMusic];
    }
}

- (void)propServiceDidFinishFetchRecommendMusicListForPropID:(NSString *)propID
{
    if (self.propViewModel.currentSticker != nil && [self.propViewModel.currentSticker.effectIdentifier isEqual:propID]) {
        if (ACCConfigBool(kConfigBool_recorder_auto_use_effect_recommend_music) || ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music)) {
            [self handleAutoApplyWeakBindMusicForEffect:propID];
        } else if (self.propViewModel.propPanelStatus != ACCPropPanelDisplayStatusShow) {
            [self showMusicBubbleForPropRecommendationWithEffectID:propID];
        }
    }
}

#pragma mark - ACCRecorderViewContainerItemsHideShowObserver

- (void)shouldItemsShow:(BOOL)show animated:(BOOL)animated
{
    [self updateSelectMusicAndSingMusicButton];
}

- (BOOL)shouldHideSelectMusicButton
{
    NSUInteger segmentCount = [self publishModel].repoVideoInfo.fragmentInfo.count;
    
    // (已经有拍摄片段 || 是重拍) && 不应该滚动显示歌曲名
    if ((segmentCount > 0 || self.musicService.inputData.publishModel.repoReshoot.isReshoot) && !self.selectMusicButton.shouldAnimate) {
        return YES;
    }
    
    // 拍照、直播tab
    ACCRecordModeIdentifier modeID = self.switchModeService.currentRecordMode.modeId;
    if (modeID == ACCRecordModeTakePicture || modeID == ACCRecordModeLivePhoto) {
        return YES;
    }
    
    // 进入K歌拍摄页（K歌tab点歌、其他tab点跟唱、外部带音乐K歌、草稿backup恢复）
    if (self.karaokeService.inKaraokeRecordPage) {
        return YES;
    }
    
    // 其他组件要求隐藏拍摄页小组件，或者正显示半屏panel
    if (self.viewContainer.itemsShouldHide || self.viewContainer.isShowingPanel) {
        return YES;
    }
    
    // 小游戏
    if (self.musicService.inputData.publishModel.repoGame.gameType != ACCGameTypeNone) {
        return YES;
    }
    
    // 合拍
    if (self.repository.repoDuet.isDuet) {
        return YES;
    }
    
    // 正在拍摄
    if (self.cameraService.recorder.recorderState == ACCCameraRecorderStateRecording) {
        return YES;
    }
    
    // flower camera
    if (self.scanService.currentMode != ACCScanModeNone) {
        return YES;
    }
    if (self.flowerService.isShowingPhotoProp) {
        return YES;
    }
    
    return NO;
}

- (BOOL)shouldHideSingMusicButton
{
    if (!ACCConfigBool(kConfigBool_karaoke_enabled) || !ACCConfigBool(kConfigBool_enable_story_tab_in_recorder) || !ACCConfigBool(kConfigBool_karaoke_entrance_after_select_music)) {
        return YES;
    }
    BOOL hidden = [self shouldHideSelectMusicButton];
    id<ACCMusicModelProtocolD> music = (id<ACCMusicModelProtocolD>)self.repository.repoMusic.music;
    // 如果选音乐cell应该隐藏，也隐藏跟唱 cell
    // 如果歌曲不能K歌，隐藏跟唱 cell
    // 春节tab隐藏跟唱
    return hidden || !music.karaoke || self.flowerService.inFlowerPropMode;
}

@end
