//
//  ACCVideoEditTipsComponent.m
//  AWEStudio
//
//  Created by lxp on 2019/9/27.
//

#import "ACCVideoEditTipsComponent.h"
#import <CameraClient/ACCBubbleDefinition.h>
#import <CameraClient/AWEAIMusicRecommendManager.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>

#import "ACCBubbleProtocol.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCConfigKeyDefines.h"

#import "AWEImageAndTitleBubble.h"
#import "AWEEditStickerBubbleManager.h"
#import <CreationKitArch/AWEStudioExcludeSelfView.h>
#import "ACCEditMusicServiceProtocol.h"
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import <CreationKitComponents/ACCFilterDefines.h>
#import "ACCVideoEditTipsViewModel.h"
#import "ACCVideoEditTipsServiceImpl.h"
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <KVOController/NSObject+FBKVOController.h>

#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCCacheProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCWebImageProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import "ACCEditCutMusicServiceProtocol.h"
#import "ACCStickerServiceProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CameraClient/ACCEditSmartMovieProtocol.h>
#import "ACCEditVoiceChangerServiceProtocol.h"
#import "ACCStickerPanelServiceProtocol.h"
#import "ACCVideoEditTipsDiaryGuideFrequencyChecker.h"
#import "ACCRepoKaraokeModelProtocol.h"
#import <CreationKitArch/ACCRepoMusicModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreativeKit/ACCENVProtocol.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import "ACCImageAlbumEditServiceProtocol.h"
#import "ACCImageAlbumFlowServiceProtocol.h"
#import "ACCImageAlbumCropServiceProtocol.h"
#import "ACCVideoEditFlowControlService.h"
#import "AWEVideoPublishResponseModel.h"
#import "ACCGrootStickerServiceProtocol.h"
#import "ACCBarItem+Adapter.h"
#import "ACCStudioGlobalConfig.h"
#import "ACCToolBarAdapterUtils.h"
#import "ACCRepoImageAlbumInfoModel.h"
#import "AWERepoDuetModel.h"
#import <CameraClient/ACCFlowerRedPacketHelperProtocol.h>

@interface ACCVideoEditTipsComponent() <
ACCPanelViewDelegate,
ACCVideoEditTipsServiceSubscriber
>
@property (nonatomic, assign) BOOL allowShowFunctionBubble;      //是否允许弹功能提示toast
@property (nonatomic, assign) BOOL allowShowGrootBubble;

@property (nonatomic, assign) BOOL skipShowImageAlbumSwitchModeBubble;
@property (nonatomic, assign) BOOL skipShowImageAlbumSlideGuide;
@property (nonatomic, assign) BOOL skipShowSmartMovieBubble;

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;
@property (nonatomic, strong) ACCVideoEditTipsServiceImpl *tipsSerivce;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;
@property (nonatomic, weak) id<ACCEditCutMusicServiceProtocol> cutMusicService;
@property (nonatomic, weak) id<ACCEditVoiceChangerServiceProtocol> voiceChangerService;
@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;
@property (nonatomic, weak) id<ACCImageAlbumEditServiceProtocol> imageAlbumEditService;
@property (nonatomic, weak) id<ACCImageAlbumFlowServiceProtocol> imageAlbumFlowService;
@property (nonatomic, weak) id<ACCImageAlbumCropServiceProtocol> imageAlbumCropService;
@property (nonatomic, weak) id<ACCVideoEditFlowControlService> flowControlService;
@property (nonatomic, weak) id<ACCGrootStickerServiceProtocol> grootService;
@property (nonatomic, strong) id<ACCEditSmartMovieProtocol> smartMovieService;

@property (nonatomic, strong) UIView *stickerBubbleWindow;
@property (nonatomic, strong) ACCVideoEditTipsViewModel *viewModel;

@end

@implementation ACCVideoEditTipsComponent
@synthesize allowShowFunctionBubble;

IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)
IESOptionalInject(self.serviceProvider, cutMusicService, ACCEditCutMusicServiceProtocol)
IESOptionalInject(self.serviceProvider, voiceChangerService, ACCEditVoiceChangerServiceProtocol)
IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, flowControlService, ACCVideoEditFlowControlService)
IESOptionalInject(self.serviceProvider, grootService, ACCGrootStickerServiceProtocol)
IESAutoInject(self.serviceProvider, smartMovieService, ACCEditSmartMovieProtocol)
IESOptionalInject(self.serviceProvider, imageAlbumEditService, ACCImageAlbumEditServiceProtocol)
IESOptionalInject(self.serviceProvider, imageAlbumFlowService, ACCImageAlbumFlowServiceProtocol)
IESOptionalInject(self.serviceProvider, imageAlbumCropService, ACCImageAlbumCropServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCVideoEditTipsService),
                                   self.tipsSerivce);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider {
    self.tipsSerivce.repository = self.repository;
    [self.tipsSerivce addSubscriber:self];
}

#pragma mark - ACCFeatureComponent protocol

- (void)dealloc
{
    [@[AWEEditStickerBubbleManager.videoStickerBubbleManager,
       AWEEditStickerBubbleManager.interactiveStickerBubbleManager,
       AWEEditStickerBubbleManager.textStickerBubbleManager] enumerateObjectsUsingBlock:^(AWEEditStickerBubbleManager * _Nonnull bubble, NSUInteger idx, BOOL * _Nonnull stop) {
           [bubble destroy];
       }];
    
    ACCLog(@"%@ dealloc",NSStringFromSelector(_cmd));
}

- (void)componentDidMount
{
    [self.viewContainer.panelViewController registerObserver:self];
    
    [self loadShowedFunctionsValue];
    
    @weakify(self);
    [@[AWEEditStickerBubbleManager.videoStickerBubbleManager,
       AWEEditStickerBubbleManager.interactiveStickerBubbleManager,
       AWEEditStickerBubbleManager.textStickerBubbleManager] enumerateObjectsUsingBlock:^(AWEEditStickerBubbleManager * _Nonnull bubble, NSUInteger idx, BOOL * _Nonnull stop) {
        @weakify(bubble)
        bubble.defaultTargetView = ^UIView * _Nonnull{
            @strongify(self)
            @strongify(bubble)
            if (bubble.getParentViewActualFrameBlock) { // 适配刘海屏
                if (!self.stickerBubbleWindow) {
                    CGRect rect = bubble.getParentViewActualFrameBlock();
                    AWEStudioExcludeSelfView *bubbleWindow = [[AWEStudioExcludeSelfView alloc] initWithFrame:rect];
                    [self.viewContainer.containerView addSubview:bubbleWindow];
                    self.stickerBubbleWindow = bubbleWindow;
                }
                return self.stickerBubbleWindow;
            }
            return self.viewContainer.containerView;
        };
    }];
    [self.viewContainer.topRightBarItemContainer setMoreTouchUpEvent:^(BOOL isFold) {
        @strongify(self);
        [self.tipsSerivce dismissFunctionBubbles];
    }];
    [self p_bindViewModels];
}

- (void)componentDidUnmount
{
    [self.viewContainer.panelViewController unregisterObserver:self];
}

- (void)componentDidAppear
{
    if (self.publishModel.repoContext.videoType != AWEVideoTypeReplaceMusicVideo) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.allowShowGrootBubble = YES;
            BOOL allowShowQuickPublishBubble = [self allowShowQuickPublishBubble];
            [self checkAndShowRedPacketBubble];
            [self checkAndShowQuickPublishBubble];
            [self checkAndShowNewYearWishBubble];
            [self checkAndShowClipAtShareToStorySceneBubble:allowShowQuickPublishBubble];
            [self checkAndShowKaraokeStickerBubble];
            [self checkAndShowImageAlbumSlideGuide];
            [self checkAndShowImageAlbumSwitchModeBubble];
            [self checkAndShowTagsBubble];
            [self checkAndShowImageAlbumCropBubble];
            [self checkAndShowSmartMovieBubble];
            [self checkAndShowLiveStickerBubble];
            [self checkAndShowCanvasInteractionGuide];
            [self checkAndShowCustomStickerBubble];
            [self checkAndShowLyricStickerBubble];
            [self checkAndShowFunctionBubble];
            self.viewModel.isVCAppeared = YES;
        });
    }
}

- (void)componentDidDisappear
{
    [self.tipsSerivce dismissFunctionBubbles];
}

- (void)p_bindViewModels
{
    @weakify(self);
    [self.musicService.willSelectMusicSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.tipsSerivce dismissFunctionBubbles];
    }];
    
    [[self stickerPanelService].willShowStickerPanelSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.tipsSerivce saveShowedFunctionsByType:AWEStudioEditFunctionSticker];
        [self.tipsSerivce dismissFunctionBubbles];
    }];
    
    [self.cutMusicService.didClickCutMusicButtonSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self.tipsSerivce dismissFunctionBubbles];
    }];
    
    [[[[self stickerService] willStartEditingStickerSignal] deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self)
        [self.tipsSerivce dismissFunctionBubbles];
    }];
    
    [[[self stickerService].stickerDeselectedSignal deliverOnMainThread] subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        self.allowShowGrootBubble = NO;
        [self.tipsSerivce saveShowedFunctionsByType:AWEStudioEditFunctionText];
        [self.tipsSerivce dismissFunctionBubbles];
    }];
    
    [[[[self grootService] showGrootStickerTipsSignal] deliverOnMainThread]  subscribeNext:^(id   _Nullable x) {
        @strongify(self);
        [self checkAndShowGrootStickerBubble];
    }];
}

#pragma mark - ACCPanelViewDelegate

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController willShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCVideoEditMusicContext) {
        [self.tipsSerivce saveShowedFunctionsByType:AWEStudioEditFunctionMusic];
    }
}

- (void)panelViewController:(id<ACCPanelViewController>)panelViewController didShowPanelView:(id<ACCPanelViewProtocol>)panelView
{
    if (panelView.identifier == ACCFilterContext) {
        [self.tipsSerivce dismissFunctionBubbles];
    }
}

#pragma mark - 功能提示弹窗

- (void)loadShowedFunctionsValue
{
    self.tipsSerivce.showedValue = [[ACCCache() objectForKey:kAWEStudioEditFunctionToastShowedValuesKey] integerValue];
    if ([IESAutoInline(ACCBaseServiceProvider(), ACCENVProtocol) isFirstLaunchAfterUpdating]) {
        self.tipsSerivce.showedValue = self.tipsSerivce.showedValue | 30;
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            [ACCCache() setObject:@(self.tipsSerivce.showedValue) forKey:kAWEStudioEditFunctionToastShowedValuesKey];
        });
    }
}

- (BOOL)allowShowQuickPublishBubble
{
    return ACCConfigInt(kConfigInt_editor_toolbar_optimize) != ACCStoryEditorOptimizeTypeNone
    && ACCConfigInt(kConfigInt_edit_diary_strong_guide_style) == ACCEditDiaryStrongGuideStyleTip
    && [ACCVideoEditTipsDiaryGuideFrequencyChecker shouldShowGuideWithKey:kAWENormalVideoEditQuickPublishGuideTipShowDateKey frequency:ACCConfigInt(kConfigInt_edit_diary_strong_guide_frequency)]
    && self.publishModel.repoContext.videoType != AWEVideoTypeNewYearWish;
}

- (void)checkAndShowQuickPublishBubble
{
    // 无视且禁用 allowShowFunctionBubble
    if ([self allowShowQuickPublishBubble]) {
        self.allowShowFunctionBubble = NO;
        self.allowShowGrootBubble = NO;
        [self.tipsSerivce sendShowQuickPublishBubbleSignal];
        if (!self.publishModel.repoDraft.isBackUp && !self.publishModel.repoDraft.isDraft) {
            self.skipShowImageAlbumSwitchModeBubble = YES;
            self.skipShowImageAlbumSlideGuide = YES;
            self.skipShowSmartMovieBubble = YES;
        }
    }
}

- (void)checkAndShowImageAlbumSlideGuide
{
    if (!self.skipShowImageAlbumSlideGuide) {
        [self.tipsSerivce sendShowImageAlbumSlideGuideSignal];
        if (self.imageAlbumEditService.isImageScrollGuideAllowed) {
            self.skipShowImageAlbumSwitchModeBubble = YES;
            self.skipShowSmartMovieBubble = YES;
            self.allowShowFunctionBubble = NO;
        }
    }
}

- (void)checkAndShowImageAlbumSwitchModeBubble
{
    if (!self.skipShowImageAlbumSwitchModeBubble) {
        [self.tipsSerivce sendShowImageAlbumSwitchModeBubbleSignal];
        if (self.imageAlbumFlowService.isSwitchModeBubbleAllowed) {
            self.skipShowSmartMovieBubble = YES;
            self.allowShowFunctionBubble = NO;
        }
    }
}

NSString *const kAWEEditFlowerRedPacketBubbleShowKey = @"kAWEEditFlowerRedPacketBubbleShowKey";
- (BOOL)allowRedPacketBubble
{
    if ([self publishModel].repoImageAlbumInfo.isImageAlbumEdit) {
        return NO;
    }

    BOOL didNotShowen = ![ACCCache() boolForKey:kAWEEditFlowerRedPacketBubbleShowKey];
    return didNotShowen && [ACCFlowerRedPacketHelper() isFlowerRedPacketActivityOn];
}

- (void)checkAndShowRedPacketBubble
{
    if ([self allowRedPacketBubble] && self.allowShowFunctionBubble) {
        self.allowShowFunctionBubble = NO;
        [ACCCache() setBool:YES forKey:kAWEEditFlowerRedPacketBubbleShowKey];
        let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarRedpacketContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
        @weakify(self);
        [self showBubbleWithItemId:ACCEditToolBarRedpacketContext showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:@"试试视频红包" forView:[self bubbleAnchorViewWithDirection:direction actionItemId:ACCEditToolBarRedpacketContext] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointZero inDirection:direction functionType:AWEStudioEditFunctionFlowerRedPacket];
        }];
    }
}

NSString *const kAWEEditTagsBubbleShowKey = @"kAWEEditTagsBubbleShowKey";

- (BOOL)allowShowTagsBubble
{
    if (![self publishModel].repoImageAlbumInfo.isImageAlbumEdit) {
        return NO;
    }

    BOOL showBubbleCount = ![ACCCache() boolForKey:kAWEEditTagsBubbleShowKey];
    return showBubbleCount && ACCConfigBool(kConfigBool_enable_editor_tags);
}

- (void)checkAndShowTagsBubble
{
    if ([self allowShowTagsBubble] && self.allowShowFunctionBubble) {
        self.allowShowFunctionBubble = NO;
        [ACCCache() setBool:YES forKey:kAWEEditTagsBubbleShowKey];
        let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarTagsContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
        @weakify(self);
        [self showBubbleWithItemId:ACCEditToolBarTagsContext showBlock:^{
            @strongify(self);
            NSMutableDictionary *params = [self.repository.repoTrack.referExtra mutableCopy];
            [params addEntriesFromDictionary:[self.repository.repoTrack mediaCountInfo]?:@{}];
            [ACCTracker() trackEvent:@"tag_popup_show" params:params];
            [self.tipsSerivce showFunctionBubbleWithContent:@"可以给图片加标记了" forView:[self bubbleAnchorViewWithDirection:direction actionItemId:ACCEditToolBarTagsContext] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointZero inDirection:direction functionType:AWEStudioEditFunctionTags];
        }];
    }
}

NSString *const kAWEEditImageAlbumCropBubbleHasShownKey = @"kAWEEditImageAlbumCropBubbleHasShownKey";

- (BOOL)allowShowImageAlbumCropBubble
{
    if (![self publishModel].repoImageAlbumInfo.isImageAlbumEdit) {
        return NO;
    }
    
    if (!ACCConfigBool(kConfigBool_show_image_multi_crop_bubble) || !ACCConfigBool(kConfigBool_enable_image_multi_crop)) {
        return NO;
    }

    if ([ACCCache() boolForKey:kAWEEditImageAlbumCropBubbleHasShownKey]) {
        return NO;
    }
    
    // TODO:点击过也不展示
    
    return YES;
}

- (void)checkAndShowImageAlbumCropBubble
{
    if (![self allowShowImageAlbumCropBubble]) {
        return;
    }
    
    if (!self.allowShowFunctionBubble) {
        return;
    }
    
    self.allowShowFunctionBubble = NO;
    [ACCCache() setBool:YES forKey:kAWEEditImageAlbumCropBubbleHasShownKey];
    // 展示逻辑
    let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarCropImageContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
    @weakify(self);
    [self showBubbleWithItemId:ACCEditToolBarCropImageContext showBlock:^{
        @strongify(self);
        [self.tipsSerivce showFunctionBubbleWithContent:[NSString stringWithFormat:@"%@图片，获得更好展示效果", self.imageAlbumCropService.cropTitle]
                                                forView:[self bubbleAnchorViewWithDirection:direction actionItemId:ACCEditToolBarCropImageContext]
                                          containerView:self.rootVC.view
                                              mediaView:self.editService.mediaContainerView
                                       anchorAdjustment:CGPointZero
                                            inDirection:direction
                                           functionType:AWEStudioEditFunctionImageAlbumCrop];
    }];
}

- (void)checkAndShowSmartMovieBubble
{
    if (!self.skipShowSmartMovieBubble) {
        [self.tipsSerivce sendShowSmartMovieBubbleSignal];
        if (self.smartMovieService.isSmartMovieBubbleAllowed) {
            self.allowShowFunctionBubble = NO;
        }
    }
}

- (BOOL)allowShowNewYearWishBubble
{
    BOOL isWish = self.publishModel.repoContext.videoType == AWEVideoTypeNewYearWish;
    NSInteger bubbleTag = [ACCCache() boolForKey:kAWENormalVideoEditNewYearWishBubbleShowKey];
    if (isWish && !bubbleTag) return YES;
    return NO;
}

- (BOOL)allowShowKaraokeStickerBubble
{
    BOOL isKaraoke = self.publishModel.repoContext.videoType == AWEVideoTypeKaraoke;
    BOOL isDuetSing = self.publishModel.repoDuet.isDuetSing;
    /**
     * kAWENormalVideoEditKaraokeStickerBubbleShowKey 存储的是本次应该展示的气泡类型，0 = 调音气泡，1 = 音频模式换背景气泡
     */
    NSInteger bubbleTag = [ACCCache() integerForKey:kAWENormalVideoEditKaraokeStickerBubbleShowKey];
    if (bubbleTag == 0 && (isKaraoke || isDuetSing)) {
        // K歌或合唱，展示调音气泡
        return YES;
    }
    id<ACCRepoKaraokeModelProtocol> repoModel = [self.tipsSerivce.repository extensionModelOfProtocol:@protocol(ACCRepoKaraokeModelProtocol)];
    if (bubbleTag == 1 && isKaraoke && repoModel.recordMode == ACCKaraokeRecordModeAudio) {
        // K歌展示换背景气泡
        return YES;
    }
    return NO;
}

- (void)checkAndShowKaraokeStickerBubble
{
    if ([self allowShowKaraokeStickerBubble] && self.allowShowFunctionBubble) {
        self.allowShowFunctionBubble = NO;
        NSInteger bubbleTag = [ACCCache() integerForKey:kAWENormalVideoEditKaraokeStickerBubbleShowKey];
        [ACCCache() setInteger:bubbleTag + 1 forKey:kAWENormalVideoEditKaraokeStickerBubbleShowKey];
        let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarInfoStickerContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
        void* itemId = bubbleTag == 0 ? ACCEditToolBarKaraokeConfigContext : ACCEditToolBarKaraokeBGConfigContext;
        @weakify(self);
        [self showBubbleWithItemId:itemId showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:bubbleTag == 0 ? @"可以调整唱歌的效果" : @"可更换背景哦"  forView:[self bubbleAnchorViewWithDirection:direction actionItemId:bubbleTag == 0 ? ACCEditToolBarKaraokeConfigContext : ACCEditToolBarKaraokeBGConfigContext] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointZero inDirection:direction functionType:bubbleTag == 0 ? AWEStudioEditFunctionKaraokeVolume : AWEStudioEditFunctionKaraokeAudioBG];
        }];
    }
}

- (void)checkAndShowNewYearWishBubble
{
    if ([self allowShowNewYearWishBubble]) {
        self.allowShowFunctionBubble = NO;
        [ACCCache() setBool:YES forKey:kAWENormalVideoEditNewYearWishBubbleShowKey];
        let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarInfoStickerContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
        void* itemId = ACCEditToolBarNewYearTextContext;
        @weakify(self);
        [self showBubbleWithItemId:itemId showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:@"这里可以查看心愿灵感"  forView:[self bubbleAnchorViewWithDirection:direction actionItemId:ACCEditToolBarNewYearTextContext] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointZero inDirection:direction functionType:AWEStudioEditFunctionWishText];
        }];
    }
}

- (BOOL)allowShowLiveStickerBubble
{
    if ([self publishModel].repoImageAlbumInfo.isImageAlbumEdit) {
        return NO;
    }
    BOOL showBubbleCount = ![ACCCache() boolForKey:kAWENormalVideoEditLiveStickerBubbleShowKey];
    return showBubbleCount && self.flowControlService.uploadParamsCache.settingsParameters.hasLive.boolValue && [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin] && ![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isChildMode] && [ACCStudioGlobalConfig() shouldKeepLiveMode];
}

- (void)checkAndShowLiveStickerBubble
{
    if ([self allowShowLiveStickerBubble] && self.allowShowFunctionBubble) {
        self.allowShowFunctionBubble = NO;
        [ACCCache() setBool:YES forKey:kAWENormalVideoEditLiveStickerBubbleShowKey];
        let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarInfoStickerContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
        @weakify(self);
        [self showBubbleWithItemId:ACCEditToolBarInfoStickerContext showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:@"添加预告并准时开播，会有更多观众看你的直播" forView:[self bubbleAnchorViewWithDirection:direction actionItemId:ACCEditToolBarInfoStickerContext] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointZero inDirection:direction functionType:AWEStudioEditFunctionLiveSticker];
            [self liveStickerToastShowTrack];
        }];
    }
}

-  (void)checkAndShowGrootStickerBubble
{
    BOOL showBubbleCount = ![ACCCache() boolForKey:kAWENormalVideoEditGrootStickerBubbleShowKey];
    BOOL allowedShow = showBubbleCount && [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isLogin] && ![IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) isChildMode];
    if (allowedShow && self.allowShowGrootBubble && ACCConfigBool(kConfigBool_sticker_support_groot)) {
        self.allowShowFunctionBubble = NO;
        self.allowShowGrootBubble = NO;
        [ACCCache() setBool:YES forKey:kAWENormalVideoEditGrootStickerBubbleShowKey];
        let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarInfoStickerContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
        @weakify(self);
        [self showBubbleWithItemId:ACCEditToolBarInfoStickerContext showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:@"添加动植物贴纸" forView:[self bubbleAnchorViewWithDirection:direction actionItemId:ACCEditToolBarInfoStickerContext] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointZero inDirection:direction functionType:AWEStudioEditFunctionGrootSticker];
            [self grootPropToastShowTrack];
        }];
    }
}

- (void)checkAndShowCanvasInteractionGuide
{
    [self.tipsSerivce sendShowCanvasInteractionGuideSignal];
}

- (BOOL)allowShowCustomStickerBubble
{
    NSInteger showBubbleCount = [ACCCache() integerForKey:kAWENormalVideoEditCustomBubbleShowKey];
    let userService = IESAutoInline(self.serviceProvider, ACCUserServiceProtocol);
    return (showBubbleCount == 0) && ACCConfigBool(kConfigBool_info_sticker_support_uploading_pictures) && ![userService isChildMode];
}

- (void)checkAndShowCustomStickerBubble
{
    if ([self allowShowCustomStickerBubble] && self.allowShowFunctionBubble) {
        self.allowShowFunctionBubble = NO;
        NSInteger showBubbleCount = [ACCCache() integerForKey:kAWENormalVideoEditCustomBubbleShowKey];
        [ACCCache() setInteger:showBubbleCount + 1 forKey:kAWENormalVideoEditCustomBubbleShowKey];
        let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarInfoStickerContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
        @weakify(self);
        [self showBubbleWithItemId:ACCEditToolBarInfoStickerContext showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:ACCLocalizedString(@"creation_edit_sticker_upload_bubble", @"Try custom photo stickers") forView:[self bubbleAnchorViewWithDirection:direction actionItemId:ACCEditToolBarInfoStickerContext] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointZero inDirection:direction functionType:AWEStudioEditFunctionCustomSticker];
        }];
    }
}

- (void)checkAndShowLyricStickerBubble
{
    if ([self.viewModel allowShowLyricStickerBubble] && self.allowShowFunctionBubble && self.publishModel.repoContext.videoType != AWEVideoTypeKaraoke && [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarInfoStickerContext]) {
        self.allowShowFunctionBubble = NO;
        self.viewModel.isNormalVideoCanShowMusicStickerBubble = NO;
        BOOL hasMusicLyric = self.publishModel.repoMusic.music && self.publishModel.repoMusic.music.lyricUrl;
        NSString *cacheKey = hasMusicLyric ? kAWENormalVideoEditHasMusicLyricBubbleShowKey : kAWENormalVideoEditNoMusicLyricBubbleShowKey;

        NSInteger showBubbleCount = [ACCCache() integerForKey:cacheKey];
        [ACCCache() setInteger:showBubbleCount + 1 forKey:cacheKey];
        
        let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarInfoStickerContext].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
        @weakify(self);
        [self showBubbleWithItemId:ACCEditToolBarInfoStickerContext showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:ACCLocalizedString(@"creation_edit_sticker_lyrics_icon_guide", @"试试添加歌词吧") forView:[self bubbleAnchorViewWithDirection:direction actionItemId:ACCEditToolBarInfoStickerContext] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointZero inDirection:direction functionType:AWEStudioEditFunctionLyrics];
        }];
    }
}

- (void)checkAndShowFunctionBubble
{
    if (!self.allowShowFunctionBubble) {
        self.allowShowGrootBubble = NO;
        return;
    }
    
    self.allowShowFunctionBubble = NO;
    NSArray *functionArray = [self showBubbleFunctionArray];
    for (int i = 0; i < functionArray.count; i++) {
        AWEStudioEditFunctionType type = [[functionArray objectAtIndex:i] integerValue];
        if (![self shouldShowFuncionBubble:type]) {
            continue;
        }
        NSTimeInterval duration = [self.publishModel.repoVideoInfo.video totalVideoDuration];
        let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
        BOOL forbidMusicBubble = [config limitMusicAccordingLongVideo] && duration >= config.longVideoDurationLowerLimit;
        if (AWEStudioEditFunctionMusic == type && forbidMusicBubble) {
            continue;
        }
        
        if (AWEStudioEditFunctionMusic == type && self.publishModel.repoMusic.music) {
            continue;
        }

        if (AWEStudioEditFunctionChangeVoice == type && (![self.voiceChangerService shouldShowEntrance] || ACCConfigInt(kConfigInt_editor_toolbar_optimize) != ACCStoryEditorOptimizeTypeNone)) {
            continue;
        }
        
        if ([self showFunctionBubble:type]) {
            self.allowShowGrootBubble = NO;
            break;
        }
    }
}

#pragma mark 检查是否需要显示分享到日常场景剪裁 bubble
- (void)checkAndShowClipAtShareToStorySceneBubble:(BOOL)allowShowQuickPublishBubble
{
    if (!allowShowQuickPublishBubble &&
        [self.viewModel allowShowClipAtShareToStorySceneBubble] &&
        [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarClipContext]) {
        self.allowShowFunctionBubble = NO;
        NSString *key = [NSString stringWithFormat:@"%@%@", kAWENormalVideoEditClipAtShareToStorySceneBubbleShowKey, [IESAutoInline(ACCBaseServiceProvider(), ACCUserServiceProtocol) currentLoginUserModel].userID];
        NSInteger showBubbleCount = [ACCCache() integerForKey:key];
        [ACCCache() setInteger:showBubbleCount + 1 forKey:key];
        
        void *itemId = ACCEditToolBarClipContext;
        let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:itemId].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;
        NSInteger defaultDuration = ACCConfigInt(kConfigInt_enable_share_to_story_clip_default_duration_in_edit_page);
        NSString *content = [NSString stringWithFormat:@"已自动截选前 %ld秒 内容", (long)defaultDuration];
        @weakify(self);
        [self showBubbleWithItemId:itemId showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:content forView:[self bubbleAnchorViewWithDirection:direction actionItemId:itemId] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointZero inDirection:direction functionType:AWEStudioEditFunctionClipAtShareToStoryScene];
        }];
    }
}

- (BOOL)isTopRightBarBubble:(AWEStudioEditFunctionType)type
{
    switch (type) {
        case AWEStudioEditFunctionMusic:
        case AWEStudioEditFunctionEffect:
        case AWEStudioEditFunctionSticker:
        case AWEStudioEditFunctionChangeVoice:
        case AWEStudioEditFunctionVideoEnhance:
        case AWEStudioEditFunctionText:
        case AWEStudioEditFunctionLyrics:
        case AWEStudioEditFunctionCustomSticker:
            return YES;
            
        default:
            return NO;
    }
}

- (BOOL)shouldShowFuncionBubble:(AWEStudioEditFunctionType)type
{
    void *viewId = ACCEditToolBarMusicContext;
    switch (type) {
        case AWEStudioEditFunctionMusic: {
            viewId = ACCEditToolBarMusicContext;
            return YES;
        }
            break;
            
        case AWEStudioEditFunctionEffect: {
            viewId = ACCEditToolBarEffectContext;
        }
            break;
            
        case AWEStudioEditFunctionSticker: {
            viewId = ACCEditToolBarInfoStickerContext;
        }
            break;
        case AWEStudioEditFunctionLyrics: {
            viewId = ACCEditToolBarInfoStickerContext;
        }
            break;
            
        case AWEStudioEditFunctionChangeVoice: {
            viewId = ACCEditToolBarVoiceChangeContext;
        }
            break;
            
        case AWEStudioEditFunctionVideoEnhance: {
            viewId = ACCEditToolBarVideoEnhanceContext;
        }
            break;
        case AWEStudioEditFunctionText: {
            viewId = ACCEditToolBarTextContext;
        }
            break;
        case AWEStudioEditFunctionCustomSticker: {
            viewId = ACCEditToolBarInfoStickerContext;
            break;
        }
        case AWEStudioEditFunctionLiveSticker: {
            viewId = ACCEditToolBarInfoStickerContext;
            break;
        }
        case AWEStudioEditFunctionKaraokeVolume:{
            viewId = ACCEditToolBarKaraokeConfigContext;
        }
            break;
        case AWEStudioEditFunctionKaraokeAudioBG:{
            viewId = ACCEditToolBarKaraokeBGConfigContext;
        }
            break;
        case AWEStudioEditFunctionWishModule:{
            viewId = ACCEditToolBarNewYearModuleContext;
        }
            break;
        case AWEStudioEditFunctionWishText:{
            viewId = ACCEditToolBarNewYearTextContext;
        }
            break;
        default:
            return NO;
    }
    return !![IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:viewId];
}

- (BOOL)showFunctionBubble:(AWEStudioEditFunctionType)type
{
    BOOL ret = NO;
    NSString *bubbleStr = @"";
    void *viewId = ACCEditToolBarMusicContext;
    ACCBubbleManagerDirection direction = ACCBubbleManagerDirectionUp;
    CGPoint adjustment = CGPointZero;

    if (!(self.tipsSerivce.showedValue & (1 << type))) {
        switch (type) {
            case AWEStudioEditFunctionMusic: {
                bubbleStr = ACCLocalizedString(@"edit_page_prompt_music", @"点击这里添加音乐");
                viewId = ACCEditToolBarMusicContext;
                adjustment = CGPointMake(0, -5);
                ret = YES;
            }
                break;
                
            case AWEStudioEditFunctionEffect: {
                bubbleStr = ACCLocalizedString(@"edit_page_prompt_effect",@"试试添加有趣的特效");
                viewId = ACCEditToolBarEffectContext;
                ret = YES;
            }
                break;
                
            case AWEStudioEditFunctionSticker: {
                bubbleStr = ACCLocalizedString(@"edit_page_prompt_sticker",@"加点好玩的贴纸") ;
                viewId = ACCEditToolBarInfoStickerContext;
                ret = YES;
            }
                break;
            case AWEStudioEditFunctionLyrics: {
                bubbleStr = ACCLocalizedString(@"creation_edit_sticker_lyrics_icon_guide", @"试试添加歌词吧");
                viewId = ACCEditToolBarInfoStickerContext;
                ret = YES;
            }
                break;
            case AWEStudioEditFunctionCustomSticker : {
                bubbleStr = ACCLocalizedString(@"creation_edit_sticker_upload_bubble", @"Try custom photo stickers");
                viewId = ACCEditToolBarInfoStickerContext;
                ret = YES;
            }
                break;
            case AWEStudioEditFunctionChangeVoice: {
                bubbleStr = ACCLocalizedString(@"edit_page_prompt_voice",@"试试变声效果");
                viewId = ACCEditToolBarVoiceChangeContext;
                direction = ACCBubbleManagerDirectionLeft;
                ret = YES;
            }
                break;
            
            case AWEStudioEditFunctionVideoEnhance: {
                bubbleStr = ACCLocalizedString(@"auto_enhance_on",@"已开启画质增强");
                viewId = ACCEditToolBarVideoEnhanceContext;
                direction = ACCBubbleManagerDirectionLeft;
                ret = YES;
            }
                break;
            case AWEStudioEditFunctionText: {
                bubbleStr = ACCLocalizedString(@"creation_edit_text_hint",@"点击使用文字");
                viewId = ACCEditToolBarTextContext;
                ret = YES;
            }
                break;
            case AWEStudioEditFunctionLiveSticker:{
                bubbleStr = @"添加预告并准时开播，会有更多观众看你的直播";
                viewId = ACCEditToolBarInfoStickerContext;
                ret = YES;
            }
                break;
            case AWEStudioEditFunctionKaraokeVolume:{
                bubbleStr = @"可以调整唱歌的效果";
                viewId = ACCEditToolBarKaraokeConfigContext;
                ret = YES;
            }
                break;
            case AWEStudioEditFunctionKaraokeAudioBG:{
                bubbleStr = @"可更换背景哦";
                viewId = ACCEditToolBarKaraokeBGConfigContext;
                ret = YES;
            }
                break;
               
            default:
                return NO;
        }
    }
    
    direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:viewId].location == ACCBarItemResourceLocationRight ? ACCBubbleManagerDirectionLeft : ACCBubbleManagerDirectionUp;

    // AI配乐特殊bubble
    if (ret && AWEStudioEditFunctionMusic == type) {
        if ([self.musicService useMusicSelectPanel]) {
            if ([AWEAIMusicRecommendManager sharedInstance].musicFetchType != AWEAIMusicFetchTypeAI) {
                @weakify(self);
                [self.KVOController observe:[AWEAIMusicRecommendManager sharedInstance]
                                    keyPath:NSStringFromSelector(@selector(musicFetchType))
                                    options:NSKeyValueObservingOptionNew
                                      block:^(typeof(self) _Nullable observer,AWEAIMusicRecommendManager *_Nonnull object,NSDictionary<NSString *, id> *_Nonnull change) {
                                          @strongify(self);
                                          dispatch_async(dispatch_get_main_queue(), ^{
                                              AWEAIMusicFetchType type = [change[NSKeyValueChangeNewKey] integerValue];
                                              if (!(self.tipsSerivce.showedValue & (1 << AWEStudioEditFunctionMusic)) && !self.publishModel.repoMusic.music)
                                              {
                                                  if (type == AWEAIMusicFetchTypeAI) {
                                                      self.allowShowGrootBubble = NO;
                                                      [self p_showRecommendedMusicBubbleIfNeeded];
                                                  } else {
                                                      if ([IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarMusicContext]) {
                                                          @weakify(self);
                                                          [self showBubbleWithItemId:viewId showBlock:^{
                                                              @strongify(self);
                                                              [self.tipsSerivce showFunctionBubbleWithContent:bubbleStr forView:[self bubbleAnchorViewWithDirection:direction actionItemId:viewId] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:adjustment inDirection:direction functionType:AWEStudioEditFunctionMusic];
                                                          }];
                                                      } else {
                                                          [self.tipsSerivce saveShowedFunctionsByType:AWEStudioEditFunctionMusic];
                                                          [self.tipsSerivce sendShowMusicBubbleSignalByType:ACCNormalMusicBubble];
                                                      }
                                                    
                                                  }
                                              }
                                          });
                                      }];
            } else if ([AWEAIMusicRecommendManager sharedInstance].musicFetchType == AWEAIMusicFetchTypeAI) {
                self.allowShowGrootBubble = NO;
                [self p_showRecommendedMusicBubbleIfNeeded];
            }
        } else {
            if (viewId == ACCEditToolBarMusicContext && (self.publishModel.repoDuet.isDuet)) {
                return NO;//dute and react has not music entrance in video edit page,so no need show music guide bubble
            }
            if ([IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarMusicContext]) {
                self.allowShowGrootBubble = NO;
                @weakify(self);
                [self showBubbleWithItemId:viewId showBlock:^{
                    @strongify(self);
                    [self.tipsSerivce showFunctionBubbleWithContent:bubbleStr forView:[self bubbleAnchorViewWithDirection:direction actionItemId:viewId] containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:adjustment inDirection:direction functionType:AWEStudioEditFunctionMusic];
                }];
            } else {
                [self.tipsSerivce saveShowedFunctionsByType:AWEStudioEditFunctionMusic];
                [self.tipsSerivce sendShowMusicBubbleSignalByType:ACCNormalMusicBubble];
            }
        }
    
        return NO;
    }
    
    // 普通bubble
    if (ret) {
        UIView *forView = [self bubbleAnchorViewWithDirection:direction actionItemId:viewId];
        @weakify(self);
        [self showBubbleWithItemId:viewId showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:bubbleStr forView:forView containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:adjustment inDirection:direction functionType:type];
        }];
        return YES;
    }
    
    return NO;
}

- (void)p_showRecommendedMusicBubbleIfNeeded
{
    BOOL needsShow = YES;

    if ([self.publishModel.repoUploadInfo isAIVideoClipMode]) {
        needsShow = NO;
    }
    if (needsShow) {
        if ([IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarMusicContext]) {
            [self p_showRecommendedMusicBubble];
        } else {
            [self.tipsSerivce saveShowedFunctionsByType:AWEStudioEditFunctionMusic];
            [self.tipsSerivce sendShowMusicBubbleSignalByType:ACCAIMusicBubble];
        }
    }
}

- (void)p_showRecommendedMusicBubble
{
    id<ACCMusicModelProtocol> music = [AWEAIMusicRecommendManager sharedInstance].recommedMusicList.firstObject;
    if (music) {
        [ACCWebImage() requestImageWithURLArray:music.thumbURL.URLList completion:^(UIImage *image, NSURL *url, NSError *error) {
            if (!image || error || !url) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                let direction = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarMusicContext].location == ACCBarItemResourceLocationBottom ? AWEImageAndTitleBubbleDirectionUp : AWEImageAndTitleBubbleDirectionLeft;
                UIView *anchorView = [self bubbleAnchorViewWithDirection:[self bubbleManagerDirectionWithNewBubbleDirection:direction] actionItemId:ACCEditToolBarMusicContext];
                if (direction == AWEImageAndTitleBubbleDirectionLeft) {
                    @weakify(self);
                    [self showBubbleWithItemId:ACCEditToolBarMusicContext showBlock:^{
                        @strongify(self);
                        [self.tipsSerivce showImageBubble:image forView:anchorView containerView:self.viewContainer.containerView mediaView:self.editService.mediaContainerView inDirection:direction subtitle:music.musicName functionType:AWEStudioEditFunctionMusic];
                    }];
                } else {
                    [self.tipsSerivce showImageBubble:image forView:anchorView containerView:self.viewContainer.containerView mediaView:self.editService.mediaContainerView inDirection:direction subtitle:music.musicName functionType:AWEStudioEditFunctionMusic];
                }
            });
        }];
    } else {
        ACCBubbleManagerDirection direction = ACCBubbleManagerDirectionUp;
        UIView *anchorView = [self bubbleAnchorViewWithDirection:direction actionItemId:ACCEditToolBarMusicContext];
        @weakify(self);
        [self showBubbleWithItemId:ACCEditToolBarMusicContext showBlock:^{
            @strongify(self);
            [self.tipsSerivce showFunctionBubbleWithContent:ACCLocalizedString(@"edit_page_prompt_music", @"点击这里添加音乐") forView:anchorView containerView:self.rootVC.view mediaView:self.editService.mediaContainerView anchorAdjustment:CGPointMake(0, -5) inDirection:direction functionType:AWEStudioEditFunctionMusic];
        }];
    }
}

- (NSArray *)showBubbleFunctionArray
{
    return @[@(AWEStudioEditFunctionMusic),
             @(AWEStudioEditFunctionText),
             @(AWEStudioEditFunctionSticker),
             @(AWEStudioEditFunctionEffect),
             @(AWEStudioEditFunctionChangeVoice)];
}

- (ACCBubbleManagerDirection)bubbleManagerDirectionWithNewBubbleDirection:(AWEImageAndTitleBubbleDirection)newDirection {
    // TODO: 新的 AI 气泡可以使用 ACCBubbleManager 的自定义view方法实现
    switch (newDirection) {
        case AWEImageAndTitleBubbleDirectionUp:
            return ACCBubbleManagerDirectionUp;
        case AWEImageAndTitleBubbleDirectionDown:
            return ACCBubbleManagerDirectionDown;
        case AWEImageAndTitleBubbleDirectionLeft:
            return ACCBubbleManagerDirectionLeft;
        case AWEImageAndTitleBubbleDirectionRight:
            return ACCBubbleManagerDirectionRight;
    }
}

- (void)showBubbleWithItemId:(void *)idStr showBlock:(dispatch_block_t)block
{
    if ([ACCToolBarAdapterUtils useAdaptedToolBarContainer]) {
        ACCBarItem *item = [self.viewContainer.topRightBarItemContainer barItemWithItemId:idStr];
        item.showBubbleBlock = block;
    } else {
        ACCBLOCK_INVOKE(block);
    }
}

- (UIView *)bubbleAnchorViewWithDirection:(ACCBubbleManagerDirection)direction actionItemId:(void *)idStr {
    UIView* anchorView;
    AWEEditActionItemView *itemView = [self.viewContainer viewWithBarItemID:idStr];
    switch (direction) {
        case ACCBubbleManagerDirectionUp:
            anchorView = itemView.button;
            break;
        case ACCBubbleManagerDirectionDown:
            {
                BOOL showTitle = ACCConfigBool(kConfigBool_show_title_in_video_camera);
                anchorView = showTitle ? itemView.label : itemView.button;
            }
            break;
        case ACCBubbleManagerDirectionLeft:
        case ACCBubbleManagerDirectionRight:
            if (itemView.acc_top > itemView.superview.acc_height) {
                // collapse items using Expand icon
                if (self.viewContainer.topRightBarItemContainer.moreItemView) {
                    anchorView = self.viewContainer.topRightBarItemContainer.moreItemView.button;
                } else {
                    anchorView = itemView.button;
                }
            } else {
                anchorView = itemView.button;
            }
            break;
    }
    if ([ACCToolBarAdapterUtils useAdaptedToolBarContainer]) {
        anchorView = itemView;
    }
    return anchorView;
}

- (BOOL)allowShowFunctionBubble
{
    return self.viewModel.inputData.showGuideBubble;
}

- (BOOL)allowShowGrootBubble {
    if ([self publishModel].repoImageAlbumInfo.isImageAlbumEdit) {
        return NO;
    }
    return _allowShowGrootBubble;
}

- (void)setAllowShowFunctionBubble:(BOOL)allowShowFunctionBubble
{
    self.viewModel.inputData.showGuideBubble = allowShowFunctionBubble;
}

#pragma mark - getter

- (UIViewController *)rootVC
{
    if ([self.controller isKindOfClass:[UIViewController class]]) {
        return (UIViewController *)self.controller;
    }
    NSAssert(nil, @"exception");
    return nil;
}

- (AWEVideoPublishViewModel *)publishModel
{
    return self.viewModel.inputData.publishModel;
}

#pragma mark - view model

- (ACCVideoEditTipsViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [self.modelFactory createViewModel:ACCVideoEditTipsViewModel.class];
    }
    return _viewModel;
}

- (ACCVideoEditTipsServiceImpl *)tipsSerivce {
    if (!_tipsSerivce) {
        _tipsSerivce = [[ACCVideoEditTipsServiceImpl alloc] init];
    }
    return _tipsSerivce;
}

-(id<ACCStickerServiceProtocol>)stickerService
{
    let service = IESAutoInline(self.serviceProvider, ACCStickerServiceProtocol);
    NSAssert(service, @"should not be nil");
    return service;
}

#pragma mark - ACCVideoEditTipsServiceSubscriber

- (void)tipService:(id<ACCVideoEditTipsService>)tipService didShowImageBubbleWithFunctionType:(AWEStudioEditFunctionType)type
{
    if (![self isTopRightBarBubble:type]) {
        return;
    }
    
    [self.tipsSerivce saveShowedFunctionsByType:type];
    [self trackerEventByBubbleType:type];
}

- (void)tipService:(id<ACCVideoEditTipsService>)tipService didShowFunctionBubbleWithFunctionType:(AWEStudioEditFunctionType)type
{
    if (![self isTopRightBarBubble:type]) {
        return;
    }
    
    [self.tipsSerivce saveShowedFunctionsByType:type];
    [self trackerEventByBubbleType:type];
}

- (void)trackerEventByBubbleType:(AWEStudioEditFunctionType)type
{
    NSString *typeStr = @"";
    switch (type) {
        case AWEStudioEditFunctionMusic:
            typeStr = @"music";
            break;
            
        case AWEStudioEditFunctionEffect:
            typeStr = @"effect";
            break;
            
        case AWEStudioEditFunctionSticker:
            typeStr = @"info_sticker";
            break;
            
        case AWEStudioEditFunctionChangeVoice:
            typeStr = @"voice";
            break;
        case AWEStudioEditFunctionText:
            typeStr = @"text";
            break;
        case AWEStudioEditFunctionLyrics:
            typeStr = @"lyrics_sticker";
            break;
        default:
            break;
    }
    // https://docs.google.com/spreadsheets/d/1iQa0ajvLXK8KdwAtm3ZN-34XiwNZ41LM_dZ62QxC-0w/edit#gid=0
    
    NSDictionary *referExtra = self.publishModel.repoTrack.referExtra;
    NSDictionary *params = @{@"enter_from" : @"video_edit_page",
                             @"type" : typeStr ?: @"",
                             @"creation_id": self.publishModel.repoContext.createId ?: @"",
                             @"content_type": referExtra[@"content_type"] ?: @"",
                             @"content_source": referExtra[@"content_source"] ?: @""
                             };
    
    [ACCTracker() trackEvent:@"function_toast_show" params:params needStagingFlag:NO];
}

- (void)grootPropToastShowTrack {
    NSDictionary *extraDict = self.publishModel.repoUploadInfo.extraDict;
    NSMutableDictionary *params = [@{
        @"creation_id": self.publishModel.repoContext.createId ?: @"",
        @"enter_from" : @"video_edit_page",
        @"enter_method" : self.publishModel.repoTrack.enterMethod ?: @"",
        @"shoot_way" :self.publishModel.repoTrack.referString ?: @"",
        } mutableCopy];
    params[@"from_parent_id"] = extraDict[@"from_parent_id"];
    params[@"is_groot_new"] = extraDict[@"is_groot_new"];
    [ACCTracker() trackEvent:@"groot_prop_toast_show" params:[params copy] needStagingFlag:NO];
}

- (void)liveStickerToastShowTrack
{
    NSDictionary *params = @{
        @"creation_id": self.publishModel.repoContext.createId ?: @"",
        @"enter_from" : @"video_edit_page",
        @"enter_method" : self.publishModel.repoTrack.enterMethod ?: @"",
        @"shoot_way" :self.publishModel.repoTrack.referString ?: @"",
        };
    [ACCTracker() trackEvent:@"livesdk_live_announce_guide" params:params needStagingFlag:NO];
}

@end
