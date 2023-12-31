//
//  ACCEditLyricsStickerViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by raomengyun on 2020/12/6.
//

#import "AWERepoMusicModel.h"
#import "ACCEditLyricsStickerViewController.h"
#import "AWELyricStickerPanelView.h"
#import "ACCEditorDraftService.h"
#import "AWEEditorStickerGestureViewController.h"
#import <CreationKitArch/AWEStudioExcludeSelfView.h>
#import "ACCLyricsStickerContentView.h"
#import "ACCStickerEditContentProtocol.h"
#import "AWEXScreenAdaptManager.h"
#import "AWEStickerLyricStyleManager.h"
#import "ACCDraftProtocol.h"
#import "AWERepoVideoInfoModel.h"
#import <CreationKitInfra/ACCToastProtocol.h>
#import "ACCEditLyricStickerViewModel.h"
#import "ACCEditLyricStickerMusicSelectProtocol.h"
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>

#import <EffectPlatformSDK/EffectPlatform.h>
#import <ByteDanceKit/NSArray+BTDAdditions.h>
#import <CreativeKitSticker/ACCStickerContainerView.h>
#import <CreativeKitSticker/ACCStickerContainerProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoUploadInfomationModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/ACCRepoMVModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/AWEStoryTextImageModel.h>
#import <CreativeKit/ACCMacros.h>

@implementation ACCEditLyricsStickerInputData
@end

CGFloat const kACCEditLyricsStickerPanelHeight = 208.f;

@interface ACCEditLyricsStickerViewController ()
<AWEEditorStickerGestureViewControllerDelegate,
ACCStickerContainerDelegate,
ACCEditPreviewMessageProtocol>

@property (nonatomic, strong) ACCEditLyricsStickerInputData *inputData;

@property (nonatomic, strong) UIView *playerContainerView;
@property (nonatomic, strong) AWELyricStickerPanelView *lyricPanelView;

@property (nonatomic, strong) UIView *maskViewOne;
@property (nonatomic, strong) UIView *maskViewTwo;
@property (nonatomic, strong) UIView *maskViewThree;    // 支持全面屏适配
@property (nonatomic, strong) UIView *maskViewFour;     // 支持全面屏适配

// 本次更新的字体颜色相关的贴纸 id
@property (nonatomic, assign) NSInteger lyricsFontUpdateStickerId;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;

@end

@implementation ACCEditLyricsStickerViewController

- (instancetype)initWithInputData:(ACCEditLyricsStickerInputData *)inputData
                       datasource:(id<ACCEditLyricsStickerDatasource>)datasource
{
    self = [super init];
    if (self) {
        _inputData = inputData;
        _datasource = datasource;
    }
    return self;
}

#pragma mark - LifeCycles

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self.editService.preview addSubscriber:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self refreshUI];
    [self refreshStickerViews];
    [self showLyricsPanel];
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime
{
    for (NSArray <ACCStickerViewType> *sticker in self.inputData.stickerContainer.allStickerViews) {
        if ([sticker conformsToProtocol:@protocol(ACCPlaybackResponsibleProtocol)]) {
            [(id<ACCPlaybackResponsibleProtocol>)sticker updateWithCurrentPlayerTime:currentTime];
        }
    }
//<<<<<<< HEAD  @chenlong
//
//    [self.inputData.textContainerView updateTextViewsStatusWithCurrentPlayerTime:currentTime isSelectTime:YES];
//    if (self.inputData.publishModel.bgmAsset) {
//        CMTime startTime = [self.inputData.editService.preview.videoData audioTimeClipRangeForAsset:self.inputData.publishModel.bgmAsset].start;
//        if (self.audioClipFeatureManager.isShowingAudioClipView) {
//           [self.audioClipFeatureManager updateAudioClipViewWithTime:(currentTime + CMTimeGetSeconds(startTime))];
//        }
//    }
//=======
//>>>>>>> feature/nle
}

- (void)refreshStickerViews
{
    [[self.inputData.stickerContainer allStickerViews] btd_forEach:^(ACCStickerViewType  _Nonnull obj) {
        if ([obj.contentView isKindOfClass:ACCLyricsStickerContentView.class] &&
            (((ACCLyricsStickerContentView *)obj.contentView).stickerId == self.inputData.stickerId || self.inputData.repository.repoContext.videoType == AWEVideoTypeKaraoke)) {
            // 歌词贴纸面板，点击歌词贴纸应该是退出界面
            @weakify(self);
            obj.config.secondTapCallback =
            ^(__kindof ACCBaseStickerView * _Nonnull wrapperView, UITapGestureRecognizer * _Nonnull gesture) {
                @strongify(self);
                [self p_dismiss];
            };
            obj.config.onceTapCallback =
            ^(__kindof ACCBaseStickerView * _Nonnull wrapperView, UITapGestureRecognizer * _Nonnull gesture) {
                @strongify(self);
                [self p_dismiss];
            };
        } else {
            // 其他贴纸不允许手势操作，并且置灰
            obj.config.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
                return NO;
            };
            
            if ([obj.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
                ((UIView<ACCStickerEditContentProtocol> *)obj.contentView).transparent = YES;
            }
        }
    }];
}

- (void)refreshUI
{
    // 播放器视图设置
    [self.inputData.editService.preview resetPlayerWithViews:@[self.playerContainerView]];
    if (self.playerContainerView.superview != self.view) {
        [self.view addSubview:self.playerContainerView];
    }
    
    // 贴纸容器设置，如果有老容器会先删除老的容器
    if (self.inputData.stickerContainer.superview != self.view) {
        UIView *lastContainer = [self.view.subviews btd_find:^BOOL(__kindof UIView * _Nonnull obj) {
            return [obj isKindOfClass:ACCStickerContainerView.class];
        }];
        if (lastContainer) {
            [lastContainer removeFromSuperview];
        }
        
        // 贴纸容器
        [self.view addSubview:self.inputData.stickerContainer];
        self.inputData.stickerContainer.delegate = self;
    }
    
    // 更新拍摄器边框
    if (self.maskViewOne.superview == nil) {
        [self p_createMaskViewWithFrame:self.view.frame
                            playerFrame:self.inputData.originalPlayerViewContainerViewFrame];
    } else {
        [self.view bringSubviewToFront:self.maskViewOne];
        [self.view bringSubviewToFront:self.maskViewTwo];
        [self.view bringSubviewToFront:self.maskViewThree];
        [self.view bringSubviewToFront:self.maskViewFour];
    }
}

- (void)showLyricsPanel
{
    BOOL isUsingMVMusic = self.inputData.repository.repoContext.isMVVideo &&
        [self.inputData.repository.repoMusic.music.musicID isEqualToString:self.inputData.repository.repoMV.templateMusicId];
    BOOL isMusicLongerThanVideo = self.inputData.repository.repoMusic.music.duration.doubleValue > self.inputData.repository.repoVideoInfo.video.totalVideoDuration;
    if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) != ACCMusicLoopModeOff && !self.inputData.repository.repoUploadInfo.isAIVideoClipMode) {
        isMusicLongerThanVideo = YES;
    }
    BOOL enableClip = !isUsingMVMusic && isMusicLongerThanVideo;
    
    __block IESEffectModel *firstEffectModel;
    if (self.lyricPanelView) {
        [self.view bringSubviewToFront:self.lyricPanelView];
        firstEffectModel = self.lyricPanelView.firstEffectModel;
        self.lyricPanelView.hidden = NO;
        
        [self.lyricPanelView updateWithMusicModel:self.inputData.repository.repoMusic.music enableClip:enableClip];
        [self.lyricPanelView showWithEffectId:[self.inputData.editService.sticker filterMusicLyricEffectId]
                                        color:[self.inputData.editService.sticker filterMusicLyricColor]];
        
        if (self.lyricPanelView.isEmptyEffect) {
            @weakify(self);
            if (self.inputData.repository.repoContext.videoType == AWEVideoTypeKaraoke) {
                [AWEStickerLyricStyleManager fetchOrQueryCachedLyricRelatedEffectList:AWEStickerKaraokeLyricStylePanelStr completion:
                 ^(NSError * _Nonnull error, NSArray<IESEffectModel *> * _Nonnull effects) {
                    @strongify(self);
                    if (!error && effects.count > 0) {
                        [self.lyricPanelView updateWithEffectModels:effects];
                    } else {
                        AWELogToolError(AWELogToolTagEdit, @"lyrics sticker panel, fetch effect failed: %@", error);
                    }
                }];
            } else {
                [AWEStickerLyricStyleManager fetchOrQueryCachedLyricRelatedEffectList:AWEStickerLyricStylePanelStr completion:
                 ^(NSError * _Nonnull error, NSArray<IESEffectModel *> * _Nonnull effects) {
                    @strongify(self);
                    if (!error && effects.count > 0) {
                        [self.lyricPanelView updateWithEffectModels:effects];
                    } else {
                        AWELogToolError(AWELogToolTagEdit, @"lyrics sticker panel, fetch effect failed: %@", error);
                    }
                }];
            }
        }
        return;
    }

    const CGFloat lyricStickerPanelHeight = kACCEditLyricsStickerPanelHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
    AWELyricStickerPanelView *panelView =
    [[AWELyricStickerPanelView alloc] initWithFrame:CGRectMake(0,
                                                               self.view.frame.size.height -
                                                               lyricStickerPanelHeight,
                                                               self.view.frame.size.width,
                                                               lyricStickerPanelHeight)
                                     selectEffectId:[self.editService.sticker filterMusicLyricEffectId]
                                              color:[self.editService.sticker filterMusicLyricColor]
                                           isKaraoke:self.inputData.repository.repoContext.videoType == AWEVideoTypeKaraoke
                                     viewController:self];
    panelView.creationId = self.inputData.repository.repoContext.createId;
    panelView.shootWay = self.inputData.repository.repoTrack.referString;
    if (self.inputData.disableChangeMusic) {
        panelView.disableChangeMusic = YES;
    }
    
    CAShapeLayer *maskLayer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, lyricStickerPanelHeight)
                                               byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight
                                                     cornerRadii:CGSizeMake(12, 12)];
    maskLayer.path = [path CGPath];
    panelView.layer.mask = maskLayer;
    
    [panelView updateWithMusicModel:self.inputData.repository.repoMusic.music enableClip:enableClip];
    
    if (self.inputData.repository.repoContext.videoType == AWEVideoTypeKaraoke) {
        [AWEStickerLyricStyleManager fetchOrQueryCachedLyricRelatedEffectList:AWEStickerKaraokeLyricStylePanelStr completion:
         ^(NSError * error, NSArray<IESEffectModel *> * effects) {
            if (!error && effects.count > 0) {
                [panelView updateWithEffectModels:effects];
                firstEffectModel = effects.firstObject;
            } else {
                AWELogToolError(AWELogToolTagEdit, @"lyrics sticker panel, fetch effect failed: %@", error);
            }
        }];
    } else {
        [AWEStickerLyricStyleManager fetchOrQueryCachedLyricRelatedEffectList:AWEStickerLyricStylePanelStr completion:
         ^(NSError * error, NSArray<IESEffectModel *> * effects) {
            if (!error && effects.count > 0) {
                [panelView updateWithEffectModels:effects];
                firstEffectModel = effects.firstObject;
            } else {
                AWELogToolError(AWELogToolTagEdit, @"lyrics sticker panel, fetch effect failed: %@", error);
            }
        }];
    }
    
    @weakify(self);
    panelView.selectColorHandler = ^(AWEStoryColor * _Nonnull selectColor) {
        @strongify(self);
        NSNumber *musicLyricStickedId = [self.editService.sticker filterMusicLyricStickerId];
        if (musicLyricStickedId != nil && musicLyricStickedId.integerValue != NSIntegerMin) {
            [self p_updateLyricsStickerColorWithId:musicLyricStickedId.integerValue color:selectColor];
        }
    };
    
    panelView.selectStickerStyleHandler = ^(IESEffectModel *effectModel, AWEStoryColor *color, NSError *error) {
        @strongify(self);
        if (!error && effectModel.filePath) {
            [ACCDraft() saveInfoStickerPath:effectModel.filePath draftID:self.inputData.repository.repoDraft.taskID
                                 completion:^(NSError *draftError, NSString *draftStickerPath) {
                @weakify(self);
                if (draftError || ACC_isEmptyString(draftStickerPath)) {
                    [ACCToast() showError:ACCLocalizedCurrentString(@"error_retry")];
                    AWELogToolError(AWELogToolTagEdit, @"edit lyrics sitcker style, save draft failed: %@", draftError);
                    return;
                }
                
                [self.datasource editLyricsViewController:self
                                         addLyricsSticker:effectModel
                                                     path:draftStickerPath
                                                  tabName:nil
                                               completion:^(NSInteger stickerId) {
                    @strongify(self);
                    // !IMPORTANT: 更换贴纸样式操作会删除贴纸再添加新的贴纸，新旧贴纸 id 不同
                    // 所以这里需要重新设置容器上歌词贴纸的 id，否则更新贴纸大小会出错
                    if (self.inputData.repository.repoContext.videoType != AWEVideoTypeKaraoke) {
                        self.inputData.stickerId = stickerId;
                        UIView<ACCStickerProtocol> *stickerWrapperView =
                        [[self.inputData.stickerContainer allStickerViews] btd_find:^BOOL(ACCStickerViewType  _Nonnull obj) {
                            return [obj.contentView isKindOfClass:ACCLyricsStickerContentView.class];
                        }];
                        ((ACCLyricsStickerContentView *)stickerWrapperView.contentView).stickerId = stickerId;
                    }
                    
                    // 更新贴纸颜色
                    if (color) {
                        [self p_updateLyricsStickerColorWithId:stickerId color:color];
                    }
                }];
             }];
        } else {
            AWELogToolError(AWELogToolTagEdit, @"lyrics sticker panel, select sticker failed: %@", error);
        }
    };
    
    panelView.dismissHandler = ^{
        @strongify(self);
        [self p_dismiss];
        NSDictionary *params = @{
            @"creation_Id" : self.inputData.repository.repoContext.createId ? : @"",
            @"shoot_way" : self.inputData.repository.repoTrack.referString ? : @"",
            @"music_id" : self.inputData.repository.repoMusic.music.musicID ? : @"",
            @"color_id" : self.lyricPanelView.currentSelectColor.colorString ? : @"",
            @"dynamics" :  self.lyricPanelView.currentEffectModel.effectName ? : @""
        };
        [ACCTracker() trackEvent:@"edit_lyricsticker_complete"
                          params:params
                 needStagingFlag:NO];
    };

    void(^addLyricStickerBlock)(void) = ^{
        @strongify(self);
        // 重选歌曲会先收起选择样式面板，面板重新弹起的时候会重新给容器数据赋值，所以这里不需要改变容器的数据
        [self.datasource editLyricsViewController:self
                                 addLyricsSticker:firstEffectModel
                                             path:firstEffectModel.filePath
                                          tabName:nil
                                       completion:nil];
        [self.editService.preview continuePlay];
    };

    panelView.clickMusicNameHandler = ^{
        @strongify(self);
        if (self.inputData.repository.repoContext.videoType == AWEVideoTypeKaraoke) {
            return;
        }
        if (self.inputData.disableChangeMusic) {
            return;
        }
        [self p_presentMusicStickerSearchVCFromLyricEdit:YES
                                              completion:^(id<ACCMusicModelProtocol> musicModel, NSError *error, BOOL dismiss) {
            @strongify(self);
            if (!musicModel || error) {
                [self.editService.preview continuePlay];
                AWELogToolError(AWELogToolTagEdit, @"lyrics sticker panel, present music sticker failed: %@", error);
                return;
            }
            
            if ([self.delegate respondsToSelector:@selector(editLyricsViewController:didSelectMusic:error:)]) {
                [self.delegate editLyricsViewController:self didSelectMusic:musicModel error:error];
            }
            
            [self p_removeMusicLyricSticker];
            
            if (firstEffectModel.downloaded) {
                addLyricStickerBlock();
            } else {
                [EffectPlatform downloadEffect:firstEffectModel
                                      progress:NULL
                                    completion:^(NSError * _Nullable error, NSString * _Nullable filePath) {
                    if (error) {
                        AWELogToolError(AWELogToolTagEdit, @"lyrics sticker panel, download effect failed: %@", error);
                    }
                    
                    addLyricStickerBlock();
                }];
            }
            [self.lyricPanelView resetStickerPanelState];
            [self p_dismiss];
        }];
    };
    
    panelView.clickClipMusicHandler = ^{
        @strongify(self);
        [self p_presentMusicStickerAudioClipView];
    };
    
    self.lyricPanelView = panelView;
    [self.view addSubview:self.lyricPanelView];
}

#pragma mark - ACCEditLyricsStickerProtocol

- (void)clipMusic:(HTSAudioRange)audioRange repeatCount:(NSInteger)repeatCount
{
    if ([self.delegate respondsToSelector:@selector(editLyricsViewControllerShowAudioClipView:)]) {
        [self.delegate editLyricsViewControllerClipMusic:audioRange repeatCount:repeatCount];
    }
    [self p_updateMusicLyricStickerAudioRange:audioRange];
}

- (void)updatePlayerModelAudioRange:(HTSAudioRange)audioRange
{
    [self p_updatePlayerModelAudioRange:audioRange];
}

- (void)presentMusicStickerSearchVCFromLyricEdit:(BOOL)fromLyricEdit
                                      completion:(void (^)(id<ACCMusicModelProtocol>, NSError *, BOOL dismiss))completion
{
    [self p_presentMusicStickerSearchVCFromLyricEdit:fromLyricEdit completion:completion];
}

#pragma mark - Privates

- (void)p_presentMusicStickerAudioClipView
{
    if ([self.delegate respondsToSelector:@selector(editLyricsViewControllerAddAudioClipView:)]) {
        [self.delegate editLyricsViewControllerAddAudioClipView:self];
    }
    
    @weakify(self);
    [self.lyricPanelView hide:^(BOOL finished) {
        @strongify(self);
        if ([self.delegate respondsToSelector:@selector(editLyricsViewControllerShowAudioClipView:)]) {
            [self.delegate editLyricsViewControllerShowAudioClipView:self];
        }
    }];
    
    [self.editService.preview addSubscriber:self];
}

- (void)audioRangeChanging:(HTSAudioRange)range changeType:(AWEAudioClipRangeChangeType)changeType
{
    [self p_updateMusicLyricStickerAudioRange:range];
    
    if (changeType == AWEAudioClipRangeChangeTypeChange) {
        NSDictionary *params = @{@"creation_Id" : self.inputData.repository.repoContext.createId ? : @"",
                                 @"shoot_way" : self.inputData.repository.repoTrack.referString ? : @"",
                                 @"music_id" : self.inputData.repository.repoMusic.music.musicID ? : @"",
                                 @"dynamics" :  self.lyricPanelView.currentEffectModel.effectName ? : @"",
                                 @"begin_time" : @(range.location * 1000),
        };
        [ACCTracker() trackEvent:@"lyricsticker_clip_adjust"
                           params:params
                  needStagingFlag:NO];
    }
}

- (void)audioRangeDidChange:(HTSAudioRange)range changeType:(AWEAudioClipRangeChangeType)changeType
{
    [self p_updatePlayerModelAudioRange:range];
    [self.lyricPanelView show];
    
    NSDictionary *params = @{
        @"creation_Id" : self.inputData.repository.repoContext.createId ? : @"",
        @"shoot_way" : self.inputData.repository.repoTrack.referString ? : @"",
        @"music_id" : self.inputData.repository.repoMusic.music.musicID ? : @"",
        @"dynamics" :  self.lyricPanelView.currentEffectModel.effectName ? : @""
    };
    [ACCTracker() trackEvent:@"select_lyricsticker_clip_complete"
                      params:params
             needStagingFlag:NO];
}

- (void)p_removeMusicLyricSticker
{
    NSArray<ACCStickerViewType> *lyricStickerWrappers =
    [[self.inputData.stickerContainer allStickerViews] btd_filter:^BOOL(ACCStickerViewType  _Nonnull obj) {
        return [obj.contentView isKindOfClass:ACCLyricsStickerContentView.class];
    }];
    
    if (lyricStickerWrappers) {
        [lyricStickerWrappers enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.inputData.stickerContainer removeStickerView:obj];
        }];
    }
    
    // 移除原容器的歌词贴纸
    [self.datasource editLyricsViewControllerRemoveMusicLyricSticker:self];
}

- (void)p_presentMusicStickerSearchVCFromLyricEdit:(BOOL)fromLyricEdit
                                      completion:(void (^)(id<ACCMusicModelProtocol>, NSError *, BOOL dismiss))completion
{
    [self.editService.preview pause];

    id<ACCEditLyricStickerMusicSelectPageProtocol> musicLyricVC =
    [IESAutoInline(ACCBaseServiceProvider(), ACCEditLyricStickerMusicSelectProtocol)
     createWithRepository:self.inputData.repository];

    musicLyricVC.pageSource = fromLyricEdit ? @"lyrics_edit_page" : @"video_edit_page";
    @weakify(self);
    
    HTSAudioRange range = {0};
    __block HTSAudioRange clipedRange = range;
    __block BOOL useSuggestClipRange = self.inputData.repository.repoMusic.useSuggestClipRange;
    __block NSInteger musicRepeatCount = -1;
    
    musicLyricVC.didClipRange = ^(HTSAudioRange range, NSInteger repeatCount) {
        clipedRange = range;
        musicRepeatCount = repeatCount;
    };
    
    musicLyricVC.suggestSelectedChangeBlock = ^(BOOL selected) {
        useSuggestClipRange = selected;
    };
    
    musicLyricVC.completion = ^(id<ACCMusicModelProtocol> audio, NSError *error) {
        @strongify(self);
        if (audio && self.lyricPanelView) {
            BOOL isUsingMVMusic = self.inputData.repository.repoContext.isMVVideo &&
                [self.inputData.repository.repoMusic.music.musicID isEqualToString:self.inputData.repository.repoMV.templateMusicId];
            BOOL isMusicLongerThanVideo = audio.duration.doubleValue > self.inputData.repository.repoVideoInfo.video.totalVideoDuration;
            if (ACCConfigEnum(kConfigInt_manually_music_loop_mode, ACCMusicLoopMode) != ACCMusicLoopModeOff && !self.inputData.repository.repoUploadInfo.isAIVideoClipMode) {
                isMusicLongerThanVideo = YES;
            }
            BOOL enableClip = !isUsingMVMusic && isMusicLongerThanVideo;
            [self.lyricPanelView updateWithMusicModel:audio enableClip:enableClip];
            
            NSAssert(self.inputData.draftService, @"should not be nil");
            [self.inputData.draftService hadBeenModified];
        }
        
        ACCBLOCK_INVOKE(completion, audio, error, NO);
        
        if (clipedRange.length != 0) {
            [self clipMusic:clipedRange repeatCount:musicRepeatCount];
            [self p_updatePlayerModelAudioRange:clipedRange];
        }
        self.inputData.repository.repoMusic.useSuggestClipRange = useSuggestClipRange;
    };
    
    musicLyricVC.dismissHandler = ^{
        ACCBLOCK_INVOKE(completion, nil, nil, YES);
    };
    
    CGFloat startOffset = fromLyricEdit ? ACC_SCREEN_HEIGHT : ACC_SCREEN_HEIGHT * 0.11;
    [musicLyricVC showOnViewController:self.inputData.containerViewController startOffset:startOffset completion:nil];
}

- (void)p_updatePlayerModelAudioRange:(HTSAudioRange)audioRange
{
    [self p_updateMusicLyricStickerAudioRange:audioRange];
}

- (void)p_updateMusicLyricStickerAudioRange:(HTSAudioRange)audioRange
{
    NSNumber *musicStickerId = [self.editService.sticker filterMusicLyricStickerId];
    if (musicStickerId != nil && musicStickerId.integerValue != NSIntegerMin) {
        id<ACCMusicModelProtocol> music = self.inputData.repository.repoMusic.music;
        NSTimeInterval trimIn = audioRange.location + self.inputData.repository.repoMusic.music.previewStartTime;
        NSTimeInterval videoDuration = self.inputData.repository.repoVideoInfo.video.totalVideoDuration;
        NSTimeInterval audioDuration = audioRange.length;
        NSTimeInterval srtDuration;
        BOOL isMusicLoop = [self.inputData.repository.repoMusic shouldEnableMusicLoop:videoDuration];
        
        if (audioDuration > 0) {
            srtDuration = audioDuration > videoDuration ? videoDuration : audioDuration;
        } else if (music.loaclAssetUrl) {
            AVURLAsset *asset = [AVURLAsset URLAssetWithURL:music.loaclAssetUrl options:@{
                AVURLAssetPreferPreciseDurationAndTimingKey: @(YES)
            }];
            Float64 duration = CMTimeGetSeconds(asset.duration);
            srtDuration = MIN(duration, videoDuration);
        } else {
            srtDuration = videoDuration;
        }

        [self.editService.sticker setSrtAudioInfo:musicStickerId.integerValue
                                            seqIn:0
                                           trimIn:trimIn
                                         duration:srtDuration
                                       audioCycle:isMusicLoop];
    }
}

- (void)p_dismiss
{
    @weakify(self);
    [self.lyricPanelView hide:^(BOOL finished) {
        if (finished) {
            @strongify(self);
            if (self.parentViewController) {
                [self willMoveToParentViewController:nil];
                [self removeFromParentViewController];
                [self.view removeFromSuperview];
                [self didMoveToParentViewController:nil];
            } else if (self.presentingViewController) {
                [self dismissViewControllerAnimated:NO completion:NULL];
            } else if (self.navigationController) {
                [self.navigationController popViewControllerAnimated:NO];
            }
            
            [self p_recoverStickerViewsAlpha];
            
            if ([self.delegate respondsToSelector:@selector(editLyricsViewControllerDidDismiss:)]) {
                [self.delegate editLyricsViewControllerDidDismiss:self];
            }
        }
    }];
}

- (void)p_recoverStickerViewsAlpha
{
    // 退出去的时候需要把置灰的视图恢复
    [[self.inputData.stickerContainer allStickerViews] btd_forEach:^(ACCStickerViewType  _Nonnull obj) {
        if (![obj.contentView isKindOfClass:ACCLyricsStickerContentView.class] ||
            ((ACCLyricsStickerContentView *)obj.contentView).stickerId != self.inputData.stickerId) {
            if ([obj.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
                ((UIView<ACCStickerEditContentProtocol> *)obj.contentView).transparent = NO;
            }
        }
    }];
}

- (void)p_updateLyricsStickerColorWithId:(NSInteger)stickerId color:(AWEStoryColor *)color
{
    CGFloat red, green, blue, alpha;
    [color.color getRed:&red green:&green blue:&blue alpha:&alpha];
    [self.editService.sticker setSrtColor:stickerId
                                      red:red
                                    green:green
                                     blue:blue
                                    alpha:alpha];
    if ([self.delegate respondsToSelector:@selector(editLyricsViewController:didSelectColor:)]) {
        [self.delegate editLyricsViewController:self didSelectColor:color.color];
    }
}

- (void)p_createMaskViewWithFrame:(CGRect)frame playerFrame:(CGRect)playerFrame
{
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        //上下有黑边
        CGFloat maskTopHeight = CGRectGetMinY(playerFrame);
        CGFloat maskBottomHeight = frame.size.height - CGRectGetMaxY(playerFrame);

        CGFloat radius = 0.0;
        if (ACC_FLOAT_EQUAL_TO([AWEXScreenAdaptManager standPlayerFrame].size.height, playerFrame.size.height) &&
            ACC_FLOAT_LESS_THAN([AWEXScreenAdaptManager standPlayerFrame].size.width, playerFrame.size.width)) {
            radius = 12.0;
        }

        self.maskViewOne = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), maskTopHeight + radius)];
        self.maskViewTwo = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(playerFrame) - radius, CGRectGetWidth(frame), maskBottomHeight + radius)];
        self.maskViewOne.backgroundColor = [UIColor blackColor];
        self.maskViewTwo.backgroundColor = [UIColor blackColor];

        [self p_makeMaskLayerForMaskViewOneWithRadius:radius];
        [self p_makeMaskLayerForMaskViewTwoWithRadius:radius];
        [self.view addSubview:self.maskViewOne];
        [self.view addSubview:self.maskViewTwo];

        if (CGRectGetWidth(playerFrame) < CGRectGetWidth(frame)) {
            //左右有黑边
            CGFloat maskWidth = (CGRectGetWidth(frame) - CGRectGetWidth(playerFrame)) * 0.5;
            self.maskViewThree = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, maskWidth, CGRectGetHeight(frame))];
            self.maskViewFour = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(playerFrame), 0, maskWidth, CGRectGetHeight(frame))];
            self.maskViewThree.backgroundColor = [UIColor blackColor];
            self.maskViewFour.backgroundColor = [UIColor blackColor];
            [self.view addSubview:self.maskViewThree];
            [self.view addSubview:self.maskViewFour];
        }
    } else {
        if (CGRectGetHeight(playerFrame) < CGRectGetHeight(frame)) {
            //上下有黑边
            CGFloat maskHeight = (CGRectGetHeight(frame) - CGRectGetHeight(playerFrame)) * 0.5;
            self.maskViewOne = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(frame), maskHeight)];
            self.maskViewTwo = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(playerFrame), CGRectGetWidth(frame), maskHeight)];
        } else if (CGRectGetWidth(playerFrame) < CGRectGetWidth(frame)) {
            //左右有黑边
            CGFloat maskWidth = (CGRectGetWidth(frame) - CGRectGetWidth(playerFrame)) * 0.5;
            self.maskViewOne = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(0, 0, maskWidth, CGRectGetHeight(frame))];
            self.maskViewTwo = [[AWEStudioExcludeSelfView alloc] initWithFrame:CGRectMake(CGRectGetMaxX(playerFrame), 0, maskWidth, CGRectGetHeight(frame))];
        }
        self.maskViewOne.backgroundColor = [UIColor blackColor];
        self.maskViewTwo.backgroundColor = [UIColor blackColor];
        [self.view addSubview:self.maskViewOne];
        [self.view addSubview:self.maskViewTwo];
    }
}

- (void)p_makeMaskLayerForMaskViewOneWithRadius:(CGFloat)radius
{
    CGRect frame = self.maskViewOne.bounds;
    CAShapeLayer *layer = [CAShapeLayer layer];

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame))];
    [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame)) radius:radius startAngle:0 endAngle:-(M_PI * 0.5) clockwise:NO];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius)];
    [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame)) radius:radius startAngle:-(M_PI * 0.5) endAngle:-M_PI clockwise:NO];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame))];

    layer.path = path.CGPath;
    self.maskViewOne.layer.mask = layer;
}

- (void)p_makeMaskLayerForMaskViewTwoWithRadius:(CGFloat)radius
{
    CGRect frame = self.maskViewTwo.bounds;
    CAShapeLayer *layer = [CAShapeLayer layer];

    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame))];
    [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame)) radius:radius startAngle:-M_PI endAngle:-(M_PI * 1.5) clockwise:NO];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius)];
    [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame)) radius:radius startAngle:-(M_PI * 1.5) endAngle:-(M_PI * 2.0) clockwise:NO];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame))];

    layer.path = path.CGPath;
    self.maskViewTwo.layer.mask = layer;
}

#pragma mark - ACCStickerContainerDelegate

- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer
          gestureStarted:(UIGestureRecognizer *)gesture
                  onView:(UIView *)targetView
{
}

- (void)stickerContainer:(ACCStickerContainerView *)stickerContainer
            gestureEnded:(UIGestureRecognizer *)gesture
                  onView:(UIView *)targetView
{
}

- (BOOL)stickerContainerTapBlank:(ACCStickerContainerView *)stickerContainer
                         gesture:(UIGestureRecognizer *)gesture
{
    [self p_dismiss];
    return YES;
}

#pragma mark - Accessories

- (UIView *)playerContainerView
{
    if (_playerContainerView == nil) {
        _playerContainerView = [UIView new];
        _playerContainerView.frame = self.inputData.originalPlayerViewContainerViewFrame;
        _playerContainerView.layer.masksToBounds = YES;
        _playerContainerView.layer.cornerRadius = 13.f;
    }
    return _playerContainerView;
}

- (id<ACCEditServiceProtocol>)editService
{
    if (!_editService) {
        _editService = self.inputData.editService;
    }
    return _editService;
}

@end
