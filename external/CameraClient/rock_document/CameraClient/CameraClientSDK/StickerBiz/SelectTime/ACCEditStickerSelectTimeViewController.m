//
//  ACCEditStickerSelectTimeViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by guochenxiang on 2020/8/23.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "ACCEditStickerSelectTimeViewController.h"
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import <CameraClient/AWEVideoRangeSlider.h>
#import <CreationKitArch/AWEImagesView.h>
#import <CreationKitArch/AWEVideoImageGenerator.h>
#import <CameraClient/ACCViewControllerProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCAPMProtocol.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <KVOController/NSObject+FBKVOController.h>
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import "ACCStickerPlayerApplying.h"
#import <CreativeKitSticker/ACCStickerContainerView+ACCStickerCopying.h>
#import "ACCTextStickerView.h"
#import "ACCStickerSelectTimeConfig.h"
#import <CreationKitArch/VEEditorSession+ACCPreview.h>
#import "ACCInfoStickerContentView.h"
#import <CreativeKitSticker/ACCBaseStickerView.h>
#import "ACCStickerBizDefines.h"
#import "ACCStickerContainerView+CameraClient.h"
#import "ACCSerialization.h"
#import <CreativeKit/UIButton+ACCAdditions.h>
#import <CameraClient/UIImage+ACCUIKit.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitInfra/UIView+ACCRTL.h>
#import <CameraClient/ACCConfigKeyDefines.h>
#import "AWERepoVideoInfoModel.h"

#import <CreationKitArch/ACCRepoContextModel.h>
#import <CreationKitArch/ACCRepoTrackModel.h>
#import "ACCStickerSelectTimeConfigImpl.h"
#import "IESInfoSticker+ACCAdditions.h"

static CGFloat const kACCSelectTimeBottomViewHeight = 204.5;
static CGFloat const kACCSelectTimeFramesViewHeight = 36.0;
static CGFloat const kACCSelectTimeFramesViewWidth = 32.0;
static CGFloat const kACCSelectTimeFramesViewLeft = 45;
static CGFloat const kACCSelectTimeFramesViewTop = 77;
static CGFloat const kACCSelectTimeFramesViewTopOptimized = 120;
static CGFloat const kACCSelectTimeSlideWidth = 35;
static CGFloat const kACCSelectTimeOffsetTime = 1 / 20;

static NSString * const ACCVideoEditStickerSelectTimeLabelFont = @"awe_video_edit_sticker_select_time_label_font";

@implementation ACCEditStickerSelectTimeInputData

@end

@interface ACCEditStickerSelectTimeViewController () <AWEMediaSmallAnimationProtocol, AWEVideoRangeSliderDelegate>

@property (nonatomic, strong) id<ACCStickerSelectTimeConfig> config;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UILabel *bottomTitleLabel;
@property (nonatomic, strong) UILabel *selectTimeLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) AWEImagesView *framesView;
@property (nonatomic, strong) UIImageView *fakeWaveView;
@property (nonatomic, strong) AWEVideoRangeSlider *videoRangeSlider;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *saveBtn;
@property (nonatomic, strong) UIView *lineView;

@property (nonatomic, assign) CGRect originalPlayerRect;
@property (nonatomic, strong) AWEVideoImageGenerator *imageGenerator;

@property (nonatomic, strong) UIView *playerContainer;
@property (nonatomic, strong) id<ACCStickerPlayerApplying> player;
@property (nonatomic, strong) UIView <ACCStickerProtocol> *selectedStickerView;
@property (nonatomic, strong) ACCTextStickerView *selectedTextView;// If current-edit is text sticker, is selectedStickerView's contentview, else nil
@property (nonatomic, copy)   NSArray<IESInfoSticker *> *infoStickers;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isSliding;

@property (nonatomic, strong) ACCStickerContainerView *stickerContainer;

@property (nonatomic, strong) NSArray *preLoadFramesArray;

@property (nonatomic, assign) CGFloat containerScale;
@property (nonatomic, assign) CGPoint containerCenter;
@property (nonatomic, copy) NSString *currentStickerIds;

@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCStickerSelectTimeVCDelegate> delegate;
@property (nonatomic, strong) AWEVideoPublishViewModel *repository;

@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;

@end

@implementation ACCEditStickerSelectTimeViewController

- (instancetype)initWithConfig:(id<ACCStickerSelectTimeConfig>)config
                     inputData:(ACCEditStickerSelectTimeInputData *)inputData
{
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        self.config = config;
        self.player = inputData.player;
        self.repository = [(ACCStickerSelectTimeConfigImpl *)config repository];
        if (self.player) {//从viewDidAppear挪到这里，防止进来的时候闪屏(特效-滤镜-星星)
            CGFloat offsetTime = kACCSelectTimeOffsetTime;
            if (self.repository.repoVideoInfo.video.previewFrameRate > 1) {
                offsetTime = 1 / self.repository.repoVideoInfo.video.previewFrameRate;
            }
            [self.player seekToTimeAndRender:CMTimeMakeWithSeconds(offsetTime, self.repository.repoVideoInfo.video.previewFrameRate)];
            [self.player setHighFrameRateRender:YES];
            [self.player setStickerEditMode:YES];
        }
        self.isPlaying = NO;
        self.isSliding = NO;
        self.originalPlayerRect = inputData.playerRect;
        self.stickerContainer = inputData.stickerContainer;
        [self updateSelectedStickerView:inputData.stickerView];
        
        self.delegate = inputData.delegate;
        self.transitionService = inputData.transitionService;
        self.editService = inputData.editService;
        
        @weakify(self);
        [inputData.stickerContainer.allStickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.config.typeId isEqualToString:ACCStickerTypeIdInfo] ||
                [obj.config.typeId isEqualToString:ACCStickerTypeIdText] ||
                [obj.config.typeId isEqualToString:ACCStickerTypeIdSocial] ||
                [obj.config.typeId isEqualToString:ACCStickerTypeIdVideoComment]) {
                obj.config.gestureCanStartCallback = ^BOOL(__kindof ACCBaseStickerView<ACCGestureResponsibleStickerProtocol> * _Nonnull contentView, UIGestureRecognizer * _Nonnull gesture) {
                    @strongify(self);
                    [self beforeReceiveGestureRecognizerTargetView:contentView];
                    return YES;
                };
            } else {
                obj.config.supportGesture = ^BOOL(ACCStickerGestureType gestureType, id _Nullable contextId, UIGestureRecognizer *gestureRecognizer) {
                    return NO;
                };
            }
        }];
    }
    return self;
}

- (void)dealloc
{
    if (self.imageGenerator) {
        [self.imageGenerator cancel];
        self.imageGenerator = nil;
    }
    
    self.player = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [ACCViewControllerService() viewController:self setDisableFullscreenPopTransition:YES];
    [ACCViewControllerService() viewController:self setPrefersNavigationBarHidden:YES];
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    
    [self setupUI];
    [self setupPlayer];
    [self showFrameImages];
    [self recoverStickerView];
}

- (void)viewWillLayoutSubviews
{
    [super viewWillLayoutSubviews];
    [self updateTextReadAndWave:NO];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.player setStickerEditMode:NO];
    [self.player seekToTimeAndRender:kCMTimeZero];
    [self.player play];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupPlayer
{
    [self.player resetPlayerWithView:@[self.playerContainer]];
    [self.player setStickerEditMode:YES];
    
    self.infoStickers = self.repository.repoVideoInfo.video.infoStickers;
    [self setStickersAlpha:YES];
    [self updateStickersDuration];
    
    CGFloat startTime = self.selectedStickerView.realStartTime;
    CGFloat duration = self.selectedStickerView.realDuration;
    
    if(self.repository.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineReverse) {
        startTime = [self.repository.repoVideoInfo.video totalVideoDuration] - startTime - duration;
    }
    
    self.videoRangeSlider.leftPosition = [self p_limitMaxDuration:startTime] * self.videoRangeSlider.bodyWidth / self.videoRangeSlider.maxGap;
    self.videoRangeSlider.rightPosition = [self p_limitMaxDuration:(startTime + duration)] * self.videoRangeSlider.bodyWidth / self.videoRangeSlider.maxGap;
    { // to set snap position
            AWETextStickerReadModel *readModel = self.selectedTextView.textModel.readModel;
            if(readModel.stickerKey) {
                self.videoRangeSlider.audioDuration = [self.config.textReadingRanges objectForKey:readModel.stickerKey].durationSeconds;
            }
        }
    [self.videoRangeSlider updateTimeLabel];
    [self.videoRangeSlider showSliderAreaShow:YES animated:NO];
    [self updateTextReadAndWave:NO];
    
    @weakify(self);
    [self.KVOController observe:self.player
                        keyPath:NSStringFromSelector(@selector(currentPlayerTime))
                        options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                          block:^(typeof(self) _Nullable observer, id  _Nonnull object, NSDictionary<NSString *,id> * _Nonnull change) {
                              @strongify(self);
                              if (!self.isSliding) {
                                  CGFloat currentPlayerTime = [change[NSKeyValueChangeNewKey] floatValue];
                                  [self.videoRangeSlider updateVideoIndicatorByPosition:currentPlayerTime];
                                  [self updateStickerContainerHiddenStatusWithCurrentPlayerTime:currentPlayerTime];
                              }
                          }];
}

- (void)setupUI
{
    [self.view addSubview:self.bottomView];
    
    [self.bottomView addSubview:self.cancelBtn];
    ACCMasMaker(self.cancelBtn, {
        make.left.equalTo(@16);
        make.width.height.equalTo(@24);
        make.bottom.equalTo(@(-14 - ACC_IPHONE_X_BOTTOM_OFFSET));
    });
    
    [self.bottomView addSubview:self.saveBtn];
    ACCMasMaker(self.saveBtn, {
        make.right.equalTo(@(-16));
        make.width.height.equalTo(@24);
        make.bottom.equalTo(@(-14 - ACC_IPHONE_X_BOTTOM_OFFSET));
    });
    
    [self.bottomView addSubview:self.bottomTitleLabel];
    ACCMasMaker(self.bottomTitleLabel, {
        make.centerX.equalTo(@0);
        make.centerY.equalTo(self.saveBtn);
        make.left.greaterThanOrEqualTo(self.cancelBtn.mas_right).offset(16);
        make.right.lessThanOrEqualTo(self.saveBtn.mas_left).offset(-16);
    });
    
    UIView *lineView = [[UIView alloc] init];
    lineView.backgroundColor = ACCResourceColor(ACCUIColorConstLineSecondary2);
    self.lineView = lineView;
    [self.bottomView addSubview:lineView];
    ACCMasMaker(lineView, {
        make.left.right.equalTo(@0);
        make.height.equalTo(@0.5);
        make.bottom.equalTo(self.saveBtn.mas_top).offset(-14);
    });
    
    [self.bottomView addSubview:self.playButton];
    ACCMasMaker(self.playButton, {
        make.top.equalTo(@12);
        make.right.equalTo(@(-16));
        make.height.width.equalTo(@28);
    });
    
    [self.bottomView addSubview:self.selectTimeLabel];
    ACCMasMaker(self.selectTimeLabel, {
        make.left.equalTo(@16);
        make.centerY.equalTo(self.playButton);
        make.right.lessThanOrEqualTo(self.playButton.mas_left).offset(-16);
    });
    
    // 帧
    [self.bottomView addSubview:self.framesView];
    ACCMasMaker(self.framesView, {
        make.left.equalTo(@(kACCSelectTimeFramesViewLeft));
        make.right.equalTo(@(-kACCSelectTimeFramesViewLeft));
        make.top.equalTo(@(kACCSelectTimeFramesViewTop));
        make.height.equalTo(@(kACCSelectTimeFramesViewHeight));
    });
    
    // 裁剪框
    [self.bottomView addSubview:self.videoRangeSlider];
    self.videoRangeSlider.bubleText = self.selectTimeLabel;
    
    if (!self.fakeWaveView) {
        UIView *fakeWaveContainer = [[UIView alloc] initWithFrame:self.framesView.frame];
        [fakeWaveContainer setUserInteractionEnabled:NO];
        fakeWaveContainer.clipsToBounds = YES;
        fakeWaveContainer.backgroundColor = ACCResourceColor(ACCColorConstBGInverse2);
        [self.bottomView insertSubview:fakeWaveContainer belowSubview:self.videoRangeSlider];
        ACCMasMaker(fakeWaveContainer, {
            make.width.equalTo(self.framesView);
            make.height.equalTo(self.framesView);
            make.centerX.equalTo(self.framesView);
            make.centerY.equalTo(self.framesView);
        });
        
        self.fakeWaveView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, 0.f, 30.f)];
        [fakeWaveContainer addSubview:self.fakeWaveView];
        ACCMasMaker(self.fakeWaveView, {
            make.centerY.equalTo(fakeWaveContainer);
        });
    }
    [self configFakeWaveView];
    // 播放
    [self.view addSubview:self.playerContainer];
    [self configScale];
    [self.playerContainer addSubview:self.stickerContainer];
    self.stickerContainer.transform = CGAffineTransformMakeScale(self.containerScale, self.containerScale);
    self.stickerContainer.center = self.containerCenter;
    [self makeMaskLayerForContainerView:self.stickerContainer];
    
    [self p_setupUIOptimization];
}

- (void)updateStickersDuration
{
    CGFloat timeMachineDuration = self.repository.repoVideoInfo.video.totalDurationWithTimeMachine;
    CGFloat videoDataDuration = self.repository.repoVideoInfo.video.totalVideoDuration;
    
    for (UIView<ACCStickerProtocol> *view in self.stickerContainer.stickerViewList) {
        NSTimeInterval duration =  timeMachineDuration > videoDataDuration ? timeMachineDuration : videoDataDuration;
        if (view.realStartTime + view.realDuration > duration && duration > 0) {
            view.realDuration = duration - view.realStartTime;
        }
    }
}

- (void)updateSelectedStickerView:(UIView<ACCStickerProtocol> *)stickerView
{
    if (self.stickerContainer.stickerViewList.count > 0) {
        for (UIView<ACCStickerProtocol> *view in self.stickerContainer.stickerViewList) {
            if ([view isEqual:stickerView]) {
                stickerView = view;
                break;
            }
        }
    }
    self.selectedStickerView = stickerView;
}

- (void)showFrameImages
{
    if (self.preLoadFramesArray) {
        [self.framesView refreshWithImageArray:self.preLoadFramesArray aspectRatio:kACCSelectTimeFramesViewWidth / kACCSelectTimeFramesViewHeight mode:AWEImagesViewContentModePreserveAspectRatioAndFill];
    } else {
        [self loadFirstPreviewFrame];
        [self reloadPreviewFrames];
    }
}

- (void)loadFirstPreviewFrame
{
    CGFloat scale = [UIScreen mainScreen].scale;
    @weakify(self);
    [self.player getSourcePreviewImageAtTime:0 preferredSize:CGSizeMake(scale * kACCSelectTimeFramesViewWidth, scale * kACCSelectTimeFramesViewHeight) compeletion:^(UIImage * _Nonnull image, NSTimeInterval atTime) {
        NSMutableArray *previewImageArray = @[].mutableCopy;
        if (image) {
            @strongify(self);
            image = [image acc_blurredImageWithRadius:15];
            [previewImageArray addObject:image];
            [self.framesView refreshWithImageArray:previewImageArray aspectRatio:kACCSelectTimeFramesViewWidth / kACCSelectTimeFramesViewHeight mode:AWEImagesViewContentModePreserveAspectRatioAndFill];
        }
    }];
}

- (void)reloadPreviewFrames
{
    if (self.preLoadFramesArray.count) {
        return;
    }
    NSInteger count = ceil((ACC_SCREEN_WIDTH - 2 * kACCSelectTimeFramesViewLeft) / kACCSelectTimeFramesViewWidth);
    if (count == 0) {
        return;
    }
    
    CGFloat totalDuration = [self.repository.repoVideoInfo.video totalVideoDuration];
    CGFloat step = totalDuration / count;
    NSMutableArray *previewImageDictArray = @[].mutableCopy;
    
    [self.imageGenerator cancel];
    [ACCAPM() attachFilter:@"edit_time" forKey:@"extracting_frame"];
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize imageSize = CGSizeMake(540, 960);
    if (self.config.sizeOfVideo && !self.player.previewEdge) {
         imageSize = self.config.sizeOfVideo.CGSizeValue;
     }
         
    if (imageSize.width > 0) {
        imageSize = CGSizeMake(kACCSelectTimeFramesViewWidth * scale, kACCSelectTimeFramesViewWidth * scale * imageSize.height / imageSize.width);
    }
    
    @weakify(self);
    if ([self.delegate respondsToSelector:@selector(imageGenerator:requestImages:step:size:array:completion:)]) {
        [self.delegate imageGenerator:self.imageGenerator requestImages:count step:step size:imageSize array:previewImageDictArray completion:^{
            NSMutableArray *previewImageArray = @[].mutableCopy;
            [previewImageDictArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [previewImageArray addObject:obj[@"image"]];
            }];
            @strongify(self);
            self.preLoadFramesArray = previewImageArray;
            [self.framesView refreshWithImageArray:previewImageArray aspectRatio:kACCSelectTimeFramesViewWidth / kACCSelectTimeFramesViewHeight mode:AWEImagesViewContentModePreserveAspectRatioAndFill];
            if ([self hasAnyPinnedInfoSticker]) {
                [self.player setStickerEditMode:YES];
            }
            [ACCAPM() attachFilter:nil forKey:@"extracting_frame"];
        }];
    }
}

#pragma mark - getter

- (UIView *)bottomView
{
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, ACC_SCREEN_HEIGHT, ACC_SCREEN_WIDTH, kACCSelectTimeBottomViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET)];
        _bottomView.backgroundColor = ACCResourceColor(ACCColorBGCreation2);
        UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:_bottomView.bounds
                                                   byRoundingCorners:UIRectCornerTopRight | UIRectCornerTopLeft
                                                         cornerRadii:CGSizeMake(12, 12)];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.path = path.CGPath;
        _bottomView.layer.mask = maskLayer;
    }
    return _bottomView;
}

- (UILabel *)selectTimeLabel
{
    if (!_selectTimeLabel) {
        _selectTimeLabel = [[UILabel alloc] init];
        _selectTimeLabel.text = [NSString stringWithFormat:ACCLocalizedString(@"com_mig_selected_sticker_lasts_for_1fs",@"已选取贴纸持续时间 %.1fs"), self.repository.repoVideoInfo.video.totalVideoDuration];
        _selectTimeLabel.textAlignment = NSTextAlignmentLeft;
        _selectTimeLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _selectTimeLabel.font = ACCResourceFont(ACCVideoEditStickerSelectTimeLabelFont);
    }
    return _selectTimeLabel;
}

- (UIButton *)playButton
{
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:ACCResourceImage(@"cameraStickerPlay") forState:UIControlStateNormal];
        [_playButton setImage:ACCResourceImage(@"cameraStickerPause") forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(clickPlayButton:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (AWEImagesView *)framesView
{
    if (!_framesView) {
        _framesView = [[AWEImagesView alloc] initWithFrame:CGRectMake(kACCSelectTimeFramesViewLeft, [self p_selectTimeFramesViewTopY], ACC_SCREEN_WIDTH - 2 * kACCSelectTimeFramesViewLeft, kACCSelectTimeFramesViewHeight)];
        _framesView.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    return _framesView;
}

- (AWEVideoRangeSlider *)videoRangeSlider
{
    if (!_videoRangeSlider) {
        _videoRangeSlider = [[AWEVideoRangeSlider alloc] initWithFrame:CGRectMake(kACCSelectTimeFramesViewLeft - kACCSelectTimeSlideWidth, [self p_selectTimeFramesViewTopY] - 2, ACC_SCREEN_WIDTH - kACCSelectTimeFramesViewLeft * 2 + kACCSelectTimeSlideWidth * 2, kACCSelectTimeFramesViewHeight + 4)
                                slideWidth:kACCSelectTimeSlideWidth
                               cursorWidth:4
                                    height:48
                             hasSelectMask:YES];
        _videoRangeSlider.delegate = self;
        _videoRangeSlider.enterFromType = AWEEnterFromTypeStickerSelectTime;
        _videoRangeSlider.maxGap = [self p_limitMaxDuration:self.repository.repoVideoInfo.video.totalVideoDuration];
        _videoRangeSlider.minGap = 1.0;
        _videoRangeSlider.cursorCanOverrunMaxGap = YES;
        _videoRangeSlider.showSideHandlerInfo = YES;
        [_videoRangeSlider showVideoIndicator];
    }
    
    return _videoRangeSlider;
}

- (UILabel *)bottomTitleLabel
{
    if (!_bottomTitleLabel) {
        _bottomTitleLabel = [[UILabel alloc] init];
        _bottomTitleLabel.text = ACCLocalizedString(@"infosticker_time_edit_title", @"贴纸时长");
        _bottomTitleLabel.textAlignment = NSTextAlignmentCenter;
        _bottomTitleLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse2);
        _bottomTitleLabel.font = [ACCFont() systemFontOfSize:15 weight:ACCFontWeightMedium];
    }
    return _bottomTitleLabel;
}

- (UIButton *)cancelBtn
{
    if (!_cancelBtn) {
        _cancelBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_cancelBtn setImage:ACCResourceImage(@"icon_edit_bar_cancel") forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(didClickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)saveBtn
{
    if (!_saveBtn) {
        _saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_saveBtn setImage:ACCResourceImage(@"icon_edit_bar_done") forState:UIControlStateNormal];
        [_saveBtn addTarget:self action:@selector(didClickSaveBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _saveBtn;
}

- (UIView *)playerContainer
{
    if (!_playerContainer) {
        _playerContainer = [[UIView alloc] initWithFrame:[self mediaSmallMediaContainerFrame]];
        _playerContainer.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    return _playerContainer;
}

- (AWEVideoImageGenerator *)imageGenerator
{
    if (!_imageGenerator) {
        _imageGenerator = [[AWEVideoImageGenerator alloc] init];
    }
    return _imageGenerator;
}

#pragma mark - action

- (void)clickPlayButton:(id)sender
{
    NSString *clickTypeStr = nil;
    if (self.isPlaying) {
        [self moviePause];
        clickTypeStr = @"stop";
    } else {
        [self moviePlay];
        clickTypeStr = @"play";
    }
    
    // Track Info
    ACCStickerSelectTimeConfigImpl *config = (ACCStickerSelectTimeConfigImpl *)self.config;
    if (config != nil) {
        [ACCTracker() trackEvent:@"preview_item"
                          params:@{
                              @"click_type" : clickTypeStr ?: @"",
                              @"function_type" : @"info_sticker_duration",
                              @"shoot_way" : config.repository.repoTrack.referString ?: @"",
                              @"content_source" : [config.repository.repoTrack referExtra][@"content_source"] ?: @"",
                              @"content_type" : [config.repository.repoTrack referExtra][@"content_type"] ?: @"",
                              @"is_multi_content" : config.repository.repoTrack.mediaCountInfo[@"is_multi_content"] ?: @"",
                              @"mix_type" : [config.repository.repoTrack referExtra][@"mix_type"] ?: @"",
                              @"creation_id" : config.repository.repoContext.createId ?: @"",
                          }];
    }
}

- (void)didClickCancelBtn:(id)sender
{
    [self configTextReadWhenExit:NO];
    [self p_trackTimeSetCancel];
    
    if ([self.delegate respondsToSelector:@selector(didCancelStickerContainer:)]) {
        [self.delegate didCancelStickerContainer:self.stickerContainer];
    }
    
    [self p_dismiss];
}

- (void)didClickSaveBtn:(id)sender
{
    [self configTextReadWhenExit:YES];
    if ([self.delegate respondsToSelector:@selector(didUpdateStickerContainer:)]) {
        [self.delegate didUpdateStickerContainer:self.stickerContainer];
    }
    
    [self p_trackTimeSetConfirm];
    [self p_dismiss];
}

- (void)p_dismiss
{
    [self.KVOController unobserveAll];
    if (self.transitionService) {
        [self.transitionService dismissViewController:self completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma mark - AWEMediaSmallAnimationProtocol

- (UIView *)mediaSmallMediaContainer
{
    return self.playerContainer;
}

- (UIView *)mediaSmallBottomView
{
    return self.bottomView;
}

- (CGRect)mediaSmallMediaContainerFrame
{
    CGFloat playerY = [UIDevice acc_isIPhoneX] ? 44 : 0;
    CGFloat playerHeight = ACC_SCREEN_HEIGHT - kACCSelectTimeBottomViewHeight - ACC_IPHONE_X_BOTTOM_OFFSET - playerY - 8.0;
    CGFloat playerWidth = self.view.acc_width;
    CGFloat playerX = (self.view.acc_width - playerWidth) * 0.5;
    CGSize videoSize = CGSizeMake(540, 960);
    if (!CGRectEqualToRect(self.player.playerFrame, CGRectZero)) {
        videoSize = self.player.playerFrame.size;
    }
    return AVMakeRectWithAspectRatioInsideRect(videoSize, CGRectMake(playerX, playerY, playerWidth, playerHeight));
}

- (CGFloat)mediaSmallBottomViewHeight
{
    return kACCSelectTimeBottomViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
}

#pragma mark - AWEVideoRangeSliderDelegate

- (void)videoRangeDidBeginByType:(AWEThumbType)type
{
    AWELogToolInfo(AWELogToolTagEdit, @"sticker select time, videoRangeDidBeginByType %@", @(type));
    self.videoRangeSlider.rangeChangeCount = 0;
    
    [self moviePause];
    self.isSliding = YES;
    
    if (type != AWEThumbTypeCursor) {
        ACCInfoStickerContentView *contentView = (id)[self.selectedStickerView contentView];
        if ([contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            [self.editService.sticker startChangeStickerDuration:contentView.stickerId];
        }
    }
}

- (void)videoRangeDidEndByType:(AWEThumbType)type
{
    AWELogToolInfo(AWELogToolTagEdit, @"sticker select time, videoRangeDidEndByType %@, rangeChangeCount %ld",@(type),(long)self.videoRangeSlider.rangeChangeCount);
    self.videoRangeSlider.rangeChangeCount = 0;
    
    self.isSliding = NO;
    
    if (type != AWEThumbTypeCursor) {
        ACCInfoStickerContentView *contentView = (id)[self.selectedStickerView contentView];
        if ([contentView isKindOfClass:ACCInfoStickerContentView.class]) {
            [self.editService.sticker stopChangeStickerDuration:contentView.stickerId];
        }
    }
        
    if (type == AWEThumbTypeCursor) {
        return;
    } else if (type == AWEThumbTypeLeft) {
        [self updateTextReadAndWave:YES];
    }
    
    CMTime startCMTime = CMTimeMakeWithSeconds(self.videoRangeSlider.leftPosition, self.repository.repoVideoInfo.video.previewFrameRate);
    CMTime endCMTime = CMTimeMakeWithSeconds(self.videoRangeSlider.rightPosition, self.repository.repoVideoInfo.video.previewFrameRate);
    CMTime subCMTime = CMTimeSubtract(endCMTime, startCMTime);
    
    CGFloat startTime = CMTimeGetSeconds(startCMTime);
    CGFloat duration = CMTimeGetSeconds(subCMTime);
    
    if(self.repository.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineReverse) {
        startTime = [self.repository.repoVideoInfo.video totalVideoDuration] - startTime - duration;
    }
    
    self.selectedStickerView.realStartTime = startTime;
    self.selectedStickerView.realDuration = duration;
    
    if (ACC_FLOAT_EQUAL_TO(duration, self.repository.repoVideoInfo.video.totalVideoDuration)) {
        duration = -1;
    }
}

- (void)videoRangeDidChangByPosition:(CGFloat)position movedType:(AWEThumbType)type
{
    CMTime currentPlayerCMTime = CMTimeMakeWithSeconds(position, self.repository.repoVideoInfo.video.previewFrameRate);
    CGFloat currentPlayerTime = CMTimeGetSeconds(currentPlayerCMTime);
    ACCLog(@"seekToTimeAndRender %.2f",currentPlayerTime);
    
    if (!self.player) {
        AWELogToolInfo(AWELogToolTagEdit, @"sticker select time, videoRangeDidChangByPosition exception, movedType %lu",(unsigned long)type);
    } else {
        self.videoRangeSlider.rangeChangeCount +=1;
    }
    
    if (type == AWEThumbTypeLeft) {
        [self updateTextReadAndWave:NO];
    }
    
    CMTime startCMTime = CMTimeMakeWithSeconds(self.videoRangeSlider.leftPosition, self.repository.repoVideoInfo.video.previewFrameRate);
    CMTime endCMTime = CMTimeMakeWithSeconds(self.videoRangeSlider.rightPosition, self.repository.repoVideoInfo.video.previewFrameRate);
    CMTime subCMTime = CMTimeSubtract(endCMTime, startCMTime);

    CGFloat startTime = CMTimeGetSeconds(startCMTime);
    CGFloat duration = CMTimeGetSeconds(subCMTime);

    if(self.repository.repoVideoInfo.video.effect_timeMachineType == HTSPlayerTimeMachineReverse) {
        startTime = [self.repository.repoVideoInfo.video totalVideoDuration] - startTime - duration;
    }
    if (self.stickerContainer.stickerViewList.count > 0) {
        if ([self.stickerContainer.stickerViewList containsObject:(id)self.selectedStickerView]) {
            self.selectedStickerView.realStartTime = startTime;
            self.selectedStickerView.realDuration = duration;
        }
    }
    [self.stickerContainer doDeselectAllStickers];
    [self.player seekToTimeAndRender:currentPlayerCMTime];
    [self updateStickerContainerHiddenStatusWithCurrentPlayerTime:currentPlayerTime];
}

- (BOOL)videoRangeIgnoreGesture
{
    return self.isPlaying;
}

- (void)trackSliderAdjustment
{
    [self p_trackTimeSetAdjust];
}

- (BOOL)needUpdateVideoRangeSlider:(UIView<ACCStickerSelectTimeRangeProtocol> *)view
{
    if (self.selectedStickerView == view) {
        return NO;
    }
    return YES;
}

- (void)videoRangeSliderAnimation
{
    [UIView animateKeyframesWithDuration:0.6 delay:0 options:0 animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5  animations:^{
            self.videoRangeSlider.alpha = 0.0;
            self.playButton.alpha = 0.0;
            self.videoRangeSlider.bubleText.alpha = 0.0;
            self.framesView.alpha = 0.0;
        }];
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            self.videoRangeSlider.alpha = 1.0;
            self.playButton.alpha = 1.0;
            self.videoRangeSlider.bubleText.alpha = 1.0;
            self.framesView.alpha = 1.0;
        }];
    } completion:nil];
}

#pragma mark - Setter

- (void)setSelectedStickerView:(UIView<ACCStickerProtocol> *)selectedStickerView
{
    _selectedStickerView = selectedStickerView;
    [self setStickersAlpha:YES];
    
    if([[self.selectedStickerView contentView] isKindOfClass:ACCTextStickerView.class]) {
        _selectedTextView = (ACCTextStickerView *)[self.selectedStickerView contentView];
    } else {
        _selectedTextView = nil;
    }
}

#pragma mark - private

- (void)updateStickerContainerHiddenStatusWithCurrentPlayerTime:(CGFloat) currentPlayerTime
{
    if (self.stickerContainer.stickerViewList.count > 0) {
        for (UIView <ACCSelectTimeRangeStickerProtocol> *stickerView in self.stickerContainer.stickerViewList) {
            [stickerView updateWithCurrentPlayerTime:currentPlayerTime];
        }
    }
}

- (CGFloat)p_limitMaxDuration:(CGFloat)totalDuration
{
    if (self.config.videoSource == AWEVideoSourceCapture &&
        totalDuration > self.config.maxDuration) {
        return self.config.maxDuration;
    }
    return totalDuration;
}

- (void)moviePlay
{
    [self.player setStickerEditMode:NO];
    [self.videoRangeSlider showSliderAreaShow:NO animated:YES];
    [self.videoRangeSlider.bubleText setText:ACCLocalizedString(@"tap_the_sticker_to_set_it_duration",@"点击贴纸进行时长设置")];
    [self.playButton setSelected:YES];
    self.isPlaying = YES;
    if (ACCConfigEnum(kConfigInt_text_reader_multiple_sound_effects, ACCTextReaderPhase2Type) == ACCTextReaderPhase2TypeDisable) {
        self.fakeWaveView.alpha = 0.f;
    }
    
    [self setStickersAlpha:NO];
}

- (void)moviePause
{
    [self.player setStickerEditMode:YES];
    [self.videoRangeSlider showSliderAreaShow:YES animated:YES];
    [self.playButton setSelected:NO];
    self.isPlaying = NO;
    [self.videoRangeSlider updateTimeLabel];
    self.fakeWaveView.alpha = 1.f;
    
    [self setStickersAlpha:YES];
}

- (void)setStickersAlpha:(BOOL)isAlpha
{
    if ([self.player currentBrushNumber] > 0) {
        [self.player setBrushCanvasAlpha:isAlpha ? 0.5 : 1];
    }
    
    [self.stickerContainer.allStickerViews enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.contentView conformsToProtocol:@protocol(ACCStickerEditContentProtocol)]) {
            UIView<ACCStickerEditContentProtocol> *contentView = (id)obj.contentView;
            contentView.transparent = (obj != self.selectedStickerView);
        }
    }];
}

- (void)recoverStickerView
{
    NSMutableArray *currentStickerIds = [[NSMutableArray alloc] init];
    for (IESInfoSticker *infoSticker in self.config.video.infoStickers) {
        if (infoSticker.isNeedRemove || infoSticker.acc_isNotNormalInfoSticker) {
            continue;
        }
        
        IESInfoStickerProps *props = [IESInfoStickerProps new];
        [self.player getStickerId:infoSticker.stickerId props:props];
        
        if (props.userInfo[@"stickerID"] && [props.userInfo[@"stickerID"] isKindOfClass:[NSString class]]) {
            NSString *stickerId = (NSString *)props.userInfo[@"stickerID"];
            if (stickerId.length > 0) {
                [currentStickerIds addObject:stickerId];
            }
        }
    }
    
    self.currentStickerIds = [currentStickerIds componentsJoinedByString:@","];
}

- (void)configTextReadWhenExit:(BOOL)save
{
    [[self.stickerContainer stickerViewsWithTypeId:ACCStickerTypeIdText] enumerateObjectsUsingBlock:^(ACCStickerViewType  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        ACCTextStickerView *contentView = (ACCTextStickerView *)[obj contentView];
        if ([contentView isKindOfClass:ACCTextStickerView.class])
        {
            AWETextStickerReadModel *readModel = contentView.textModel.readModel;
            if (readModel.useTextRead && readModel.stickerKey) {
                AVAsset *audioAsset = [self.config audioAssetInVideoDataWithKey:readModel.stickerKey];
                if (save) {
                    // Write player data to source data
                    IESMMVideoDataClipRange *audioRange = [ACCSerialization restoreFromObj:contentView.timeEditingRange to:IESMMVideoDataClipRange.class];
                    if (audioRange && audioAsset) {
                        [self.config.textReadingRanges setObject:audioRange forKey:readModel.stickerKey];
                    }
                } else {
                    // Use source data to recover player data
                    IESMMVideoDataClipRange *audioRange = [self.config.textReadingRanges objectForKey:readModel.stickerKey];
                    if (audioRange && audioAsset) {
                        [self.player setAudioClipRange:audioRange forAudioAsset:audioAsset];
                    }
                }
            }
        }
    }];

}

- (IESInfoStickerProps *)createStickerInfoWithInfo:(IESInfoStickerProps *)info
{
    IESInfoStickerProps *props = [IESInfoStickerProps new];
    props.offsetX = info.offsetX;
    props.offsetY = info.offsetY;
    props.angle = info.angle;
    props.scale = info.scale;
    props.stickerId = info.stickerId;
    return props;
}

- (void)updateVideoRangeSlider
{
    CGFloat leftPosition = [self p_limitMaxDuration:self.selectedStickerView.realStartTime] * self.videoRangeSlider.bodyWidth / self.videoRangeSlider.maxGap;
    self.videoRangeSlider.leftPosition = leftPosition;
    CGFloat rightPosition = [self p_limitMaxDuration:(self.selectedStickerView.realStartTime + self.selectedStickerView.realDuration)] * self.videoRangeSlider.bodyWidth / self.videoRangeSlider.maxGap;
    [self.videoRangeSlider updateActualRightPosition:rightPosition];
    [self.videoRangeSlider updateTimeLabel];
}

// When change select a text sticker
- (void)configFakeWaveView
{
    if (!self.fakeWaveView) {
        return;
    }
    
    AWETextStickerReadModel *readModel = self.selectedTextView.textModel.readModel;
    if (readModel.useTextRead && self.videoRangeSlider.maxGap > 0 && self.videoRangeSlider.bodyWidth > 0) {
        UIImage *waveImage = nil;
        if ([UIDevice acc_isIPad]) {
            UIImage *waveImg1 = ACCResourceImage(@"ic_text_reading_fake_wave_2");
            UIImage *waveImg2 = ACCResourceImage(@"ic_text_reading_fake_wave_2");
            CGSize size = CGSizeMake(waveImg1.size.width + waveImg2.size.width, waveImg1.size.height);
            UIGraphicsBeginImageContext(size);
            [waveImg1 drawInRect:CGRectMake(0, 0, waveImg1.size.width, size.height)];
            [waveImg2 drawInRect:CGRectMake(waveImg1.size.width, 0, waveImg2.size.width, size.height)];
            waveImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
        } else {
            waveImage = ACCResourceImage(@"ic_text_reading_fake_wave_2");
        }
        
        CGFloat audioDuration = 0;
        if(readModel.stickerKey) {
            audioDuration = [self.config.textReadingRanges objectForKey:readModel.stickerKey].durationSeconds;
        }
        // Ratio of audio in total video
        CGFloat durationRate = audioDuration/self.videoRangeSlider.maxGap;
        // Width of wave view
        CGFloat waveWidth = self.videoRangeSlider.bodyWidth * durationRate;
        // Crop image size
        waveImage = [waveImage btd_imageCroppingFromRect:CGRectMake(0.f, 0.f, waveWidth * waveImage.size.height / 30.f, waveImage.size.height)];
        self.fakeWaveView.acc_left = self.videoRangeSlider.leftPosition/self.videoRangeSlider.maxGap * self.videoRangeSlider.bodyWidth;
        self.fakeWaveView.acc_width = waveWidth;
        self.fakeWaveView.image = waveImage;
        self.fakeWaveView.hidden = NO;
    } else {
        self.fakeWaveView.hidden = YES;
    }
}

- (void)updateTextReadAndWave:(BOOL)adjustAudio
{
    if (self.videoRangeSlider.maxGap > 0) {
        self.fakeWaveView.acc_left = self.videoRangeSlider.leftPosition/self.videoRangeSlider.maxGap * self.videoRangeSlider.bodyWidth;
    }
    AWETextStickerReadModel *readModel = self.selectedTextView.textModel.readModel;
    if (adjustAudio && readModel.useTextRead && readModel.stickerKey) {
        AVAsset *audioAsset = [self.config audioAssetInVideoDataWithKey:readModel.stickerKey];
        IESMMVideoDataClipRange *audioRange = [self.config.textReadingRanges objectForKey:readModel.stickerKey];
        
        IESMMVideoDataClipRange *editingTextRange = [[IESMMVideoDataClipRange alloc] init];
        editingTextRange.attachSeconds = self.videoRangeSlider.leftPosition;
        editingTextRange.durationSeconds = audioRange.durationSeconds;
        editingTextRange.repeatCount = 1;
        self.selectedTextView.timeEditingRange = [ACCSerialization transformOriginalObj:editingTextRange to:ACCVideoDataClipRangeStorageModel.class];
        
        [self.player setAudioClipRange:editingTextRange forAudioAsset:audioAsset];
    }
}

- (void)makeMaskLayerForContainerView:(UIView *)view
{
    CGRect frame = [self.view convertRect:self.playerContainer.frame toView:view];
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];

    layer.path = path.CGPath;
    view.layer.mask = layer;
}

- (void)configScale
{
    self.containerScale = 1.0;
    
    CGFloat standScale = 9.0 / 16.0;
    CGRect currentFrame = [self mediaSmallMediaContainerFrame];
    CGFloat currentWidth = CGRectGetWidth(currentFrame);
    CGFloat currentHeight = CGRectGetHeight(currentFrame);
    CGRect oldFrame = self.originalPlayerRect;
    CGFloat oldWidth = CGRectGetWidth(oldFrame);
    CGFloat oldHeight = CGRectGetHeight(oldFrame);
    
    if (currentHeight > 0 && oldWidth > 0 && oldHeight > 0 ) {
        if (fabs(currentWidth / currentHeight - standScale) < 0.01) {
            self.containerScale = currentWidth / oldWidth;
        }
        
        if (currentWidth / currentHeight - standScale > 0.01) {
            self.containerScale = currentWidth / oldWidth;
        }
        
        if (currentWidth / currentHeight - standScale < -0.01) {
            self.containerScale = currentHeight / oldHeight;
        }
    }
    
    self.containerCenter = CGPointMake(self.playerContainer.center.x - self.playerContainer.frame.origin.x, self.playerContainer.center.y - self.playerContainer.frame.origin.y);
}

- (CGFloat)p_selectTimeFramesViewTopY
{
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        return kACCSelectTimeFramesViewTop;
    } else {
        return kACCSelectTimeFramesViewTopOptimized;
    }
}

#pragma mark - Pin

/// 是否有任何一个信息化贴纸被Pin住
- (BOOL)hasAnyPinnedInfoSticker {
    __block BOOL r = NO;
    [self.config.video.infoStickers enumerateObjectsUsingBlock:^(IESInfoSticker * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if (obj.pinStatus == VEStickerPinStatus_Pinned) {
            r = YES;
            *stop = YES;
        }
    }];
    return r;
}

#pragma mark - Track
- (void)p_trackTimeSetCancel
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.config.referExtra];
    params[@"prop_ids"] = self.currentStickerIds ?: @"";
    
    NSString *event = @"prop_timeset_cancel";
    params[@"is_diy_prop"] = @(NO);
    id<ACCStickerContentProtocol> contentView = [self.selectedStickerView contentView];
    if ([contentView isKindOfClass:ACCInfoStickerContentView.class]) {
        params[@"is_diy_prop"] = @(((ACCInfoStickerContentView *)contentView).isCustomUploadSticker);
    }
    AWETextStickerReadModel *readModel = self.selectedTextView.textModel.readModel;
    [params setObject:@(readModel.useTextRead) forKey:@"is_text_reading"];
    if (readModel) { // Different event in text sticker
        event = @"text_timeset_cancel";
        [params setValue:(self.selectedTextView.textModel.isAddedInEditView ? @"general_mode" : @"text_mode") forKey:@"text_type"];
    }
    [ACCTracker() trackEvent:event
                      params:[params copy]
             needStagingFlag:NO];
}

- (void)p_trackTimeSetConfirm
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.config.referExtra];
    params[@"prop_ids"] = self.currentStickerIds ?: @"";
    
    NSString *event = @"prop_timeset_confirm";
    params[@"is_diy_prop"] = @(NO);
    id<ACCStickerContentProtocol> contentView = [self.selectedStickerView contentView];
    if ([contentView isKindOfClass:ACCInfoStickerContentView.class]) {
        params[@"is_diy_prop"] = @(((ACCInfoStickerContentView *)contentView).isCustomUploadSticker);
    }
    
    AWETextStickerReadModel *readModel = self.selectedTextView.textModel.readModel;
    [params setObject:@(readModel.useTextRead) forKey:@"is_text_reading"];
    if (readModel) { // Different event in text sticker
        event = @"text_timeset_confirm";
        [params setValue:(self.selectedTextView.textModel.isAddedInEditView ? @"general_mode" : @"text_mode") forKey:@"text_type"];
    }
    [ACCTracker() trackEvent:event
                      params:params
             needStagingFlag:NO];
}

- (void)p_trackTimeSetAdjust
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.config.referExtra];
    params[@"prop_ids"] = self.currentStickerIds ?: @"";
    params[@"is_diy_prop"] = @(NO);
    AWETextStickerReadModel *readModel = self.selectedTextView.textModel.readModel;
    [params setObject:@(readModel.useTextRead) forKey:@"is_text_reading"];
    NSString *event = @"prop_duration_adjust";
    if (readModel) { // Different event in text sticker
        event = @"text_duration_adjust";
        [params setValue:(self.selectedTextView.textModel.isAddedInEditView ? @"general_mode" : @"text_mode") forKey:@"text_type"];
    }
    id<ACCStickerContentProtocol> contentView = [self.selectedStickerView contentView];
    if ([contentView isKindOfClass:ACCInfoStickerContentView.class]) {
        params[@"is_diy_prop"] = @(((ACCInfoStickerContentView *)contentView).isCustomUploadSticker);
    }
    
    [ACCTracker() trackEvent:event params:params needStagingFlag:NO];
}

- (void)beforeReceiveGestureRecognizerTargetView:(nonnull UIView *)targetView
{
    if (targetView) {
        [self moviePause];
        if ([self needUpdateVideoRangeSlider:(UIView<ACCStickerSelectTimeRangeProtocol> *)targetView]) {
            [self videoRangeSliderAnimation];
        }
        self.selectedStickerView = (UIView <ACCStickerProtocol> *)targetView;
        [self updateVideoRangeSlider];
        [self configFakeWaveView];
    }
}

#pragma mark - UI Optimization

/// Adjust UI according to AB
- (void)p_setupUIOptimization
{
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeDisabled) {
        return;
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeSaveCancelBtn) {
        [self p_setupUIOptimizationSaveCancelBtn];
        [self p_setupUIOptimizationPlayBtn];
        [self p_setupUIOptimizationReplaceIconWithText:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypePlayBtn) {
        [self p_setupUIOptimizationSaveCancelBtn];
        [self p_setupUIOptimizationPlayBtn];
        [self p_setupUIOptimizationReplaceIconWithText:YES];
    } else if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeReplaceIconWithText) {
        [self p_setupUIOptimizationSaveCancelBtn];
        [self p_setupUIOptimizationPlayBtn];
        [self p_setupUIOptimizationReplaceIconWithText:NO];
    }
}

- (void)p_setupUIOptimizationSaveCancelBtn
{
    self.bottomTitleLabel.hidden = YES;
    self.lineView.hidden = YES;
    
    self.cancelBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
    self.saveBtn.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
    self.playButton.acc_hitTestEdgeInsets = UIEdgeInsetsMake(-10, -10, -10, -10);
    
    ACCMasReMaker(self.selectTimeLabel, {
        make.left.equalTo(@16);
        make.right.equalTo(@(-16));
        make.height.equalTo(@52);
        make.top.equalTo(self.bottomView.mas_top).offset(52);
    });
    
    ACCMasReMaker(self.framesView, {
        make.left.equalTo(@(kACCSelectTimeFramesViewLeft));
        make.right.equalTo(@(-kACCSelectTimeFramesViewLeft));
        make.top.equalTo(@(kACCSelectTimeFramesViewTopOptimized));
        make.height.equalTo(@(kACCSelectTimeFramesViewHeight));
    });
}

- (void)p_setupUIOptimizationPlayBtn
{
    ACCMasReMaker(self.playButton, {
        make.centerX.equalTo(self.bottomView.mas_centerX);
        make.centerY.equalTo(self.cancelBtn.mas_centerY);
        make.height.width.equalTo(@28);
    });
}

- (void)p_setupUIOptimizationReplaceIconWithText:(BOOL)shouldUseText
{
    if (shouldUseText) {
        [self.cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
        [self.cancelBtn setTitle:@"取消" forState:UIControlStateHighlighted];
        [self.cancelBtn setImage:nil forState:UIControlStateNormal];
        [self.cancelBtn setImage:nil forState:UIControlStateHighlighted];
        self.cancelBtn.titleLabel.font = [ACCFont() systemFontOfSize:17];
        [self.cancelBtn.titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        ACCMasReMaker(self.cancelBtn, {
            make.left.mas_equalTo(@16);
            make.height.mas_equalTo(@24);
            make.top.mas_equalTo(@14);
        });

        [self.saveBtn setTitle:@"保存" forState:UIControlStateNormal];
        [self.saveBtn setTitle:@"保存" forState:UIControlStateHighlighted];
        [self.saveBtn setImage:nil forState:UIControlStateNormal];
        [self.saveBtn setImage:nil forState:UIControlStateHighlighted];
        self.saveBtn.titleLabel.font = [ACCFont() systemFontOfSize:17];
        [self.saveBtn.titleLabel setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
        ACCMasReMaker(self.saveBtn, {
            make.right.mas_equalTo(@(-16));
            make.height.mas_equalTo(@24);
            make.top.mas_equalTo(@14);
        });
    } else {
        ACCMasReMaker(self.cancelBtn, {
            make.left.equalTo(@16);
            make.width.height.equalTo(@24);
            make.top.equalTo(@14);
        });
        
        ACCMasReMaker(self.saveBtn, {
            make.right.equalTo(@(-16));
            make.width.height.equalTo(@24);
            make.top.equalTo(@14);
        });
    }
}

@end
