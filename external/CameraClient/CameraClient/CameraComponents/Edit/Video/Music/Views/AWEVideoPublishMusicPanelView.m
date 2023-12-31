//
//  AWEVideoPublishMusicPanelView.m
//  AWEStudio
//
//  Created by Nero Li on 2019/1/9.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoPublishMusicPanelView.h"
#import "HTSVideoSoundEffectPanelView.h"
#import "AWEMusicSelectItem.h"
#import "AWEVideoEditDefine.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCMusicSelectViewProtocol.h"
#import <CameraClient/ACCCameraClient.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import "AWEVideoPublishMusicSelectView.h"
#import "ACCMusicPanelToolbar.h"
#import <KVOController/NSObject+FBKVOController.h>
#import "ACCVideoEditMusicViewModel.h"
#import "AWERepoMusicModel.h"
#import "AWERepoVideoInfoModel.h"
#import "AWERepoContextModel.h"

static CGFloat kFunctionViewHeight = 152.f;
static const CGFloat ButtonHeight = 45.f;
static const CGFloat PanelSpacePadding = 6.f;

@interface AWEVideoPublishMusicPanelView() <ACCMusicPanelBottomToolbarDelegate, HTSVideoSoundEffectPanelViewActionDelegate>

@property (nonatomic, weak) ACCVideoEditMusicViewModel *musicViewModel;

@property (nonatomic, readwrite) UIView<ACCMusicSelectViewProtocol> *musicSelectView;
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, assign) NSInteger currentTag;
@property (nonatomic, strong) UIButton *musicSelectButton;
@property (nonatomic, strong) UIButton *volumeButton;
@property (nonatomic, strong) UIView *bottomLineView;
@property (nonatomic, strong) NSMutableArray <AWEMusicSelectItem *> *userCollectedMusicList;

// checkbox
@property (nonatomic, strong) ACCMusicPanelBottomToolbar *musicBottomToolBar;

@end

@implementation AWEVideoPublishMusicPanelView

@synthesize clipButtonClickHandler, didSelectMusicHandler, dismissHandler, enterMusicLibraryHandler, favoriteButtonClickHandler, queryLyricStickerHandler, showHandler, tapClickCloseHandler, willAddLyricStickerHandler, willRemoveLyricStickerHandler;
@synthesize volumeView = _volumeView;

- (instancetype)initWithFrame:(CGRect)frame musicSelectView:(ACCVideoEditMusicViewModel *)musicViewModel userCollectedMusicList:(NSMutableArray<AWEMusicSelectItem *> *)userCollectedMusicList {
    self = [super initWithFrame:frame];
    if (self) {
        _musicViewModel = musicViewModel;
        _currentTag = -1;
        _userCollectedMusicList = userCollectedMusicList;
        if ([AWEVideoPublishMusicSelectView headerViewTitleHeight2Line]) {
            kFunctionViewHeight = 186.f;
        } else {
            kFunctionViewHeight = 152.f;
        }
        [self setupUI];
    }
    return self;
}

- (void)dealloc
{
    ACCLog(@"%@ dealloc",self.class);
}

- (void)setupUI
{
    [self addSubview:self.blurView];
    ACCMasMaker(self.blurView, {
        make.left.right.equalTo(self);
        make.height.equalTo(@([self contentViewHeight]));
        make.top.equalTo(@(ACC_SCREEN_HEIGHT));
    });
    
    UIBezierPath * path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self contentViewHeight]) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12, 12)];
    
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self contentViewHeight]);
    maskLayer.path = path.CGPath;
    self.blurView.layer.mask = maskLayer;
    
    [self addSubview:self.topView];
    ACCMasMaker(self.topView, {
        make.top.left.right.equalTo(self);
        make.bottom.equalTo(self.blurView.mas_top);
    });
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToClose:)];
    [self.topView addGestureRecognizer:tapGesture];
    
    [self.blurView.contentView addSubview:self.musicSelectView];
    ACCMasMaker(self.musicSelectView, {
        make.top.equalTo(@(0));
        make.left.equalTo(@(0));
        make.width.equalTo(@(ACC_SCREEN_WIDTH));
        make.height.equalTo(@(kFunctionViewHeight));
    });
    
    @weakify(self);
    self.musicSelectView.willAddLyricStickerHandler = ^(id<ACCMusicModelProtocol>music) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.willAddLyricStickerHandler, music, nil);
    };
    
    self.musicSelectView.willRemoveLyricStickerHandler = ^{
        @strongify(self);
        ACCBLOCK_INVOKE(self.willRemoveLyricStickerHandler);
    };
    
    self.musicSelectView.queryLyricStickerHandler = ^(UIButton *lyricStickerButton){
        @strongify(self);
        ACCBLOCK_INVOKE(self.queryLyricStickerHandler, lyricStickerButton);
    };
    
    self.musicSelectView.clipButtonClickHandler = ^{
        @strongify(self);
        ACCBLOCK_INVOKE(self.clipButtonClickHandler);
        [self hide:^(BOOL finished) {
            
        }];
    };
    
    self.musicSelectView.favoriteButtonClickHandler = ^(id<ACCMusicModelProtocol> music, BOOL collect) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.favoriteButtonClickHandler, music, collect);
    };
        
    self.musicSelectView.didSelectMusicHandler = ^(id<ACCMusicModelProtocol>  _Nullable selectedMusic, id<ACCMusicModelProtocol>  _Nullable canceledMusic, NSError * _Nonnull error, BOOL autoPlay) {
        @strongify(self);
        if ([self.musicViewModel canDeselectMusic]) {
            if (selectedMusic == nil || error) {
                self.musicBottomToolBar.musicScoreSelected = NO;
            } else {
                self.musicBottomToolBar.musicScoreSelected = YES;
            }
        }
        // 控制是否选中音乐
        ACCBLOCK_INVOKE(self.didSelectMusicHandler, selectedMusic, canceledMusic, error, autoPlay);
    };
    
    self.musicSelectView.enterMusicLibraryHandler = ^{
        @strongify(self);
        ACCBLOCK_INVOKE(self.enterMusicLibraryHandler);
    };
        
    // 某些场景下，禁止取消选中音乐
    self.musicSelectView.deselectMusicBlock = ^{
        @strongify(self);
        NSString *toastString = [self.musicViewModel.musicPanelViewModel deselectedMusicToast];
        if (!ACC_isEmptyString(toastString)) {
            [ACCToast() show:toastString];
        }
    };
    
    self.bottomLineView = ({
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, kFunctionViewHeight, ACC_SCREEN_WIDTH, 0.5)];
        lineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineSecondary2);
        [self.blurView.contentView addSubview:lineView];
        ACCMasMaker(lineView, {
            make.left.equalTo(@0);
            make.top.equalTo(@(kFunctionViewHeight));
            make.height.equalTo(@0.5);
            make.width.equalTo(@(ACC_SCREEN_WIDTH));
        });
        lineView;
    });

    
    BOOL enableCheckbox = [self.musicViewModel.musicPanelViewModel enableCheckbox];
    if (enableCheckbox) {
        CGFloat baseHeight = [self contentViewTotalHeight];
        [self.blurView.contentView addSubview:self.volumeView];
        ACCMasMaker(self.volumeView, {
            make.top.equalTo(@(0));
            make.left.equalTo(@(ACC_SCREEN_WIDTH));
            make.width.equalTo(@(ACC_SCREEN_WIDTH));
            make.height.equalTo(@(baseHeight));
        });
        
        if (![self.musicViewModel.musicPanelViewModel shouldShowMusicPanelTabOnly]) {
            // 老面版线上样式，新增checkbox
            self.musicBottomToolBar = ({
                ACCMusicPanelBottomToolbar *musicBottomToolbar = [[ACCMusicPanelBottomToolbar alloc] initWithFrame:CGRectMake(0, kFunctionViewHeight, ACC_SCREEN_WIDTH, ButtonHeight) isDarkBackground:YES delegate:self];
                [self.blurView.contentView addSubview:musicBottomToolbar];
                ACCMasMaker(musicBottomToolbar, {
                    make.left.equalTo(@0);
                    make.width.equalTo(@(ACC_SCREEN_WIDTH));
                    make.top.equalTo(self.bottomLineView);
                    make.height.equalTo(@(ButtonHeight));
                })
                musicBottomToolbar;
            });
            
            [self addVolumeObserver];
        } else {
            self.volumeView.hidden = YES;
            self.musicBottomToolBar.hidden = YES;
            self.bottomLineView.hidden = YES;
        }
    } else {
        [self.blurView.contentView addSubview:self.volumeView];
        ACCMasMaker(self.volumeView, {
            make.top.equalTo(@(0));
            make.left.equalTo(@(ACC_SCREEN_WIDTH));
            make.width.equalTo(@(ACC_SCREEN_WIDTH));
            make.height.equalTo(@(kFunctionViewHeight));
        });
        
        // 老面板线上样式
        UIButton *musicSelectButton = [self actionButton];
        musicSelectButton.frame = CGRectMake(0, kFunctionViewHeight, ACC_SCREEN_WIDTH/2, ButtonHeight);
        [musicSelectButton setTitle:ACCLocalizedCurrentString(@"av_music") forState:UIControlStateNormal];
        musicSelectButton.tag = 100;
        [self.blurView.contentView addSubview:musicSelectButton];
        self.musicSelectButton = musicSelectButton;
        
        UIButton *volumeButton = [self actionButton];
        volumeButton.frame = CGRectMake(ACC_SCREEN_WIDTH/2, kFunctionViewHeight, ACC_SCREEN_WIDTH/2, ButtonHeight);
        [volumeButton setTitle:ACCLocalizedCurrentString(@"volume") forState:UIControlStateNormal];
        volumeButton.tag = 101;
        [self.blurView.contentView addSubview:volumeButton];
        self.volumeButton = volumeButton;
        
        ACCMasMaker(musicSelectButton, {
            make.top.equalTo(self.musicSelectView.mas_bottom);
            make.left.equalTo(@(0));
            make.width.equalTo(@(ACC_SCREEN_WIDTH/2));
            make.height.equalTo(@(ButtonHeight));
        });
        
        ACCMasMaker(volumeButton, {
            make.top.equalTo(self.musicSelectView.mas_bottom);
            make.left.equalTo(musicSelectButton.mas_right);
            make.width.equalTo(@(ACC_SCREEN_WIDTH/2));
            make.height.equalTo(@(ButtonHeight));
        });
        
        UIView *seprateView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 0.5, 16)];
        seprateView.center = CGPointMake(ACC_SCREEN_WIDTH / 2, 176);
        seprateView.backgroundColor = ACCResourceColor(ACCUIColorConstLineSecondary2);
        [self.blurView.contentView addSubview:seprateView];
        ACCMasMaker(seprateView, {
            make.centerX.equalTo(self.blurView.contentView);
            make.centerY.equalTo(musicSelectButton);
            make.height.equalTo(@16);
            make.width.equalTo(@0.5);
        });
        
        if ([self.musicViewModel.musicPanelViewModel shouldShowMusicPanelTabOnly]) {
            self.volumeButton.hidden = YES;
            self.volumeView.hidden = YES;
            self.musicSelectButton.hidden = YES;
            seprateView.hidden = YES;
            self.bottomLineView.hidden = YES;
        }
    }
    
    [self updateSelectedPanel:0 aniamted:NO];
}

- (UIButton *)actionButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.backgroundColor = [UIColor clearColor];
    [button setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse2) forState:UIControlStateNormal];
    button.titleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
    [button addTarget:self action:@selector(changePanel:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIView *)topView
{
    if (_topView == nil) {
        _topView = [UIView new];
        _topView.backgroundColor = [UIColor clearColor];
        //accessibility
        _topView.isAccessibilityElement = YES;
        _topView.accessibilityLabel = @"关闭配乐面板";
        _topView.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitStaticText;
    }
    return _topView;
}

- (UIVisualEffectView *)blurView
{
    if (_blurView == nil) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        _blurView.clipsToBounds = YES;
        _blurView.frame = CGRectMake(0, ACC_SCREEN_HEIGHT, ACC_SCREEN_WIDTH, [self contentViewHeight]);
    }
    return _blurView;
}

- (UIView<ACCMusicSelectViewProtocol> *)musicSelectView
{
    if (_musicSelectView == nil) {
        _musicSelectView = [[AWEVideoPublishMusicSelectView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, kFunctionViewHeight) musicViewModel:self.musicViewModel userCollectedMusicList:self.userCollectedMusicList];
    }
    return _musicSelectView;
}

- (HTSVideoSoundEffectPanelView *)volumeView
{
    if (_volumeView == nil) {
        _volumeView = [[HTSVideoSoundEffectPanelView alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH, 0, ACC_SCREEN_WIDTH, kFunctionViewHeight) useBlurBackground:NO];
        _volumeView.backgroundColor = [UIColor clearColor];
        [_volumeView adjustForMusicSelectPanelOptimizationWithDelegate:self];
    }
    return _volumeView;
}

- (void)setSelectViewUserCollectedMusicDelegate:(NSObject<AWEVideoPublishMusicSelectViewUserCollectedMusicDelegate> *)delegate {
    self.musicSelectView.userCollectedMusicDelegate = delegate;
}

- (void)updateSelectedPanel:(NSUInteger)index aniamted:(BOOL)animated
{
    if (index == self.currentTag) {
        return;
    }
    
    BOOL enableCheckbox = [self.musicViewModel.musicPanelViewModel enableCheckbox];
    if (index == 0) {
        ACCMasReMaker(self.musicSelectView, {
            make.top.equalTo(@(0));
            make.left.equalTo(@(0));
            make.width.equalTo(@(ACC_SCREEN_WIDTH));
            make.height.equalTo(@(kFunctionViewHeight));
        });
        if (enableCheckbox) {
            // 线上音乐面板，加上checkbox
            CGFloat baseHeight = [self contentViewTotalHeight];
            ACCMasReMaker(self.volumeView, {
                make.top.equalTo(@(0));
                make.left.equalTo(@(ACC_SCREEN_WIDTH));
                make.width.equalTo(@(ACC_SCREEN_WIDTH));
                make.height.equalTo(@(baseHeight));
            });
            ACCMasReMaker(self.bottomLineView, {
                    make.left.equalTo(@0);
                    make.top.equalTo(@(kFunctionViewHeight));
                    make.height.equalTo(@0.5);
                    make.width.equalTo(@(ACC_SCREEN_WIDTH));
            });
            ACCMasReMaker(self.musicBottomToolBar, {
                make.left.equalTo(@0);
                make.width.equalTo(@(ACC_SCREEN_WIDTH));
                make.top.equalTo(self.bottomLineView);
                make.height.equalTo(@(ButtonHeight));
            });
        } else {
            ACCMasReMaker(self.volumeView, {
                make.top.equalTo(@(0));
                make.left.equalTo(@(ACC_SCREEN_WIDTH));
                make.width.equalTo(@(ACC_SCREEN_WIDTH));
                make.height.equalTo(@(kFunctionViewHeight));
            });
        }
        [self.musicSelectButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse2) forState:UIControlStateNormal];
        [self.volumeButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse3) forState:UIControlStateNormal];
    } else {
        ACCMasReMaker(self.musicSelectView, {
            make.top.equalTo(@(0));
            make.left.equalTo(@(-ACC_SCREEN_WIDTH));
            make.width.equalTo(@(ACC_SCREEN_WIDTH));
            make.height.equalTo(@(kFunctionViewHeight));
        });
        if (enableCheckbox) {
            // 线上音乐面板，加上checkbox
            CGFloat baseHeight = [self contentViewTotalHeight];
            ACCMasReMaker(self.volumeView, {
                make.top.equalTo(@(0));
                make.left.equalTo(@(0));
                make.width.equalTo(@(ACC_SCREEN_WIDTH));
                make.height.equalTo(@(baseHeight));
            });
            ACCMasReMaker(self.bottomLineView, {
                    make.left.equalTo(@(-ACC_SCREEN_WIDTH));
                    make.top.equalTo(@(kFunctionViewHeight));
                    make.height.equalTo(@0.5);
                    make.width.equalTo(@(ACC_SCREEN_WIDTH));
            });
            ACCMasReMaker(self.musicBottomToolBar, {
                make.left.equalTo(@(-ACC_SCREEN_WIDTH));
                make.width.equalTo(@(ACC_SCREEN_WIDTH));
                make.top.equalTo(self.bottomLineView);
                make.height.equalTo(@(ButtonHeight));
            });
            [self disableOriginMusicByVideoType];
        } else {
            ACCMasReMaker(self.volumeView, {
                make.top.equalTo(@(0));
                make.left.equalTo(@(0));
                make.width.equalTo(@(ACC_SCREEN_WIDTH));
                make.height.equalTo(@(kFunctionViewHeight));
            });
        }
        [self.musicSelectButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse3) forState:UIControlStateNormal];
        [self.volumeButton setTitleColor:ACCResourceColor(ACCUIColorConstTextInverse2) forState:UIControlStateNormal];
    }
    
    if (animated) {
        [UIView animateWithDuration:0.4f animations:^{
            [self layoutIfNeeded];
        }];
    } else {
        [self layoutIfNeeded];
    }
    self.currentTag = index;
}

- (void)changePanel:(UIButton *)sender
{
    NSMutableDictionary *attributes = [self.musicViewModel.repository.repoTrack.referExtra mutableCopy];
    [attributes setValue:sender.titleLabel.text forKey:@"tab_name"];
    [ACCTracker() trackEvent:@"click_music_tab" params:attributes needStagingFlag:NO];
    NSUInteger index = 0;
    if (sender == self.volumeButton) {
        index = 1;
    }
    [self updateSelectedPanel:index aniamted:YES];
}

- (void)tapToClose:(UITapGestureRecognizer *)gesture
{
    if (self.tapClickCloseHandler) {
        self.tapClickCloseHandler();
    } else {
        [self dismiss];
    }
}

- (void)show
{
    [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        ACCMasReMaker(self.blurView, {
            make.left.right.equalTo(self);
            make.bottom.equalTo(self).offset(PanelSpacePadding);
            make.height.equalTo(@([self contentViewHeight]));
        });
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        if (finished) {
            ACCBLOCK_INVOKE(self.showHandler);
            [[NSNotificationCenter defaultCenter] postNotificationName:ACCMusicSelectionViewDidShow object:self.musicSelectView];
        }
    }];
    // 面板优化默认展示时选中第一个tab
    [self.musicSelectView resetToFirstTabItem];
}


- (void)hide:(void(^)(BOOL finished))completion {
    ACCMasReMaker(self.blurView, {
        make.left.right.equalTo(self);
        make.height.equalTo(@([self contentViewHeight]));
        make.top.equalTo(self.mas_bottom);
    });
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        ACCBLOCK_INVOKE(completion, finished);
    }];
}

- (void)dismiss {
    [self.musicSelectView trackFirstDismissPanelMusicType];
    @weakify(self);
    [self hide:^(BOOL finished) {
        @strongify(self);
        ACCBLOCK_INVOKE(self.dismissHandler);
        self.hidden = YES;
        [self.musicSelectView.collectionView setContentOffset:CGPointZero animated:NO];
        [self.musicSelectView willDismissView];
    }];
}

- (void)updateWithMusicList:(NSMutableArray <AWEMusicSelectItem *>*)musicList
               playingMusic:(id<ACCMusicModelProtocol>)playingMusic
{
    [self.musicSelectView updateWithMusicList:musicList playingMusic:playingMusic];
}

- (void)updatePlayerTime:(NSTimeInterval)playerTime
{
    [self.musicSelectView updatePlayerTime:playerTime];
}

- (void)updateCurrentPlayMusicClipRange:(HTSAudioRange)range
{
    [self.musicSelectView updateCurrentPlayMusicClipRange:range];
}

- (void)updateWithUserCollectedMusicList:(NSMutableArray <AWEMusicSelectItem *> *)userCollectedMusicList {
    [self.musicSelectView updateWithUserCollectedMusicList:userCollectedMusicList];
}

- (void)updateActionButtonState
{
    [self.musicSelectView updateActionButtonState];
}

- (void)resetFirstAnimation
{
    [self.musicSelectView resetFirstAnimation];
}

- (void)refreshMusicVolumeAfterAiClip:(CGFloat)musicVolume
{
    self.volumeView.musicVolume = musicVolume;
    self.musicViewModel.musicPanelViewModel.bgmVolume = musicVolume;
}

#pragma mark - private

- (CGFloat)contentViewTotalHeight {
    BOOL enableCheckbox = [self.musicViewModel.musicPanelViewModel enableCheckbox];
    if (enableCheckbox) {
        return kFunctionViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET + ButtonHeight + PanelSpacePadding;
    } else {
        return 190.f + ACC_IPHONE_X_BOTTOM_OFFSET + PanelSpacePadding;
    }
}

#pragma mark - ACCPannelViewProtocol

- (CGFloat)panelViewHeight {
    return self.frame.size.height;
}

- (void *)identifier {
    return ACCVideoEditMusicContext;
}

- (CGFloat)contentViewHeight
{
    CGFloat baseHeight = [self contentViewTotalHeight];
    if ([self.musicViewModel.musicPanelViewModel shouldShowMusicPanelTabOnly]) {
        baseHeight -= ButtonHeight;
    }
    return baseHeight;
}

#pragma mark - volume

- (BOOL)disableOriginMusicByVideoType
{
    if (self.musicViewModel.publishModel.repoContext.videoType == AWEVideoTypeQuickStoryPicture ||
        self.musicViewModel.publishModel.repoContext.videoType == AWEVideoTypeLivePhoto) {
        self.volumeView.voiceVolume = 0;
        self.volumeView.userControlVoiceDisable = YES;
        self.musicBottomToolBar.originMusicSelected = NO;
        self.musicBottomToolBar.originMusicDisable = YES;
        return YES;
    }
    return NO;
}

- (void)addVolumeObserver {
    BOOL disabledByVideoType = [self disableOriginMusicByVideoType];
    if (!disabledByVideoType) {
        BOOL voiceVolumeDisable = self.musicViewModel.repository.repoMusic.voiceVolumeDisable;
        self.musicBottomToolBar.originMusicSelected = !voiceVolumeDisable;
        self.volumeView.userControlVoiceDisable = voiceVolumeDisable;
        self.musicViewModel.musicPanelViewModel.voiceVolume = [self.musicViewModel.publishModel.repoMusic voiceVolume];
        
        @weakify(self);
        [self.KVOController observe:self.musicViewModel.publishModel.repoVideoInfo
                            keyPath:NSStringFromSelector(@selector(videoMuted))
                            options:NSKeyValueObservingOptionNew
                              block:^(typeof(self) _Nullable observer, AWERepoVideoInfoModel *_Nonnull object, NSDictionary<NSString *, id> *_Nonnull change) {
            @strongify(self);
            if (!object.videoMuted && !self.musicViewModel.publishModel.repoMusic.voiceVolumeDisable) {
                self.musicViewModel.musicPanelViewModel.voiceVolume = [self.musicViewModel.publishModel.repoMusic voiceVolume];
            }
        }];
        
        [self.KVOController observe:self.volumeView keyPath:NSStringFromSelector(@selector(preconditionVoiceDisable)) options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld block:^(typeof(self)  _Nullable observer, HTSVideoSoundEffectPanelView *_Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
            @strongify(self);
            if (object.preconditionVoiceDisable) {
                self.musicViewModel.musicPanelViewModel.voiceVolume = object.voiceVolume;
                self.musicBottomToolBar.originMusicSelected = NO;
                self.musicBottomToolBar.originMusicDisable = YES;
            } else {
                BOOL voiceVolumeDisable = self.musicViewModel.musicPanelViewModel.publishViewModel.repoMusic.voiceVolumeDisable;
                self.musicBottomToolBar.originMusicSelected = !voiceVolumeDisable;
                self.musicBottomToolBar.originMusicDisable = NO;
                if (voiceVolumeDisable) {
                    self.volumeView.voiceVolume = 0;
                } else {
                    self.volumeView.voiceVolume = object.voiceVolume;
                }
            }
        }];
    }
    
    if ([self.musicViewModel canDeselectMusic]){
        if (self.musicViewModel.publishModel.repoMusic.music != nil) {
            self.musicViewModel.musicPanelViewModel.bgmVolume = [self.musicViewModel.publishModel.repoMusic musicVolume];
        } else {
            // 未选择音乐则配置默认bgm音量
            CGFloat repoMusicVolume = [self.musicViewModel.publishModel.repoMusic musicVolume];
            self.musicViewModel.musicPanelViewModel.bgmVolume = repoMusicVolume > 0 ? repoMusicVolume : 1;
        }
        @weakify(self);
        [self.KVOController observe:self.volumeView.bgmSlider
                            keyPath:NSStringFromSelector(@selector(enabled))
                            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                              block:^(typeof(self) _Nullable observer, UISlider *_Nonnull object, NSDictionary<NSString *, id> *_Nonnull change) {
            @strongify(self);
            self.musicBottomToolBar.musicScoreSelected = object.isEnabled;
            if (object.isEnabled) {
                self.volumeView.musicVolume = self.musicViewModel.musicPanelViewModel.bgmVolume;
                self.musicViewModel.publishModel.repoMusic.musicVolume = self.musicViewModel.musicPanelViewModel.bgmVolume;
            }
        }];
        
        [self.KVOController observe:self.musicViewModel.musicPanelViewModel
                            keyPath:NSStringFromSelector(@selector(bgmMusicDisable))
                            options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                              block:^(typeof(self) _Nullable observer, ACCMusicPanelViewModel *_Nonnull object, NSDictionary<NSString *, id> *_Nonnull change) {
            @strongify(self);
            self.musicBottomToolBar.musicScoreDisable = object.bgmMusicDisable;
        }];
    } else {
        self.musicBottomToolBar.musicScoreSelected = YES;
        self.musicBottomToolBar.musicScoreDisable = YES;
    }
}

#pragma mark - ACCMusicPanelToolbarDelegate

- (BOOL)toolbarMusicScoreSelected:(BOOL)isSelected {
    if (isSelected) {
        // 自动选择可见范围内的第一首歌
        return [self.musicSelectView selectVisibleMusicItem];
    } else {
        // 是否可以取消选中
        if ([self.musicViewModel canDeselectMusic]) {
            [self.musicSelectView deselectMusic];
            return YES;
        } else {
            NSString *toastString = [self.musicViewModel.musicPanelViewModel deselectedMusicToast];
            if (!ACC_isEmptyString(toastString)) {
                [ACCToast() show:toastString];
            }
            return NO;
        }
    }
}

- (void)toolbarOriginMusicSelected:(BOOL)isSelected {
    self.musicViewModel.musicPanelViewModel.publishViewModel.repoMusic.voiceVolumeDisable = !isSelected;
    if (isSelected) {
        self.musicBottomToolBar.originMusicSelected = YES;
        self.volumeView.voiceVolume = self.musicViewModel.musicPanelViewModel.voiceVolume;
        self.volumeView.userControlVoiceDisable = NO;
    } else {
        // 取消选中，原声音乐设置为0，且禁止slider滑动，记录取消原声前最后一次记录的原声音量大小
        self.musicBottomToolBar.originMusicSelected = NO;
        self.volumeView.voiceVolume = 0;
        self.volumeView.userControlVoiceDisable = YES;
    }
}

- (void)toolbarVolumeTapped {
    NSMutableDictionary *attributes = [self.musicViewModel.repository.repoTrack.referExtra mutableCopy];
    [attributes setValue:@"音量" forKey:@"tab_name"];
    [ACCTracker() trackEvent:@"click_music_tab" params:attributes needStagingFlag:NO];
    NSInteger index = 1;
    [self updateSelectedPanel:index aniamted:YES];
}

#pragma mark - HTSVideoSoundEffectPanelViewActionDelegate

- (BOOL)enableMusicPanelVertical
{
    return [self.musicViewModel.musicPanelViewModel enableMusicPanelVertical];
}

- (BOOL)enableCheckbox
{
    return [self.musicViewModel.musicPanelViewModel enableCheckbox];
}

- (void)volumeViewBackButtonTapped {
    NSMutableDictionary *attributes = [self.musicViewModel.repository.repoTrack.referExtra mutableCopy];
    [attributes setValue:@"配乐" forKey:@"tab_name"];
    [ACCTracker() trackEvent:@"click_music_tab" params:attributes needStagingFlag:NO];
    NSInteger index = 0;
    [self updateSelectedPanel:index aniamted:YES];
}

- (void)bgmSliderDidFinishSlidingWithValue:(float)value {
    self.musicViewModel.musicPanelViewModel.bgmVolume = value;
}

- (void)voiceSliderDidFinishSlidingWithValue:(float)value {
    self.musicViewModel.musicPanelViewModel.voiceVolume = value;
}

@end
