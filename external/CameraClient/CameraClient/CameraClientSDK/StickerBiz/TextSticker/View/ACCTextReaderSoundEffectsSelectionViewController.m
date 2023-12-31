//
//  ACCTextReaderSoundEffectsSelectionViewController.m
//  CameraClient-Pods-Aweme
//
//  Created by Daniel on 2021/3/2.
//

#import "ACCTextReaderSoundEffectsSelectionViewController.h"

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreationKitInfra/AWEMediaSmallAnimationProtocol.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>

#import "ACCTextReaderSoundEffectsSelectionBottomView.h"
#import "ACCConfigKeyDefines.h"

@interface ACCTextReaderSoundEffectsSelectionViewController ()
<
UIGestureRecognizerDelegate,
ACCEditPreviewMessageProtocol,
AWEMediaSmallAnimationProtocol
>

@property (nonatomic, strong) UIImageView *playButton;
@property (nonatomic, strong) UIButton *playBtn;
@property (nonatomic, strong) UIView *playerContainer;
@property (nonatomic, strong) ACCStickerContainerView *stickerContainerView;
@property (nonatomic, strong) ACCTextReaderSoundEffectsSelectionBottomView *bottomView;

@property (nonatomic, weak) id<ACCStickerPlayerApplying> player;
@property (nonatomic, weak) id<ACCEditServiceProtocol> editService;
@property (nonatomic, weak) id<ACCEditTransitionServiceProtocol> transitionService;
@property (nonatomic, weak) id<ACCTextReaderSoundEffectsSelectionViewControllerProviderProtocol> dataProvider;
@property (nonatomic, assign) CGFloat containerScale;
@property (nonatomic, assign) CGPoint containerCenter;
@property (nonatomic, assign) CGRect originalPlayerRect;
@property (nonatomic, strong) UITapGestureRecognizer *togglePlayingTapGesture;

@end

@implementation ACCTextReaderSoundEffectsSelectionViewController

- (instancetype)initWithEditService:(id<ACCEditServiceProtocol>)editService
               stickerContainerView:(ACCStickerContainerView *)stickerContainerView
                             player:(id<ACCStickerPlayerApplying>) player
                  transitionService:(id<ACCEditTransitionServiceProtocol>)transitionService
                       dataProvider:(id<ACCTextReaderSoundEffectsSelectionViewControllerProviderProtocol>)dataProvider
{
    self = [super init];
    if (self) {
        _editService = editService;
        _stickerContainerView = stickerContainerView;
        _player = player;
        _transitionService = transitionService;
        _dataProvider = dataProvider;
        _originalPlayerRect = editService.mediaContainerView.frame;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self p_setupUI];
    self.togglePlayingTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(p_handleTapGesture:)];
    self.togglePlayingTapGesture.delegate = self;
    [self.view addGestureRecognizer:self.togglePlayingTapGesture];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.editService.preview addSubscriber:self];
    [self.player resetPlayerWithView:@[self.playerContainer]];
    [self.editService.preview play];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.editService.preview removeSubscriber:self];
}

#pragma mark - Private Methods

- (void)p_setupUI
{
    self.view.backgroundColor = ACCResourceColor(ACCColorBGCreation);
    self.playerContainer.frame = [self mediaSmallMediaContainerFrame];
    self.playerContainer.userInteractionEnabled = NO;
    [self.editService.preview addSubscriber:self];
    [self.view addSubview:self.playerContainer];
    
    [self p_configStickerContainerView];
    
    _playButton = ({
        UIImageView *view = [[UIImageView alloc] initWithImage:ACCResourceImage(@"iconBigplaymusic")];
        [self.view addSubview:view];
        view.contentMode = UIViewContentModeCenter;
        [view setHidden:YES];
        
        view;
    });
    ACCMasMaker(self.playButton, {
        make.centerX.centerY.equalTo(self.playerContainer);
    });
    
    CGFloat frameHeight = kACCTextReaderSoundEffectsSelectionBottomViewWithBottomBarHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
    CGRect frame = CGRectMake(0,
                              self.view.frame.size.height - frameHeight,
                              self.view.frame.size.width,
                              frameHeight);
    self.bottomView = [[ACCTextReaderSoundEffectsSelectionBottomView alloc] initWithFrame:frame
                                                                                     type:ACCTextReaderSoundEffectsSelectionBottomViewTypeBottomBar
                                                                    isUsingOwnAudioPlayer:NO];
    
    @weakify(self);
    self.bottomView.getTextReaderModelBlock = ^AWETextStickerReadModel * _Nonnull {
        @strongify(self);
        return [self.dataProvider getTextReaderModel];
    };
    self.bottomView.didSelectSoundEffectCallback = ^(NSString * _Nonnull audioFilePath, NSString * _Nonnull audioSpeakerID) {
        @strongify(self);
        [self.dataProvider didSelectTTSAudio:audioFilePath
                                   speakerID:audioSpeakerID];
    };
    self.bottomView.didTapCancelCallback = ^{
        @strongify(self);
        [self.dataProvider didTapCancelDelegate];
        [self p_dismiss];
    };
    self.bottomView.didTapFinishCallback = ^(NSString * _Nonnull audioFilePath, NSString * _Nonnull speakerID, NSString * _Nonnull speakerName) {
        @strongify(self);
        [self.dataProvider didTapFinishDelegate:audioFilePath speakerID:speakerID speakerName:speakerName];
        [self p_dismiss];
    };
    [self.bottomView setupUI];
    
    [self.view addSubview:self.bottomView];
    
    ACCMasMaker(self.bottomView, {
        make.leading.equalTo(self.view);
        make.bottom.equalTo(self.view);
        make.trailing.equalTo(self.view);
        make.height.equalTo(@(frameHeight));
    });
    
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypePlayBtn ||
        ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) == ACCEditViewUIOptimizationTypeReplaceIconWithText) {
        [self.playButton removeFromSuperview];
        self.playButton = nil;
        self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.playBtn setImage:ACCResourceImage(@"cameraStickerPlay") forState:UIControlStateNormal];
        [self.playBtn setImage:ACCResourceImage(@"cameraStickerPause") forState:UIControlStateSelected];
        [self.playBtn addTarget:self action:@selector(p_handleTapGesture:) forControlEvents:UIControlEventTouchUpInside];
        [self.bottomView addSubview:self.playBtn];
        ACCMasReMaker(self.playBtn, {
            make.centerX.equalTo(self.bottomView);
            make.top.equalTo(self.bottomView).offset(12);
            make.height.width.equalTo(@28);
        });
    }
}

- (void)p_configStickerContainerView
{
    if (self.stickerContainerView) {
        [self p_configScale];
        [self.playerContainer addSubview:self.stickerContainerView];
        self.stickerContainerView.transform = CGAffineTransformMakeScale(self.containerScale, self.containerScale);
        self.stickerContainerView.center = self.containerCenter;
        [self p_makeMaskLayerForContainerView:self.stickerContainerView];
    }
}

- (void)p_configScale
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

- (void)p_makeMaskLayerForContainerView:(UIView *)view
{
    CGRect frame = [self.view convertRect:self.playerContainer.frame toView:view];
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRect:frame];
    
    layer.path = path.CGPath;
    view.layer.mask = layer;
}

- (void)p_dismiss
{
    if (self.transitionService) {
        [self.transitionService dismissViewController:self completion:nil];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)p_handleTapGesture:(UITapGestureRecognizer *)gesture
{
    BOOL willPause = self.editService.preview.status == HTSPlayerStatusPlaying;
    willPause ? [self.player pause] : [self.player play];
    if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) != ACCEditViewUIOptimizationTypePlayBtn &&
        ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) != ACCEditViewUIOptimizationTypeReplaceIconWithText) {
        [self.playButton setHidden:self.editService.preview.status == HTSPlayerStatusPlaying];
    }
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playStatusChanged:(HTSPlayerStatus)status {
    if (status == HTSPlayerStatusPlaying) {
        [self.playBtn setSelected:YES];
        if (ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) != ACCEditViewUIOptimizationTypePlayBtn &&
            ACCConfigEnum(kConfigInt_edit_view_ui_optimization, ACCEditViewUIOptimizationType) != ACCEditViewUIOptimizationTypeReplaceIconWithText) {
            [self.playButton setHidden:YES];
        }
    } else {
        [self.playBtn setSelected:NO];
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
    CGFloat playerY = ([UIDevice acc_isIPhoneX] ? 44 : 0) + 16.0f;
    CGFloat playerHeight = ACC_SCREEN_HEIGHT - kACCTextReaderSoundEffectsSelectionBottomViewHeight - ACC_IPHONE_X_BOTTOM_OFFSET - playerY - 8.0 - 32;
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
    return kACCTextReaderSoundEffectsSelectionBottomViewHeight + ACC_IPHONE_X_BOTTOM_OFFSET;
}

#pragma mark - Getters and Setters

- (UIView *)playerContainer
{
    if (!_playerContainer) {
        _playerContainer = [[UIView alloc] init];
        _playerContainer.layer.cornerRadius = 2;
        _playerContainer.layer.masksToBounds = YES;
    }
    return _playerContainer;
}

#pragma mark - ACCEditPreviewMessageProtocol

- (void)playerCurrentPlayTimeChanged:(NSTimeInterval)currentTime
{
    for (NSArray <ACCStickerViewType> *sticker in self.stickerContainerView.allStickerViews) {
        if ([sticker conformsToProtocol:@protocol(ACCPlaybackResponsibleProtocol)]) {
            [(id<ACCPlaybackResponsibleProtocol>)sticker updateWithCurrentPlayerTime:currentTime];
        }
    }
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    CGPoint touchPoint = [touch locationInView:self.view];
    return CGRectContainsPoint(self.playerContainer.frame, touchPoint);
}


@end
