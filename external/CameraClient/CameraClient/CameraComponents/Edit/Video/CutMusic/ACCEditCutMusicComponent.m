//
//  ACCEditCutMusicComponent.m
//  Pods
//
//  Created by lxp on 2019/9/25.
//

#import "AWERepoMusicModel.h"
#import "ACCEditCutMusicComponent.h"
#import <CreationKitInfra/ACCLoadingViewProtocol.h>
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import "AWEAIMusicRecommendManager.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCEditorDraftService.h"
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCVideoEditToolBarDefinition.h"
#import <CreationKitArch/ACCBarItemResourceConfigManagerProtocol.h>
#import "ACCEditCutMusicViewModel.h"
#import "VEEditorSession+ACCAudioEffect.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import "ACCLVAudioRecoverUtil.h"
#import "ACCLyricsStickerServiceProtocol.h"
#import "AWEAudioClipFeatureManager.h"
#import "ACCCutMusicRangeChangeContext.h"
#import "ACCEditMusicServiceProtocol.h"
#import <CreationKitArch/ACCMVTemplateInfo.h>
#import <CreationKitArch/ACCPublishRepository.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/AWERepoVideoInfoModel.h>
#import <CreationKitArch/ACCRepoCutSameModel.h>
#import "AWERepoMVModel.h"
#import <CameraClient/AWEVideoEditDefine.h>
#import "ACCConfigKeyDefines.h"
#import "ACCEditBarItemExtraData.h"
#import "ACCEditMVModel.h"
#import "ACCSelectMusicProtocol.h"
#import "AWERepoDuetModel.h"

#import "ACCBarItem+Adapter.h"
#import "ACCEditPreviewProtocolD.h"
#import <CreativeKit/ACCProtocolContainer.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

@interface ACCEditCutMusicComponent () <ACCEditPreviewMessageProtocol>

@property (nonatomic, weak) id<ACCEditViewContainer> viewContainer;

@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;
@property (nonatomic, weak) id<ACCLyricsStickerServiceProtocol> lyricsStickerService;

@property (nonatomic, assign) BOOL fromLyrics;
@property (nonatomic, assign) BOOL initMusicLoopStatus;
@property (nonatomic, assign) NSInteger initRepeatCount;
@property (nonatomic, strong) ACCEditCutMusicViewModel *viewModel;

@end

@implementation ACCEditCutMusicComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)
IESAutoInject(self.serviceProvider, lyricsStickerService, ACCLyricsStickerServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCEditCutMusicServiceProtocol),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.viewModel.repository = self.repository;
    self.viewModel.serviceProvider = self.serviceProvider;
}

- (void)loadComponentView {
    if ([self shouldAddCutMusicEntrance]) {
        [self.viewContainer addToolBarBarItem:[self barItem]];
    }
}

- (void)componentDidMount
{
    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    [self p_bindViewModel];
    [self p_initialForLVAudioFrame];
    [self p_updateClipMusicBarItem:[self buttonEnable]];
}

- (void)componentWillAppear
{
    if (self.repository.repoFlowControl.step != AWEPublishFlowStepCapture) {
        [ACCLVAudioRecoverUtil recoverAudioIfNeededWithOption:ACCLVFrameRecoverAll publishModel:self.publishModel editService:self.editService];
    }
}

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)p_bindViewModel
{
    @weakify(self);
    [self.musicService.cutMusicButtonClickedSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self cutMusicClicked];
    }];
    
    [self.musicService.didSelectCutMusicSignal.deliverOnMainThread subscribeNext:^(NSValue * _Nullable x) {
        @strongify(self);
        HTSAudioRange range;
        [x getValue:&range];
        [self.viewModel clipMusic:range repeatCount:-1];
        [self.viewModel sendDidFinishCutMusicSignal:[ACCCutMusicRangeChangeContext createWithAudioRange:range changeType:AWEAudioClipRangeChangeTypeUnknown]];
    }];
    
    __block HTSAudioRange previousAudioRange = {0};
    [self.musicService.mvWillAddMusicSignal.deliverOnMainThread subscribeNext:^(RACThreeTuple<ACCEditVideoData *,id<ACCMusicModelProtocol>,AVURLAsset *> * _Nullable x) {
        @strongify(self);
        previousAudioRange = self.repository.repoMusic.audioRange;
        [self.viewModel clipMusicBeforeAddedIfNeeded:x.first music:x.second asset:x.third];
    }];
    
    [self.musicService.didAddMusicSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self.viewModel clipMusicAfterAddedIfNeeded];
        [self p_updateClipMusicBarItem:YES];
    }];
    
    [self.musicService.didDeselectMusicSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self p_updateClipMusicBarItem:NO];
    }];
    
    [self.musicService.mvDidChangeMusicSignal.deliverOnMainThread subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (!x.boolValue) {
            BOOL invalidPreRange = previousAudioRange.length == 0 || (previousAudioRange.location < 0 || previousAudioRange.location >= previousAudioRange.length);
            if (!invalidPreRange) {
                self.repository.repoMusic.audioRange = previousAudioRange;
            }
        }
    }];
    
    [self.lyricsStickerService.addClipViewSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self cutMusicClikcedFromLyrics:YES];
    }];
    
    [self.lyricsStickerService.showClipViewSignal.deliverOnMainThread subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        NSMutableDictionary *referInfo = [self.repository.repoTrack.referExtra mutableCopy];
        referInfo[@"music_edited_from"] = @"lyricsticker";
        self.viewModel.audioClipFeatureManager.audioClipCommonTrackDic = [referInfo copy];

        [self.viewModel.audioClipFeatureManager showMusicClipView];
        [self p_trackMusicEditFromLyricsSticker];
    }];
    
    [self.lyricsStickerService.didFinishCutMusicSignal.deliverOnMainThread subscribeNext:^(RACTwoTuple * _Nullable x) {
        @strongify(self);
        HTSAudioRange range;
        [x.first getValue:&range];
        NSInteger repeatCount = -1;
        if ([self.repository.repoMusic shouldEnableMusicLoop:self.totalVideoDuration]) {
            // 通过 RAC 拿到透传的 repeatCount
            repeatCount = [x.second intValue];
        }
        [self.viewModel clipMusic:range repeatCount:repeatCount];
        [self.viewModel sendDidFinishCutMusicSignal:[ACCCutMusicRangeChangeContext createWithAudioRange:range changeType:AWEAudioClipRangeChangeTypeUnknown]];
    }];
}

- (void)p_initialForLVAudioFrame
{
    if (self.repository.repoUploadInfo.isAIVideoClipMode) {
        return;
    }
    
    if (self.repository.repoDuet.isDuetSing) {
        // 合唱的延时 由 AWEDuetEditComponent 自己管理；
        return;
    }
    
    BOOL fromMusicianUpload = self.repository.repoContext.videoSource == AWEVideoSourceAlbum && [self.repository.repoMusic.bgmAsset isKindOfClass:[AVURLAsset class]];
    if (fromMusicianUpload &&
        !self.repository.repoDraft.isDraft &&
        !self.repository.repoDraft.isBackUp &&
        !self.repository.repoContext.isMVVideo &&
        self.repository.repoContext.videoType != AWEVideoTypePhotoToVideo) {
        CGFloat musicShootDuration = [self.repository.repoMusic.music.shootDuration floatValue];
        // 修正背景音乐的 range，此时不应直接复用拍摄页中存储的值
        self.repository.repoMusic.bgmClipRange.durationSeconds = musicShootDuration;
        if ([self.repository.repoMusic shouldEnableMusicLoop:self.totalVideoDuration] && !ACC_FLOAT_EQUAL_ZERO(musicShootDuration)) {
            self.repository.repoMusic.bgmClipRange.repeatCount = ceil(self.totalVideoDuration / musicShootDuration);
        }
        [self.editService.audioEffect setAudioClipRange:self.repository.repoMusic.bgmClipRange forAudioAsset:self.repository.repoMusic.bgmAsset];
        return;
    }
    
    // 比如react的情况下因为didFinishRecording的时候并没有music.localAssetURL导致不会去生成clip
    // update bgmClipRange to video length, because user can record anothor fragment if not fully recording before, thus will change video duration.
    IESMMVideoDataClipRange *clipRange = self.repository.repoMusic.bgmClipRange;
    if (!clipRange || self.repository.repoDuet.isDuet) {
        clipRange = IESMMVideoDataClipRangeMakeV2(0, [self.publishModel.repoVideoInfo.video totalVideoDuration], 0, 1);
    }
    if ((ACCConfigBool(kConfigBool_music_record_audio_da) || ACCConfigBool(kConfigBool_duet_record_audio_da)) && self.editService.audioEffect.bgmAsset) {
        CGFloat delay = self.repository.repoVideoInfo.delay/1000.0;
        CGFloat attachSeconds = clipRange.attachSeconds;
        CGFloat startSeconds = clipRange.startSeconds - delay;
        if (startSeconds < 0) {
            attachSeconds += -1 * startSeconds;
            startSeconds = 0;
        }
        clipRange.startSeconds = startSeconds;
        clipRange.attachSeconds = attachSeconds;
    }
    // 强制更新clipRange
    self.repository.repoMusic.bgmClipRange = clipRange;
    // VE 有 bug，setAudioClipRange 之前需要先 pause，不然可能延时不生效 @liuxuan.ranger 在排查，客户端先兜底。
    BOOL isPlaying = [[self editService] preview].status == HTSPlayerStatusPlaying;
    if (isPlaying) {
        [self.editService.preview pause];
    }
    [self.editService.audioEffect setAudioClipRange:clipRange forAudioAsset:self.editService.audioEffect.bgmAsset];
    if (isPlaying) {
        [self.editService.preview continuePlay];
    }
}

- (BOOL)shouldAddCutMusicEntrance
{
    if ([self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeRePostVideo) {
        return NO;
    }
    
    if ([self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeShareAsStory) {
        return NO;
    }
    
    if ([self publishModel].repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
        return NO;
    }
    
    return  !self.repository.repoDuet.isDuet && ![self.musicService useMusicSelectPanel];
     
}

- (ACCBarItem<ACCEditBarItemExtraData*>*)barItem {
    let config = [IESAutoInline(self.serviceProvider, ACCBarItemResourceConfigManagerProtocol) configForIdentifier:ACCEditToolBarMusicCutContext];
    if (!config) return nil;
    ACCBarItem<ACCEditBarItemExtraData*>* bar = [[ACCBarItem alloc] init];
    bar.title = config.title;
    bar.imageName = config.imageName;
    bar.location = config.location;
    bar.itemId = ACCEditToolBarMusicCutContext;
    bar.type = ACCBarItemFunctionTypeCover;
    @weakify(self);
    bar.barItemActionBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        if (!self.isMounted) {
            return;
        }
        [self.viewModel sendCheckMusicFeatureToastSignal];
        if (self.musicService.musicFeatureDisable) {
             return;
        }
        if ([itemView isKindOfClass:[AWEEditActionItemView class]]) {
            AWEEditActionItemView *view = (AWEEditActionItemView*)itemView;
            if (!view.enable) {
                return;
            }
        }
        [self cutMusicClicked];
    };
    bar.barItemViewConfigBlock = ^(UIView * _Nonnull itemView) {
        @strongify(self);
        AWEEditActionItemView* view = (AWEEditActionItemView*)itemView;
        view.enable = [self buttonEnable];
    };
    bar.extraData = [[ACCEditBarItemExtraData alloc] initWithButtonClass:nil type:AWEEditAndPublishViewDataTypeCutMusic];
    return bar;
}

- (BOOL)buttonEnable
{
    if (!self.repository.repoMusic.music) {
        return NO;
    }
    
    NSTimeInterval duration = [self.repository.repoVideoInfo.video totalVideoDuration];
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    if ([config limitMusicAccordingLongVideo] && duration >= config.longVideoDurationLowerLimit) {
        return NO;
    }
    
    return YES;
}

- (void)p_updateClipMusicBarItem:(BOOL)enableClip
{
    if ([self.repository.repoContext isMVVideo]) {
        return;
    }
    
    AWEEditActionItemView *itemView = [self.viewContainer viewWithBarItemID:ACCEditToolBarMusicCutContext];
    itemView.enable = enableClip;
}

#pragma mark - 剪音乐

- (void)cutMusicClicked
{
    if (![self buttonEnable]) {
        return;
    }
    
    [self cutMusicClikcedFromLyrics:NO];
}

- (void)cutMusicClikcedFromLyrics:(BOOL)fromLyrics
{
    CGFloat allowedDuration = [self.repository.repoVideoInfo.video totalVideoDurationAddTimeMachine];
    self.initMusicLoopStatus = self.repository.repoMusic.enableMusicLoop;
    self.initRepeatCount = -1;
    CGFloat musicShootDuration = [self.repository.repoMusic.music.shootDuration floatValue];
    if (self.initMusicLoopStatus && !ACC_FLOAT_EQUAL_ZERO(musicShootDuration)) {
        self.initRepeatCount = ceil(allowedDuration / musicShootDuration);
    }
    self.fromLyrics = fromLyrics;
    [self createMusicCutViewIfNeed];
    
    // mv音乐动效裁剪时长使用视频时长作为最大时长
    BOOL isMusicEffectMV = self.repository.repoCutSame.isClassicalMV && AWEMVTemplateTypeMusicEffect == self.repository.repoMV.mvTemplateType;
    self.viewModel.audioClipFeatureManager.allowUsingVideoDurationAsMaxMusicDuration = isMusicEffectMV;
    
    //裁剪音乐时长修改为server下发的shoot_duration字段值，在拍摄页已经对最长拍摄时长进行了shoot_duration纠正，这里编辑页不知道是否还有必要做限制？
    let config = IESAutoInline(ACCBaseServiceProvider(), ACCVideoConfigProtocol);
    if (self.repository.repoMusic.music.shootDuration && [self.repository.repoMusic.music.shootDuration integerValue] >= [config videoMinSeconds] && ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) == ACCMusicLoopModeOff) {
        allowedDuration = MIN(allowedDuration, [self.repository.repoMusic.music.shootDuration floatValue]);
    }

    NSMutableDictionary *trackDic = [self.repository.repoTrack.referExtra mutableCopy];
    trackDic[@"music_edited_from"] = [self shouldAddCutMusicEntrance] ? @"edit_normal" : @"recommend_music";
    self.viewModel.audioClipFeatureManager.audioClipCommonTrackDic = [trackDic copy];
    
    self.viewModel.audioClipFeatureManager.music = self.repository.repoMusic.music;
    self.viewModel.audioClipFeatureManager.useSuggestInitial = self.repository.repoMusic.useSuggestClipRange;
    [self.viewModel.audioClipFeatureManager updateAudioBarWithURL:self.repository.repoMusic.music.loaclAssetUrl
                                                    totalDuration:self.repository.repoMusic.music.auditionDuration.floatValue ?: CMTimeGetSeconds([self musicAsset].duration)
                                                    startLocation:self.repository.repoMusic.audioRange.location
                                       exsitingVideoTotalDuration:allowedDuration
                                                  enableMusicLoop:self.repository.repoMusic.enableMusicLoop];
    
    if (!fromLyrics) {
        [self.viewContainer.containerView acc_fadeShow:NO duration:0.15];
        @weakify(self);
        [self.viewModel.audioClipFeatureManager showMusicClipViewWithCompletion:^{
            @strongify(self);
            self.viewContainer.containerView.alpha = 0.0;
        }];
    }
    
    [self.viewModel sendDidClickCutMusicButtonSignal];
    [self observeAsset];
    if (!fromLyrics) {
        [self p_trackMusicEdit];
    }
}

- (void)observeAsset {
    if (self.musicAsset) {
        [[self editService].preview addSubscriber:self];
    }
}

- (void)createMusicCutViewIfNeed
{
    if (self.viewModel.audioClipFeatureManager) {
        return;
    }
    
    self.viewModel.audioClipFeatureManager = [[AWEAudioClipFeatureManager alloc] init];
    self.viewModel.audioClipFeatureManager.sceneType = ACCMusicEnterScenceTypeEditor;
    [self.viewModel.audioClipFeatureManager addAudioCLipViewForViewController:self.containerViewController];
    __block BOOL useSuggestClipRange = self.repository.repoMusic.useSuggestClipRange;

    @weakify(self);
    self.viewModel.audioClipFeatureManager.audioClipDoneBlock = ^(HTSAudioRange range, AWEAudioClipRangeChangeType changeType, BOOL enableMusicLoop, NSInteger repeatCount) {
        @strongify(self);
        self.repository.repoMusic.enableMusicLoop = enableMusicLoop;
        [self p_audioRangeDidChange:range changeType:changeType];
        NSString *editdFrom = [self shouldAddCutMusicEntrance] ? @"edit_normal" : @"recommend_music";
        if (self.fromLyrics) {
            editdFrom = @"lyricsticker";
        }
        self.repository.repoMusic.musicEditedFrom = editdFrom;
        self.repository.repoMusic.useSuggestClipRange = useSuggestClipRange;
        [self p_showContainerViewIfNeeded];
    };
    self.viewModel.audioClipFeatureManager.audioClipCancelBlock = ^(HTSAudioRange range, AWEAudioClipRangeChangeType changeType) {
        @strongify(self);
        self.repository.repoMusic.enableMusicLoop = self.initMusicLoopStatus;
        [self.viewModel clipMusic:range repeatCount:self.initRepeatCount];
        [self p_audioRangeDidChange:range changeType:changeType];
        [self p_showContainerViewIfNeeded];
    };
    self.viewModel.audioClipFeatureManager.suggestSelectedChangeBlock = ^(BOOL selected) {
        useSuggestClipRange = selected;
    };
    
    self.viewModel.audioClipFeatureManager.audioRangeChangeBlock = ^(HTSAudioRange range, AWEAudioClipRangeChangeType changeType, NSInteger repeatCount) {
        @strongify(self);
        if (self.lyricsStickerService.hasAlreadyAddLyricSticker) {
            self.repository.repoMusic.enableMusicLoop = repeatCount > 1;
        }
        [self.viewModel clipMusic:range repeatCount:repeatCount];
        [self.viewModel sendCutMusicRangeDidChangeSignal:[ACCCutMusicRangeChangeContext createWithAudioRange:range changeType:changeType]];
    };
}

- (void)p_showContainerViewIfNeeded
{
    if (self.fromLyrics) {
        return;
    }
    if ([self.musicService useMusicSelectPanel]) {
        self.viewContainer.containerView.hidden = NO;
        [self.viewModel sendDidDismissPanelSignal];
    } else {
        [self.viewContainer.containerView acc_fadeShow:YES duration:0.3];
    }
}

- (void)p_audioRangeDidChange:(HTSAudioRange)range changeType:(AWEAudioClipRangeChangeType)changeType
{
    self.repository.repoMusic.audioRange = range;
    [self.viewModel sendDidFinishCutMusicSignal:[ACCCutMusicRangeChangeContext createWithAudioRange:range changeType:changeType]];
    [[self editService].preview removeSubscriber:self];
    // mv影集-音乐动效
    if ((self.repository.repoCutSame.isClassicalMV || AWEVideoTypePhotoToVideo == self.repository.repoContext.videoType) && AWEMVTemplateTypeMusicEffect == self.repository.repoMV.mvTemplateType) {
        if (AWEAudioClipRangeChangeTypeHideView == changeType) {
            [self didFinishClipMusic:range];
        }
    }
}

- (void)didFinishClipMusic:(HTSAudioRange)range
{
    ACCEditMVModel *mvModel = self.repository.repoMV.mvModel;
    ACCEditVideoData *videoData = self.repository.repoVideoInfo.video;
    ACCEditVideoData *editBufferVideoData = [videoData copy]; // 编辑缓冲区数据，编辑成功后替换掉 publishViewMode.video 和 player的videoData，失败直接废弃
    AVAsset *musicAsset = self.repository.repoMusic.bgmAsset;
    if (mvModel && editBufferVideoData && musicAsset && range.length > 0) {
        IESMMVideoDataClipRange *clipRange = IESMMVideoDataClipRangeMake(range.location, range.length);
        editBufferVideoData.audioTimeClipInfo = @{};
        [editBufferVideoData updateAudioTimeClipInfoWithClipRange:clipRange asset:musicAsset];
        [[self editService].preview pause];
        UIView<ACCLoadingViewProtocol> *loadingView = [ACCLoading() showLoadingOnView:self.containerViewController.view];
        @weakify(self);
        [mvModel userChangeMusic:editBufferVideoData completion:^(BOOL result, NSError *error, ACCEditVideoData *info) {
            @strongify(self);
            [loadingView dismiss];
            if (result && info) {
                [self.repository.repoVideoInfo updateVideoData:info];
                self.repository.repoMusic.audioRange = range;
                [ACCGetProtocol(self.editService.preview, ACCEditPreviewProtocolD) updateVideoData:info
                                               updateType:VEVideoDataUpdateBGMAudio
                                            completeBlock:^(NSError * _Nonnull error) {
                    // 恢复音乐音量设置
                    @strongify(self);
                    [[self audioEffectService] setVolumeForAudio:self.repository.repoMusic.musicVolume];
                    [[self editService].preview play];
                    if (error) {
                        ACC_LogError(@"preview service update videoData for update BGM audio error %@", error);
                    }
                }];
                
                let draftService = IESAutoInline(self.serviceProvider, ACCEditorDraftService);
                NSAssert(draftService, @"should not be nil");
                [draftService hadBeenModified];
            } else {
                [[self editService].preview play];
            }
            if (error) {
                ACC_LogError(@"mv change music error %@", error);
            }
        }];
    }
}

- (void)p_trackMusicEdit
{
    [ACCTracker() trackEvent:@"music_edit"
                       label:@"mid_page"
                       value:nil
                       extra:nil
                  attributes:self.repository.repoTrack.referExtra];
    NSMutableDictionary *attributes = [self.repository.repoTrack.referExtra mutableCopy];
    if ([self.musicService useMusicSelectPanel]) {
        [attributes setValue:[NSString stringWithFormat:@"%d", (int)[AWEAIMusicRecommendManager sharedInstance].musicFetchType] forKeyPath:@"music_rec_type"];
    }
    attributes[@"music_edited_from"] = [self shouldAddCutMusicEntrance] ? @"edit_normal" : @"recommend_music";
    attributes[@"can_music_loop"] = [self.viewModel.audioClipFeatureManager shouldShowMusicLoopComponent] ? @"1" : @"0";
    [ACCTracker() trackEvent:@"edit_music" params:attributes needStagingFlag:NO];
}

- (void)p_trackMusicEditFromLyricsSticker
{
    NSMutableDictionary *referInfo = [self.repository.repoTrack.referExtra mutableCopy];
    referInfo[@"music_edited_from"] = @"lyricsticker";
    referInfo[@"can_music_loop"] = [self.viewModel.audioClipFeatureManager shouldShowMusicLoopComponent] ? @"1" : @"0";
    [ACCTracker() trackEvent:@"edit_music" params:[referInfo copy] needStagingFlag:NO];
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)realVideoFramePTSChanged:(NSTimeInterval)PTS
{
    if (self.musicAsset) {
        CMTime startTime = [self.publishModel.repoVideoInfo.video audioTimeClipRangeForAsset:self.musicAsset].start;
        if (self.viewModel.audioClipFeatureManager.isShowingAudioClipView) {
            if ([self.viewModel.audioClipFeatureManager isMusicLoopOpen]) {
                [self.viewModel.audioClipFeatureManager updateAudioClipViewWithTime:PTS];
            } else {
                [self.viewModel.audioClipFeatureManager updateAudioClipViewWithTime:(PTS + CMTimeGetSeconds(startTime))];
            }
        }
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

- (AVAsset *)musicAsset
{
    return self.repository.repoMusic.bgmAsset;
}

- (ACCEditCutMusicViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [[ACCEditCutMusicViewModel alloc] init];
    }
    return _viewModel;
}

-(id<ACCEditServiceProtocol>)editService
{
    let editService = IESAutoInline(self.serviceProvider, ACCEditServiceProtocol);
    NSAssert(editService, @"should not be nil");
    return editService;
}

- (id<ACCEditAudioEffectProtocol>)audioEffectService
{
    return [self editService].audioEffect;
}

- (CGFloat)totalVideoDuration
{
    CGFloat p_totalVideoDuration = [self.repository.repoVideoInfo.video totalVideoDuration];
    if (self.repository.repoVideoInfo.video.effect_timeMachineType != HTSPlayerTimeMachineNormal) {
        p_totalVideoDuration = [self.repository.repoVideoInfo.video totalVideoDurationAddTimeMachine];
    }
    return p_totalVideoDuration;
}

@end
