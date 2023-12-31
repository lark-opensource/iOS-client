//
//  ACCVideoEditMusicComponent.m
//  AWEStudio
//
//  Created by lxp on 2019/9/10.
//

#import "AWERepoDraftModel.h"
#import "AWERepoMusicModel.h"
#import "AWERepoPublishConfigModel.h"
#import "AWERepoPropModel.h"
#import "AWERepoContextModel.h"
#import "ACCVideoEditMusicComponent.h"
#import <CameraClient/ACCSelectMusicInputData.h>
#import <CameraClient/ACCCornerBarNaviController.h>
#import "AWEMusicSelectItem.h"
#import "AWEAIMusicRecommendManager.h"
#import "ACCLVAudioRecoverUtil.h"
#import "AWEVideoEditDefine.h"
#import "ACCCutMusicRangeChangeContext.h"
#import "AWERepoVideoInfoModel.h"
#import "ACCEditMusicBizModule.h"
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import "ACCEditorMusicConfigAssembler.h"

#import "UIViewController+AWEDismissPresentVCStack.h"
#import <CreationKitArch/AWEAnimatedMusicCoverButton.h>
#import "ACCEditFirstCreativeServiceProtocol.h"
#import "ACCLyricsStickerServiceProtocol.h"
#import "ACCEditVolumeServiceProtocol.h"
#import "ACCEditClipServiceProtocol.h"
#import "ACCEditClipV1ServiceProtocol.h"
#import "ACCFriendsServiceProtocol.h"
#import <CameraClient/ACCCommerceServiceProtocol.h>
#import <CreationKitInfra/ACCTapticEngineManager.h>

#import <CameraClient/ACCSelectMusicStudioParamsProtocol.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <HTSServiceKit/HTSMessageCenter.h>
#import <CameraClient/ACCConfigKeyDefines.h>

#import "AWEVideoPublishMusicPanelView.h"
#import "ACCVideoEditMusicViewModel.h"
#import "ACCVideoEditMusicViewModel+ACCSelectMusic.h"
#import "ACCMusicPanelAnimator.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <KVOController/NSObject+FBKVOController.h>
#import "ACCEditCutMusicServiceProtocol.h"
#import "ACCTransitioningDelegateProtocol.h"
#import <CreationKitArch/ACCMVTemplateInfo.h>
#import "ACCVideoEditChallengeBindViewModel.h"
#import "ACCVideoEditTipsService.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import "AWEScrollStringButton.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWECameraContainerIconManager.h"
#import <CreationKitArch/ACCPublishRepository.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCVideoMusicProtocol.h"
#import <CameraClient/ACCDraftResourceRecoverProtocol.h>
#import "ACCStickerServiceProtocol.h"
#import <CreationKitArch/ACCRecordInformationRepoModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "AWERepoCutSameModel.h"
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoChallengeModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CameraClient/ACCRepoQuickStoryModel.h>
#import <CameraClient/ACCSelectTemplateServiceProtocol.h>
#import "ACCEditTransitionService.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCEditImageAlbumMixedProtocolD.h"
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import "ACCBarItem+Adapter.h"
#import "ACCToolBarAdapterUtils.h"
#import "ACCStudioGlobalConfig.h"

#import "ACCMusicPanelViewModel.h"
#import "ACCMusicPanelView.h"
#import <CameraClient/ACCCameraClient.h>

// 智能照片电影
#import <CameraClient/ACCEditSmartMovieProtocol.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CameraClient/ACCSmartMovieABConfig.h>
#import <CameraClient/ACCSmartMovieManagerProtocol.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

static NSString *const kChallengeBindMoudleKeyMusic = @"music";

typedef NS_ENUM(NSUInteger, ACCVideoEditMusicAssetDownloadingStatus) {
    ACCVideoEditMusicAssetDownloadingStatusNone = 0,
    ACCVideoEditMusicAssetDownloadingStatusDownloading,
    ACCVideoEditMusicAssetDownloadingStatusFaild,
};

@interface ACCVideoEditMusicComponent () <
ACCPanelViewDelegate,
ACCMusicCollectMessage,
ACCEditSessionLifeCircleEvent,
ACCDraftResourceRecoverProtocol,
ACCVideoEditTipsServiceSubscriber,
HTSVideoSoundEffectPanelViewDelegate
>

@property (nonatomic, strong) UIView<ACCMusicPanelViewProtocol> *musicPanelView;

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) UIView<ACCScrollStringButtonProtocol> *selectMusicButton;
@property (nonatomic, weak) id<ACCVideoEditTipsService> tipsSerivce;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditCutMusicServiceProtocol> cutMusicService;
@property (nonatomic, weak) id<ACCEditFirstCreativeServiceProtocol> firstCreativeService;
@property (nonatomic, weak) id<ACCLyricsStickerServiceProtocol> lyricsStickerService;
@property (nonatomic, weak) id<ACCEditVolumeServiceProtocol> volumeService;
@property (nonatomic, weak) id<ACCEditClipServiceProtocol> clipService;
@property (nonatomic, weak) id<ACCEditClipV1ServiceProtocol> clipV1Service;
@property (nonatomic, weak) id<ACCSelectTemplateServiceProtocol> selectTemplateService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCEditSmartMovieProtocol> smartMovieService;

@property (nonatomic, strong) ACCEditMusicBizModule *musicBizModule;

@property (nonatomic, strong) id <UIViewControllerTransitioningDelegate, ACCInteractiveTransitionProtocol> transDelegate;

@property (nonatomic, strong) ACCVideoEditMusicViewModel *viewModel;
@property (nonatomic, assign) BOOL shouldRefetchFavorites;
@property (nonatomic, assign) BOOL isShowing;
@property (nonatomic, assign) BOOL isMusicStoryCutEnable;

// 后置下载的音乐下载状态
@property (nonatomic, assign) ACCVideoEditMusicAssetDownloadingStatus postponeMusicAssetDownloadingStatus;

@end

@implementation ACCVideoEditMusicComponent

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, tipsSerivce, ACCVideoEditTipsService)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESOptionalInject(self.serviceProvider, cutMusicService, ACCEditCutMusicServiceProtocol)
IESOptionalInject(self.serviceProvider, lyricsStickerService, ACCLyricsStickerServiceProtocol)
IESOptionalInject(self.serviceProvider, volumeService, ACCEditVolumeServiceProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, smartMovieService, ACCEditSmartMovieProtocol)

IESOptionalInject(self.serviceProvider, clipService, ACCEditClipServiceProtocol)
IESOptionalInject(self.serviceProvider, clipV1Service, ACCEditClipV1ServiceProtocol)
IESOptionalInject(self.serviceProvider, firstCreativeService, ACCEditFirstCreativeServiceProtocol)
IESOptionalInject(self.serviceProvider, selectTemplateService, ACCSelectTemplateServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCEditMusicServiceProtocol),
                                   self.viewModel);
}

#pragma mark - ACCFeatureComponent

- (void)dealloc
{
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.musicBizModule = [[ACCEditMusicBizModule alloc] initWithServiceProvider:self.serviceProvider];

    self.viewModel.repository = self.repository;
    self.viewModel.serviceProvider = self.serviceProvider;
    self.viewModel.musicBizModule = self.musicBizModule;
    
    [self.editService addSubscriber:self];
    [self.tipsSerivce addSubscriber:self];
}

- (void)loadComponentView {
    if ([self publishModel].repoMusic.disableMusicModule) {
        return;
    }
    
    [self.musicBizModule setup];

    if (!self.publishModel.repoDuet.isDuet) {
        [self.viewContainer addToolBarBarItem:[self barItem]];
    }
    if ([self.controller enableFirstRenderOptimize]) {
        [self loadSelectMusicButton];
        [self refreshVideoEditMusicRelatedUI];
        [self updateSelectMusicTitle];
    }
}

- (void)componentDidMount
{
    if ([self publishModel].repoMusic.disableMusicModule) {
        return;
    }
    
    REGISTER_MESSAGE(ACCMusicCollectMessage, self);

    [self bindViewModel];
    self.isShowing = YES;
    
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    if (!self.repository.repoDuet.isDuet) {
        [self.viewContainer addToolBarBarItem:[self barItem]];
    }
    
    
    AWERepoMusicModel *repoMusic = self.repository.repoMusic;
    if (!self.repository.repoDraft.isDraft &&
        (repoMusic.musicSelectFrom == AWERecordMusicSelectSourceChallengeStrongBinded
         || repoMusic.musicSelectFrom == AWERecordMusicSelectSourceStickerForceBind
         || repoMusic.musicSelectFrom == AWERecordMusicSelectSourceRecommendAutoApply)) {
        [self.viewModel updateChallengeOrPropRecommendMusic:repoMusic.music];
    }
    
    @weakify(self);
    [self.viewModel configForbidWeakBindMusicWithBlock:^{  // 配置弱绑定音乐
        @strongify(self);
        [self updateMusicButton];
    }];

    [[self challengeBindViewModel] addToIgnoreListWhenRemoveAllEditWithModuleKey:kChallengeBindMoudleKeyMusic];
    /// 从本地恢复的music不需要update，因为话题没有持久化
    if (!self.repository.repoMusic.music || !self.repository.repoDraft.isDraft || self.repository.repoMusic.music.challenge) {
        [self updateChallenge];
    }
    
    [self p_initialForLVAudioFrame];
    if ([self.repository.repoContext supportNewEditClip] &&
        (self.repository.repoDraft.isDraft ||
         self.repository.repoDraft.isBackUp ||
         self.repository.repoImageAlbumInfo.isTransformedFromImageAlbumMVVideoEditMode ||
         [self.repository.repoSmartMovie transformedForSmartMovie])) {
        [self.viewModel fetchHotMuiscListIfNeeded];
    }
    
    if (!self.publishModel.repoDraft.isDraft && !self.publishModel.repoDraft.isBackUp) {
        BOOL isOneClickFilmRecommendMusic = self.publishModel.repoContext.videoType == AWEVideoTypeOneClickFilming && self.publishModel.repoMusic.music;
        [self.viewModel setNeedResetInitialMusic:self.publishModel.repoContext.videoType == AWEVideoTypeSmartMV || isOneClickFilmRecommendMusic];
    }
    
    if (self.publishModel.repoMusic.music) {
        [self.viewModel setMusicWhenEnterEditPage:self.publishModel.repoMusic.music];
    }
    
    [self p_dowloadPostponeMusicAssetIfNeed];
}

- (void)componentDidUnmount
{
    [self.viewContainer.panelViewController unregisterObserver:self];
    UNREGISTER_MESSAGE(ACCMusicCollectMessage, self);
}

- (void)componentWillAppear
{
    if ([self publishModel].repoMusic.disableMusicModule) {
        return;
    }

    if (![self.controller enableFirstRenderOptimize]) {
        [self loadSelectMusicButton];
        [self refreshVideoEditMusicRelatedUI];
    }
    
    if (self.shouldRefetchFavorites) {
        [self.viewModel retryFetchFirstPage];
        self.shouldRefetchFavorites = NO;
    }
    if (self.repository.repoFlowControl.step != AWEPublishFlowStepCapture) {
        [ACCLVAudioRecoverUtil recoverAudioIfNeededWithOption:ACCLVFrameRecoverAll publishModel:self.publishModel editService:self.editService];
    }
}

- (void)componentDidAppear
{
    if ([self publishModel].repoMusic.disableMusicModule) {
        return;
    }

    self.isShowing = YES;
    [self checkNeedDeselectMusic];
    [self updateMusicButton];
    [self.viewModel handleSmartMVInitialMusic:self.publishModel.repoMusic.music];
    
    [self p_handleOfflineMusicIfNeeded];
}

- (void)componentWillDisappear
{
    self.isShowing = NO;
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

#pragma mark - ACCVideoEditTipsServiceSubscriber

- (void)tipService:(id<ACCVideoEditTipsService>)tipService didTappedImageBubbleWithFunctionType:(AWEStudioEditFunctionType)type {
    if (type == AWEStudioEditFunctionMusic || type == AWEStudioEditFunctionTopSelectMusic) {
        [self showMusicSelectPanelView];
    }
}

#pragma mark - 
- (void)muteVideoIfNeeded
{
    
}

- (void)firstRenderWithEditService:(id<ACCEditServiceProtocol>)editService {
    if (!self.repository.repoDuet.isDuet) { // 非合拍场景
        if (self.repository.repoMusic.music) {
            [self.viewModel fetchPhotoToVideoMusicSilently];
            [self.viewModel fetchFramesAndUPload];
        } else {
            @weakify(self);
            [self.viewModel fetchPhotoToVideoMusicWithCompletion:^(BOOL success) {
                @strongify(self);
                if (success && self.isShowing) {
                    [self.viewModel selectFirstMusicAutomatically];
                }
                // prepare for fetch AI musicList if needed
                [self.viewModel fetchFramesAndUPload];
            }];
        }
    }
}

#pragma mark - Private

- (void)bindViewModel
{
    @weakify(self);    
    [self.viewModel.mvDidChangeMusicSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.boolValue) {
            [self refreshVideoEditMusicRelatedUI];
            [self.musicPanelView updateActionButtonState];
        }
    }];
    
    __block UIView<ACCLoadingViewProtocol> *loadingView = nil;
    [[self.viewModel.mvChangeMusicLoadingSignal deliverOnMainThread] subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.boolValue) {
            loadingView = [ACCLoading() showLoadingAndDisableUserInteractionOnView:self.containerViewController.view];
            // 标记为正在设置mv音乐动效的音乐
            // 音乐动效类mv的音乐设置过程是异步的，当正在设置音乐动效的音乐时，禁止再次设置音乐
            self.musicPanelView.musicSelectView.mvChangeMusicInProgress = YES;
        } else {
            [loadingView dismiss];
            // 标记为设置mv音乐动效的音乐已结束
            self.musicPanelView.musicSelectView.mvChangeMusicInProgress = NO;
        }
    }];
    
    [[self.viewModel.changeMusicTipsSignal deliverOnMainThread] subscribeNext:^(NSString * _Nullable x) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [ACCToast() showToast:x];
        });
    }];
    
    [[self.viewModel.musicListSignal deliverOnMainThread] subscribeNext:^(NSArray<AWEMusicSelectItem *> * _Nullable x) {
        @strongify(self);
        [self.musicPanelView updateWithMusicList:[x mutableCopy] playingMusic:self.repository.repoMusic.music];
    }];
    
    [[[self.smartMovieService.recoverySignal deliverOnMainThread] takeUntil:self.rac_willDeallocSignal] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.viewModel updateMusicList];
    }];
    [[[self.smartMovieService.didSwitchMusicSignal deliverOnMainThread] takeUntil:self.rac_willDeallocSignal]subscribeNext:^(id  _Nullable x) {
         @strongify(self)
         [self.viewModel sendSmartMovieDidAddMusicSignal];
    }];
    [[self.viewModel.collectedMusicListSignal deliverOnMainThread] subscribeNext:^(NSArray<AWEMusicSelectItem *> * _Nullable x) {
        @strongify(self);
        [self.musicPanelView updateWithUserCollectedMusicList:[x mutableCopy]];
    }];
    
    [self.viewModel.didRequestMusicSignal subscribeNext:^(id<ACCMusicModelProtocol> _Nullable music) {
        @strongify(self);
    
        if ([self.repository.repoMusic.music.musicID isEqual:music.musicID]) {
            if (music.challenge.itemID.length) {
                self.repository.repoMusic.music.challenge = music.challenge;
            } else {
                self.repository.repoMusic.music.challenge = nil;
            }
            
            [self updateChallenge];
        }
    }];
    
    [self.clipService.didFinishClipEditSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        if ([AWEAIMusicRecommendManager sharedInstance].clipVideoModified) {
            if (![self.viewModel AIMusicDisableWithType:NULL]) {
                [self.musicPanelView resetFirstAnimation];
                [self.viewModel reFetchFramesAndUpload];
            }
        }
    }];
    
    [self.cutMusicService.checkMusicFeatureToastSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self showMusicFeatureDisableToast];
    }];
    
    [self.cutMusicService.didFinishCutMusicSignal.deliverOnMainThread subscribeNext:^(ACCCutMusicRangeChangeContext * _Nullable x) {
        @strongify(self);
        [self.musicPanelView updateCurrentPlayMusicClipRange:x.audioRange];
    }];
    
    [self.cutMusicService.didDismissPanelSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self showMusicSelectPanelView];
    }];
    
    [self.firstCreativeService.didTapChangeMusicViewSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self showMusicSelectPanelView];
    }];
    
    [self.lyricsStickerService.didSelectMusicSignal.deliverOnMainThread subscribeNext:^(id<ACCMusicModelProtocol> _Nullable x) {
        @strongify(self);
        [self.viewModel handleSelectMusic:x error:nil removeMusicSticker:NO];
    }];
    
    [self.lyricsStickerService.updateMusicRelateUISignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self refreshMusicRelatedButton];
    }];
    
    [self.lyricsStickerService.updateLyricsStickerButtonSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.integerValue == ACCMusicPanelLyricsStickerButtonChangeTypeReset) {
            [self resetLyricStickerButton];
        } else if (x.integerValue == ACCMusicPanelLyricsStickerButtonChangeTypeEnable) {
            [self enableLyricStickerButton];
        } else if (x.integerValue == ACCMusicPanelLyricsStickerButtonChangeTypeUnenable) {
            [self unenableLyricStickerButton];
        }
    }];
    
    [self.volumeService.checkMusicFeatureToastSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self showMusicFeatureDisableToast];
    }];
    
    [self.viewModel.didDeselectMusicSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self updateChallenge];
        [self updateMusicButton];
        if ([self p_shouldSaveDraftWhenSelectMusic]) {
            [ACCDraft() saveDraftWithPublishViewModel:self.repository
                                                video:self.repository.repoVideoInfo.video
                                               backup:!self.repository.repoDraft.originalDraft
                                       presaveHandler:^(id<ACCDraftModelProtocol> draftModel) {
                
            } completion:^(BOOL success, NSError * _Nonnull error) {
                
            }];
        }
    }];
    
    [[self tipsSerivce].showMusicBubbleSignal.deliverOnMainThread subscribeNext:^(NSNumber *x) {
        @strongify(self);
        ACCMusicBubbleType bubbleType = (ACCMusicBubbleType)[x integerValue];
        if (bubbleType == ACCNormalMusicBubble) {
            [self showRecommendedNormalMusicBubble];
        } else if (bubbleType == ACCAIMusicBubble) {
            [self showRecommendedAIMusicBubble];
        }
    }];
    
    [[self viewModel].refreshMusicRelatedUISignal.deliverOnMainThread subscribeNext:^(NSNumber *x) {
        @strongify(self);
        if (x.boolValue) {
            [self updateMusicButton];
        }
    }];
    
    if ([self.viewModel shouldSelectMusicAutomatically]) {
        [self.viewModel.didAddMusicSignal subscribeNext:^(NSNumber * _Nullable x) {
            @strongify(self);
            [self updateMusicButton];
            if ([self p_shouldSaveDraftWhenSelectMusic]) {
                [ACCDraft() saveDraftWithPublishViewModel:self.repository
                                                    video:self.repository.repoVideoInfo.video
                                                   backup:!self.repository.repoDraft.originalDraft
                                           presaveHandler:^(id<ACCDraftModelProtocol> draftModel) {
                    
                } completion:^(BOOL success, NSError * _Nonnull error) {
                    
                }];
            }
        }];
    }
    
    if (!self.repository.repoDuet.isDuet) {
        if ([self p_shouldConfigSelectMusicUI]) {
            if ([self.viewModel shouldSelectMusicAutomatically] || ACCConfigBool(kConfigBool_edit_auto_use_effect_recommend_music)) {
                [RACObserve(self.viewModel, isRequestingMusicForQuickPicture) subscribeNext:^(NSNumber * x) {
                    @strongify(self);
                    //user has selected a music
                    if (x.boolValue) {
                        //开始的时候更新一下，结束的时候会自动设置进去，这里不需要再更新，简化update内的状态对应关系，防止跳变
                        //when request is done, select music will update music button
                        //incase of state jump
                        [self updateMusicButton];
                    }
                }];
            }
        }
    }
    
    [self.clipV1Service.finishClipCheckMusicSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.viewModel fetchHotMuiscListIfNeeded];
    }];
    
    [self.clipV1Service.didFinishClipEditSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.boolValue) {
            [self p_deselectMusic];
        }
    }];
    
    [self.clipV1Service.refreshMusicVolumeAfterAiClipSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.musicPanelView refreshMusicVolumeAfterAiClip:self.repository.repoMusic.musicVolume];
    }];
    
    [self.selectTemplateService.didRemoveMusicSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.musicPanelView.musicSelectView deselectMusic];
        [self.musicPanelView updateActionButtonState];
        [self refreshVideoEditMusicRelatedUI];
    }];
    
    if ([self p_shouldShowAdditionalActionButtonOnMusicButton] && !self.publishModel.repoCutSame.isClassicalMV) {
        [RACObserve(self.publishModel.repoMusic, music) subscribeNext:^(id<ACCMusicModelProtocol>  _Nullable music) {
            @strongify(self);
            if ([self isMusicStoryShare]) {
                
                [self.selectMusicButton hideCloseButton];
                CGFloat videoDuration = self.repository.repoVideoInfo.video.totalVideoDuration;
                BOOL isMusicLongerThanVideo = music.duration.doubleValue > videoDuration;
                if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) != ACCMusicLoopModeOff) {
                    isMusicLongerThanVideo = YES;
                }
                self.isMusicStoryCutEnable = (music != nil && isMusicLongerThanVideo);
                self.selectMusicButton.isDisableStyle = !self.isMusicStoryCutEnable;
                self.selectMusicButton.acc_enabled = self.isMusicStoryCutEnable;
                [self ACC_updateLayout];
                return;
            }
            
            // 智照模式下，可以在换音乐时有取消操作，所以此时直接返回即可
            if ([ACCSmartMovieABConfig isOn]) {
                if (acc_sharedSmartMovieManager().isCanceled) {
                    return;
                }
            }
            
            if (music && [self selectMusicbuttonEnable] && [self.viewModel canDeselectMusic]) {
                [self.selectMusicButton showCloseButton];
            } else {
                [self.selectMusicButton hideCloseButton];
            }
            [self ACC_updateLayout];
        }];
    }
}

- (void)p_initialForLVAudioFrame
{
    if (self.repository.repoUploadInfo.isAIVideoClipMode) {
        return;
    }
    
    BOOL fromMusicianUpload = self.repository.repoContext.videoSource == AWEVideoSourceAlbum && [self.repository.repoMusic.bgmAsset isKindOfClass:[AVURLAsset class]];
    if (fromMusicianUpload &&
        !self.repository.repoDraft.isDraft &&
        !self.repository.repoDraft.isBackUp &&
        !self.repository.repoContext.isMVVideo &&
        self.repository.repoContext.videoType != AWEVideoTypePhotoToVideo) {
        //  进编辑页之前，bgm音频已经被加入到videoAsset中，在这里同步acc_bgmAsset以解决音乐无法取消的问题
        //  https://jira.bytedance.com/browse/AME-92905
        [self.editService.audioEffect setBgmAsset:self.repository.repoMusic.bgmAsset];
        [self.viewModel replaceAudio:((AVURLAsset *)self.repository.repoMusic.bgmAsset).URL completeBlock:nil];
        [self.editService.audioEffect refreshAudioPlayer];
        return;
    }
    
    if (self.repository.repoDuet.isDuet) {
        //新框架：新合拍也支持类似抢镜一样的调节音量，所以这里要进行参数赋值才行
        //参考：https://bytedance.feishu.cn/docs/doccnnwWxXMdBT6Q6pSG1AO0PTl?sidebarOpen=1
        // 新框架：抢镜模式下，当前audioAssets.firstObject就是被react的视频asset，当做背景asset赋值，这样进入编辑页面可以调节音量
        AVURLAsset *asset = [self p_reactedBGMAsset];
        self.repository.repoMusic.bgmAsset = asset;
        self.editService.audioEffect.bgmAsset = asset;
    } else {
        // 针对拍摄时添加bgm的情况，对比路径，找出video中的具体实例
        __block AVAsset *currBgmAsset = self.repository.repoMusic.bgmAsset;
        [self.repository.repoVideoInfo.video.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[AVURLAsset class]] && [currBgmAsset isKindOfClass:[AVURLAsset class]]) {
                if ([((AVURLAsset *)currBgmAsset).URL.path isEqualToString:((AVURLAsset *)obj).URL.path]) {
                    currBgmAsset = obj;
                    *stop = YES;
                }
            }
        }];
        self.editService.audioEffect.bgmAsset = currBgmAsset;
    }
}

/// react模式下，被react视频的mp4asset，也就是被当做bgm的asset
- (AVURLAsset *)p_reactedBGMAsset {
    __block AVURLAsset *asset = nil;
    [self.repository.repoVideoInfo.video.audioAssets enumerateObjectsUsingBlock:^(AVAsset * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj isKindOfClass:[AVURLAsset class]]) {
            BOOL isReactedVideo = [((AVURLAsset *)obj).URL.path.lastPathComponent hasSuffix:@".mp4"];
            if (isReactedVideo) {
                asset = (AVURLAsset *)obj;
                *stop = YES;
            }
        }
    }];
    return asset;
}

- (void)updateChallenge
{
    [self.viewModel sendUpdateChallengeModelSignal];
    [[self challengeBindViewModel] updateCurrentBindChallenges:[self.viewModel currentBindChallenges] moduleKey:kChallengeBindMoudleKeyMusic];
}

- (void)triggleSelectMusic
{
    if (self.postponeMusicAssetDownloadingStatus == ACCVideoEditMusicAssetDownloadingStatusDownloading) {
        return;
    }
    
    if (self.postponeMusicAssetDownloadingStatus == ACCVideoEditMusicAssetDownloadingStatusFaild) {
        [self p_dowloadPostponeMusicAssetIfNeed];
        return;
    }
    
    // 音乐分享日常只支持裁剪
    if ([self isMusicStoryShare]) {
        [self.stickerService deselectAllSticker];
        if (!self.isMusicStoryCutEnable) {
            return;
        }
        [self.viewModel sendCutMusicButtonClickedSignal];
        return;
    }
    if ([self showMusicFeatureDisableToast]) {
        return;
    }
    [self.stickerService deselectAllSticker];
    [self selectMusicWithType:[self.viewModel selectMusic]];
}

- (void)checkNeedDeselectMusic
{
    if (!self.repository.repoMusic.music || self.repository.repoUploadInfo.videoClipMode == AWEVideoClipModeAI) {
        return;
    }
    
    if ([self showMusicFeatureDisableToast] && !self.repository.repoDuet.isDuet) {
        [self.viewModel deselectMusic:self.repository.repoMusic.music];
        [self refreshMusicRelatedButton];
        [self.viewModel sendRefreshVolumeViewSignal:self.musicPanelView.volumeView];
        
        if ([self.viewModel useMusicSelectPanel]) {
            [self.viewModel updateMusicList];
            [self.viewModel markShowIfNeeded];
        }
    }
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)barItem {
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarMusicContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* item = [[ACCBarItem alloc] init];
    item.title = config.title;
    item.imageName = config.imageName;
    item.location = config.location;
    item.itemId = ACCEditToolBarMusicContext;
    item.type = ACCBarItemFunctionTypeCover;

    @weakify(self);
    item.barItemActionBlock = ^(UIView * _Nonnull view) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        if ([view isKindOfClass:[AWEEditActionItemView class]]) {
            [self triggleSelectMusic];
        }
    };
    item.barItemViewConfigBlock = ^(UIView * _Nonnull view) {
        @strongify(self);
            AWEEditActionItemView *itemView = (AWEEditActionItemView*)view;
            itemView.enable = [self buttonEnable];
    };
    item.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:[AWEAnimatedMusicCoverButton class] type:AWEEditAndPublishViewDataTypeSelectMusic];
    return item;
}

- (BOOL)buttonEnable
{
    return ![self.viewModel AIMusicDisableWithType:NULL];
}

- (BOOL)showMusicFeatureDisableToast
{
    ACCVideoEditMusicDisableType type = ACCVideoEditMusicDisableTypeUnknow;
    BOOL disable = [self.viewModel AIMusicDisableWithType:&type];
    
    switch (type) {
        case ACCVideoEditMusicDisableTypeUnknow:
            break;
            
        case ACCVideoEditMusicDisableTypeAIClip:
            if (!ACCConfigBool(kConfigBool_enable_new_clips) && !self.repository.repoDraft.isDraft && !self.repository.repoDraft.isBackUp) {
                [ACCToast() show:ACCLocalizedString(@"stickpoint_back_to_select_music", @"返回上一步切换卡点音乐")];
            }
            break;
            
        case ACCVideoEditMusicDisableTypeLongVideo:
            [ACCToast() show:ACCLocalizedString(@"longer_video_disale_music", @"视频超过60s时，音乐暂不可用")];
            break;
    }
    
    return disable;
}

- (void)selectMusicWithType:(ACCVideoEditSelectMusicType)type
{
    if ([self isMusicStoryShare]) {
        return;
    }
    
    switch (type) {
        case ACCVideoEditSelectMusicTypeNone: {
            if (self.repository.repoContext.videoType == AWEVideoTypeAR) {
                [ACCToast() show: ACCLocalizedString(@"com_mig_adding_sound_is_not_supported_in_ar_camera", @"AR相机不支持更换音乐哦")];
            }
        }
            break;
        case ACCVideoEditSelectMusicTypePanel:
            [self selectMusicInPanel];
            break;
        case ACCVideoEditSelectMusicTypeLibrary:
            [self selectMusicInLibrary];
            break;
    }
}

- (void)selectMusicInPanel
{
    void (^commonAction)(void) = ^{
        [self.viewModel fetchFramesAndUPloadIfNeeded];
        [self.viewModel updateMusicList];
        [self.viewModel markShowIfNeeded];
        [self.viewModel clickShowMusicPanelTrack];
    };
    
    [self.viewModel fetchAIRecommendMuiscListIfNeeded]; // 打开面板采取获取AI配乐音乐
    
    if (self.musicPanelView != nil) {
        self.musicPanelView.hidden = NO;
        [self.viewModel sendRefreshVolumeViewSignal:self.musicPanelView.volumeView];
        [self showMusicPanel];
        commonAction();
        return;
    }
    //  选择使用新老音乐面板
    UIView<ACCMusicPanelViewProtocol> *panelView = nil;
    BOOL enableMusicPanelVertical = [[self viewModel].musicPanelViewModel enableMusicPanelVertical];
    if (enableMusicPanelVertical) {
        panelView = [[ACCMusicPanelView alloc] initWithFrame:self.containerViewController.view.frame musicSelectView:self.viewModel userCollectedMusicList:[self.viewModel.userCollectedMusicList mutableCopy]];
        panelView.accessibilityViewIsModal = YES;
    } else {
        panelView =[[AWEVideoPublishMusicPanelView alloc] initWithFrame:self.containerViewController.view.frame musicSelectView:self.viewModel userCollectedMusicList:[self.viewModel.userCollectedMusicList mutableCopy]];
        panelView.accessibilityViewIsModal = YES;
    }
  
    panelView.musicSelectView.canDeselectMusic = [self.viewModel canDeselectMusic];
    if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        panelView.musicSelectView.disableAddLyric = YES;
        panelView.musicSelectView.disableCutMusic = YES;
    }
    
    if (self.repository.repoPublishConfig.isFirstPost) {
        panelView.musicSelectView.disableAddLyric = YES;
    }
    
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCCommerceServiceProtocol) isEnterFromECommerceComment:self.repository]) {
        panelView.musicSelectView.disableAddLyric = YES;
    }
        
    self.musicPanelView = panelView;
    self.musicPanelView.volumeView.delegate = self;
    [self.musicPanelView setSelectViewUserCollectedMusicDelegate:self.viewModel];
    [self.viewModel sendRefreshVolumeViewSignal:self.musicPanelView.volumeView];
    [self.viewContainer.panelViewController registerObserver:self];
  
    @weakify(self);
    panelView.tapClickCloseHandler = ^{
       @strongify(self)
       [self dismissMusicPanel];
    };
    
    panelView.didSelectMusicHandler = ^(id<ACCMusicModelProtocol>  _Nullable selectedMusic, id<ACCMusicModelProtocol>  _Nullable canceledMusic, NSError * _Nonnull error, BOOL autoPlay) {
        @strongify(self);
        if (selectedMusic == nil && error == nil) {
            [self.viewModel deselectMusic:selectedMusic autoPlay:autoPlay completeBlock:^{
                @strongify(self);
                [self.viewModel sendRefreshVolumeViewSignal:self.musicPanelView.volumeView];
                [self.viewModel sendMusicChangedSignal];
            }];
        } else {
            [self.viewModel handleSelectMusic:selectedMusic error:error removeMusicSticker:YES completeBlock:^{
                @strongify(self); // 有部分音乐资源操作是异步完成的，需要在此类操作中进行面板UI刷新
                if ([self p_shouldSaveDraftWhenSelectMusic]) {
                    [ACCDraft() saveDraftWithPublishViewModel:self.repository
                                                        video:self.repository.repoVideoInfo.video
                                                       backup:!self.repository.repoDraft.originalDraft
                                               presaveHandler:^(id<ACCDraftModelProtocol> _Nonnull draft) {
                    }
                                                   completion:^(BOOL success, NSError *error) {
                    }];
                }
                [self.viewModel sendRefreshVolumeViewSignal:self.musicPanelView.volumeView];
                
                [self.viewModel sendMusicChangedSignal];
            }];
        }
        [self updateChallenge];
        [self refreshMusicRelatedButton];
        [self.viewModel sendRefreshVolumeViewSignal:self.musicPanelView.volumeView];
    };
    
    panelView.enterMusicLibraryHandler = ^{
        @strongify(self);
        [self selectMusicWithType:[self.viewModel selectMusicInLibrary]];
    };
    
    panelView.willAddLyricStickerHandler = ^(id<ACCMusicModelProtocol> music, NSString * coordinateRatio) {
        @strongify(self);
        [self.viewModel.toggleLyricsButtonSubject sendNext:[RACThreeTuple pack:@(YES) :coordinateRatio :music]];
    };
    
    panelView.willRemoveLyricStickerHandler = ^{
        @strongify(self);
        [self.viewModel.toggleLyricsButtonSubject sendNext:[RACThreeTuple pack:@(NO) :nil :nil]];
    };
    
    panelView.queryLyricStickerHandler = ^(UIButton *lyricStickerButton){
        @strongify(self);
        if ([self.lyricsStickerService hasAlreadyAddLyricSticker]) {
            lyricStickerButton.selected = YES;
            lyricStickerButton.isAccessibilityElement = YES;
            lyricStickerButton.accessibilityValue = @"已选定";
        } else {
            lyricStickerButton.selected = NO;
            lyricStickerButton.isAccessibilityElement = YES;
            lyricStickerButton.accessibilityValue = @"未选定";
        }
    };
    
    panelView.clipButtonClickHandler = ^{
        @strongify(self);
        [self dismissMusicPanel];
        [self.viewModel sendCutMusicButtonClickedSignal];
    };
    
    panelView.favoriteButtonClickHandler = ^(id<ACCMusicModelProtocol> music, BOOL collect) {
        @strongify(self);
        let userService = IESAutoInline(self.serviceProvider, ACCUserServiceProtocol);
        BOOL wasLogin = [userService isLogin];
        [userService requireLogin:^(BOOL success) {
            @strongify(self);
            if (success) {
                [self.viewModel collectMusic:music collect:collect];
                if (!wasLogin) {
                    [self.viewModel retryFetchFirstPage];
                }
            } else {
                [self.musicPanelView updateActionButtonState];
            }
        }];
    };
    
    panelView.musicSelectView.didSelectTabHandler = ^(NSInteger index) {
        @strongify(self);
        if (index == 0) {
            if ([self.repository.repoMusic.music.musicSelectedFrom isEqualToString:@"recommend_favourite"]) {
                [self.viewModel updateMusicList];
            }
        } else if (index == 1) {
            let userService = IESAutoInline(self.serviceProvider, ACCUserServiceProtocol);
            if (![userService isLogin]) {
                [userService requireLogin:^(BOOL success) {
                    [self.viewModel retryFetchFirstPage];
                }];
            }
        }
    };
    [self showMusicPanel];
    
    self.viewModel.musicPanelShowingProvider = ^BOOL{
        @strongify(self);
        return self.viewModel.musicPanelViewModel.isShowing;
    };
    
    commonAction();
}

- (void)selectMusicInLibrary
{
    @weakify(self);
    void (^commonAction)(void) = ^{
        @strongify(self);
        if ([self.viewModel useMusicSelectPanel]) {
            [self.viewModel updateMusicList];
            [self.viewModel retryFetchFirstPage];
            [self.viewModel markShowIfNeeded];
            [self.viewModel sendRefreshVolumeViewSignal:self.musicPanelView.volumeView];
        }
    };
    
    ACCSelectMusicInputData *inputData = [[ACCSelectMusicInputData alloc] init];
    inputData.publishModel = self.repository;
    inputData.challenge = self.repository.repoChallenge.challenge;
    inputData.audioRange = self.repository.repoMusic.audioRange;
    inputData.sceneType = ACCMusicEnterScenceTypeEditor;
    inputData.useSuggestClipRange = self.repository.repoMusic.useSuggestClipRange;
    inputData.enableMusicLoop = self.repository.repoMusic.enableMusicLoop;
    inputData.allowUsingVideoDurationAsMaxMusicDuration = self.repository.repoCutSame.isClassicalMV && AWEMVTemplateTypeMusicEffect == self.repository.repoMV.mvTemplateType;
    CGFloat allowedDuration = [self.repository.repoVideoInfo.video totalVideoDurationAddTimeMachine];
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    if (self.repository.repoMusic.music.shootDuration && [self.repository.repoMusic.music.shootDuration integerValue] >= [config videoMinSeconds] && ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) == ACCMusicLoopModeOff) {
        allowedDuration = MIN(allowedDuration, [self.repository.repoMusic.music.shootDuration floatValue]);
    }
    inputData.exsitingVideoDuration = allowedDuration;
    NSMutableDictionary *clipInfo = self.repository.repoTrack.referExtra.mutableCopy;
    clipInfo[@"music_edited_from"] = @"edit_change_music";
    inputData.clipTrackInfo = clipInfo.copy;
    inputData.enableClipBlock = ^BOOL(id<ACCMusicModelProtocol> _Nonnull music) {
        @strongify(self);
        BOOL isUsingMVMusic = self.repository.repoContext.isMVVideo && [music.musicID isEqualToString:self.repository.repoMV.templateMusicId];
        BOOL isMusicLongerThanVideo = music.shootDuration.doubleValue > [self.repository.repoVideoInfo.video totalVideoDuration] + 0.6;
        if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) != ACCMusicLoopModeOff && !self.repository.repoUploadInfo.isAIVideoClipMode) {
            isMusicLongerThanVideo = YES;
        }
        return !isUsingMVMusic && isMusicLongerThanVideo;
    };
    
    HTSAudioRange range = {0};
    __block HTSAudioRange clipedRange = range;
    inputData.didClipWithRange = ^(HTSAudioRange range, NSString *musicEditedFrom, BOOL enableMusicLoop, NSInteger repeatCount) {
        @strongify(self);
        clipedRange = range;
        self.repository.repoMusic.enableMusicLoop = enableMusicLoop;
        self.repository.repoMusic.musicEditedFrom = musicEditedFrom;
    };
    inputData.didSuggestClipRangeChange = ^(BOOL selected) {
        @strongify(self);
        self.repository.repoMusic.useSuggestClipRange = selected;
    };
    inputData.setForbidSimultaneousScrollViewPanGesture = ^(BOOL forbid) {
        @strongify(self);
        self.transDelegate.swipeInteractionController.forbidSimultaneousScrollViewPanGesture = forbid;
    };
    
    if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
        inputData.disableCutMusic = YES;
    }
    
    __block __weak UIViewController<ACCSelectMusicComponetCommonProtocol> *weakSelectMusicVC = nil;

    [self.editService.preview pause];
    let selectMusicObj = IESAutoInline(ACCBaseServiceProvider(), ACCSelectMusicProtocol);
    UIViewController<ACCSelectMusicComponetCommonProtocol> *assSelectMusicVC = [selectMusicObj selectMusicPageWithInputData:inputData pick:^(id<ACCMusicModelProtocol> _Nullable music, NSError * _Nullable error) {
        @strongify(self);
        [self.viewModel handleSelectMusic:music error:error removeMusicSticker:YES];
        if (clipedRange.length != 0) {
            [self.viewModel didSelectCutMusicSignal:clipedRange];
        }
        //埋点统计
        if (music.musicSelectedFrom) {
            music.awe_selectPageName = @"edit_page";
        }
        [self refreshMusicRelatedButton];
        [weakSelectMusicVC.presentingViewController acc_dismissModalStackAnimated:YES completion:nil];
        commonAction();
        [self.editService.preview continuePlay];
    } cancel:^(id<ACCMusicModelProtocol> _Nullable music) {
        @strongify(self);
        if (music) {
            [self.viewModel deselectMusic:music autoPlay:NO];

            NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
            referExtra[@"music_id"] = music.musicID;
            referExtra[@"enter_from"] = @"change_music_page";
            referExtra[@"enter_method"] = @"click_dustbin";
            [ACCTracker() trackEvent:@"unselect_music" params:referExtra needStagingFlag:NO];

            [self refreshMusicRelatedButton];
            [self.musicPanelView.musicSelectView selectMusic:nil error:nil autoPlay:NO];
            commonAction();
        }
    }];
    
    assSelectMusicVC.videoDuration = ceil([self.repository.repoVideoInfo.video totalVideoDurationAddTimeMachine] * 1000);
    weakSelectMusicVC = assSelectMusicVC;
    
    if ([assSelectMusicVC conformsToProtocol:@protocol(ACCSelectMusicStudioParamsProtocol)]) {
        NSArray<NSString *> * propBindMusicIDArray = self.repository.repoVideoInfo.fragmentInfo.count ? self.repository.repoVideoInfo.fragmentInfo[0].propBindMusicIdArray : nil;
        if (!propBindMusicIDArray.count) {
            propBindMusicIDArray = self.repository.repoProp.propBindMusicIDArray;
        }
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).propBindMusicIdArray = propBindMusicIDArray;
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).propId = self.repository.repoVideoInfo.fragmentInfo.count ? self.repository.repoVideoInfo.fragmentInfo[0].stickerId : nil;
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).previousPage = @"video_edit_page";
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).shouldHideCellMoreButton = YES;
    
        
        if (self.repository.repoContext.videoType == AWEVideoTypePhotoToVideo) {
            ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).needDisableDeselectMusic = ACCConfigBool(kConfigBool_enable_lightning_pic_to_video_optimize) ? NO : YES;
            ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).uploadRecommendMusic = self.repository.repoMV.mvMusic;
        }
        // mv影集音乐
        if (self.repository.repoContext.isMVVideo && self.repository.repoMV.mvMusic.playURL.URLList.count > 0) {
            ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).mvMusic = self.repository.repoMV.mvMusic;
        } else { // mv, status音乐和普通视频音乐分开
            ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).selectedMusic = self.repository.repoMusic.music;
        }
        
        if (self.repository.repoImageAlbumInfo.isImageAlbumEdit) {
            ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).shouldHideSelectedMusicViewClipActionBtn = YES;
            if (!ACCConfigBool(kConfigBool_image_mode_support_delete_music)) {
                ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).shouldHideCancelButton = YES;
                ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).shouldHideSelectedMusicViewDeleteActionBtn = YES;
            }
        }
        
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).shouldAccommodateVideoDurationToMusicDuration = [self.repository.repoVideoInfo shouldAccommodateVideoDurationToMusicDuration];
        ((id<ACCSelectMusicStudioParamsProtocol>)assSelectMusicVC).maximumMusicDurationToAccommodate = [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) singlePhotoOptimizationABTesting].maximumVideoDuration;
    }
    
    ACCCornerBarNaviController *navigationController = [[ACCCornerBarNaviController alloc] initWithRootViewController:assSelectMusicVC];
    navigationController.navigationBar.translucent = NO;
    navigationController.modalPresentationCapturesStatusBarAppearance = YES;
    navigationController.modalPresentationStyle = UIModalPresentationCustom;
    navigationController.transitioningDelegate = self.transDelegate;
    [self.transDelegate.swipeInteractionController wireToViewController:navigationController.topViewController];
    [self.containerViewController presentViewController:navigationController animated:YES completion:nil];
    [self.transitionService setPreviousPage:NSStringFromClass([assSelectMusicVC class])];
}

- (void)resetLyricStickerButton
{
    [self.musicPanelView.musicSelectView resetLyricStickerButtonStatus];
}

- (void)enableLyricStickerButton
{
    [self.musicPanelView.musicSelectView enableLyricStickerButton];
}

- (void)unenableLyricStickerButton
{
    [self.musicPanelView.musicSelectView unenableLyricStickerButton];
}

- (UIView<ACCScrollStringButtonProtocol> *)selectMusicButton
{
    if (!_selectMusicButton) {
        _selectMusicButton = (UIView<ACCScrollStringButtonProtocol> *)[[AWEScrollStringButton alloc] init];
        [_selectMusicButton addTarget:self action:@selector(selectMusicButtonClicked:)];
        [_selectMusicButton.closeButton addTarget:self action:@selector(didClickCloseButtonOnMusicButton:) forControlEvents:UIControlEventTouchUpInside];
        _selectMusicButton.enableConstantSpeed = YES;
        _selectMusicButton.closeButton.isAccessibilityElement = YES;
        _selectMusicButton.closeButton.accessibilityLabel = @"取消选择";
        _selectMusicButton.closeButton.accessibilityTraits = UIAccessibilityTraitButton;
    }
     return _selectMusicButton;
}
- (void)p_handleOfflineMusicIfNeeded
{
    if (self.repository.repoContext.needShowMusicOfflineAlert) {
        self.repository.repoContext.needShowMusicOfflineAlert = NO;
        
        if ([self.repository.repoContext canChangeMusicInEditPage]) {
            [ACCAlert() showAlertWithTitle:@"换支音乐？"
                               description:@"草稿里用的音乐下线了，无法加载。换支音乐吧？"
                                     image:nil
                         actionButtonTitle:@"换支音乐"
                         cancelButtonTitle:@"等会再说"
                               actionBlock:^{
                                   [self triggleSelectMusic];
                               }
                               cancelBlock:nil];
        } else {
            [ACCAlert() showAlertWithTitle:@"音乐已被清除"
                               description:@"草稿里用的音乐下线了，无法加载。音乐已被清除。"
                                     image:nil
                         actionButtonTitle:@"我知道了"
                         cancelButtonTitle:nil
                               actionBlock:nil
                               cancelBlock:nil]; 
        }
        
        [ACCDraft() saveDraftWithPublishViewModel:self.repository
                                            video:self.repository.repoVideoInfo.video
                                           backup:!self.repository.repoDraft.originalDraft
                                   presaveHandler:^(id<ACCDraftModelProtocol> _Nonnull draft) {
            // retrieve saveDate
            if (self.repository.repoDraft.originalDraft.saveDate != nil) {
                draft.saveDate = self.repository.repoDraft.originalDraft.saveDate;
            }
        }
                                       completion:^(BOOL success, NSError *error) {
            if (success) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kACCAwemeDraftUpdateNotification
                                                                    object:nil
                                                                  userInfo:@{[ACCDraft() draftIDKey]:self.repository.repoDraft.originalModel.repoDraft.taskID?:@""}];
            }
        }];
    }
    
    if (self.repository.repoContext.triggerChangeOfflineMusic) {
        self.repository.repoContext.triggerChangeOfflineMusic = NO;
        
        [self triggleSelectMusic];
    }
}

#pragma mark - Select Music

- (void)loadSelectMusicButton
{
    if (self.publishModel.repoContext.videoType != AWEVideoTypeReplaceMusicVideo &&
        !self.publishModel.repoPublishConfig.isFirstPost &&
        ![ACCStudioGlobalConfig() supportEditWithPublish]) {
        
        if ([self.repository.repoQuickStory shouldBuildQuickStoryPanel] || self.repository.repoContext.videoType == AWEVideoTypeNewYearWish) {
            if ([self p_shouldConfigSelectMusicUI]) {
                [self configSelectMusicButtonIfNeeded];
                
            } else {
                [self configSelectMusicButtonIfNeeded];
            }
        }
    }
}

- (void)didClickCloseButtonOnMusicButton:(UIButton *)button;
{
    [ACCTapticEngineManager tap];
    NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.repository.repoTrack.referExtra];
    referExtra[@"music_id"] = self.repository.repoMusic.music.musicID;
    referExtra[@"enter_from"] = @"video_edit_page";
    referExtra[@"enter_method"] = @"click_outer_cross";
    [ACCTracker() trackEvent:@"unselect_music" params:referExtra needStagingFlag:NO];
    [self ACC_updateLayout];
    [self.musicPanelView.musicSelectView selectMusic:nil error:nil];
    [self.viewModel deselectMusic:self.repository.repoMusic.music];
    [self.viewModel sendMusicChangedSignal];
}

- (void)selectMusicButtonClicked:(id)sender
{
    if (!self.isMounted) {
        return;
    }
    [self triggleSelectMusic];
}

- (void)showRecommendedNormalMusicBubble
{
    
    if ([self isMusicStoryShare]) {
        return;
    }
    
    [self.tipsSerivce showFunctionBubbleWithContent:ACCLocalizedString(@"edit_page_prompt_music", @"Tap to add a sound")
                                            forView:self.selectMusicButton
                                      containerView:((UIViewController*)self.controller).view
                                          mediaView:self.editService.mediaContainerView
                                   anchorAdjustment:CGPointMake(0, -5)
                                        inDirection:ACCBubbleManagerDirectionDown
                                       functionType:AWEStudioEditFunctionTopSelectMusic];
}

- (void)showRecommendedAIMusicBubble
{
    if ([self isMusicStoryShare]) {
        return;
    }
    
    id<ACCMusicModelProtocol> music = [AWEAIMusicRecommendManager sharedInstance].recommedMusicList.firstObject;
    if (music) {
        [ACCWebImage() requestImageWithURLArray:music.thumbURL.URLList completion:^(UIImage *image, NSURL *url, NSError *error) {
            if (!image || error || !url) {
                return;
            }

            dispatch_async(dispatch_get_main_queue(), ^{
                [self showAIMusicRecommedBubble:image forView:self.selectMusicButton inDirection:AWEImageAndTitleBubbleDirectionDown music:music];
            });
        }];
    } else {
        [self.tipsSerivce showFunctionBubbleWithContent:ACCLocalizedString(@"edit_page_prompt_music", @"Tap to add a sound")
                                                forView:self.selectMusicButton
                                          containerView:((UIViewController*)self.controller).view
                                              mediaView:self.editService.mediaContainerView
                                       anchorAdjustment:CGPointMake(0, -5)
                                            inDirection:ACCBubbleManagerDirectionDown
                                           functionType:AWEStudioEditFunctionTopSelectMusic];
    }
}

- (void)showAIMusicRecommedBubble:(UIImage *)image forView:(UIView *)targetView inDirection:(AWEImageAndTitleBubbleDirection)direction music:(id<ACCMusicModelProtocol>)model
{
    if ([self isMusicStoryShare]) {
        return;
    }
    
    [self.tipsSerivce showImageBubble:image forView:targetView containerView:((UIViewController*)self.controller).view mediaView:self.editService.mediaContainerView inDirection:direction subtitle:model.musicName functionType:AWEStudioEditFunctionTopSelectMusic];
}

- (void)updateMusicButton
{
    [self updateSelectMusicTitle];
    [self startSelectMusicAnimation];
}

- (void)updateSelectMusicTitle {

    if (self.postponeMusicAssetDownloadingStatus == ACCVideoEditMusicAssetDownloadingStatusDownloading) {
        self.selectMusicButton.shouldAnimate = NO;
        [self.selectMusicButton configWithImage:[AWECameraContainerIconManager selectMusicButtonLoadingImage] title:@"音乐加载中" hasMusic:NO];
        self.selectMusicButton.enableImageRotation = YES;
        [self ACC_updateLayout];
        return;
    }
    
    if (self.postponeMusicAssetDownloadingStatus == ACCVideoEditMusicAssetDownloadingStatusFaild) {
        self.selectMusicButton.shouldAnimate = NO;
        [self.selectMusicButton configWithImage:[AWECameraContainerIconManager selectMusicButtonSelectedImage] title:@"点击重新加载" hasMusic:NO];
        self.selectMusicButton.enableImageRotation = NO;
        [self ACC_updateLayout];
        return;
    }

    if ([self p_shouldConfigSelectMusicUI] && ![ACCStudioGlobalConfig() supportEditWithPublish]) {

        id<ACCMusicModelProtocol> music = self.repository.repoMusic.music;

        BOOL hasMusic = music != nil;
        
        NSString *title = nil;
        
        if (!hasMusic) {
            title = ACCLocalizedString(@"choose_music", @"选择音乐");
        } else {
            if (!ACC_isEmptyString(music.musicName)) {
                title = music.musicName;
                NSString *matchedPGCTitle = [music awe_matchedPGCMusicInfoStringWithPrefix];
                if (!music.isPGC && !ACC_isEmptyString(matchedPGCTitle)) { // 非PGC音乐中，如果有符合使用的PGC音乐
                    title = [NSString stringWithFormat:@"%@（%@）", title, matchedPGCTitle];
                }
            } else {
                if (!ACC_isEmptyString(self.repository.repoMV.mvMusic.musicName)) {
                    title = self.repository.repoMV.mvMusic.musicName;
                } else {
                    title = ACCLocalizedString(@"music_selected", @"已选择音乐");
                }
            }
        }
        
        UIImage *image = nil;
        
        BOOL shouldAutoApplyWeakBind = [self.viewModel shouldAutoApplyWeakBind];
        BOOL shouldAutoSelect = [self.viewModel shouldSelectMusicAutomatically];
        BOOL isRequestingMusicForQuickPicture = self.viewModel.isRequestingMusicForQuickPicture.boolValue;
        if (!hasMusic && isRequestingMusicForQuickPicture && (shouldAutoApplyWeakBind || shouldAutoSelect)) {
            //当前没有音乐【没有从前置页面带过来】
            //No Music now
            //在请求AI配乐
            //is requesting AI musics
            //开启AB
            //AB is on
            //展示loading images
            //is showing loading image
            image = [AWECameraContainerIconManager selectMusicButtonLoadingImage];
            self.selectMusicButton.enableImageRotation = YES;
        } else {
            image = hasMusic ? [AWECameraContainerIconManager selectMusicButtonSelectedImage] : [AWECameraContainerIconManager selectMusicButtonNormalImage];
            self.selectMusicButton.enableImageRotation = NO;
        }
        
        self.selectMusicButton.shouldAnimate = hasMusic;
        CGFloat margin = [ACCToolBarAdapterUtils useToolBarFoldStyle] ? 98 : 84;
        CGFloat maxWidth = MIN(300, CGRectGetWidth([UIScreen mainScreen].bounds) - margin * 2);
        [self.selectMusicButton configWithImage:image title:title hasMusic:hasMusic maxButtonWidth:maxWidth];
    } else {
         AWEEditActionItemView *itemView = [self.viewContainer viewWithBarItemID:ACCEditToolBarMusicContext];
         AWEAnimatedMusicCoverButton *musicCoverButton =  (AWEAnimatedMusicCoverButton *)itemView.button;
         UIImage *image = [self musicCoverButtonIcon];
        [musicCoverButton setImage:image forState:UIControlStateNormal];
        
        if ([self.viewModel shouldSelectMusicAutomatically]) {
            if (!self.repository.repoMusic.music && self.viewModel.isRequestingMusicForQuickPicture.boolValue) {
                musicCoverButton.isLoading = YES;
                musicCoverButton.loadingIconCenterOffset = CGPointMake(10, 10);
            } else {
                musicCoverButton.isLoading = NO;
            }
        }
        itemView.enable = [self selectMusicbuttonEnable];
    }
    self.selectMusicButton.acc_enabled = [self selectMusicbuttonEnable];
    [self ACC_updateLayout];
}

- (void)startSelectMusicAnimation {

    if (self.postponeMusicAssetDownloadingStatus == ACCVideoEditMusicAssetDownloadingStatusDownloading ||
        self.postponeMusicAssetDownloadingStatus == ACCVideoEditMusicAssetDownloadingStatusFaild) {
        [self.selectMusicButton stopAnimation];
        return;
    }
    if ([self p_shouldConfigSelectMusicUI] && ![ACCStudioGlobalConfig() supportEditWithPublish]) {
        if (!self.publishModel.repoMusic.music) {
            [self.selectMusicButton stopAnimation];
        } else {
            [self.selectMusicButton startAnimation];
        }
    }
}

- (BOOL)selectMusicbuttonEnable
{
    if ([self.repository.repoUploadInfo isAIVideoClipMode] && ![self.repository.repoContext supportNewEditClip] && self.repository.repoContext.videoType != AWEVideoTypeOneClickFilming) {
        return NO;
    }
    
    NSTimeInterval duration = [self.repository.repoVideoInfo.video totalVideoDuration];
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    if ([config limitMusicAccordingLongVideo] && duration >= config.longVideoDurationLowerLimit) {
        return NO;
    }
    
    return YES;
}

- (void)configSelectMusicButtonIfNeeded
{
    if (!self.repository.repoDuet.isDuet && self.repository.repoContext.videoType != AWEVideoTypeKaraoke) {
        if ([self p_shouldConfigSelectMusicUI]) {
            if (self.selectMusicButton.superview == nil) {
                [self.viewContainer.containerView addSubview:self.selectMusicButton];
                [self.selectMusicButton showLabelShadow];
                [self ACC_updateLayout];
            }
        }
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
    CGFloat centerY = topInset + 44 / 2;
    self.selectMusicButton.bounds = CGRectMake(0, 0, self.selectMusicButton.buttonWidth, 40);
    self.selectMusicButton.acc_centerY = centerY;
    self.selectMusicButton.acc_centerX = self.viewContainer.containerView.acc_width / 2;
}

#pragma mark - 更换音乐

- (void)showMusicSelectPanelView
{
    [self selectMusicWithType:[self.viewModel selectMusicInPanel]];
}

- (void)showMusicPanel { // 新老面板功用状态
    [self.viewModel.musicPanelViewModel resetPanelShowStatus:YES];
    [self.viewContainer.panelViewController animatePanelView:self.musicPanelView withAnimator:[[ACCMusicPanelAnimator alloc] initWithAnimationType:ACCPanelAnimationShow]];
}

- (void)dismissMusicPanel { // 新老面板功用状态
    [self.viewModel.musicPanelViewModel resetPanelShowStatus:NO];
    [self.viewContainer.panelViewController animatePanelView:self.musicPanelView withAnimator:[[ACCMusicPanelAnimator alloc] initWithAnimationType:ACCPanelAnimationDismiss]];
}

#pragma mark - 音乐后置下载相关
- (BOOL)p_shouldDownloadPostponeMusicAsset
{
    if (!self.repository.repoMusic.music || self.repository.repoMusic.music.loaclAssetUrl != nil) {
        return NO; // 无音乐 或 已下载
    }
    
    if (self.repository.repoMusic.musicConfigAssembler.config != nil) {
        return YES;
    }
    
    // 业务判断
    if ([self isMusicStoryShare] &&
        ACCConfigBool(kConfigBool_music_story_enable_download_after_to_edit_page)) {
        return YES;
    }
    
    return NO;
}

- (void)p_dowloadPostponeMusicAssetIfNeed
{
    if (![self p_shouldDownloadPostponeMusicAsset]) {
        return;
    }
    
    if (self.postponeMusicAssetDownloadingStatus == ACCVideoEditMusicAssetDownloadingStatusDownloading) {
        return;
    }
    
    self.postponeMusicAssetDownloadingStatus =  ACCVideoEditMusicAssetDownloadingStatusDownloading;
    [self updateMusicButton];
    
    @weakify(self);
    NSString *downloadMusicId = self.repository.repoMusic.music.musicID;
    [ACCVideoMusic() fetchLocalURLForMusic:self.repository.repoMusic.music
                              withProgress:nil
                                completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {

        @strongify(self);
        self.postponeMusicAssetDownloadingStatus =  ACCVideoEditMusicAssetDownloadingStatusNone;
        if (![self.repository.repoMusic.music.musicID isEqualToString:downloadMusicId?:@""]) {
            return; // music changed
        }
        if (!error && !ACC_isEmptyString(localURL.path)) {
            self.postponeMusicAssetDownloadingStatus =  ACCVideoEditMusicAssetDownloadingStatusNone;
            self.repository.repoMusic.music.loaclAssetUrl = localURL;
            self.repository.repoMusic.music.originLocalAssetUrl = localURL;
            [self.viewModel replaceAudio:localURL completeBlock:nil];
        } else {
            self.postponeMusicAssetDownloadingStatus =  ACCVideoEditMusicAssetDownloadingStatusFaild;
            if (self) {
                [ACCToast() show:@"音乐加载失败"];
            }
        }
        [self updateMusicButton];
    }];
}

- (BOOL)p_shouldSaveDraftWhenSelectMusic
{
    return self.repository.repoContext.videoType != AWEVideoTypeNewYearWish;
}

- (BOOL)p_shouldConfigSelectMusicUI
{
    return ACCConfigInt(kConfigInt_editor_toolbar_optimize) == ACCStoryEditorOptimizeTypeA || self.repository.repoContext.videoType == AWEVideoTypeNewYearWish;
}

#pragma mark - 更新音乐相关的UI

- (void)refreshMusicRelatedButton
{
    if ([self p_shouldConfigSelectMusicUI] &&
        ![IESAutoInline(self.serviceProvider, ACCStudioGlobalConfig) supportEditWithPublish]) {
        [self.viewModel sendRefreshMusicRelatedUISignal];
    } else {
        AWEAnimatedMusicCoverButton *musicCoverButton =  (AWEAnimatedMusicCoverButton *)[self.viewContainer viewWithBarItemID:ACCEditToolBarMusicContext].button;
        UIImage *image = [self musicCoverButtonIcon];
        [musicCoverButton setImage:image forState:UIControlStateNormal];
    }
}

- (UIImage *)musicCoverButtonIcon
{
    if (self.repository.repoContext.videoType == AWEVideoTypeReplaceMusicVideo) {
        return self.repository.repoMusic.music != nil ? ACCResourceImage(@"icon_edit_view_add_music_complete_action") : ACCResourceImage(@"icon_edit_view_music_action");
    } else {
        return self.repository.repoMusic.music != nil ? ACCResourceImage(@"icon_edit_sounds_selected") : ACCResourceImage(@"ic_camera_music");
    }
}

- (void)refreshVideoEditMusicRelatedUI
{
    [self refreshMusicRelatedButton];

    UIButton *cutButton =  [self.viewContainer viewWithBarItemID:ACCEditToolBarMusicCutContext].button;
    UIButton *soundButton = [self.viewContainer viewWithBarItemID:ACCEditToolBarSoundContext].button;
    UIButton *musicButton = [self.viewContainer viewWithBarItemID: ACCEditToolBarMusicContext].button;
    
    if (self.repository.repoMusic.music &&
        !self.repository.repoMusic.music.isFromImportVideo
        && self.repository.repoContext.videoType != AWEVideoTypeAR) {
        AVAsset *asset = self.repository.repoMusic.bgmAsset;
        Float64 duration = CMTimeGetSeconds(asset.duration);
        cutButton.enabled = duration > [self.repository.repoVideoInfo.video totalVideoDuration] + 0.6;
    } else {
        cutButton.enabled = NO;
    }
    
    if (self.repository.repoDuet.isDuet) {
        cutButton.enabled = NO;
        soundButton.enabled = YES;
        musicButton.enabled = NO;
    } else if ([self.repository.repoUploadInfo isAIVideoClipMode]) {
        cutButton.enabled = YES;
        soundButton.enabled = YES;
        musicButton.enabled = YES;
    }
    
    // mv原声禁用剪裁音乐
    if (self.repository.repoContext.isMVVideo) {
        if ([self.repository.repoMusic.music.musicID isEqualToString:self.repository.repoMV.templateMusicId]) {
            cutButton.enabled = NO;
        }
    }
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    return nil;
}

+ (void)regenerateTheNecessaryResourcesForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
                                                completion:(ACCDraftRecoverCompletion)completion
{
    id<ACCMusicModelProtocol> music = publishModel.repoMusic.music;
    
    if (publishModel.repoDuet.isDuet) {
        AVURLAsset *bgmAsset = (AVURLAsset *)publishModel.repoMusic.bgmAsset;
        if ((bgmAsset == nil) || CMTimeGetSeconds(bgmAsset.duration) == 0) {//Android过来的草稿需要主动添加duet源视频作为背景音频
            NSURL *duetSourceURL = publishModel.repoDuet.duetLocalSourceURL;
            if (duetSourceURL) {
                AVAsset *sourceAsset = [AVURLAsset URLAssetWithURL:duetSourceURL  options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
                if ([sourceAsset isKindOfClass:[AVURLAsset class]] &&
                    CMTimeGetSeconds(sourceAsset.duration) > 0) {
                    publishModel.repoVideoInfo.video.audioAssets = @[sourceAsset];
                    publishModel.repoMusic.bgmAsset = sourceAsset;
                }
            }
        }
    }
    
    if (!music.loaclAssetUrl && !ACC_isEmptyString(music.musicID) && !publishModel.repoDuet.isDuet && publishModel.repoContext.videoType != AWEVideoTypeKaraoke) {
        id<ACCVideoMusicProtocol> musicService = ACCVideoMusic();
        [musicService fetchLocalURLForMusic:music
                               withProgress:nil
                                 completion:^(NSURL * _Nonnull localURL, NSError * _Nonnull error) {
            
            if (!error && localURL.path) {
                music.loaclAssetUrl = localURL;
                publishModel.repoMusic.music = music;
                
                AVURLAsset *bgmAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:music.loaclAssetUrl.path] options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
                if ([bgmAsset isKindOfClass:[AVURLAsset class]] &&
                    CMTimeGetSeconds(bgmAsset.duration) > 0) {
                    publishModel.repoVideoInfo.video.audioAssets = @[bgmAsset];
                    publishModel.repoMusic.bgmAsset = bgmAsset;
                }
            }
            ACCBLOCK_INVOKE(completion, error, NO);
        }];
    } else if (music.loaclAssetUrl && music.isLocalScannedMedia && [publishModel.repoCutSame isNewCutSameOrSmartFilming]) {
        AVURLAsset *bgmAsset = [AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:music.loaclAssetUrl.path] options:@{AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)}];
        if ([bgmAsset isKindOfClass:[AVURLAsset class]] &&
            CMTimeGetSeconds(bgmAsset.duration) > 0) {
            publishModel.repoVideoInfo.video.audioAssets = @[bgmAsset];
        }
        ACCBLOCK_INVOKE(completion, nil, NO);
    } else if (!music.loaclAssetUrl && music.isLocalScannedMedia) {
        AVAsset *localAudioAsset = publishModel.repoVideoInfo.video.audioAssets.firstObject;
        NSURL *localAudioURL = [(AVURLAsset *)localAudioAsset URL];
        music.loaclAssetUrl = localAudioURL;
        publishModel.repoMusic.bgmAsset = localAudioAsset;
        ACCBLOCK_INVOKE(completion, nil, NO);
    } else {
        ACCBLOCK_INVOKE(completion, nil, NO);
    }
}

#pragma mark - getter

- (UIViewController *)containerViewController
{
    return self.controller.root;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return (AWEVideoPublishViewModel *)IESAutoInline(self.serviceProvider, ACCPublishRepository);
}

- (ACCVideoEditMusicViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [[ACCVideoEditMusicViewModel alloc] init];
    }
    return _viewModel;
}

- (id <UIViewControllerTransitioningDelegate,ACCInteractiveTransitionProtocol>)transDelegate
{
    if (!_transDelegate) {
        _transDelegate = [IESAutoInline(self.serviceProvider, ACCTransitioningDelegateProtocol) modalTransitionDelegate];
    }
    return _transDelegate;
}

- (ACCVideoEditChallengeBindViewModel *)challengeBindViewModel
{
    ACCVideoEditChallengeBindViewModel *viewModel = [self getViewModel:[ACCVideoEditChallengeBindViewModel class]];
    NSAssert(viewModel, @"should not be nil");
    return viewModel;
}

-(id<ACCStickerServiceProtocol>)stickerService
{
    let service = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
    NSAssert(service, @"should not be nil");
    return service;
}

- (BOOL)p_shouldShowAdditionalActionButtonOnMusicButton
{
    if ([self isMusicStoryShare]) {
        return YES;
    }
    return [IESAutoInline(ACCBaseServiceProvider(), ACCFriendsServiceProtocol) shouldShowCloseButtonOnMusicButton];
}

- (BOOL)isMusicStoryShare
{
    return self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory;
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didShowPanelView:(id<ACCPanelViewProtocol>)panelView {
    if (panelView.identifier != ACCVideoEditMusicContext) {
        return;
    }
    @weakify(self)
    [self.KVOController observe:self.musicPanelView.volumeView
                        keyPath:NSStringFromSelector(@selector(voiceVolume))
                        options:NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer,HTSVideoSoundEffectPanelView *_Nonnull object,NSDictionary<NSString *, id> *_Nonnull change) {
        @strongify(self)
        [self.viewModel sendVoiceVolumeChangedSignal:object];
        if (object.voiceVolume < 0.01) {
            AWELogToolInfo(AWELogToolTagEdit, @"voice volume %.2f",object.voiceVolume);
        }
    }];
    
    [self.KVOController observe:self.musicPanelView.volumeView
                        keyPath:NSStringFromSelector(@selector(musicVolume))
                        options:NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer,HTSVideoSoundEffectPanelView *_Nonnull object,NSDictionary<NSString *, id> *_Nonnull change) {
        @strongify(self)
        [self.viewModel sendMusicVolumeChangedSignal:object];
        if (object.musicVolume < 0.01) {
            AWELogToolInfo(AWELogToolTagEdit, @"music volume %.2f",object.musicVolume);
        }
    }];
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didDismissPanelView:(id<ACCPanelViewProtocol>)panelView {
    if (panelView.identifier == ACCVideoEditMusicContext) {
        [self.musicPanelView updateSelectedPanel:0 aniamted:NO];

        [self.KVOController unobserve:self.musicPanelView.volumeView];
        [self.viewModel resetCollectedMusicListIfNeeded];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willDismissPanelView:(id<ACCPanelViewProtocol>)panelView {
    if (panelView.identifier == ACCVideoEditMusicContext) {
        if (!self.cutMusicService.isClipViewShowing) {
           [UIView animateWithDuration:0.2 animations:^{
               self.viewContainer.containerView.alpha = 1.0;
           }];
            [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) startAutoPlayWithKey:@"musicPanel"];
        }
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView {
    if (panelView.identifier == ACCVideoEditMusicContext) {
        [ACCImageAlbumMixedD(self.editService.imageAlbumMixed) stopAutoPlayWithKey:@"musicPanel"];
        [UIView animateWithDuration:0.2 animations:^{
            self.viewContainer.containerView.alpha = .0f;
        }];
    }
}

#pragma mark - ACCMusicCollectMessage

- (void)didToggleMusicCollectStateWithMusicId:(NSString *)musicId collect:(BOOL)collect sender:(id)sender
{
    [self.viewModel updateCollectStateWithMusicId:musicId collect:collect];
    if ([self.repository.repoMusic.music.musicID isEqualToString:musicId]) {
        [self.musicPanelView updateActionButtonState];
    }
    self.shouldRefetchFavorites = YES;
}

- (void)p_deselectMusic
{
    if (self.musicPanelView.musicSelectView) {
        [self.musicPanelView.musicSelectView deselectMusic];
    } else {
        [self.viewModel deselectMusic:nil];
    }
}

#pragma mark - HTSVideoSoundEffectPanelViewDelegate
- (void)htsVideoSoundEffectPanelView:(HTSVideoSoundEffectPanelView *)panelView sliderValueDidFinishChangeFromVoiceSlider:(BOOL)fromVoiceSlider
{
    BOOL isFromIM = self.repository.repoContext.isIMRecord;
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    params[@"enter_from"] = @"video_edit_page";
    if (fromVoiceSlider) {
        params[@"volume_bar"] = @"origin";
    } else {
        params[@"volume_bar"] = @"music";
    }
    params[@"shoot_way"] = self.repository.repoTrack.referString ?: @"";
    params[@"creation_id"] = self.repository.repoContext.createId ?: @"";
    params[@"content_source"] = self.publishModel.repoTrack.referExtra[@"content_source"] ?: @"";
    params[@"content_type"] = self.publishModel.repoTrack.referExtra[@"content_type"] ?: @"";
    if (!isFromIM) {
        params[@"is_multi_content"] = self.repository.repoTrack.mediaCountInfo[@"is_multi_content"] ?: @"";
    }
    NSString *eventName = isFromIM ? @"im_music_tab_edit_volume" : @"music_tab_edit_volume";
    [ACCTracker() trackEvent:eventName params:params needStagingFlag:NO];
}

@end
