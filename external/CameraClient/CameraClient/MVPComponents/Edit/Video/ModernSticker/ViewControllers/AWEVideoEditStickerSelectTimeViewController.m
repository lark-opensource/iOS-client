//
//  AWEVideoEditStickerSelectTimeViewController.m
//  AWEStudio
//
//  Created by guochenxiang on 2018/9/26.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoEditStickerSelectTimeViewController.h"
#import <CreationKitArch/AWEVideoPublishViewModel.h>
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import <CameraClient/AWEVideoRangeSlider.h>
#import <CreationKitArch/AWEImagesView.h>
#import <CreationKitArch/AWEVideoImageGenerator.h>
#import "AWESimplifiedStickerContainerView.h"
#import "AWEStoryTextContainerView.h"
#import <CameraClient/ACCViewControllerProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCAPMProtocol.h>
#import <CameraClient/ACCAssetImageGeneratorTracker.h>
#import <CreativeKit/ACCFontProtocol.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitInfra/ACCLogProtocol.h>
#import <CreativeKit/ACCTrackProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIFont+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>
#import <ByteDanceKit/UIImage+BTDAdditions.h>
#import <CreationKitRTProtocol/ACCEditServiceProtocol.h>
#import <CreationKitInfra/UIView+ACCRTL.h>
#import <CreationKitArch/ACCRepoStickerModel.h>
#import "AWERepoVideoInfoModel.h"
#import <CreationKitArch/ACCRepoTrackModel.h>
#import <CameraClient/UIImage+ACCUIKit.h>
#import "IESInfoSticker+ACCAdditions.h"
#import <CreationKitArch/ACCRepoContextModel.h>

CGFloat kAWESelectTimeBottomViewHeight = 204.5;
CGFloat kAWESelectTimeFramesViewHeight = 36.0;
CGFloat kAWESelectTimeFramesViewWidth = 32.0;
CGFloat kAWESelectTimeFramesViewLeft = 45;
CGFloat kAWESelectTimeFramesViewTop = 77;
CGFloat kAWESelectTimeSlideWidth = 35;
CGFloat kAWESelectTimeOffsetTime = 1 / 20;

static NSString * const AWEVideoEditStickerSelectTimeLabelFont = @"awe_video_edit_sticker_select_time_label_font";

@interface AWEVideoEditStickerSelectTimeViewController () <AWEMediaSmallAnimationProtocol, AWEVideoRangeSliderDelegate, AWESimplifiedStickerContainerViewDelegate, ACCEditPreviewMessageProtocol>

@property (nonatomic, strong) AWEVideoPublishViewModel *publishViewModel;

@property (nonatomic, strong) UIView *bottomView;
@property (nonatomic, strong) UILabel *bottomTitleLabel;
@property (nonatomic, strong) UILabel *selectTimeLabel;
@property (nonatomic, strong) UIButton *playButton;
@property (nonatomic, strong) AWEImagesView *framesView;
@property (nonatomic, strong) UIImageView *fakeWaveView;
@property (nonatomic, strong) AWEVideoRangeSlider *videoRangeSlider;
@property (nonatomic, strong) UIButton *cancelBtn;
@property (nonatomic, strong) UIButton *saveBtn;
@property (nonatomic, strong) AWESimplifiedStickerContainerView *stickerContainerView;

@property (nonatomic, assign) CGRect originalPlayerRect;
@property (nonatomic, strong) AWEEditorStickerGestureViewController *stickerGestureController;

@property (nonatomic, strong) AWEVideoImageGenerator *imageGenerator;

@property (nonatomic, strong) UIView *playerContainer;
@property (nonatomic, strong) id<ACCEditServiceProtocol> editService;
@property (nonatomic, assign) NSInteger selectedStickerEditid;
@property (nonatomic, strong) UIView <ACCStickerSelectTimeRangeProtocol> *selectedStickerView;
@property (nonatomic, copy) NSArray<AWEVideoStickerEditCircleView *> *allStickerViews;
@property (nonatomic, copy)   NSArray<IESInfoSticker *> *infoStickers;
@property (nonatomic, assign) BOOL isPlaying;
@property (nonatomic, assign) BOOL isSliding;

// 文字贴纸
@property (nonatomic, strong) AWEStoryTextContainerView *textContainerView;
@property (nonatomic, strong) UIView <ACCStickerSelectTimeRangeProtocol> *selectedTextView;
@property (nonatomic, strong) AWEStoryTextImageModel *selectedTextModel;
@property (nonatomic, strong) IESMMVideoDataClipRange *editingTextRange;

@property (nonatomic, copy) NSDictionary *initialStickerInfoDict;
@property (nonatomic, copy) NSDictionary <NSNumber *, NSValue *> *initialStickerSizeDict;

@property (nonatomic, assign) CGFloat containerScale;
@property (nonatomic, assign) CGPoint containerCenter;
@property (nonatomic, copy) NSString *currentStickerIds;

@end

@implementation AWEVideoEditStickerSelectTimeViewController

- (instancetype)initWithModel:(AWEVideoPublishViewModel *)model
                  editService:(id<ACCEditServiceProtocol>)editService
                  stickerView:(UIView <ACCStickerSelectTimeRangeProtocol> *)stickerView
            textContainerView:(AWEStoryTextContainerView *)textContainerView
           originalPlayerRect:(CGRect)playerRect
              allStickerViews:(NSArray<AWEVideoStickerEditCircleView *> *)allStickerViews
{
    self = [super init];
    if (self) {
        self.hidesBottomBarWhenPushed = YES;
        self.publishViewModel = model;
        self.editService = editService;
        if (self.editService) {//从viewDidAppear挪到这里，防止进来的时候闪屏(特效-滤镜-星星)
            CGFloat offsetTime = kAWESelectTimeOffsetTime;
            if (model.repoVideoInfo.video.previewFrameRate > 1) {
                offsetTime = 1 / model.repoVideoInfo.video.previewFrameRate;
            }
            [self.editService.preview seekToTime:CMTimeMakeWithSeconds(offsetTime, model.repoVideoInfo.video.previewFrameRate)];
            [self.editService.preview setHighFrameRateRender:YES];
            [self.editService.preview setStickerEditMode:YES];
        }
        self.allStickerViews = [allStickerViews copy];
        self.isPlaying = NO;
        self.isSliding = NO;
        self.originalPlayerRect = playerRect;
        self.textContainerView = textContainerView;
        [self updateSelectedStickerView:stickerView];
    }
    return self;
}

- (void)dealloc
{
    if (self.imageGenerator) {
        [self.imageGenerator cancel];
        self.imageGenerator = nil;
    }
    
    self.editService = nil;
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
    
    @weakify(self);
    self.stickerGestureController.gestureStartBlock = ^BOOL(UIView *editView) {
        @strongify(self);

        if ([editView isKindOfClass:[AWEStoryBackgroundTextView class]] && ((AWEStoryBackgroundTextView *)editView).isCaption) {
            return NO;
        }
        
        if ([editView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
            if (((AWEStoryBackgroundTextView *)editView).isInteractionSticker) {
                return NO;
            }
        }
        
        if ([editView isKindOfClass:[AWEStickerEditBaseView class]]) {
            [self moviePause];
            if ([self needUpdateVideoRangeSlider:(AWEStickerEditBaseView *)editView]) {
                [self videoRangeSliderAnimation];
            }
            
            if ([editView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
                self.selectedStickerView = (AWEStickerEditBaseView *)editView;
                self.selectedStickerEditid = -1;
                [self updateVideoRangeSlider];
                [self.stickerContainerView makeAllStickersResignActive];
            }
            
            if ([editView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
                 self.selectedStickerEditid = ((AWEVideoStickerEditCircleView *)editView).stickerEditId;
            }
            return YES;
        } else {
            return NO;
        }
    };

    // fix text stickers display out of time range issue. AME-67332
    [self.textContainerView updateTextViewsStatusWithCurrentPlayerTime:self.videoRangeSlider.leftPosition isSelectTime:YES];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [UIView animateWithDuration:0.2 animations:^{
        self.cancelBtn.alpha = 1;
        self.saveBtn.alpha = 1;
    }];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.editService.preview setStickerEditMode:NO];
    [self.editService.preview seekToTime:kCMTimeZero];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)prefersStatusBarHidden
{
    return YES;
}

- (void)setupPlayer
{
    [self.editService.preview resetPlayerWithViews:@[self.playerContainer]];
    [self.editService.preview setStickerEditMode:YES];
    
    self.infoStickers = self.publishViewModel.repoVideoInfo.video.infoStickers;
    [self setStickersAlpha:YES];
    [self resetStickerValidTime];
    
    self.videoRangeSlider.leftPosition = [self p_limitMaxDuration:self.selectedStickerView.realStartTime] * self.videoRangeSlider.bodyWidth / self.videoRangeSlider.maxGap;
    self.videoRangeSlider.rightPosition = [self p_limitMaxDuration:(self.selectedStickerView.realStartTime + self.selectedStickerView.realDuration)] * self.videoRangeSlider.bodyWidth / self.videoRangeSlider.maxGap;
    [self.videoRangeSlider updateTimeLabel];
    [self.videoRangeSlider showSliderAreaShow:YES animated:NO];
    [self.videoRangeSlider updateVideoIndicatorByPosition:self.videoRangeSlider.leftPosition];
    // fix AME-67332 https://jira.bytedance.com/browse/AME-67332
    CMTime currentPlayerCMTime = CMTimeMakeWithSeconds(self.videoRangeSlider.leftPosition, self.publishViewModel.repoVideoInfo.video.previewFrameRate);
    [self.editService.preview seekToTime:currentPlayerCMTime];
    [self updateTextReadAndWave:NO];
    
    [self.editService.preview addSubscriber:self];
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
        make.left.equalTo(@(kAWESelectTimeFramesViewLeft));
        make.right.equalTo(@(-kAWESelectTimeFramesViewLeft));
        make.top.equalTo(@(kAWESelectTimeFramesViewTop));
        make.height.equalTo(@(kAWESelectTimeFramesViewHeight));
    });
    
    // 裁剪框
    [self.bottomView addSubview:self.videoRangeSlider];
    self.videoRangeSlider.bubleText = self.selectTimeLabel;
    
    if (self.selectedTextModel.readModel.useTextRead) {
        UIView *fakeWaveContainer = [[UIView alloc] initWithFrame:self.framesView.frame];
        fakeWaveContainer.clipsToBounds = YES;
        [self.bottomView insertSubview:fakeWaveContainer belowSubview:self.videoRangeSlider];
        ACCMasMaker(fakeWaveContainer, {
            make.width.equalTo(self.framesView);
            make.height.equalTo(@30.f);
            make.centerX.equalTo(self.framesView);
            make.centerY.equalTo(self.framesView);
        });
        
        UIView *fakeBGView = [[UIView alloc] init];
        fakeBGView.backgroundColor = ACCResourceColor(ACCColorBGCreation5);
        [fakeWaveContainer addSubview:fakeBGView];
        ACCMasMaker(fakeBGView, {
            make.edges.equalTo(self.framesView);
        });
        
        CGFloat durationRate = 1.f;
        CGFloat waveLength = self.videoRangeSlider.bodyWidth;
        UIImage *waveImage = ACCResourceImage(@"ic_text_reading_fake_wave");
        
        if (self.videoRangeSlider.maxGap > 0 && self.videoRangeSlider.bodyWidth > 0) {
            CGFloat audioDuration = 0;
            if(self.selectedTextModel.readModel.stickerKey) {
                audioDuration = [self.publishViewModel.repoSticker.textReadingRanges objectForKey:self.selectedTextModel.readModel.stickerKey].durationSeconds;
            }
            durationRate = audioDuration/self.videoRangeSlider.maxGap;
            waveLength *= durationRate;
            waveImage = [waveImage btd_imageCroppingFromRect:CGRectMake(0.f, 0.f, waveImage.size.width*waveLength/365.f, waveImage.size.height)];
        }
        
        self.fakeWaveView = [[UIImageView alloc] initWithFrame:CGRectMake(0.f, 0.f, waveLength, self.framesView.bounds.size.height)];
        self.fakeWaveView.image = waveImage;
        [fakeWaveContainer addSubview:self.fakeWaveView];
    }
    
    // 播放
    [self.view addSubview:self.playerContainer];
    
    // Sticker Gesture Recognizer
    [self.view addSubview:self.stickerGestureController.view];
    // Sticker Container View
    [self.view addSubview:self.stickerContainerView];
    
    [self.stickerGestureController configSimpliedInfoStickerContainer:self.stickerContainerView];
    
    if (self.textContainerView) {
        [self configScale];
        [self.playerContainer addSubview:self.textContainerView];
        self.textContainerView.transform = CGAffineTransformMakeScale(self.containerScale, self.containerScale);
        self.textContainerView.center = self.containerCenter;
        [self.stickerGestureController configTextStickerContainer:self.textContainerView];
        [self makeMaskLayerForTextContainer];
    }
    
    if (self.interactionImageView) {
        [self.playerContainer addSubview:self.interactionImageView];
        ACCMasMaker(self.interactionImageView, {
            make.edges.equalTo(self.playerContainer);
        });
    }
}

- (void)updateSelectedStickerView:(UIView <ACCStickerSelectTimeRangeProtocol>*)stickerView
{
    if ([stickerView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        self.selectedStickerView = (AWEVideoStickerEditCircleView *)stickerView;
        self.selectedStickerEditid = ((AWEVideoStickerEditCircleView *)stickerView).stickerEditId;
    } else if ([stickerView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
        self.selectedStickerEditid = -1;
        [self.textContainerView.textViews enumerateObjectsUsingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj.textStickerId isEqualToString:((AWEStoryBackgroundTextView *)stickerView).textStickerId]) {
                self.selectedStickerView = obj;
                *stop = YES;
            }
        }];
    } else {
        self.selectedStickerView = stickerView;
        self.selectedStickerEditid = -1;
    }

    [self resetStickerValidTime];
}

- (void)updateSelectedTextReadModel:(AWEStoryTextImageModel *)textModel
{
    self.selectedTextModel = textModel;
}

- (void)showFrameImages
{
    if (self.preLoadFramesArray) {
        [self.framesView refreshWithImageArray:self.preLoadFramesArray aspectRatio:kAWESelectTimeFramesViewWidth / kAWESelectTimeFramesViewHeight mode:AWEImagesViewContentModePreserveAspectRatioAndFill];
    } else {
        [self loadFirstPreviewFrame];
        [self reloadPreviewFrames];
    }
}

- (void)loadFirstPreviewFrame
{
    CGFloat scale = [UIScreen mainScreen].scale;
    @weakify(self);
    [self.editService.captureFrame getSourcePreviewImageAtTime:0 preferredSize:CGSizeMake(scale * kAWESelectTimeFramesViewWidth, scale * kAWESelectTimeFramesViewHeight) compeletion:^(UIImage * _Nonnull image, NSTimeInterval atTime) {
        NSMutableArray *previewImageArray = @[].mutableCopy;
        if (image) {
            @strongify(self);
            image = [image acc_blurredImageWithRadius:15];
            [previewImageArray addObject:image];
            AWEImagesViewContentMode mode = AWEImagesViewContentModePreserveAspectRatioAndFill;
            if (image.size.width > image.size.height) {
                mode = AWEImagesViewContentModePreserveAspectRatio;
            }
            [self.framesView refreshWithImageArray:previewImageArray aspectRatio:kAWESelectTimeFramesViewWidth / kAWESelectTimeFramesViewHeight mode:mode];
        }
    }];
}

- (void)reloadPreviewFrames
{
    if (self.preLoadFramesArray.count) {
        return;
    }
    NSInteger count = ceil((ACC_SCREEN_WIDTH - 2 * kAWESelectTimeFramesViewLeft) / kAWESelectTimeFramesViewWidth);
    if (count == 0) {
        return;
    }
    
    CGFloat totalDuration = [self.publishViewModel.repoVideoInfo.video totalVideoDuration];
    CGFloat step = totalDuration / count;
    NSMutableArray *previewImageDictArray = @[].mutableCopy;
    
    __weak typeof(self) weakSelf = self;
    [self.imageGenerator cancel];
    [ACCAPM() attachFilter:@"edit_time" forKey:@"extracting_frame"];
    NSTimeInterval imageGeneratorBegin = CFAbsoluteTimeGetCurrent();
    
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize imageSize = CGSizeMake(540, 960);
    if (self.publishViewModel.repoVideoInfo.sizeOfVideo && !self.editService.preview.previewEdge) {
        imageSize = self.publishViewModel.repoVideoInfo.sizeOfVideo.CGSizeValue;
    }
         
    if (imageSize.width > 0) {
        imageSize = CGSizeMake(kAWESelectTimeFramesViewWidth * scale, kAWESelectTimeFramesViewWidth * scale * imageSize.height / imageSize.width);
    }

    [self.imageGenerator requestImages:count effect:YES index:0 step:step size:imageSize array:previewImageDictArray editService:self.editService oneByOneImageBlock:nil completion:^{
        NSMutableArray *previewImageArray = @[].mutableCopy;
        [previewImageDictArray enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [previewImageArray addObject:obj[@"image"]];
        }];
        weakSelf.preLoadFramesArray = previewImageArray;
        [self.framesView refreshWithImageArray:previewImageArray aspectRatio:kAWESelectTimeFramesViewWidth / kAWESelectTimeFramesViewHeight mode:AWEImagesViewContentModePreserveAspectRatioAndFill];
        if ([self.stickerContainerView hasAnyPinnedInfoSticker]) {
            [weakSelf.editService.preview setStickerEditMode:YES];
        }
        [ACCAPM() attachFilter:nil forKey:@"extracting_frame"];
        
        //performance track
        [ACCAssetImageGeneratorTracker trackAssetImageGeneratorWithType:ACCAssetImageGeneratorTypeStickerSelectTime frames:count
                                                              beginTime:imageGeneratorBegin extra:weakSelf.publishViewModel.repoTrack.commonTrackInfoDic];
    }];
}

#pragma mark - getter

- (UIView *)bottomView
{
    if (_bottomView == nil) {
        _bottomView = [[UIView alloc] initWithFrame:CGRectMake(0, ACC_SCREEN_HEIGHT - kAWESelectTimeBottomViewHeight - ACC_IPHONE_X_BOTTOM_OFFSET, ACC_SCREEN_WIDTH, kAWESelectTimeBottomViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET)];
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
        _selectTimeLabel.text = [NSString stringWithFormat:ACCLocalizedString(@"com_mig_selected_sticker_lasts_for_1fs",@"已选取贴纸持续时间 %.1fs"), self.publishViewModel.repoVideoInfo.video.totalVideoDuration];
        _selectTimeLabel.textAlignment = NSTextAlignmentLeft;
        _selectTimeLabel.textColor = ACCResourceColor(ACCUIColorConstTextInverse);
        _selectTimeLabel.font = ACCResourceFont(AWEVideoEditStickerSelectTimeLabelFont);
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
        _framesView = [[AWEImagesView alloc] initWithFrame:CGRectMake(kAWESelectTimeFramesViewLeft, kAWESelectTimeFramesViewTop, ACC_SCREEN_WIDTH - 2 * kAWESelectTimeFramesViewLeft, kAWESelectTimeFramesViewHeight)];
        _framesView.accrtl_viewType = ACCRTLViewTypeNormal;
    }
    return _framesView;
}

- (AWEVideoRangeSlider *)videoRangeSlider
{
    if (!_videoRangeSlider) {
        _videoRangeSlider = [[AWEVideoRangeSlider alloc] initWithFrame:CGRectMake(kAWESelectTimeFramesViewLeft - kAWESelectTimeSlideWidth, kAWESelectTimeFramesViewTop - 2, ACC_SCREEN_WIDTH - kAWESelectTimeFramesViewLeft * 2 + kAWESelectTimeSlideWidth * 2, kAWESelectTimeFramesViewHeight + 4)
                                slideWidth:kAWESelectTimeSlideWidth
                               cursorWidth:4
                                    height:48
                             hasSelectMask:YES];
        _videoRangeSlider.delegate = self;
        _videoRangeSlider.enterFromType = AWEEnterFromTypeStickerSelectTime;
        _videoRangeSlider.maxGap = [self p_limitMaxDuration:self.publishViewModel.repoVideoInfo.video.totalVideoDuration];
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
        _cancelBtn.alpha = 0;
        [_cancelBtn setImage:ACCResourceImage(@"ic_camera_cancel") forState:UIControlStateNormal];
        [_cancelBtn addTarget:self action:@selector(didClickCancelBtn:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _cancelBtn;
}

- (UIButton *)saveBtn
{
    if (!_saveBtn) {
        _saveBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        _saveBtn.alpha = 0;
        [_saveBtn setImage:ACCResourceImage(@"ic_camera_save") forState:UIControlStateNormal];
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

- (AWESimplifiedStickerContainerView *)stickerContainerView
{
    if (!_stickerContainerView) {
        _stickerContainerView = [[AWESimplifiedStickerContainerView alloc] initWithFrame:[self mediaSmallMediaContainerFrame] publishModel:self.publishViewModel playerOriginalRect:self.originalPlayerRect];
        _stickerContainerView.editService = self.editService;
        _stickerContainerView.delegate = self;
    }
    return _stickerContainerView;
}

- (AWEVideoImageGenerator *)imageGenerator
{
    if (!_imageGenerator) {
        _imageGenerator = [[AWEVideoImageGenerator alloc] init];
    }
    return _imageGenerator;
}

- (AWEEditorStickerGestureViewController *)stickerGestureController
{
    if (!_stickerGestureController) {
        _stickerGestureController = [[AWEEditorStickerGestureViewController alloc] init];
        _stickerGestureController.view.frame = [self mediaSmallMediaContainerFrame];
    }
    
    return _stickerGestureController;
}

#pragma mark - action

- (void)clickPlayButton:(id)sender
{
    if (self.isPlaying) {
        [self moviePause];
        // 这种状态下需要恢复之前选中的sticker
        [self.stickerContainerView restoreLastTimeSelectStickerView];
    } else {
        [self moviePlay];
    }
}

- (void)didClickCancelBtn:(id)sender
{
    [self restoreViewToOriginalState];
    for (AWEVideoStickerEditCircleView *view in self.allStickerViews) {
        CGFloat duration = view.realDuration;
        if (ACC_FLOAT_EQUAL_TO(duration, self.publishViewModel.repoVideoInfo.video.totalVideoDuration)) {
            duration = -1;
        }
        [self.editService.sticker setSticker:view.stickerEditId startTime:view.realStartTime duration:duration];
    }
    [self p_trackTimeSetCancel];
    [self p_dismissForSave:NO];
}

- (void)didClickSaveBtn:(id)sender
{
    for (AWEVideoStickerEditCircleView *view in self.allStickerViews) {
        view.realStartTime = view.finalStartTime;
        view.realDuration = view.finalDuration;
        CGFloat duration = view.realDuration;
        if (duration + 0.15 > self.publishViewModel.repoVideoInfo.video.totalVideoDuration) {
            view.realDuration = duration + 0.15;
            duration = -1;
        }
        [self.editService.sticker setSticker:view.stickerEditId startTime:view.realStartTime duration:duration];
    }
    
    [self.textContainerView.textViews enumerateObjectsUsingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.realStartTime = obj.finalStartTime;
        obj.realDuration = obj.finalDuration;
    }];
    
    if (self.editingTextRange && self.selectedTextModel.readModel.useTextRead && self.selectedTextModel.readModel.stickerKey) {
        [self.publishViewModel.repoSticker.textReadingRanges setObject:self.editingTextRange forKey:self.selectedTextModel.readModel.stickerKey];
    }
    [self p_trackTimeSetConfirm];
    [self p_dismissForSave:YES];
}

- (void)p_dismissForSave:(BOOL)isSave
{
    [self setStickersAlpha:NO];
    @weakify(self);
    if (self.transitionService) {
        [self.transitionService dismissViewController:self completion:^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.didDismissBlock, self.textContainerView, isSave);
        }];
    } else {
        [self dismissViewControllerAnimated:YES completion:^{
            @strongify(self);
            ACCBLOCK_INVOKE(self.didDismissBlock, self.textContainerView, isSave);
        }];
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
    CGFloat playerHeight = ACC_SCREEN_HEIGHT - kAWESelectTimeBottomViewHeight - ACC_IPHONE_X_BOTTOM_OFFSET - playerY;
    CGFloat playerWidth = self.view.acc_width;
    CGFloat playerX = (self.view.acc_width - playerWidth) * 0.5;
    CGSize videoSize = CGSizeMake(540, 960);
    if (!CGRectEqualToRect(self.publishViewModel.repoVideoInfo.playerFrame, CGRectZero)) {
        videoSize = self.publishViewModel.repoVideoInfo.playerFrame.size;
    }
    return AVMakeRectWithAspectRatioInsideRect(videoSize, CGRectMake(playerX, playerY, playerWidth, playerHeight));
}

#pragma mark - AWEVideoRangeSliderDelegate

- (void)videoRangeDidBeginByType:(AWEThumbType)type
{
    AWELogToolInfo(AWELogToolTagEdit, @"sticker select time, videoRangeDidBeginByType %@", @(type));
    self.videoRangeSlider.rangeChangeCount = 0;
    
    [self moviePause];
    self.isSliding = YES;
    if (type != AWEThumbTypeCursor && [self.selectedStickerView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        [self.editService.sticker startChangeStickerDuration:self.selectedStickerEditid];
    }
}

- (void)videoRangeDidEndByType:(AWEThumbType)type
{
    AWELogToolInfo(AWELogToolTagEdit, @"sticker select time, videoRangeDidEndByType %@, rangeChangeCount %ld",@(type),(long)self.videoRangeSlider.rangeChangeCount);
    self.videoRangeSlider.rangeChangeCount = 0;
    
    self.isSliding = NO;
    if (type != AWEThumbTypeCursor && [self.selectedStickerView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        [self.editService.sticker stopChangeStickerDuration:self.selectedStickerEditid];
    }
        
    if (type == AWEThumbTypeCursor) {
        return;
    } else if (type == AWEThumbTypeLeft) {
        [self updateTextReadAndWave:YES];
    }
    
    CMTime startCMTime = CMTimeMakeWithSeconds(self.videoRangeSlider.leftPosition, self.publishViewModel.repoVideoInfo.video.previewFrameRate);
    CMTime endCMTime = CMTimeMakeWithSeconds(self.videoRangeSlider.rightPosition, self.publishViewModel.repoVideoInfo.video.previewFrameRate);
    CMTime subCMTime = CMTimeSubtract(endCMTime, startCMTime);
    
    CGFloat startTime = CMTimeGetSeconds(startCMTime);
    CGFloat duration = CMTimeGetSeconds(subCMTime);
    
    self.selectedStickerView.finalStartTime = startTime;
    self.selectedStickerView.finalDuration = duration;
    
    if (ACC_FLOAT_EQUAL_TO(duration, self.publishViewModel.repoVideoInfo.video.totalVideoDuration)) {
        duration = -1;
    }
    
    if ([self.selectedStickerView isKindOfClass:[AWEVideoStickerEditCircleView class]]) {
        [self.editService.sticker setSticker:self.selectedStickerEditid startTime:startTime duration:duration];
    }
}

- (void)videoRangeDidChangByPosition:(CGFloat)position movedType:(AWEThumbType)type
{
    CMTime currentPlayerCMTime = CMTimeMakeWithSeconds(position, self.publishViewModel.repoVideoInfo.video.previewFrameRate);
    CGFloat currentPlayerTime = CMTimeGetSeconds(currentPlayerCMTime);
    ACCLog(@"seekToTimeAndRender %.2f",currentPlayerTime);
    
    if (!self.editService) {
        AWELogToolInfo(AWELogToolTagEdit, @"sticker select time, videoRangeDidChangByPosition exception, movedType %lu",(unsigned long)type);
    } else {
        self.videoRangeSlider.rangeChangeCount +=1;
    }
    
    if (type == AWEThumbTypeLeft) {
        [self updateTextReadAndWave:NO];
    }

    CMTime startCMTime = CMTimeMakeWithSeconds(self.videoRangeSlider.leftPosition, self.publishViewModel.repoVideoInfo.video.previewFrameRate);
    CMTime endCMTime = CMTimeMakeWithSeconds(self.videoRangeSlider.rightPosition, self.publishViewModel.repoVideoInfo.video.previewFrameRate);
    CMTime subCMTime = CMTimeSubtract(endCMTime, startCMTime);

    CGFloat startTime = CMTimeGetSeconds(startCMTime);
    CGFloat duration = CMTimeGetSeconds(subCMTime);

    if ([self.selectedStickerView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
        self.selectedStickerView.finalStartTime = startTime;
        self.selectedStickerView.finalDuration = duration;
    }
    
    [self.editService.preview seekToTime:currentPlayerCMTime];
    [self.textContainerView updateTextViewsStatusWithCurrentPlayerTime:currentPlayerTime isSelectTime:YES];
}

- (BOOL)videoRangeIgnoreGesture
{
    return self.isPlaying;
}

- (void)trackSliderAdjustment
{
    [self p_trackTimeSetAdjust];
}

#pragma mark - AWEStickerContainerViewDelegate

- (void)setSticker:(NSInteger)stickerEditId offsetX:(CGFloat)x offsetY:(CGFloat)y angle:(CGFloat)angle scale:(CGFloat)scale
{
    [self.editService.sticker setSticker:stickerEditId offsetX:x offsetY:y angle:angle scale:scale];
}

- (void)setSticker:(NSInteger)stickerEditId scale:(CGFloat)scale
{
    [self.editService.sticker setStickerScale:stickerEditId scale:scale];
}

- (BOOL)activeSticker:(NSInteger)stickerEditId
{
    BOOL active = NO;
    for (AWEVideoStickerEditCircleView *view in self.allStickerViews) {
        if (view.stickerEditId == stickerEditId) {
            if ([self needUpdateVideoRangeSlider:view]) {
                self.selectedStickerView = view;
                self.selectedStickerEditid = stickerEditId;
                [self updateVideoRangeSlider];
                [self.editService.sticker setStickerAboveForInfoSticker:stickerEditId];
            }
            active = YES;
            break;
        }
    }
    return active;
}

- (BOOL)needUpdateVideoRangeSlider:(AWEStickerEditBaseView *)view
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

- (void)cancelPinSticker:(NSInteger)stickerEditId {
    if ([self.editService.sticker getStickerVisible:stickerEditId]) {
        [self.editService.sticker cancelPin:stickerEditId];
    }
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime
{
    if (!self.isSliding) {
        [self.videoRangeSlider updateVideoIndicatorByPosition:currentTime];
        [self.textContainerView updateTextViewsStatusWithCurrentPlayerTime:currentTime isSelectTime:YES];
    }
}


#pragma mark - AWEEditorStickerGestureViewControllerDelegate

//- (BOOL)enableTapGesture
//{
//    return NO;
//}

#pragma mark - Setter

- (void)setSelectedStickerView:(AWEVideoStickerEditCircleView *)selectedStickerView
{
    _selectedStickerView = selectedStickerView;
    if (_selectedTextView) {
        _selectedTextView = nil;
    }
}

- (void)setSelectedTextView:(AWEStoryBackgroundTextView *)selectedTextView
{
    _selectedTextView = selectedTextView;
    if (_selectedStickerView) {
        _selectedStickerView = nil;
    }
}

- (void)setSelectedStickerEditid:(NSInteger)selectedStickerEditid
{
    _selectedStickerEditid = selectedStickerEditid;
    [self setStickersAlpha:YES];
}

#pragma mark - private

- (CGFloat)p_limitMaxDuration:(CGFloat)totalDuration
{
    if (self.publishViewModel.repoContext.videoSource == AWEVideoSourceCapture &&
        totalDuration > self.publishViewModel.repoContext.maxDuration) {
        return self.publishViewModel.repoContext.maxDuration;
    }
    return totalDuration;
}

- (void)moviePlay
{
    [self.editService.preview setStickerEditMode:NO];
    [self.videoRangeSlider showSliderAreaShow:NO animated:YES];
    [self.videoRangeSlider.bubleText setText:ACCLocalizedString(@"tap_the_sticker_to_set_it_duration",@"点击贴纸进行时长设置")];
    [self.playButton setSelected:YES];
    self.isPlaying = YES;
    self.fakeWaveView.hidden = YES;
    
    [self setStickersAlpha:NO];
    [self.stickerContainerView makeAllStickersResignActive];
}

- (void)moviePause
{
    [self.editService.preview setStickerEditMode:YES];
    [self.videoRangeSlider showSliderAreaShow:YES animated:YES];
    [self.playButton setSelected:NO];
    self.isPlaying = NO;
    [self.videoRangeSlider updateTimeLabel];
    self.fakeWaveView.hidden = NO;
    
    [self setStickersAlpha:YES];
}

- (void)setStickersAlpha:(BOOL)isAlpha
{
    if ([self.selectedStickerView isKindOfClass:[AWEStoryBackgroundTextView class]]) {
        [self.textContainerView startSelectTimeForTextView:(AWEStoryBackgroundTextView *)self.selectedStickerView isAlpha:isAlpha];
    } else {
        [self.textContainerView startSelectTimeForTextView:nil isAlpha:isAlpha];
    }
    
    for (IESInfoSticker *infoSticker in self.infoStickers) {
        if (isAlpha && infoSticker.stickerId != self.selectedStickerEditid) {
            [self.editService.sticker setSticker:infoSticker.stickerId alpha:0.34];
        } else {
            [self.editService.sticker setSticker:infoSticker.stickerId alpha:1];
        }
    }
    
    if (self.interactionImageView) {
        self.interactionImageView.alpha = isAlpha? 0.5 : 1;
    }
    
    if ([self.editService.effect currentBrushNumber] > 0) {
        [self.editService.effect setBrushCanvasAlpha:isAlpha ? 0.5 : 1];
    }
}

- (void)recoverStickerView
{
    NSMutableDictionary *tmpInfoDict = [NSMutableDictionary dictionary];
    NSMutableDictionary <NSNumber *, NSValue *> *tmpSizeDict = [NSMutableDictionary dictionary];
    NSMutableArray *currentStickerIds = [[NSMutableArray alloc] init];
    for (IESInfoSticker *infoSticker in self.publishViewModel.repoVideoInfo.video.infoStickers) {
        if (infoSticker.isNeedRemove || infoSticker.acc_isNotNormalInfoSticker) {
            continue;
        }
        
        IESInfoStickerProps *props = [IESInfoStickerProps new];
        [self.editService.sticker getStickerId:infoSticker.stickerId props:props];
        
        CGFloat videoDuration = self.publishViewModel.repoVideoInfo.video.totalVideoDuration;
        if (props.duration < 0 || props.duration > videoDuration) {
            props.duration = videoDuration;
        }
        if (props.userInfo[@"stickerID"] && [props.userInfo[@"stickerID"] isKindOfClass:[NSString class]]) {
            NSString *stickerId = (NSString *)props.userInfo[@"stickerID"];
            if (stickerId.length > 0) {
                [currentStickerIds addObject:stickerId];
            }
        }
        
        tmpInfoDict[@(infoSticker.stickerId)] = [self createStickerInfoWithInfo:props];
        
        CGSize size = [self.editService.sticker getstickerEditBoxSize:infoSticker.stickerId];
        tmpSizeDict[@(infoSticker.stickerId)] = [NSValue valueWithCGSize:size];
        if ([ACCRTL() isRTL]) {
            props.angle = -props.angle;
        }
        [self.stickerContainerView recoverStickerWithStickerInfos:props editSize:size setCurrentSticker:infoSticker.stickerId == self.selectedStickerEditid];
    }
    for (AWEVideoStickerEditCircleView *view in self.allStickerViews) {
        view.finalStartTime = view.realStartTime;
        view.finalDuration = view.realDuration;
    }

    self.initialStickerInfoDict = [tmpInfoDict copy];
    self.initialStickerSizeDict = [tmpSizeDict copy];
    self.currentStickerIds = [currentStickerIds componentsJoinedByString:@","];
}

- (void)restoreViewToOriginalState
{
    NSArray<NSNumber *> *canceledPinStickerIdArray = self.stickerContainerView.cancelPinStickerIdArray;

    for (IESInfoSticker *infoSticker in self.publishViewModel.repoVideoInfo.video.infoStickers) {
        if (infoSticker.isNeedRemove || infoSticker.acc_isNotNormalInfoSticker) {
            continue;
        }

        if (canceledPinStickerIdArray.count > 0) {
            __block BOOL shouldContinue = NO;
            [canceledPinStickerIdArray enumerateObjectsUsingBlock:^(NSNumber * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                if (obj.integerValue == infoSticker.stickerId) {
                    // 说明这个贴纸进来的时候是被Pin住的，但是在此选择时间页面被取消Pin了，那就保留当前位置
                    shouldContinue = YES;
                    *stop = YES;
                }
            }];
            if (shouldContinue) {
                // 跳过，不恢复当前贴纸id的位置
                continue;
            }
        }
        
        if (self.initialStickerInfoDict[@(infoSticker.stickerId)] &&
            self.initialStickerSizeDict[@(infoSticker.stickerId)]) {
            CGSize currentSize = [self.editService.sticker getstickerEditBoxSize:infoSticker.stickerId];
            CGSize initialSize =  [self.initialStickerSizeDict[@(infoSticker.stickerId)] CGSizeValue];
            if (initialSize.width <= ACC_FLOAT_ZERO || initialSize.height <= ACC_FLOAT_ZERO) {
                initialSize = currentSize;
            }
            
            IESInfoStickerProps *currentProps = [IESInfoStickerProps new];
            [self.editService.sticker getStickerId:infoSticker.stickerId props:currentProps];
            
            IESInfoStickerProps *initialProps = self.initialStickerInfoDict[@(infoSticker.stickerId)];
        
             /*!
              the old way to calculate target scale :  "CGFloat initialScale = [self.initialStickerSizeDict[@(infoSticker.stickerId)] floatValue] / size.width"
              It was used  'width'  to calculate scale,  may case bugs with ' lyrics sticker' ,
              because the size of  lyrics sticker is dynamic, so the current size may changed
              now, using initial scale  and current scale to calculate the correct  target scale
             */
            CGFloat currentScale = (currentProps.scale <= ACC_FLOAT_ZERO) ? 1.f : currentProps.scale;
            CGFloat targetRecoverScale =  initialProps.scale / currentScale;
            /*!
             * the size of the lyrics sticker is dynamic, and  offsetX and offsetY is  based on the center
             * so need to calculate the diff from  'size change', then fix target offset with diff
             * !!!can not using currentProps's offset value,  because the sticker may transformed in this controller
             * @discussion this kind of sticker is easy to cause bugs because of the ' dynamic size'
             *             and it is better to take and using a image snapshoot before enter?
             */
            CGFloat correctXOffset = (currentSize.width  * targetRecoverScale - initialSize.width ) / 2;
            CGFloat correctYOffset = (currentSize.height * targetRecoverScale - initialSize.height) / 2;
            
            [self.editService.sticker setSticker:infoSticker.stickerId
                                              offsetX:initialProps.offsetX + correctXOffset
                                              offsetY:initialProps.offsetY + correctYOffset
                                                angle:initialProps.angle
                                                scale:targetRecoverScale];
        }
    }
    
    if (self.selectedTextModel.readModel.useTextRead && self.selectedTextModel.readModel.stickerKey) {
        AVAsset *audioAsset = [self.publishViewModel.repoSticker audioAssetInVideoDataWithKey:self.selectedTextModel.readModel.stickerKey];
        IESMMVideoDataClipRange *audioRange = [self.publishViewModel.repoSticker.textReadingRanges objectForKey:self.selectedTextModel.readModel.stickerKey];
        [self.editService.audioEffect setAudioClipRange:audioRange forAudioAsset:audioAsset];
    }
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
    CGFloat leftPosition = [self p_limitMaxDuration:self.selectedStickerView.finalStartTime] * self.videoRangeSlider.bodyWidth / self.videoRangeSlider.maxGap;
    self.videoRangeSlider.leftPosition = leftPosition;
    CGFloat rightPosition = [self p_limitMaxDuration:(self.selectedStickerView.finalStartTime + self.selectedStickerView.finalDuration)] * self.videoRangeSlider.bodyWidth / self.videoRangeSlider.maxGap;
    [self.videoRangeSlider updateActualRightPosition:rightPosition];
    [self.videoRangeSlider updateTimeLabel];
}

- (void)updateTextReadAndWave:(BOOL)adjustAudio
{
    self.fakeWaveView.acc_left = self.videoRangeSlider.leftPosition/self.videoRangeSlider.maxGap * self.videoRangeSlider.bodyWidth;
    if (adjustAudio && self.selectedTextModel.readModel.useTextRead && self.selectedTextModel.readModel.stickerKey) {
        AVAsset *audioAsset = [self.publishViewModel.repoSticker audioAssetInVideoDataWithKey:self.selectedTextModel.readModel.stickerKey];
        IESMMVideoDataClipRange *audioRange = [self.publishViewModel.repoSticker.textReadingRanges objectForKey:self.selectedTextModel.readModel.stickerKey];
        
        self.editingTextRange = [[IESMMVideoDataClipRange alloc] init];
        self.editingTextRange.attachSeconds = self.videoRangeSlider.leftPosition;
        self.editingTextRange.durationSeconds = audioRange.durationSeconds;
        
        [self.editService.audioEffect setAudioClipRange:self.editingTextRange forAudioAsset:audioAsset];
    }
}

- (void)makeMaskLayerForTextContainer
{
    CGRect frame = [self.view convertRect:self.playerContainer.frame toView:self.textContainerView];
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];
    
    layer.path = path.CGPath;
    self.textContainerView.layer.mask = layer;
}

- (void)makeMaskLayerForContainerView:(UIView *)view
{
    CGRect frame = [self.view convertRect:self.playerContainer.frame toView:view];
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];

    layer.path = path.CGPath;
    view.layer.mask = layer;
}

- (void)resetStickerValidTime
{
    CGFloat timeMachineDuration = self.publishViewModel.repoVideoInfo.video.totalDurationWithTimeMachine;
    CGFloat videoDataDuration = self.publishViewModel.repoVideoInfo.video.totalVideoDuration;
    NSTimeInterval duration =  timeMachineDuration > videoDataDuration ? timeMachineDuration : videoDataDuration;
    
    [self.allStickerViews enumerateObjectsUsingBlock:^(AWEVideoStickerEditCircleView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {

        if (obj.realStartTime + obj.realDuration > duration && duration > 0) {
            obj.realDuration = duration - obj.realStartTime;
        }
        obj.finalStartTime = obj.realStartTime;
        obj.finalDuration = obj.realDuration;
    }];
    
    [self.textContainerView.textViews enumerateObjectsUsingBlock:^(AWEStoryBackgroundTextView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (obj.realStartTime + obj.realDuration > duration && duration > 0) {
            obj.realDuration = duration - obj.realStartTime;
        }
        
        if (obj.realDuration < 0) {
            obj.realDuration = self.publishViewModel.repoVideoInfo.video.totalVideoDuration + 0.1;
        }
        obj.finalStartTime = obj.realStartTime;
        obj.finalDuration = obj.realDuration;
    }];
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

#pragma mark - Track
- (void)p_trackTimeSetCancel
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
    params[@"prop_ids"] = self.currentStickerIds ?: @"";
    
    NSString *event = @"prop_timeset_cancel";
    if ([self.selectedStickerView isKindOfClass:AWEVideoStickerEditCircleView.class]) {
        params[@"is_diy_prop"] = @(((AWEVideoStickerEditCircleView *)self.selectedStickerView).isCustomUploadSticker);
    } else {
        params[@"is_diy_prop"] = @(NO);
    }
    [params setObject:@(self.selectedTextModel.readModel.useTextRead) forKey:@"is_text_reading"];
    // Different event in text sticker
    if ([self.selectedStickerView isKindOfClass:[AWEStoryBackgroundTextView class]] || self.selectedTextModel) {
        event = @"text_timeset_cancel";
        [params setValue:(self.selectedTextModel.isAddedInEditView ? @"general_mode" : @"text_mode") forKey:@"text_type"];
    }
    
    [ACCTracker() trackEvent:event
                      params:[params copy]
             needStagingFlag:NO];
}

- (void)p_trackTimeSetConfirm
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
    params[@"prop_ids"] = self.currentStickerIds ?: @"";
    
    NSString *event = @"prop_timeset_confirm";
    if ([self.selectedStickerView isKindOfClass:AWEVideoStickerEditCircleView.class]) {
        params[@"is_diy_prop"] = @(((AWEVideoStickerEditCircleView *)self.selectedStickerView).isCustomUploadSticker);
    } else {
        params[@"is_diy_prop"] = @(NO);
    }
    [params setObject:@(self.selectedTextModel.readModel.useTextRead) forKey:@"is_text_reading"];
    // Different event in text sticker
    if ([self.selectedStickerView isKindOfClass:[AWEStoryBackgroundTextView class]] || self.selectedTextModel) {
        event = @"text_timeset_confirm";
        [params setValue:(self.selectedTextModel.isAddedInEditView ? @"general_mode" : @"text_mode") forKey:@"text_type"];
    }
    
    [ACCTracker() trackEvent:event
                      params:params
             needStagingFlag:NO];
}

- (void)p_trackTimeSetAdjust
{
    NSMutableDictionary *params = [NSMutableDictionary dictionaryWithDictionary:self.publishViewModel.repoTrack.referExtra];
    params[@"prop_ids"] = self.currentStickerIds ?: @"";
    if([self.selectedStickerView isKindOfClass:AWEVideoStickerEditCircleView.class]) {
        params[@"is_diy_prop"] = @(((AWEVideoStickerEditCircleView *)self.selectedStickerView).isCustomUploadSticker);
    } else {
        params[@"is_diy_prop"] = @(NO);
    }
    [params setObject:@(self.selectedTextModel.readModel.useTextRead) forKey:@"is_text_reading"];
    NSString *event = @"prop_duration_adjust";
    // Different event in text sticker
    if ([self.selectedStickerView isKindOfClass:[AWEStoryBackgroundTextView class]] || self.selectedTextModel) {
        event = @"text_duration_adjust";
        [params setValue:(self.selectedTextModel.isAddedInEditView ? @"general_mode" : @"text_mode") forKey:@"text_type"];
    }
    
    [ACCTracker() trackEvent:event params:params needStagingFlag:NO];
}

@end
