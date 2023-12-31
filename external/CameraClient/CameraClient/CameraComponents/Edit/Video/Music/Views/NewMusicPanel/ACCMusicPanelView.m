//
//  ACCMusicPanelView.m
//  CameraClient-Pods-Aweme
//
//  Created by 饶骏华 on 2021/6/24.
//

#import "ACCMusicPanelView.h"
#import "HTSVideoSoundEffectPanelView.h"
#import "AWEMusicSelectItem.h"
#import "AWEVideoEditDefine.h"
#import "ACCMusicPanelViewModel.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import "ACCMusicSelectView.h"
#import <CameraClient/ACCCameraClient.h>
#import <CreationKitArch/AWEVideoPublishViewModelDefine.h>
#import <CreativeKit/ACCMacros.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "ACCMusicPanelToolbar.h"
#import <KVOController/NSObject+FBKVOController.h>
#import "ACCVideoEditMusicViewModel.h"
#import "AWERepoVideoInfoModel.h"
#import <CameraClient/AWERepoTrackModel.h>
#import "AWERepoContextModel.h"
#import <CameraClient/ACCRepoImageAlbumInfoModel.h>

static const CGFloat kTopToolBarHeight = 55.f;
static const CGFloat kBottomToolbarHeight = 48.f;

@interface ACCMusicPanelView () <ACCMusicPanelBottomToolbarDelegate, HTSVideoSoundEffectPanelViewActionDelegate, UIGestureRecognizerDelegate>

@property (nonatomic, weak) ACCVideoEditMusicViewModel *musicViewModel;

@property (nonatomic, readwrite) UIView<ACCMusicSelectViewProtocol> *musicSelectView;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, assign) NSInteger currentTag;
@property (nonatomic, strong) NSMutableArray <AWEMusicSelectItem *> *userCollectedMusicList;

// new panel
@property (nonatomic, strong) ACCMusicPanelBottomToolbar *musicBottomToolBar;
@property (nonatomic, assign) CGPoint prevTotalMoved;
@property (nonatomic, assign) CGPoint translatedVec;
@property (nonatomic, assign) CGPoint prevGestureTranslation;
@property (nonatomic, assign) CGFloat eachPanOffset;
@property (nonatomic, assign) CGPoint startPanLocation;
@property (nonatomic, assign) BOOL isInPan;

@end

@implementation ACCMusicPanelView

@synthesize clipButtonClickHandler, didSelectMusicHandler, dismissHandler, enterMusicLibraryHandler, favoriteButtonClickHandler, queryLyricStickerHandler, showHandler, tapClickCloseHandler, willAddLyricStickerHandler, willRemoveLyricStickerHandler;
@synthesize volumeView = _volumeView;

#pragma mark - life cylce

- (instancetype)initWithFrame:(CGRect)frame
              musicSelectView:(ACCVideoEditMusicViewModel *)musicViewModel
       userCollectedMusicList:(NSMutableArray <AWEMusicSelectItem *> * _Nullable)userCollectedMusicList {
    self = [super initWithFrame:frame];
    if (self) {
        _musicViewModel = musicViewModel;
        _currentTag = -1;
        _userCollectedMusicList = userCollectedMusicList;
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
    self.topView = ({
        UIView *topView = [[UIView alloc] init];
        topView.backgroundColor = [UIColor clearColor];
        //accessibility
        topView.isAccessibilityElement = YES;
        topView.accessibilityLabel = @"关闭配乐面板";
        topView.accessibilityTraits = UIAccessibilityTraitButton | UIAccessibilityTraitStaticText;
        [self addSubview:topView];
        topView.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT - [ACCMusicPanelView volumeHeight]);
        [topView acc_addSingleTapRecognizerWithTarget:self action:@selector(tapToClose:)];
        topView;
    });
    
    self.containerView = ({
        UIView *view = [[UIView alloc] init];
        view.backgroundColor = ACCResourceColor(ACCColorBGReverse);
        view.clipsToBounds = YES;
        [self addSubview:view];
        view.frame = CGRectMake(0, ACC_SCREEN_HEIGHT, ACC_SCREEN_WIDTH, [self contentViewHeight]);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self contentViewHeight]) byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:CGSizeMake(12, 12)];
        CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
        maskLayer.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, [self contentViewHeight]);
        maskLayer.path = path.CGPath;
        view.layer.mask = maskLayer;
        view;
    });
  
    UIPanGestureRecognizer *slidingPan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    slidingPan.delegate = self;
    [self.containerView addGestureRecognizer:slidingPan];
    
    self.musicSelectView = ({
        CGFloat musicSelectViewHeight = [ACCMusicPanelView adaptionMusicCollectionViewSize].height;
        UIView<ACCMusicSelectViewProtocol> *musicSelectView = [[ACCMusicSelectView alloc] initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, kTopToolBarHeight + musicSelectViewHeight)
                                                                                           
                                                                                    musicViewModel:self.musicViewModel
                                                                                 userCollectedMusicList:self.userCollectedMusicList];
        [self.containerView addSubview:musicSelectView];
        musicSelectView.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, kTopToolBarHeight + musicSelectViewHeight);
        // config action
        @weakify(self);
        musicSelectView.willAddLyricStickerHandler = ^(id<ACCMusicModelProtocol>music) {
            @strongify(self);
            CGFloat height = [ACCMusicPanelView contentViewSizeHeight];
            CGFloat yRadio = (ACC_SCREEN_HEIGHT - height) / ACC_SCREEN_HEIGHT - 0.1;
            CGPoint point = CGPointMake(0.5, yRadio);
            NSString *pointString = NSStringFromCGPoint(point);
            // 计算面板相对高度
            ACCBLOCK_INVOKE(self.willAddLyricStickerHandler, music, pointString);
        };
        
        
        musicSelectView.willRemoveLyricStickerHandler = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.willRemoveLyricStickerHandler);
        };
        
        musicSelectView.queryLyricStickerHandler = ^(UIButton *lyricStickerButton){
            @strongify(self);
            ACCBLOCK_INVOKE(self.queryLyricStickerHandler, lyricStickerButton);
        };
        
        musicSelectView.clipButtonClickHandler = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.clipButtonClickHandler);
            [self hide:^(BOOL finished) {
                
            }];
        };
        
        musicSelectView.favoriteButtonClickHandler = ^(id<ACCMusicModelProtocol> music, BOOL collect) {
            @strongify(self);
            ACCBLOCK_INVOKE(self.favoriteButtonClickHandler, music, collect);
        };
        
        musicSelectView.didSelectMusicHandler = ^(id<ACCMusicModelProtocol>  _Nullable selectedMusic, id<ACCMusicModelProtocol>  _Nullable canceledMusic, NSError * _Nonnull error, BOOL autoPlay) {
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
        
        musicSelectView.enterMusicLibraryHandler = ^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.enterMusicLibraryHandler);
        };
        
        // 某些场景下，禁止取消选中音乐
        musicSelectView.deselectMusicBlock = ^{
            @strongify(self);
            NSString *toastString = [self.musicViewModel.musicPanelViewModel deselectedMusicToast];
            if (!ACC_isEmptyString(toastString)) {
                [ACCToast() show:toastString];
            }
        };
        
        musicSelectView;
    });

    if (![self.musicViewModel.musicPanelViewModel shouldShowMusicPanelTabOnly]) {
        //  volume adjuster
        self.volumeView = ({
            HTSVideoSoundEffectPanelView *soundEffectPanelView = [[HTSVideoSoundEffectPanelView alloc] initWithFrame:CGRectMake(ACC_SCREEN_WIDTH, 0, ACC_SCREEN_WIDTH, 254) useBlurBackground:NO];
            // config panel UI style
            [soundEffectPanelView adjustForMusicSelectPanelOptimizationWithDelegate:self];
            [self.containerView addSubview:soundEffectPanelView];
            CGFloat volumeHeight = [ACCMusicPanelView volumeHeight];
            soundEffectPanelView.frame = CGRectMake(0, 0, ACC_SCREEN_WIDTH, volumeHeight);
            soundEffectPanelView;
        });
    
        self.musicBottomToolBar = ({
            ACCMusicPanelBottomToolbar *musicBottomToolbar = [[ACCMusicPanelBottomToolbar alloc] initWithFrame:CGRectMake(0, kTopToolBarHeight + [ACCMusicPanelView adaptionMusicCollectionViewSize].height, ACC_SCREEN_WIDTH, kBottomToolbarHeight) isDarkBackground:NO delegate:self];
            [self.containerView addSubview:musicBottomToolbar];
            musicBottomToolbar;
        });
        
        [self addVolumeObserver];
    }
    
    UIView *indicatorView = [[UIView alloc] initWithFrame:CGRectMake((ACC_SCREEN_WIDTH - 32)/2, 10, 32, 4)];
    indicatorView.backgroundColor = ACCResourceColor(ACCColorLineReverse);
    indicatorView.layer.cornerRadius = 2;
    [self.containerView addSubview:indicatorView];
    
    [self updateSelectedPanel:0 aniamted:NO resetFrame:NO];
}

- (void)setSelectViewUserCollectedMusicDelegate:(NSObject<AWEVideoPublishMusicSelectViewUserCollectedMusicDelegate> *)delegate {
    self.musicSelectView.userCollectedMusicDelegate = delegate;
}

- (void)tapToClose:(UITapGestureRecognizer *)gesture
{
    if (self.tapClickCloseHandler) {
        self.tapClickCloseHandler();
    } else {
        [self dismiss];
    }
}

- (void)show {
    [UIView animateWithDuration:0.49 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = self.containerView.frame;
        frame.origin.x = 0;
        frame.origin.y = ACC_SCREEN_HEIGHT - [self contentViewHeight];
        self.containerView.frame = frame;
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
    [UIView animateWithDuration:0.15 delay:0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        CGRect frame = self.containerView.frame;
        frame.origin.x = 0;
        frame.origin.y = ACC_SCREEN_HEIGHT;
        self.containerView.frame = frame;
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
        [self.musicSelectView willDismissView];
    }];
}

- (void)updateWithMusicList:(NSMutableArray <AWEMusicSelectItem *>*)musicList
               playingMusic:(id<ACCMusicModelProtocol>)playingMusic {
    [self.musicSelectView updateWithMusicList:musicList playingMusic:playingMusic];
}

- (void)updatePlayerTime:(NSTimeInterval)playerTime {
    // 兼容线上老面板
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

#pragma mark - ACCPanelViewProtocol

- (CGFloat)panelViewHeight {
    return self.frame.size.height;
}

- (void *)identifier {
    return ACCVideoEditMusicContext;
}

#pragma mark - public
- (void)updateSelectedPanel:(NSUInteger)index aniamted:(BOOL)animated resetFrame:(BOOL)resetFrame {
    if (index == self.currentTag) {
        return;
    }
    
    CGRect containerViewFrame = self.containerView.frame;
  
    CGFloat musicSelectViewAlpha = self.musicSelectView.alpha;
    CGFloat musicBottomToolBarAlpha = self.musicBottomToolBar.alpha;
    CGFloat volumeViewAlpha = self.volumeView.alpha;
    if (index == 0) {
        // pop to musicPanelView
        if (resetFrame) {
            containerViewFrame.origin.y = ACC_SCREEN_HEIGHT - [self contentViewHeight];
        }
        musicSelectViewAlpha = 1.0;
        musicBottomToolBarAlpha = 1.0;
        volumeViewAlpha = 0;
    } else {
        // push to volumeView
        if (resetFrame) {
            containerViewFrame.origin.y = ACC_SCREEN_HEIGHT - [ACCMusicPanelView volumeHeight];
        }
        musicSelectViewAlpha = 0;
        musicBottomToolBarAlpha = 0;
        volumeViewAlpha = 1.0;
        [self disableOriginMusicByVideoType];
    }
    
    if (animated) {
        [UIView animateWithDuration:0.3f delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            self.containerView.frame = containerViewFrame;
            self.musicSelectView.alpha = musicSelectViewAlpha;
            self.musicBottomToolBar.alpha = musicBottomToolBarAlpha;
            self.volumeView.alpha = volumeViewAlpha;
        } completion:^(BOOL finished) {
            
        }];
    } else {
        self.containerView.frame = containerViewFrame;
        self.musicSelectView.alpha = musicSelectViewAlpha;
        self.musicBottomToolBar.alpha = musicBottomToolBarAlpha;
        self.volumeView.alpha = volumeViewAlpha;
    }
    self.currentTag = index;
}

- (void)updateSelectedPanel:(NSUInteger)index aniamted:(BOOL)animated {
    [self updateSelectedPanel:index aniamted:animated resetFrame:YES];
}

- (void)refreshMusicVolumeAfterAiClip:(CGFloat)musicVolume {
    self.volumeView.musicVolume = musicVolume;
    self.musicViewModel.musicPanelViewModel.bgmVolume = musicVolume;
}

#pragma mark - private

- (void)handlePan:(UIPanGestureRecognizer *)gestureRecognizer {
    UIView *view = gestureRecognizer.view;
    if (view != self.containerView) {
        return;
    }
    
    UICollectionView *collectionView = self.musicSelectView.collectionView.hidden ? self.musicSelectView.userCollectedMusicCollectionView : self.musicSelectView.collectionView;
    switch (gestureRecognizer.state) {
        case UIGestureRecognizerStateBegan:{
            if (!self.isInPan) {
                self.translatedVec = CGPointZero;
                self.prevTotalMoved = CGPointZero;
                self.eachPanOffset = 0;
            }
            self.prevGestureTranslation = CGPointZero;
            self.startPanLocation = [gestureRecognizer locationInView:view];
            self.isInPan = YES;
            break;
        }
        case UIGestureRecognizerStateChanged:{
            CGPoint translation = [gestureRecognizer translationInView:view];
            CGPoint moved = CGPointMake(self.prevTotalMoved.x + translation.x - self.prevGestureTranslation.x,
                                        self.prevTotalMoved.y + translation.y - self.prevGestureTranslation.y);
            self.prevGestureTranslation = translation;
            [self makePanTranslate:moved panLocation:self.startPanLocation collectionView:collectionView];
            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateFailed:
        case UIGestureRecognizerStateCancelled: {
            self.isInPan = NO;
            [self handlePanEndStatus];
            collectionView.scrollEnabled = YES;
            break;
        }
        default:
            break;
    }
}

- (void)handlePanEndStatus {
    self.musicSelectView.collectionView.bounces = YES;
    self.musicSelectView.userCollectedMusicCollectionView.bounces = YES;
    CGRect currentFrame = self.containerView.frame;
    CGFloat viewHeight = [self contentViewHeight];
    CGFloat viewOriginY = ACC_SCREEN_HEIGHT - viewHeight;
    NSInteger currentTage = self.currentTag; // 0 music list  1 volume view
    if (currentTage == 1) {
        viewHeight = [ACCMusicPanelView volumeHeight];
        viewOriginY = ACC_SCREEN_HEIGHT - viewHeight;
    }
    
    if (currentFrame.origin.y - viewOriginY > viewHeight/2 || self.eachPanOffset > 25) {
        // dismiss
        [self tapToClose:nil];
    } else {
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.9 initialSpringVelocity:1 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            CGRect frame = self.containerView.frame;
            frame.origin.x = 0;
            frame.origin.y = viewOriginY;
            self.containerView.frame = frame;
        } completion:^(BOOL finished) {
            
        }];
    }
}

- (void)makePanTranslate:(CGPoint)moved panLocation:(CGPoint)panLocation collectionView:(UICollectionView *)collectionView {
    CGPoint translate = CGPointMake(moved.x - self.translatedVec.x, moved.y - self.translatedVec.y);
    self.translatedVec = CGPointMake(translate.x + self.translatedVec.x, translate.y + self.translatedVec.y);
    self.prevTotalMoved = moved;
    CGRect currentFrame = self.containerView.frame;
    currentFrame.origin.y += translate.y;
      
    CGFloat viewOriginY = ACC_SCREEN_HEIGHT - [self contentViewHeight];
    NSInteger currentTage = self.currentTag; // 0 music list  1 volume view
    if (currentTage == 1) {
        viewOriginY = ACC_SCREEN_HEIGHT - [ACCMusicPanelView volumeHeight];
    }
    if (currentFrame.origin.y < viewOriginY) {
        return;
    }
    
    if (currentTage == 0 && panLocation.y > 65 && collectionView.contentOffset.y <= -7) {
        // 手势初始位置在collectionView范围内
        self.containerView.frame = currentFrame;
        self.eachPanOffset = translate.y > self.eachPanOffset ? translate.y : (translate.y >= 0 ? self.eachPanOffset : 0);
        collectionView.scrollEnabled = NO;
    } else if (panLocation.y <= (currentTage == 0 ? 65 : 254)) {
        self.containerView.frame = currentFrame;
        self.eachPanOffset = translate.y > self.eachPanOffset ? translate.y : (translate.y >= 0 ? self.eachPanOffset : 0);
        collectionView.scrollEnabled = YES;
    } else {
        self.eachPanOffset = 0;
        collectionView.scrollEnabled = YES;
    }
}

- (CGFloat)contentViewHeight {
    CGFloat baseHeight = [ACCMusicPanelView contentViewSizeHeight];
    if ([self.musicViewModel.musicPanelViewModel shouldShowMusicPanelTabOnly]) {
        baseHeight -= kBottomToolbarHeight;
    }
    return baseHeight;
}

+ (CGFloat)volumeHeight {
    return 254.f + ACC_IPHONE_X_BOTTOM_OFFSET;
}

+ (CGSize)adaptionMusicCollectionViewSize {
    return [ACCMusicSelectView adaptionMusicCollectionViewSize];
}

+ (CGFloat)contentViewSizeHeight {
    // 55 + 303 + 48 + 34(ACC_IPHONE_X_BOTTOM_OFFSET)
    CGFloat topViewHeight = kTopToolBarHeight;
    CGFloat musicCollectionViewHeight = [self adaptionMusicCollectionViewSize].height;
    CGFloat bottomViewHeight = kBottomToolbarHeight;
    return topViewHeight + musicCollectionViewHeight + bottomViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
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
    } else if (self.musicViewModel.publishModel.repoImageAlbumInfo.isImageAlbumEdit && ACCConfigBool(kConfigBool_image_mode_support_delete_music)) {
        self.volumeView.voiceVolume = 0;
        self.volumeView.userControlVoiceDisable = YES;
        self.volumeView.hidden = YES;
        
        self.musicBottomToolBar.originMusicSelected = NO;
        self.musicBottomToolBar.originMusicDisable = YES;
        self.musicBottomToolBar.originMusicScoreHide = YES;
        self.musicBottomToolBar.volumeHide = YES;
        return YES;
    } else if (self.musicViewModel.isCommerceLimitPanel) {
        self.musicBottomToolBar.originMusicScoreHide = YES;
        self.musicBottomToolBar.musicScoreHide = YES;
    } else if (self.musicViewModel.publishModel.repoContext.videoType == AWEVideoTypeNewYearWish) {
        self.volumeView.voiceVolume = 0;
        self.volumeView.userControlVoiceDisable = YES;
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
                self.volumeView.userControlVoiceDisable = voiceVolumeDisable;
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
            NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.musicViewModel.publishModel.repoTrack.referExtra];
            referExtra[@"enter_method"] = @"click_checkbox";
            referExtra[@"music_id"] = self.musicViewModel.publishModel.repoMusic.music.musicID ?: @"";
            [ACCTracker() trackEvent:@"unselect_music" params:referExtra needStagingFlag:NO];
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
        NSMutableDictionary *referExtra = [NSMutableDictionary dictionaryWithDictionary:self.musicViewModel.publishModel.repoTrack.referExtra];
        referExtra[@"enter_method"] = @"click_checkbox";
        [ACCTracker() trackEvent:@"unselect_original" params:referExtra needStagingFlag:NO];
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
