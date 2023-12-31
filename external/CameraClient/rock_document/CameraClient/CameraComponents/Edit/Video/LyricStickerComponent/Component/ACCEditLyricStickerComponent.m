//
//  ACCEditLyricStickerComponent.m
//  Pods
//
//  Created by Haoyipeng on 2019/10/27.
//

#import "AWERepoVideoInfoModel.h"
#import "AWERepoStickerModel.h"
#import "ACCEditLyricStickerComponent.h"
#import "AWEStickerLyricStyleManager.h"
#import <EffectPlatformSDK/IESFileDownloader.h>
#import <EffectPlatformSDK/EffectPlatform+Additions.h>

#import <CreationKitInfra/ACCToastProtocol.h>
#import <CreationKitInfra/NSDictionary+ACCAddition.h>
#import <CreativeKit/ACCMonitorProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/NSArray+ACCAdditions.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>

#import <CreationKitInfra/ACCLogProtocol.h>
#import <CameraClient/ACCMusicNetServiceProtocol.h>
#import "ACCStickerPanelServiceProtocol.h"
#import "ACCEditCutMusicServiceProtocol.h"
#import "ACCEditLyricStickerViewModel.h"
#import "ACCStickerGestureComponentProtocol.h"
#import <CreationKitArch/ACCEditAndPublishConstants.h>
#import "AWEStickerLyricFontManager.h"
#import <CameraClient/IESEffectModel+DStickerAddditions.h>
#import "ACCVideoEditChallengeBindViewModel.h"
#import "AWELyricStickerPanelView.h"
#import "ACCEditorDraftService.h"
#import "ACCStickerServiceProtocol.h"
#import "ACCLyricsStickerConfig.h"
#import "ACCLyricsStickerContentView.h"
#import "ACCStickerBizDefines.h"
#import "AWEEditStickerHintView.h"
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCEditViewContainer.h>
#import "ACCLyricsStickerUtils.h"
#import "ACCDraftResourceRecoverProtocol.h"
#import "ACCEditLyricsStickerViewController.h"
#import "ACCVideoEditStickerContainerConfig.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <NLEPlatform/NLESegmentSubtitleSticker+iOS.h>
#import <NLEPlatform/NLEStyleText+iOS.h>
#import "NLESegmentSticker_OC+ACCAdditions.h"
#import "NLETrackSlot_OC+ACCAdditions.h"
#import "ACCCutMusicRangeChangeContext.h"
#import "ACCEditMusicServiceProtocol.h"
#import <CreationKitInfra/ACCRTLProtocol.h>
#import <CameraClient/ACCDraftProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoMusicModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import "AWERepoContextModel.h"
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import "ACCSelectTemplateServiceProtocol.h"
#import <CreationKitArch/AWEInfoStickerInfo.h>
#import "ACCEditTransitionService.h"
#import "IESInfoSticker+ACCAdditions.h"
#import "ACCLyricsStickerHandler.h"
#import <CreationKitArch/AWEInteractionStickerLocationModel+ACCSticker.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import <CameraClient/ACCRepoSmartMovieInfoModel.h>
#import <CameraClientModel/ACCCrossPlatformStickerType.h>
#import <CameraClientModel/ACCVideoCanvasType.h>

static NSString * const kChallengeBindLyricStickerModuleKey = @"lyricSticker";
static CGFloat const kAWELyricsStickerTotalDuration = -1;
static const CGFloat kAWEStickerContainerViewHintAnimationYOffset = 8.f;
static const CGFloat kVideoStickerEditViewPadding = 12;

@interface ACCEditLyricStickerComponent () <
ACCEditLyricsStickerDatasource,
ACCEditLyricsStickerDelegate,
ACCStickerPannelObserver,
ACCDraftResourceRecoverProtocol
>

@property (nonatomic, strong) ACCLyricsStickerHandler *lyricsStickerHandler;

@property (nonatomic, weak) id<ACCStickerGestureComponentProtocol> stickerGestureComponent;

@property (nonatomic, assign) BOOL isFirstTimeToCallAddLyricOnEditPageShowWithMusicId;
@property (nonatomic, assign) BOOL isFirstTimeToCallPresentMusicStickerSearchVCFromLyricEdit;
// 添加歌词贴纸后除非手动移除，后续切换歌曲都会自动添加歌词贴纸
@property (nonatomic, assign) BOOL isRecordLyricSticker;
@property (nonatomic, strong) ACCEditLyricsStickerViewController *lyricStickerViewController;
@property (nonatomic, copy) NSString *lyricStickerChallengeId;

@property (nonatomic, strong) id<ACCEditViewContainer> viewContainer;

// 从音乐面板添加的歌词贴纸不发送收起贴纸面板信号
@property (nonatomic, assign) BOOL isFromMusicPanel;

@property (nonatomic, strong) ACCEditLyricStickerViewModel *viewModel;
@property (nonatomic, strong, readonly) ACCVideoEditChallengeBindViewModel *challengeBindViewModel;

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditorDraftService> draftService;
@property (nonatomic, weak) id<ACCStickerServiceProtocol> stickerService;
@property (nonatomic, weak) id<ACCEditCutMusicServiceProtocol> cutMusicService;
@property (nonatomic, weak) id<ACCEditMusicServiceProtocol> musicService;
@property (nonatomic, weak) id<ACCStickerPanelServiceProtocol> stickerPanelService;
@property (nonatomic, weak) id<ACCSelectTemplateServiceProtocol> selectTemplateService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;

// 提示语
@property (nonatomic, strong) AWEEditStickerHintView *hintView;
@property (nonatomic, assign) BOOL isKaraoke;
@property (nonatomic, assign) BOOL discardUnselectTrackEvent;
@property (nonatomic, strong) NSString *coordinateRatioString; // 歌词贴纸初始化位置

@property (nonatomic, copy, nullable) void (^dismissPanelHandle)(ACCStickerType, BOOL);

@end

@implementation ACCEditLyricStickerComponent

IESAutoInject(self.serviceProvider, stickerGestureComponent, ACCStickerGestureComponentProtocol)
IESAutoInject(self.serviceProvider, transitionService, ACCEditTransitionServiceProtocol)
IESAutoInject(self.serviceProvider, editService, ACCEditServiceProtocol)
IESAutoInject(self.serviceProvider, viewContainer, ACCEditViewContainer)
IESAutoInject(self.serviceProvider, cutMusicService, ACCEditCutMusicServiceProtocol)
IESAutoInject(self.serviceProvider, musicService, ACCEditMusicServiceProtocol)
IESAutoInject(self.serviceProvider, stickerPanelService, ACCStickerPanelServiceProtocol)
IESAutoInject(self.serviceProvider, stickerService, ACCStickerServiceProtocol)
IESAutoInject(self.serviceProvider, draftService, ACCEditorDraftService)
IESOptionalInject(self.serviceProvider, selectTemplateService, ACCSelectTemplateServiceProtocol)

- (ACCServiceBinding *)serviceBinding
{
    return ACCCreateServiceBinding(@protocol(ACCLyricsStickerServiceProtocol),
                                   self.viewModel);
}

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    self.viewModel.repository = self.repository;
    [self.stickerService registStickerHandler:self.lyricsStickerHandler];
    [[self stickerPanelService] registObserver:self];
}

- (void)bindViewModel
{
    // K歌贴纸的情况下，不需要这些监听和执行
    if (self.isKaraoke) {
        return;
    }
    
    @weakify(self);
    [self.musicService.didAddMusicSignal.deliverOnMainThread
     subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        [self p_didAddMusic:self.repository.repoMusic.music withRemoveLyricSticker:[x boolValue]];
    }];
    
    [self.musicService.didDeselectMusicSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self p_removeMusicLyricSticker];
    }];
    
    [self.musicService.mvDidChangeMusicSignal
     subscribeNext:^(NSNumber * _Nullable x) {
        @strongify(self);
        if (x.boolValue) {
            [self.lyricStickerViewController updatePlayerModelAudioRange:self.repository.repoMusic.audioRange];
        }
    }];
    
    [self.cutMusicService.cutMusicRangeDidChangeSignal.deliverOnMainThread subscribeNext:^(ACCCutMusicRangeChangeContext * _Nullable x) {
        @strongify(self);
        [self.lyricStickerViewController audioRangeChanging:x.audioRange changeType:x.changeType];
    }];
    
    [self.cutMusicService.didFinishCutMusicSignal.deliverOnMainThread subscribeNext:^(ACCCutMusicRangeChangeContext * _Nullable x) {
        @strongify(self);
        [[self stickerService] startEditingStickerOfType:ACCStickerTypeLyricSticker];
        [self.lyricStickerViewController audioRangeDidChange:x.audioRange changeType:x.changeType];
    }];
    
    [self.musicService.toggleLyricsButtonSignal.deliverOnMainThread subscribeNext:^(RACThreeTuple<NSNumber *,NSString *,id<ACCMusicModelProtocol>> * _Nullable x) {
        @strongify(self);
        if ([x.first boolValue]) {
            [self p_addLyricStickerFromMusicPanelWithMusic:x.third coordinateRatio:x.second];
        } else {
            self.discardUnselectTrackEvent = YES;
            [self p_removeMusicLyricSticker];
        }
        [self p_setLyricStickerIDInPublishModel];
    }];
    
    [self.selectTemplateService.didRemoveLyricStickerSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self p_dismissHintTextWithAnimation:NO];
        [self p_removeBindChallenge];
        [self.viewModel sendUpdateLyricsStickerButtonSignal:ACCMusicPanelLyricsStickerButtonChangeTypeReset];
    }];
    
    [self.selectTemplateService.recoverLyricStickerSignal subscribeNext:^(id  _Nullable x) {
        @strongify(self);
        [self p_addLyricStickerFromMusicPanelWithMusic:self.repository.repoMusic.music coordinateRatio:nil];
    }];
}

- (void)loadComponentView {
    // 草稿恢复
    [self p_recoveryLyricsStickerIfNeeded];
}

- (void)componentDidMount
{
    self.isKaraoke = (self.repository.repoContext.videoType == AWEVideoTypeKaraoke);
    
    [self p_downloadFontForLyricSticker];
    
    self.isFirstTimeToCallAddLyricOnEditPageShowWithMusicId = YES;
    self.isFirstTimeToCallPresentMusicStickerSearchVCFromLyricEdit = YES;
    ACCLog(@"===Lyric: %@", self.repository.repoTrack.enterEditPageMethod);
    [self p_addLyricOnEditPageShowWithMusicId:self.repository.repoMusic.music.musicID
                               baseMusicModel:self.repository.repoMusic.music];
    self.isFirstTimeToCallAddLyricOnEditPageShowWithMusicId = NO;
    
    [self bindViewModel];

    if (![self.controller enableFirstRenderOptimize]) {
        [self loadComponentView];
    }
    
    // 更新字体
    [self p_updateFontIfNeeded];
}

#pragma mark - ACCStickerPannelObserver

- (BOOL)handleSelectSticker:(IESEffectModel *)sticker fromTab:(NSString *)tabName
           willSelectHandle:(dispatch_block_t)willSelectHandle
         dismissPanelHandle:(void (^)(ACCStickerType type, BOOL animated))dismissPanelHandle
{
    self.dismissPanelHandle = dismissPanelHandle;
    
    if ([self stickerService].infoStickerCount >= ACCConfigInt(kConfigInt_info_sticker_max_count)) {
        return NO;
    }
    
    if (![sticker isTypeMusicLyric]) {
        return NO;
    }
    
    if (!sticker.downloaded) {
        return NO;
    }
    
    @weakify(self);
    [ACCDraft() saveInfoStickerPath:sticker.filePath
                            draftID:self.repository.repoDraft.taskID
                         completion:^(NSError *draftError, NSString *draftStickerPath) {
        if (draftError || ACC_isEmptyString(draftStickerPath)) {
            [ACCToast() showError:ACCLocalizedCurrentString(@"error_retry")];
            AWELogToolError(AWELogToolTagEdit, @"select lyrics sticker from panel and save draft failed: %@", draftError);
            return;
        }
        
        @strongify(self);
        [self p_addLyricsSticker:sticker
                            path:draftStickerPath
                         tabName:tabName
                      completion:^(NSInteger stickerId) {
            @strongify(self);
            [self p_showLyricsStickerHint];
        }];
    }];
    ACCBLOCK_INVOKE(willSelectHandle);
    
    return YES;
}

- (ACCStickerPannelObserverPriority)stikerPriority
{
    return ACCStickerPannelObserverPriorityLyrics;
}

#pragma mark - Privates
- (void)p_addLyricsSticker:(IESEffectModel *)sticker
                      path:(NSString *)path
                   tabName:(NSString *)tabName
                completion:(void (^)(NSInteger))completion
{
    [self p_addLyricsSticker:sticker path:path tabName:tabName locationModel:nil completion:completion];
}

- (void)p_addLyricsSticker:(IESEffectModel *)sticker
                      path:(NSString *)path
                   tabName:(NSString *)tabName
             locationModel:(AWEInteractionStickerLocationModel *)locationModel
                completion:(void (^)(NSInteger))completion
{
    NSMutableDictionary *userInfo = [@{
        // Larry.lai: don't remove stickerID, this need to be persist
        @"stickerID" : sticker.effectIdentifier ? : @"",
        @"tabName" : tabName ? : @"",
        kACCStickerUUIDKey : [NSUUID UUID].UUIDString ?: @""
    } mutableCopy];
    userInfo.acc_stickerType = ACCEditEmbeddedStickerTypeLyrics;
    
    // cannot apply lyric Sticker and time effect at the same time
    HTSPlayerTimeMachineType currentTimeMachineType =
    self.repository.repoVideoInfo.video.effect_timeMachineType;
    
    if (currentTimeMachineType != HTSPlayerTimeMachineNormal) {
        [ACCToast() show:ACCLocalizedString(@"effect_time_mutex", @"Lyrics stickers and time effects can't be used at the same time")];
        return;
    }
    
    @weakify(self);
    NSString *fontName = [AWEStickerLyricFontManager formatFontDicWithJSONStr:sticker.extra ? : @""];
    [AWEStickerLyricFontManager
     fetchLyricFontResourceWithFontName:fontName
     completion:^(NSError * _Nonnull error, NSString * _Nonnull fontFilePath) {
        @strongify(self);
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"Add lyric sticker failed, error: %@", error);
        }
        
        [self p_checkMusicOrShowLyricMusicViewControllerWithCompletion:^(NSString *formatLyricStr, NSError *error) {
            @strongify(self);
            if (error) {
                AWELogToolError(AWELogToolTagEdit, @"Add lyric sticker failed, error: %@", error);
            }
        
            if (formatLyricStr && formatLyricStr.length > 0) {
                [self p_removeMusicLyricSticker];
                NSInteger stickerId = [self.editService.sticker addInfoSticker:path
                                                                withEffectInfo:@[]
                                                                      userInfo:userInfo];
                if (locationModel) {
                    CGFloat offsetX = ([locationModel.x floatValue] - 0.5) * self.repository.repoVideoInfo.playerFrame.size.width;
                    CGFloat offsetY = (0.5 - [locationModel.y floatValue]) * self.repository.repoVideoInfo.playerFrame.size.height;
                    CGFloat angle = [locationModel.rotation floatValue];
                    CGFloat scale = [locationModel.scale floatValue];
                    [[self editService].sticker setSticker:stickerId
                                                   offsetX:offsetX
                                                   offsetY:offsetY
                                                     angle:angle
                                                     scale:scale];
                }
                
                IESInfoStickerProps *props = [IESInfoStickerProps new];
                [self.editService.sticker getStickerId:stickerId props:props];
                [self.editService.sticker setSrtInfo:stickerId srt:formatLyricStr];
                [self p_updateMusicLyricStickerAudioRange:self.repository.repoMusic.audioRange];
                
                [self p_bindChallengeWithChallengeId:sticker.challengeID];
                
                [ACCDraft() saveInfoStickerPath:fontFilePath
                                        draftID:self.repository.repoDraft.taskID
                                     completion:^(NSError *draftError, NSString *draftStickerPath) {
                    @strongify(self);
                    [self.editService.sticker setSrtFont:stickerId fontPath:draftStickerPath ? : @""];
                    
                    if (draftError) {
                        AWELogToolError(AWELogToolTagEdit, @"add lyrics sticker and save draft failed: %@", draftError);
                    }
                }];
                
                // 应用贴纸
                [self p_applyLyricsSticker:stickerId];
                !completion ?: completion(stickerId);
            } else {
                [ACCToast() show:ACCLocalizedString(@"creation_edit_sticker_lyrics_toast_for_loading_failed", @"歌词加载失败，请稍后重试")];
                self.isFromMusicPanel = NO;
                [self.viewModel sendUpdateLyricsStickerButtonSignal:ACCMusicPanelLyricsStickerButtonChangeTypeReset];
            }
        }];
    }];
    
    // 通知草稿有改变
    [[self draftService] hadBeenModified];
}

- (void)p_startEditLyricSticker:(NSInteger)stickerEditId
{
    [self p_updateEditLyricsViewControllerWithStickerId:stickerEditId];
    
    [self.lyricStickerViewController willMoveToParentViewController:self.controller.root];
    [self.controller.root.view addSubview:self.lyricStickerViewController.view];
    [self.controller.root addChildViewController:self.lyricStickerViewController];
    [[self stickerService] startEditingStickerOfType:ACCStickerTypeLyricSticker];
    [self.lyricStickerViewController didMoveToParentViewController:self.controller.root];
    [self.editService.preview continuePlay];
}

- (void)p_removeMusicLyricSticker
{
    // 歌词贴纸-移除贴纸
    UIView<ACCStickerProtocol> *lyricStickerWrapper =
    [[self.stickerService.stickerContainer allStickerViews] btd_find:^BOOL(ACCStickerViewType  _Nonnull obj) {
        return [obj.contentView isKindOfClass:ACCLyricsStickerContentView.class];
    }];
    
    if (lyricStickerWrapper) {
        [self.stickerService.stickerContainer removeStickerView:lyricStickerWrapper];
        // 移除歌词贴纸的时候移除提示语
        [self p_dismissHintTextWithAnimation:NO];
        
        [self p_removeBindChallenge];
    }
}

- (void)p_addLyricStickerFromExpressWithLyricsEditorConfig:(ACCEditorLyricsStickerConfig *)config
{
    if (![config isKindOfClass:[ACCEditorLyricsStickerConfig class]]) {
        NSAssert(NO, @"check class");
        return;
    }
    
    id<ACCMusicModelProtocol> music = self.repository.repoMusic.music;
    
    if (!music ||ACC_isEmptyString(music.lyricUrl)) {
        return;
    }
    
    IESEffectModel *effectModel = config.downloadedEffect;
    
    if (!effectModel.downloaded) {
        NSAssert(NO, @"effect model for lyric must be downloaded");
        AWELogToolError(AWELogToolTagMusic, @"express lyrics sticker faild because of effect model is not vaild");
        return;
    }
    
    @weakify(self);
    [self p_addLyricsSticker:effectModel
                        path:effectModel.filePath
                     tabName:nil
               locationModel:[config locationModel] 
                  completion:^(NSInteger stickerId) {
        @strongify(self);
        [self.viewModel sendUpdateLyricsStickerButtonSignal:ACCMusicPanelLyricsStickerButtonChangeTypeEnable];
    }];
}

- (void)p_addLyricStickerFromMusicPanelWithMusic:(id<ACCMusicModelProtocol>)music coordinateRatio:(NSString *)coordinateRatioString
{
    self.isFromMusicPanel = YES;
    self.repository.repoMusic.music = music;
    
    BOOL musicPanelVertical = ACCConfigBool(kConfigBool_studio_music_panel_vertical);
    AWEInteractionStickerLocationModel *locationModel = nil;
    if (musicPanelVertical) {  // 命中了竖版新音乐panel的才需要重置locationModel
        if (!ACC_isEmptyString(coordinateRatioString)) {
            self.coordinateRatioString = coordinateRatioString;
            locationModel = [[AWEInteractionStickerLocationModel alloc] init];
            CGPoint coordinateRatio = CGPointFromString(coordinateRatioString);
            NSString *offsetXStr = [NSString stringWithFormat:@"%.4f", coordinateRatio.x];
            NSString *offsetYStr = [NSString stringWithFormat:@"%.4f", coordinateRatio.y];
            locationModel.y = [NSDecimalNumber decimalNumberWithString:offsetYStr];
            locationModel.x = [NSDecimalNumber decimalNumberWithString:offsetXStr];
        } else {
            CGPoint coordinateRatio = CGPointZero;
            if (ACC_isEmptyString(self.coordinateRatioString)) {
                coordinateRatio = CGPointMake(0.5, 0.3);
            } else {
                coordinateRatio = CGPointFromString(self.coordinateRatioString);
            }
            locationModel = [[AWEInteractionStickerLocationModel alloc] init];
            NSString *offsetXStr = [NSString stringWithFormat:@"%.4f", coordinateRatio.x];
            NSString *offsetYStr = [NSString stringWithFormat:@"%.4f", coordinateRatio.y];
            locationModel.y = [NSDecimalNumber decimalNumberWithString:offsetYStr];
            locationModel.x = [NSDecimalNumber decimalNumberWithString:offsetXStr];
        }
    }

    @weakify(self);
    [AWEStickerLyricStyleManager fetchOrQueryCachedLyricRelatedEffectList:AWEStickerLyricStylePanelStr completion:
     ^(NSError * _Nonnull error, NSArray<IESEffectModel *> * _Nonnull effects) {
        @strongify(self);
        if (!error && effects.count > 0) {
            IESEffectModel *firstEffectModel = [effects firstObject];
            
            void (^addLyricsStickerBlock)(void) = ^{
                @strongify(self);
                // 应用歌词贴纸前需要先将效果移动到草稿目录中，否则 Effect 资源很可能被移除，导致添加不成功
                [ACCDraft() saveInfoStickerPath:firstEffectModel.filePath
                                        draftID:self.repository.repoDraft.taskID
                                     completion:^(NSError *draftError, NSString *draftStickerPath) {
                    if (draftError || ACC_isEmptyString(draftStickerPath)) {
                        [ACCToast() showError:ACCLocalizedCurrentString(@"error_retry")];
                        AWELogToolError(AWELogToolTagEdit, @"select lyrics sticker from musicPanel and save draft failed: %@", draftError);
                        return;
                    }
                    
                    @strongify(self);
                    [self p_addLyricsSticker:firstEffectModel
                                        path:draftStickerPath
                                     tabName:@"musicPanel"
                                  completion:^(NSInteger stickerId) {
                        @strongify(self);
                        [self.viewModel sendUpdateLyricsStickerButtonSignal:ACCMusicPanelLyricsStickerButtonChangeTypeEnable];
                        [self p_showLyricsStickerHint];
                    }];
                }];
            };
            
            if (firstEffectModel.downloaded) {
                addLyricsStickerBlock();
            } else {
                [EffectPlatform downloadEffect:firstEffectModel
                                      progress:NULL
                                    completion:
                 ^(NSError * _Nullable error, NSString * _Nullable filePath) {
                    if (error) {
                        AWELogToolError(AWELogToolTagMusic, @"Download effectmodel failed, error: %@", error);
                    }
                    
                    addLyricsStickerBlock();
                }];
            }
        }
        else{
            AWELogToolError(AWELogToolTagMusic, @"Set lyric sticker failed, error: %@", error);
            [self.viewModel sendUpdateLyricsStickerButtonSignal:ACCMusicPanelLyricsStickerButtonChangeTypeReset];
        }
    }];
}

- (void)p_setLyricStickerIDInPublishModel
{
    [self.repository.repoVideoInfo.video.infoStickers
     enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.isSrtInfoSticker) {
            self.repository.repoSticker.currentLyricStickerID = obj.userinfo[kACCStickerIDKey];
            *stop = YES;
        }
    }];
}


- (void)p_checkMusicOrShowLyricMusicViewControllerWithCompletion:(void (^)(NSString *formatLyricStr, NSError *error))completion
{
    @weakify(self);
    dispatch_async(dispatch_get_main_queue(), ^{
        @strongify(self);
        // 二期优化，服务端要求每次添加歌词贴纸时再去请求music/detail来确保有歌词
        [IESAutoInline(self.serviceProvider, ACCMusicNetServiceProtocol)
         requestMusicItemWithID:self.repository.repoMusic.music.musicID
         completion:^(id<ACCMusicModelProtocol> _Nullable model, NSError * _Nullable error) {
            if (error) {
                AWELogToolError(AWELogToolTagEdit, @"lyrics sticker fetch music detail failed: %@", error);
            }
            
            id<ACCMusicModelProtocol> musicModel = self.repository.repoMusic.music;
            if (model && !error) {
                musicModel = model;
            }
            
            [self p_checkMusicOrShowLyricMusicViewControllerWithMusicModel:musicModel
                                                                completion:completion];
        }];

    });
}

- (void)p_updateMusicLyricStickerAudioRange:(HTSAudioRange)audioRange
{
    [self.lyricStickerViewController updatePlayerModelAudioRange:audioRange];
}

- (void)p_addLyricOnEditPageShowWithMusicId:(NSString *)musicId baseMusicModel:(id<ACCMusicModelProtocol>)baseMusicModel
{
    if (!musicId ||
        self.isKaraoke ||
        [self.viewModel hasAlreadyAddLyricSticker] ||
        self.repository.repoDuet.isDuet ||
        self.repository.repoContext.videoType == AWEVideoTypePhotoMovie ||
        [self.repository.repoUploadInfo isAIVideoClipMode]) {
        return;
    }
    
    @weakify(self);
    [IESAutoInline(self.serviceProvider, ACCMusicNetServiceProtocol)
     requestMusicItemWithID:musicId
     completion:^(id<ACCMusicModelProtocol> _Nullable model, NSError * _Nullable error) {
        @strongify(self);
        if (error) {
            AWELogToolError(AWELogToolTagEdit, @"lyrics sticker fetch music detail failed: %@", error);
        }
        
        id<ACCMusicModelProtocol> musicModel = baseMusicModel;
        if (model && !error) {
            musicModel = model;
        }
        
        [self p_addLyricOnEditPageShowWithMusicModel:musicModel];
    }];
}

- (void)p_applyLyricsSticker:(NSInteger)stickerId
{
    if (stickerId < 0) {
        return;
    }
    
    [self.editService.sticker setSticker:stickerId
                               startTime:0
                                duration:kAWELyricsStickerTotalDuration];
    
    CGSize stickerSize = [self.editService.sticker getInfoStickerSize:stickerId];
    IESInfoStickerProps *props = [IESInfoStickerProps new];
    [self.editService.sticker getStickerId:stickerId props:props];
    [self.editService.sticker setStickerAboveForInfoSticker:stickerId];
    
    props.startTime = 0;
    props.duration = [self.repository.repoVideoInfo.video totalVideoDuration];
    
    // 歌词创建贴纸逻辑
    [self p_applyLyricsStickerWithId:stickerId
                               props:props
                            editSize:stickerSize
                         configBlock:nil];
    
    // https://jira.bytedance.com/browse/AME-94403
    // TOOD: 从音乐面板添加的歌词贴纸不发送收起贴纸面板信号
    if (self.isFromMusicPanel) {
        self.isFromMusicPanel = NO;
    } else {
        !self.dismissPanelHandle ?: self.dismissPanelHandle(ACCStickerTypeLyricSticker, NO);
        self.dismissPanelHandle = nil;
    }
}

- (void)p_addLyricOnEditPageShowWithMusicModel:(id<ACCMusicModelProtocol>)musicModel
{
    BOOL hasValidMusic = musicModel && musicModel.dmvAutoShow && !ACC_isEmptyString(musicModel.lyricUrl);
    if (!hasValidMusic || [self.viewModel hasAlreadyAddLyricSticker]) {
        return;
    }
    //从草稿恢复的&&不是从拍摄页过来的的不添加
    BOOL enterFromShoot = self.repository.repoContext.enterFromShoot;
    if (self.repository.repoDraft.originalModel &&
        (!enterFromShoot && self.isFirstTimeToCallAddLyricOnEditPageShowWithMusicId)) {
        return;
    }
    
    /* issues : AME-72040
     * The music model passed in the recording page('A model') is inconsistent with the model from the music details('B model')
     * e.g. The parameters: 'lyric' and 'previewStartTime' of the  'A model' are different from 'B model'
     * Sticker component using 'B model's lyricUrl to download lyric file, but use 'A model's other parameters like previewStartTime, is inconsistent！
     * So need update original music model ，keep consistent.
     **/
    self.repository.repoMusic.music = musicModel;
    
    @weakify(self);
    void(^applyAddInfoStickerBlock)(IESEffectModel *effectModel) = ^(IESEffectModel *effectModel) {
        @strongify(self);
        if ([self.viewModel hasAlreadyAddLyricSticker]) {
            return;
        }
        
        [self p_addLyricsSticker:effectModel
                            path:effectModel.filePath
                         tabName:nil
                      completion:^(NSInteger stickerId) {
            @strongify(self);
            [self p_showLyricsStickerHint];
        }];
    };
    
    [AWEStickerLyricStyleManager fetchOrQueryCachedLyricRelatedEffectList:AWEStickerLyricStylePanelStr completion:
     ^(NSError * _Nonnull error, NSArray<IESEffectModel *> * _Nonnull effects) {
        if (!error && effects.count > 0) {
            IESEffectModel *firstEffectModel = [effects firstObject];
            
            if (firstEffectModel.downloaded) {
                ACCBLOCK_INVOKE(applyAddInfoStickerBlock, firstEffectModel);
            } else {
                [EffectPlatform downloadEffect:firstEffectModel
                                      progress:NULL
                                    completion:
                 ^(NSError * _Nullable error, NSString * _Nullable filePath) {
                    if (error) {
                        AWELogToolError(AWELogToolTagEdit, @"lyrics sticker download effect failed: %@",
                                        error);
                    }
                    
                    ACCBLOCK_INVOKE(applyAddInfoStickerBlock, firstEffectModel);
                }];
            }
        } else {
            AWELogToolError(AWELogToolTagEdit, @"lyrics sticker fetch effect failed: %@",
                            error);
        }
    }];
}

- (void)p_downloadFontForLyricSticker
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [AWEStickerLyricFontManager downloadLyricFontIfNeeded];
    });
}

- (void)p_checkMusicOrShowLyricMusicViewControllerWithMusicModel:(id<ACCMusicModelProtocol>)musicModel
                                                      completion:(void (^)(NSString *formatLyricStr, NSError *error))completion
{
    BOOL hasMusicLyric = musicModel && musicModel.lyricUrl.length > 0;
    NSNumber *musicStickerId = [self.editService.sticker filterMusicLyricStickerId];
    BOOL hasMusicLyricSticker = musicStickerId != nil && musicStickerId.integerValue != NSIntegerMin;
    
    // 1. 从草稿恢复的歌词贴纸可能没有歌词信息了，会重新弹出歌词选择界面
    // 2. 当歌词选择样式面板开启的时候，切换歌词样式不会弹出歌词选择界面
    if ((hasMusicLyric && !hasMusicLyricSticker) || self.lyricStickerViewController.lyricPanelView.showing) {
        [ACCLyricsStickerUtils formatMusicLyricWithACCMusicModel:musicModel completion:completion];
    } else {
        [[self viewModel] sendWillShowLyricMusicSelectPanelSignal];
        if (self.repository.repoDraft.isDraft && self.isFirstTimeToCallPresentMusicStickerSearchVCFromLyricEdit) {
            if ([self.viewModel hasAlreadyAddLyricSticker]) {
                self.isFirstTimeToCallPresentMusicStickerSearchVCFromLyricEdit = NO;
                return;
            }
        }
        
        if (self.viewModel.musicLyricVCPresented) {
            return;
        }
        self.viewModel.musicLyricVCPresented = YES;
        
        @weakify(self);
        [self.transitionService setPreviousPage:NSStringFromClass([ACCEditLyricsStickerViewController class])];
        [self.lyricStickerViewController presentMusicStickerSearchVCFromLyricEdit:NO completion:
         ^(id<ACCMusicModelProtocol> musicModel, NSError *error, BOOL dismiss) {
            @strongify(self);
            self.viewModel.musicLyricVCPresented = NO;
            
            if (error) {
                AWELogToolError2(@"lyrics", AWELogToolTagEdit, @"present and select music failed: %@", error);
            }
            
            [self.transitionService setPreviousPage:nil];
            [self.editService.preview continuePlay];
            
            if (dismiss) {
                [[self viewModel] sendDidCancelLyricMusicSelectSignal];
                // update lyric sticker button state on music panel
                BOOL hasAddLyric = [self.viewModel hasAlreadyAddLyricSticker];
                [self.viewModel sendUpdateLyricsStickerButtonSignal:hasAddLyric ? ACCMusicPanelLyricsStickerButtonChangeTypeEnable: ACCMusicPanelLyricsStickerButtonChangeTypeReset];
            } else {
                if (!error) {
                    [self.viewModel sendDidSelectMusicSignal:musicModel];
                }
                [self.viewModel sendUpdateMusicRelateUISignal];
                [ACCLyricsStickerUtils formatMusicLyricWithACCMusicModel:musicModel completion:completion];
                [self.lyricStickerViewController.lyricPanelView resetStickerPanelState];
                
                if (musicModel) {
                    acc_dispatch_main_async_safe(^{
                        [self.viewModel sendUpdateMusicRelateUISignal];
                    });
                }
            }
        }];
    }
}

- (void)p_didAddMusic:(id<ACCMusicModelProtocol>)music withRemoveLyricSticker:(BOOL)removeLyricSticker
{
    if ((removeLyricSticker && [self.viewModel hasAlreadyAddLyricSticker]) ||
        (self.musicService.musicPanelShowing && self.isRecordLyricSticker)) {
        if (music.lyricUrl) {
            [self.viewModel sendUpdateLyricsStickerButtonSignal:ACCMusicPanelLyricsStickerButtonChangeTypeUnenable];
            [self p_removeMusicLyricSticker];
            [self.lyricStickerViewController.lyricPanelView resetStickerPanelState];
            
            
            [self p_addLyricStickerFromMusicPanelWithMusic:music coordinateRatio:nil];
            self.isRecordLyricSticker = NO;
        } else {
            [self p_removeMusicLyricSticker];
            [self.lyricStickerViewController.lyricPanelView resetStickerPanelState];
            self.isRecordLyricSticker = YES;
        }
    }
}

- (void)p_recoveryLyricsStickerIfNeeded
{
    
    if (!self.isKaraoke && (self.repository.repoDraft.isDraft ||
         self.repository.repoDraft.isBackUp ||
         self.repository.repoImageAlbumInfo.isTransformedFromImageAlbumMVVideoEditMode || [self.repository.repoSmartMovie transformedForSmartMovie])) {
        
        BOOL hasBeforeEdgeData = self.repository.repoVideoInfo.video.infoStickerAddEdgeData ? YES : NO;
        BOOL hasAfterEdgeData = hasBeforeEdgeData;
        BOOL hasStickers = NO;
        
        if (!ACC_isEmptyArray(self.repository.repoVideoInfo.video.infoStickers)) {
            [self p_recoveryLyricsSticker];
            hasStickers = YES;
        }
        
        AWELogToolInfo2(@"resolution",
                        AWELogToolTagEdit,
                        @"restore canvas has Stickers:%d, isDraft:%d, isBackUp:%d, hasBeforeEdgeData:%d, hasAfterEdgeData:%d",
                        hasStickers,
                        self.repository.repoDraft.isDraft,
                        self.repository.repoDraft.isBackUp,
                        hasBeforeEdgeData,
                        hasAfterEdgeData);
    }
}

- (void)p_recoveryLyricsSticker
{
    [[self.repository.repoVideoInfo.video.infoStickers btd_filter:^BOOL(IESInfoSticker * _Nonnull obj) {
        return obj.isSrtInfoSticker;
    }] btd_forEach:^(IESInfoSticker * _Nonnull stickerInfo) {
        // 歌词贴纸，贴纸恢复
        [self p_recoveryLyricsStickerWithStickerInfo:stickerInfo];
    }];
}

- (void)p_updateFontIfNeeded
{
    if ([self.viewModel hasAlreadyAddLyricSticker]) {
        for (IESInfoSticker *infoSticker in self.viewModel.repository.repoVideoInfo.video.infoStickers) {
            if (infoSticker.isSrtInfoSticker) {
                NSString *effectID = infoSticker.userinfo[kACCStickerIDKey] ?: @"";
                IESEffectModel *lyricEffect = [AWEStickerLyricStyleManager cachedEffectModelForEffectID:effectID panel:AWEStickerLyricStylePanelStr];
                
                if (lyricEffect.extra == nil) {
                    continue;
                }
                
                NSString *fontName = [AWEStickerLyricFontManager formatFontDicWithJSONStr:lyricEffect.extra ? : @""];
                IESEffectModel *fontEffect = [AWEStickerLyricFontManager effectModelWithFontName:fontName];
                
                @weakify(self)
                [ACCDraft() saveInfoStickerPath:fontEffect.filePath
                                        draftID:self.repository.repoDraft.taskID
                                     completion:^(NSError *draftError, NSString *draftStickerPath) {
                    @strongify(self);
                    if (draftError) {
                        AWELogToolError(AWELogToolTagEdit, @"saveInfoStickerPath error: %@", draftError);
                    }
                    
                    [self.editService.sticker setSrtFont:infoSticker.stickerId
                                                fontPath:draftStickerPath ? : @""];
                }];
            }
        }
    }
}

- (void)p_showLyricsStickerHint
{
    // 歌词贴纸，显示提示框
    UIView<ACCStickerProtocol> *lyricStickerWrapper =
    [[self.stickerService.stickerContainer allStickerViews] btd_find:^BOOL(ACCStickerViewType  _Nonnull obj) {
        return [obj.contentView isKindOfClass:ACCLyricsStickerContentView.class];
    }];
    
    if (lyricStickerWrapper) {
        // !!!IMPORTANT: 需要延时更新提示信息，原因是不能立即获取到歌词贴纸的位置
        @weakify(self);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            @strongify(self);
            [self p_showHintViewWithStickerWrapperView:lyricStickerWrapper];
        });
    }
}

#pragma mark - ChallengeBinding(Private)

- (void)p_bindChallengeWithChallengeId:(NSString *)challengeId
{
    if (ACC_isEmptyString(challengeId)) {
        // 有可能是从音乐面板恢复的 不带贴纸的话题 那就从缓存里取
        challengeId = self.lyricStickerChallengeId;
    }
    self.lyricStickerChallengeId = challengeId;
    [[self challengeBindViewModel] updateCurrentBindChallengeWithId:challengeId
                                                          moduleKey:kChallengeBindLyricStickerModuleKey];
}

- (void)p_removeBindChallenge
{
    if (ACC_isEmptyString(self.lyricStickerChallengeId)) {
        // 删除之前先从本地取下歌词贴纸带的话题id，因为有可能 下次从草稿恢复 又从音乐面板恢复歌词的case
        self.lyricStickerChallengeId = [[self challengeBindViewModel] currentBindChallegeSetsWithModuleKey:kChallengeBindLyricStickerModuleKey].firstObject.itemID;
    }
    
    [[self challengeBindViewModel] updateCurrentBindChallenges:nil
                                                     moduleKey:kChallengeBindLyricStickerModuleKey];
}

#pragma mark - Container

- (void)p_showHintViewWithStickerWrapperView:(ACCStickerViewType)wrapperView
{
    if (![self.viewModel hasAlreadyAddLyricSticker]) {
        return;
    }
    
    // 先更新坐标，防止提示位置不对
    [ACCLyricsStickerUtils updateFrameForLyricsStickerWrapperView:wrapperView
                                               editStickerService:self.editService.sticker];
    
    if (!self.hintView.superview) {
        [self.viewContainer.rootView addSubview:self.hintView];
    }
    [self.hintView showHint:ACCLocalizedString(@"creation_edit_sticker_lyrics_stciker_tap", @"点击更换样式")
                   animated:NO
                autoDismiss:NO];
    
    CGSize size = [self.hintView intrinsicContentSize];
    CGFloat x = wrapperView.frame.origin.x;
    CGFloat y = wrapperView.frame.origin.y -
                kVideoStickerEditViewPadding -
                size.height +
                kAWEStickerContainerViewHintAnimationYOffset;
    
    if (self.hintView.superview) {
        ACCMasReMaker(self.hintView, {
            make.size.equalTo(@(size));
            make.left.equalTo(@(x));
            make.top.equalTo(@(y));
        });
    }
    
    [self.hintView.superview setNeedsLayout];
    [self.hintView.superview layoutIfNeeded];
    
    self.hintView.alpha = 0.f;
    [UIView animateWithDuration:0.3 animations:^{
        self.hintView.alpha = 1.f;
        ACCMasUpdate(self.hintView, {
            make.top.equalTo(@(y - kAWEStickerContainerViewHintAnimationYOffset));
        });
        
        [self.hintView.superview setNeedsLayout];
        [self.hintView.superview layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self performSelector:@selector(p_dismissHintView) withObject:nil afterDelay:3.f];
    }];
}

- (void)p_dismissHintTextWithAnimation:(BOOL)animated
{
    [self.hintView dismissWithAnimation:animated];
    [NSObject cancelPreviousPerformRequestsWithTarget:self
                                             selector:@selector(p_dismissHintView)
                                               object:nil];
}

- (void)p_dismissHintView
{
    [UIView animateWithDuration:0.3 animations:^{
        self.hintView.alpha = 0.f;
        self.hintView.frame = CGRectOffset(self.hintView.frame,
                                           0, kAWEStickerContainerViewHintAnimationYOffset);
    } completion:^(BOOL finished) {
        [self.hintView dismissWithAnimation:NO];
    }];
}

- (ACCStickerViewType)p_applyLyricsStickerWithId:(NSInteger)stickerId
                                           props:(IESInfoStickerProps *)props
                                        editSize:(CGSize)editSize
                                     configBlock:(nullable void(^)(ACCLyricsStickerConfig *config))configBlock
{
    if (stickerId < 0) {
        return nil;
    }
    [self.editService.sticker setSticker:stickerId
                               startTime:0
                                duration:kAWELyricsStickerTotalDuration];
    
    CGSize stickerSize = editSize;
    if (CGSizeEqualToSize(stickerSize, CGSizeZero) &&
        props.scale > CGFLOAT_MIN) {
        stickerSize = [self.editService.sticker getstickerEditBoxSize:stickerId];
        stickerSize = CGSizeMake(stickerSize.width/props.scale, stickerSize.height/props.scale);
    }
    
    ACCLyricsStickerConfig *config = [[ACCLyricsStickerConfig alloc] init];
    config.hierarchyId = @(ACCStickerHierarchyTypeVeryLow);
    config.typeId = ACCStickerTypeIdLyric;
    config.timeRangeModel.pts = [NSDecimalNumber decimalNumberWithString:@"-1"];
    {
        NSString *startTime = [NSString stringWithFormat:@"%.4f", 0.f];
        NSString *endTime = [NSString stringWithFormat:@"%.4f", (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeNone ? self.repository.repoVideoInfo.video.totalVideoDuration : 9999) * 1000];
        config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
        config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
    }
    
    config.minimumScale = 1;
    config.boxMargin = UIEdgeInsetsMake(10, 10, 10, 10);
    config.boxPadding = UIEdgeInsetsMake(6, 6, 6, 6);
    config.changeAnchorForRotateAndScale = NO;
    config.gestureInvalidFrameValue = self.repository.repoSticker.gestureInvalidFrameValue;
    config.showSelectedHint = NO;
    config.preferredContainerFeature = ACCStickerContainerFeatureAdsorbing |
    ACCStickerContainerFeatureAngleAdsorbing |
    ACCStickerContainerFeatureHighlightMoment;
    
    ACCLyricsStickerContentView *contentView =
    [[ACCLyricsStickerContentView alloc] initWithFrame:CGRectMake(0, 0, stickerSize.width, stickerSize.height)];
    contentView.center = self.editService.mediaContainerView.center;
    contentView.config = config;
    contentView.stickerId = stickerId;
    contentView.stickerInfos = props;
    
    @weakify(self, contentView);
    contentView.transparentChanged = ^(BOOL transparent) {
        @strongify(self, contentView);
        [self.editService.sticker setSticker:contentView.stickerId
                                       alpha:(transparent? 0.34: 1.0)];
        if (!transparent) {
            [self.editService.sticker setStickerAboveForInfoSticker:contentView.stickerId];
        }
    };
    
    config.gestureCanStartCallback =
    ^BOOL(__kindof ACCBaseStickerView * _Nonnull wrapperView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        if (![gesture isKindOfClass:UITapGestureRecognizer.class]) {
            // 临时设置预览为60帧渲染，用于低帧率的视频渲染信息化贴纸出现卡顿的场景
            [self.editService.preview setHighFrameRateRender:YES];
            
            if ([[wrapperView contentView] conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
                ACCLyricsStickerContentView *contentView = (id)[wrapperView contentView];
                [self p_trackEvent:@"prop_adjust" params:@{
                    @"enter_from" : @"video_edit_page",
                    @"prop_id" : contentView.stickerInfos.userInfo[kACCStickerIDKey] ? : @"",
                    @"enter_method" : @"finger_gesture"
                }];
            }
        }
        
        // 歌词贴纸，隐藏 hint，不做动画，立即消失
        [self p_dismissHintTextWithAnimation:NO];
        return YES;
    };
    
    config.gestureEndCallback =
    ^(__kindof ACCBaseStickerView * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
        @strongify(self);
        if (![gesture isKindOfClass:UITapGestureRecognizer.class]) {
            // fix 操作（pinch、pan）贴纸结束，闪屏的问题。
            [self.editService.preview setHighFrameRateRender:NO];
        }
    };
    
    id tapAction =
    ^(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> *wrapperView, UITapGestureRecognizer *gesture) {
        @strongify(self);
        if ([[wrapperView contentView] conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
            UIView<ACCStickerEditContentProtocol> *cmpContent = (UIView<ACCStickerEditContentProtocol> *)[wrapperView contentView];
            cmpContent.transparent = NO;
            [self p_trackEvent:@"prop_more_click" params:@{
                @"enter_from" : @"video_edit_page",
                @"is_diy_prop": @(NO)
            }];
        }
        
        ACCLyricsStickerContentView *contentView = (ACCLyricsStickerContentView *)[wrapperView contentView];
        [self p_startEditLyricSticker:contentView.stickerId];
    };
    
    config.secondTapCallback = tapAction;
    config.onceTapCallback = tapAction;
    
    config.externalHandlePanGestureAction =
    ^(__kindof UIView<ACCStickerProtocol> * _Nonnull theView, CGPoint point) {
        @strongify(self);
        CGFloat offsetX = [theView.stickerGeometry.x floatValue];
        CGFloat offsetY = -[theView.stickerGeometry.y floatValue];
        
        ACCLyricsStickerContentView *contentView = (ACCLyricsStickerContentView *)theView.contentView;
        contentView.transparent = NO;
        CGFloat stickerAngle = contentView.stickerInfos.angle;
        offsetX = ACCRTL().isRTL ? -offsetX : offsetX;
                stickerAngle = ACCRTL().isRTL ? -stickerAngle : stickerAngle;
        
        offsetX -= contentView.beginOrigin.x;
        offsetY -= contentView.beginOrigin.y;
        [self.editService.sticker setSticker:contentView.stickerId
                                     offsetX:offsetX
                                     offsetY:offsetY
                                       angle:stickerAngle
                                       scale:1];
        
        contentView.stickerInfos.offsetX = offsetX;
        contentView.stickerInfos.offsetY = offsetY;
    };
    
    config.externalHandlePinchGestureeAction =
    ^(__kindof UIView<ACCStickerProtocol> * _Nonnull theView, CGFloat scale) {
        @strongify(self);
        ACCLyricsStickerContentView *contentView = (ACCLyricsStickerContentView *)theView.contentView;
        contentView.transparent = NO;
        
        [self.editService.sticker setSticker:contentView.stickerId
                                     offsetX:contentView.stickerInfos.offsetX
                                     offsetY:contentView.stickerInfos.offsetY
                                       angle:contentView.stickerInfos.angle
                                       scale:scale];
        
        IESInfoStickerProps *props = [IESInfoStickerProps new];
        [self.editService.sticker getStickerId:contentView.stickerId props:props];
        contentView.stickerInfos = props;
    };
    
    config.externalHandleRotationGestureAction =
    ^(__kindof UIView<ACCStickerProtocol> * _Nonnull theView, CGFloat rotation) {
        @strongify(self);
        ACCLyricsStickerContentView *contentView = (ACCLyricsStickerContentView *)theView.contentView;
        contentView.transparent = NO;
        CGFloat stickerAngle = rotation * 180.0 / M_PI;        
        [self.editService.sticker setStickerAngle:contentView.stickerId
                                             angle:stickerAngle];
        
        contentView.stickerInfos.angle = rotation * 180.0 / M_PI;
    };
    
    config.willDeleteCallback = ^{
        @strongify(self, contentView);
        if (self.discardUnselectTrackEvent) {
            self.discardUnselectTrackEvent = NO;
        } else {
            [self p_trackEvent:@"prop_delete" params:@{
                @"enter_from" : self.repository.repoTrack.enterFrom ?: @"",
                @"prop_id" : contentView.stickerInfos.userInfo[kACCStickerIDKey] ? : @"",
            }];
        }
        
        NSInteger removeIdx = [self.repository.repoSticker.infoStickerArray
                               btd_firstIndex:^BOOL(AWEInfoStickerInfo * _Nonnull obj) {
            return obj.stickerID.integerValue == contentView.stickerId;
        }];
        
        if (removeIdx != NSNotFound) {
            [self.repository.repoSticker.infoStickerArray removeObjectAtIndex:removeIdx];
            [[NSNotificationCenter defaultCenter] postNotificationName:ACCVideoChallengeChangeKey
                                                                object:nil];
        }
        
        [self.editService.sticker removeInfoSticker:contentView.stickerId];
    };
    
    !configBlock ?: configBlock(config);
    
    ACCStickerViewType stickerWrapper = [self.stickerService.stickerContainer addStickerView:contentView
                                                                                      config:config];
    stickerWrapper.stickerGeometry.preferredRatio = NO;
    
    return stickerWrapper;
}

- (void)p_recoveryLyricsStickerWithStickerInfo:(IESInfoSticker *)lyricsStickerInfo
{
    IESInfoStickerProps *props = [IESInfoStickerProps new];
    [self.editService.sticker getStickerId:lyricsStickerInfo.stickerId props:props];
    
    CGFloat videoDuration = self.repository.repoVideoInfo.video.totalVideoDuration;
    props.duration = (props.duration < 0 || props.duration > videoDuration) ? videoDuration : props.duration;
    props.offsetX = isnan(props.offsetX) ? 0 : props.offsetX;
    props.offsetY = isnan(props.offsetY) ? 0 : props.offsetY;
    
    [self p_applyLyricsStickerWithId:lyricsStickerInfo.stickerId
                               props:props
                            editSize:CGSizeZero
                         configBlock:^(ACCLyricsStickerConfig *config) {
        // 贴纸坐标不需要在这里恢复，手势开始的时候会自动恢复
        NSString *startTime = [NSString stringWithFormat:@"%.4f", props.startTime * 1000];
        NSString *endTime = [NSString stringWithFormat:@"%.4f", (props.startTime+props.duration) * 1000];
        config.timeRangeModel.startTime = [NSDecimalNumber decimalNumberWithString:startTime];
        config.timeRangeModel.endTime = [NSDecimalNumber decimalNumberWithString:endTime];
    }];
}

- (void)p_updateEditLyricsViewControllerWithStickerId:(NSInteger)stickerEditId
{
    self.lyricStickerViewController.inputData.stickerId = stickerEditId;
    self.lyricStickerViewController.inputData.repository = self.repository;
    
    // 拷贝容器
    ACCStickerContainerView *stickerContainer = [self.stickerService.stickerContainer copyForContext:@"" modConfig:^(NSObject<ACCStickerContainerConfigProtocol> * _Nonnull config) {
        // 移除除编辑歌词贴纸相关插件以外的插件
        if ([config isKindOfClass:ACCVideoEditStickerContainerConfig.class]) {
            ACCVideoEditStickerContainerConfig *rConfig = (id)config;
            [rConfig removePluginsExceptEditLyrics];
        }
    } modContainer:^(ACCStickerContainerView * _Nonnull container) {
        [container configWithPlayerFrame:self.stickerService.stickerContainer.playerFrame.CGRectValue allowMask:NO];
    } enumerateStickerUsingBlock:^(__kindof ACCBaseStickerView * _Nonnull stickerView, NSUInteger idx, ACCStickerGeometryModel * _Nonnull geometryModel, ACCStickerTimeRangeModel * _Nonnull timeRangeModel) {
        geometryModel.preferredRatio = NO;
        stickerView.stickerGeometry.preferredRatio = NO;
    }];
    [stickerContainer setShouldHandleGesture:YES];
    ((ACCEditLyricsStickerViewController *)self.lyricStickerViewController).inputData.stickerContainer = stickerContainer;
}

#pragma mark - Tracker

- (void)p_trackEvent:(NSString *)event params:(NSDictionary *)params
{
    if (self.repository.repoContext.recordSourceFrom == AWERecordSourceFromIM ||
        self.repository.repoContext.recordSourceFrom == AWERecordSourceFromIMGreet) {
        return;
    }
    
    NSMutableDictionary *dict = [self.repository.repoTrack.referExtra mutableCopy];
    [dict addEntriesFromDictionary:params];
    [ACCTracker() trackEvent:event params:dict needStagingFlag:NO];
}

#pragma mark - view model

- (ACCEditLyricStickerViewModel *)viewModel
{
    if (!_viewModel) {
        _viewModel = [[ACCEditLyricStickerViewModel alloc] init];
    }
    return _viewModel;
}

// TODO: 话题重构后移除
- (ACCVideoEditChallengeBindViewModel *)challengeBindViewModel
{
    return [self getViewModel:ACCVideoEditChallengeBindViewModel.class];
}

#pragma mark - handler
- (ACCLyricsStickerHandler *)lyricsStickerHandler
{
    if (!_lyricsStickerHandler) {
        _lyricsStickerHandler = [[ACCLyricsStickerHandler alloc] init];
        @weakify(self);
        _lyricsStickerHandler.onExpressLyricsSticker = ^(ACCEditorLyricsStickerConfig * _Nonnull stickerConfig) {
            @strongify(self);
            [self p_addLyricStickerFromExpressWithLyricsEditorConfig:stickerConfig];
        };
    }
    return _lyricsStickerHandler;
}

#pragma mark - ACCEditLyricsStickerDatasource

- (void)editLyricsViewController:(ACCEditLyricsStickerViewController *)viewControler addLyricsSticker:(IESEffectModel *)sticker path:(NSString *)path tabName:(NSString *)tabName completion:(void (^)(NSInteger))completion
{
    [self p_addLyricsSticker:sticker path:path tabName:tabName completion:completion];
}

- (void)editLyricsViewControllerRemoveMusicLyricSticker:(ACCEditLyricsStickerViewController *)viewControler
{
    [self p_removeMusicLyricSticker];
}

#pragma mark - ACCEditLyricsStickerDelegate

- (void)editLyricsViewControllerAddAudioClipView:(ACCEditLyricsStickerViewController *)viewControler
{
    [self.viewModel sendAddClipViewSignal];
}

- (void)editLyricsViewControllerShowAudioClipView:(ACCEditLyricsStickerViewController *)viewControler
{
    [self.viewModel sendShowClipViewSignal];
}

- (void)editLyricsViewControllerClipMusic:(HTSAudioRange)audioRange repeatCount:(NSInteger)repeatCount
{
    [self.viewModel sendDidFinishCutMusicSignal:audioRange repeatCount:repeatCount];
}

- (void)editLyricsViewController:(ACCEditLyricsStickerViewController *)viewControler
                  didSelectMusic:(nullable id<ACCMusicModelProtocol>)music
                           error:(nullable NSError *)error
{
    if (error) {
        AWELogToolError2(@"lyrics", AWELogToolTagEdit, @"select music failed: %@", error);
    } else {
        [self.viewModel sendDidSelectMusicSignal:music];
    }
    [self.viewModel sendUpdateMusicRelateUISignal];
}

- (void)editLyricsViewControllerDidDismiss:(ACCEditLyricsStickerViewController *)viewControler
{
    [self.editService.preview resetPlayerWithViews:@[self.editService.mediaContainerView]];
    [[self stickerService] finishEditingStickerOfType:ACCStickerTypeLyricSticker];
}

#pragma mark - Accessories

- (AWEEditStickerHintView *)hintView
{
    if (!_hintView) {
        _hintView = [AWEEditStickerHintView new];
    }
    return _hintView;
}

- (ACCEditLyricsStickerViewController *)lyricStickerViewController
{
    if (!_lyricStickerViewController) {
        ACCEditLyricsStickerInputData *inputData = [[ACCEditLyricsStickerInputData alloc] init];
        inputData.editService = self.editService;
        inputData.repository = self.repository;
        inputData.originalPlayerViewContainerViewFrame = self.editService.mediaContainerView.editPlayerFrame;
        inputData.containerViewController = self.controller.root;
        inputData.draftService = self.draftService;
        if (self.repository.repoVideoInfo.canvasType == ACCVideoCanvasTypeMusicStory) {
            inputData.disableChangeMusic = YES;
        }
        
        ACCEditLyricsStickerViewController *editLyricViewController =
        [[ACCEditLyricsStickerViewController alloc] initWithInputData:inputData datasource:self];
        editLyricViewController.delegate = self;
        _lyricStickerViewController = editLyricViewController;
    }
    return _lyricStickerViewController;
}

#pragma mark - ACCDraftResourceRecoverProtocol

+ (NSArray<NSString *> *)draftResourceIDsToDownloadForPublishViewModel:(AWEVideoPublishViewModel *)publishModel
{
    if (publishModel.repoContext.videoType == AWEVideoTypeKaraoke) {
        return @[];
    }
    return [[publishModel.repoVideoInfo.video.infoStickers acc_filter:^BOOL(IESInfoSticker * _Nonnull item) {
        NSString *stickerID = [item.userinfo objectForKey:kACCStickerIDKey] ?: @"";
        IESEffectModel *effectModel = [AWEStickerLyricStyleManager cachedEffectModelForEffectID:stickerID panel:AWEStickerLyricStylePanelStr];
        // 歌词贴纸，并且未下载或第一次迁移过来
        return item.isSrtInfoSticker && (ACC_isEmptyString(item.resourcePath) || effectModel == nil || effectModel.downloaded == NO);
    }] acc_mapObjectsUsingBlock:^id _Nonnull(IESInfoSticker * _Nonnull item, NSUInteger idex) {
        return [item.userinfo objectForKey:kACCStickerIDKey] ?: @"";
    }];
}

+ (void)updateRelatedResourcesFor:(IESEffectModel *)effect withPublishModel:(AWEVideoPublishViewModel *)publishModel completion:(nonnull ACCDraftRecoverCompletion)completion
{
    if ([effect isTypeMusicLyric] && !ACC_isEmptyString(effect.extra)) {
        NSString *fontName = [AWEStickerLyricFontManager formatFontDicWithJSONStr:effect.extra];
        if (!ACC_isEmptyString(fontName)) {
            [AWEStickerLyricFontManager downloadLyricFontIfNeeded];
            [AWEStickerLyricFontManager fetchLyricFontResourceWithFontName:fontName completion:^(NSError * _Nonnull error, NSString * _Nonnull fontFilePath) {
                [ACCDraft() saveInfoStickerPath:fontFilePath
                                        draftID:publishModel.repoDraft.taskID
                                     completion:^(NSError * _Nonnull draftError, NSString * _Nonnull draftStickerPath) {
                    NSString *srtFontFilePath = draftStickerPath ?: fontFilePath;
                    if (!ACC_isEmptyString(srtFontFilePath)) {
                        [[publishModel.repoVideoInfo.video.infoStickers acc_filter:^BOOL(IESInfoSticker * _Nonnull item) {
                            NSString *stickerID = [item.userinfo objectForKey:kACCStickerIDKey] ?: @"";
                            return item.isSrtInfoSticker && [effect.effectIdentifier isEqualToString:stickerID];
                        }] btd_forEach:^(IESInfoSticker * _Nonnull item) {
                            item.param.srtFontPath = srtFontFilePath;
                        }];
                    }
                }];
                ACCBLOCK_INVOKE(completion, error, NO);
            }];
            return;
        }
    }
    ACCBLOCK_INVOKE(completion, nil, NO);
}

+ (void)updateWithDownloadedEffects:(NSArray<IESEffectModel *> *)effects
                   publishViewModel:(AWEVideoPublishViewModel *)publishModel
                         completion:(nonnull ACCDraftRecoverCompletion)completion
{
    __block BOOL hasLyricSticker = NO;
    [[publishModel.repoVideoInfo.video.infoStickers acc_filter:^BOOL(IESInfoSticker * _Nonnull item) {
        return item.isSrtInfoSticker;
    }] btd_forEach:^(IESInfoSticker * _Nonnull sticker) {
        hasLyricSticker = YES;
        NSString *stickerID = [sticker.userinfo objectForKey:kACCStickerIDKey] ?: @"";
        [[effects acc_filter:^BOOL(IESEffectModel * _Nonnull item) {
            return [item isTypeMusicLyric];
        }] btd_forEach:^(IESEffectModel * _Nonnull item) {
            if ([item.effectIdentifier isEqualToString:stickerID] ||
                [item.originalEffectID isEqualToString:stickerID]) {
                [ACCDraft() saveInfoStickerPath:item.filePath
                                        draftID:publishModel.repoDraft.taskID
                                     completion:^(NSError * _Nonnull draftError, NSString * _Nonnull draftStickerPath) {
                    NSString *effectFilePath = draftStickerPath ?: item.filePath;
                    if (!ACC_isEmptyString(effectFilePath)) {
                        sticker.resourcePath = effectFilePath;
                    }
                }];
            }
        }];
    }];
    
    // 有歌词贴纸的时候刷新一下缓存
    if (hasLyricSticker) {
        [AWEStickerLyricStyleManager fetchOrQueryCachedLyricRelatedEffectList:AWEStickerLyricStylePanelStr completion:
         ^(NSError * _Nonnull error, NSArray<IESEffectModel *> * _Nonnull effects) {
            if (error) {
                AWELogToolError(AWELogToolTagDraft, @"Fetch Or Query Cached LyricStyle Effect List Error : %@", error);
            }
            
            ACCBLOCK_INVOKE(completion, nil, NO);
        }];
    } else {
        ACCBLOCK_INVOKE(completion, nil, NO);
    }
}

#pragma mark - ACCStickerMigrationProtocol

+ (BOOL)fillCrossPlatformStickerByUserInfo:(NSDictionary *)userInfo repository:(id<ACCPublishRepository>)sessionModel context:(id<ACCCrossPlatformMigrateContext>)context sticker:(NLESegmentSticker_OC *__autoreleasing *)sticker
{
    if (context.isLyricSticker) {
        
        NLESegmentSubtitleSticker_OC *sticker_ = [[NLESegmentSubtitleSticker_OC alloc] init];
        sticker_.stickerType = ACCCrossPlatformStickerTypeLyric;
        NSString *stickerID = [userInfo acc_stringValueForKey:kACCStickerIDKey];
        sticker_.effectSDKFile = [[NLEResourceNode_OC alloc] init];
        sticker_.effectSDKFile.resourceId = stickerID;
        sticker_.effectSDKFile.resourceType = NLEResourceTypeSubTitleSticker;
        sticker_.style = [NLEStyleText_OC new];
        IESEffectModel *effectModel = [[EffectPlatform sharedInstance] cachedEffectOfEffectId:stickerID];
        if (effectModel && !ACC_isEmptyString(effectModel.extra)) {
            NSString *fontName = [AWEStickerLyricFontManager formatFontDicWithJSONStr:effectModel.extra];
            IESEffectModel *fontModel = [AWEStickerLyricFontManager effectModelWithFontName:fontName];
            if (fontModel != nil) {
                sticker_.style.font = [[NLEResourceNode_OC alloc] init];
                sticker_.style.font.resourceType = NLEResourceTypeFont;
                sticker_.style.font.resourceId = fontModel.effectIdentifier;
            }
        }
        
        sticker_.extraDict = [NSMutableDictionary dictionary];
        sticker_.extraDict[@"tab_id"] = userInfo[@"tabName"];
        
        *sticker = sticker_;

        return YES;
    }
    return NO;
}

+ (void)updateUserInfo:(NSDictionary *__autoreleasing *)userInfo repoModel:(id<ACCPublishRepository>)sessionModel byCrossPlatformSlot:(nonnull NLETrackSlot_OC *)slot
{
    if (slot.sticker.stickerType == ACCCrossPlatformStickerTypeLyric) {
        NLESegmentSubtitleSticker_OC *sticker = (NLESegmentSubtitleSticker_OC *)slot.sticker;
        NSMutableDictionary *temp_userInfo = [NSMutableDictionary dictionary];
        temp_userInfo[kACCStickerIDKey] = sticker.effectSDKFile.resourceId ?: @"";
        temp_userInfo[@"tabName"] = sticker.extraDict[@"tab_id"];
        temp_userInfo[kACCStickerUUIDKey] = [NSUUID UUID].UUIDString ?: @"";
        
        // update currentLyricStickerID
        AWERepoStickerModel *stickerModel = [sessionModel extensionModelOfClass:[AWERepoStickerModel class]];
        stickerModel.currentLyricStickerID = sticker.effectSDKFile.resourceId;
        
        // resource path
        *userInfo = temp_userInfo;
    }
}

@end
