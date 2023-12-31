//
//  ACCRecorderAudioModeViewController.m
//  CameraClient-Pods-AwemeCore
//
//  Created by liujinze on 2021/10/15.
//

#import "ACCRecorderAudioModeViewController.h"
#import "ACCRecorderTextModeGradientView.h"
#import "ACCRecordModeBackgroundModelProtocol.h"
#import "ACCConfigKeyDefines.h"
#import "AWEXScreenAdaptManager.h"

#import <CreativeKit/ACCAnimatedButton.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <CreativeKit/NSString+CameraClientResource.h>
#import <CreationKitInfra/UIView+ACCMasonry.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreationKitArch/ACCUserServiceProtocol.h>
#import <BDWebImage/UIImageView+BDWebImage.h>
#import <lottie-ios/Lottie/LOTAnimationView.h>

static const CGFloat kRecordButtonWidth = 80;
static const CGFloat kRecordButtonHeight = kRecordButtonWidth;

@interface ACCRecorderAudioModeViewController ()<ACCCaptureButtonAnimationViewDelegate>

@property (nonatomic, strong) ACCRecorderTextModeGradientView *backgroundView;

@property (nonatomic, strong, readwrite) ACCLightningRecordAnimationView *recordAnimationView;
@property (nonatomic, strong) UIButton *recordButton;
@property (nonatomic, strong) ACCAnimatedButton *switchColorButton;
@property (nonatomic, strong) ACCAnimatedButton *closeButton;
@property (nonatomic, strong) UIImageView *userAvatarImageView;
@property (nonatomic, strong) LOTAnimationView *audioAnimationView;
@property (nonatomic, strong) NSObject<ACCRecorderBackgroundSwitcherProtocol> *backgroundManager;

@end

@implementation ACCRecorderAudioModeViewController

#pragma mark - public

- (instancetype)initWithBackgroundManager:(nonnull NSObject<ACCRecorderBackgroundSwitcherProtocol> *)backgroundManager
{
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _backgroundManager = backgroundManager;
    }
    return self;
}

- (void)becomeRecordingState
{
    [self.userAvatarImageView addSubview:self.audioAnimationView];
    ACCMasMaker(self.audioAnimationView, {
        make.centerX.equalTo(self.userAvatarImageView);
        make.bottom.equalTo(self.userAvatarImageView).offset(-15);
        make.size.mas_equalTo(CGSizeMake(44.f, 24.f));
    });
    [self.audioAnimationView play];
    [self.audioAnimationView acc_fadeShow];
    [self.closeButton acc_fadeHidden];
    [self.switchColorButton acc_fadeHidden];
}

- (void)becomeNormalState
{
    [self.closeButton acc_fadeShow];
    [self.switchColorButton acc_fadeShow];
    [self.audioAnimationView acc_fadeHiddenWithCompletion:^{
        [self.audioAnimationView removeFromSuperview];
        self.audioAnimationView = nil;
    }];
}

- (void)getTemplateBackgroundImagePath:(NSString *)path completion:(void(^)(NSString *, BOOL))completion
{
    UIImage *bgImage = [self p_getTemplateBackgroundImage];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData *imageData = UIImagePNGRepresentation(bgImage);
        NSString *filePath = [path stringByAppendingPathComponent:@"audioModeBGImage.png"];
        BOOL success = [imageData writeToFile:filePath atomically:YES];
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, filePath, success);
        });
    });
}

- (void)getTemplateuserAvatarImagePath:(NSString *)path completion:(void(^)(NSString *, BOOL))completion
{
    UIImage *avatarImage = self.userAvatarImageView.image;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSData *imageData = UIImagePNGRepresentation(avatarImage);
        NSString *filePath = [path stringByAppendingPathComponent:@"audioModeAvatarImage.png"];
        BOOL success = [imageData writeToFile:filePath atomically:YES];
        acc_dispatch_main_async_safe(^{
            ACCBLOCK_INVOKE(completion, filePath, success);
        });
    });
}

#pragma mark - life

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    [self setUI];
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    ACCBLOCK_INVOKE(self.audioViewDidApear);
    ACCBLOCK_INVOKE(self.showGuide,self.backgroundView);
}

- (void)setUI
{
    [self configBackground];
    [self.view addSubview:self.backgroundView];
    ACCMasMaker(self.backgroundView, {
        make.top.left.right.equalTo(self.view);
        make.height.mas_equalTo([AWEXScreenAdaptManager standPlayerFrame].size.height);
    });
    [self.backgroundView addSubview:self.recordButton];
    [self.backgroundView addSubview:self.recordAnimationView];
    [self.backgroundView addSubview:self.closeButton];
    ACCMasMaker(self.closeButton, {
        make.left.equalTo(@6);
        make.top.equalTo(self.backgroundView).offset(ACC_STATUS_BAR_NORMAL_HEIGHT + 20);
        make.size.mas_equalTo(CGSizeMake(44, 44));
    });
    [self createSwitchColorView];
    [self createAvatarView];
}

- (void)configBackground
{
    self.backgroundView = [[ACCRecorderTextModeGradientView alloc] init];
    self.backgroundView.contentMode = UIViewContentModeScaleAspectFill;
    self.backgroundView.userInteractionEnabled = YES;
    id<ACCRecordModeBackgroundModelProtocol> background = self.backgroundManager.currentBackground;
    if (background.isColorBackground) {
        [self.backgroundView bd_cancelImageLoad];
        self.backgroundView.image = nil;
        self.backgroundView.colors = background.CGColors;
    } else {
        self.backgroundView.colors = nil;
        [self.backgroundView bd_setImageWithURLs:background.backgroundImage.URLList placeholder:nil options:BDImageRequestDefaultPriority transformer:nil progress:nil completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            if (error) {
                ACCLog(@"bd_setImageWithURLs Failed, urls=%@, error: %@", background.backgroundImage.URLList, error);
            }
        }];
    }
}


- (void)createSwitchColorView
{
    [self.view addSubview:self.switchColorButton];
    ACCMasMaker(self.switchColorButton, {
        make.right.equalTo(@-10);
        make.top.mas_equalTo(ACC_STATUS_BAR_NORMAL_HEIGHT + 26);
        make.size.mas_equalTo(CGSizeMake(36, 56));
    });
    
    UIImageView *image = [[UIImageView alloc] initWithImage:[UIImage acc_imageWithName:@"ic_textmode_switch_color"]];
    [self.switchColorButton addSubview:image];
    ACCMasMaker(image, {
        make.top.equalTo(self.switchColorButton);
        make.centerX.equalTo(self.switchColorButton);
        make.size.mas_equalTo(CGSizeMake(36, 36));
    })
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.textColor = UIColor.whiteColor;
    label.font = [UIFont systemFontOfSize:10];
    label.textAlignment = NSTextAlignmentCenter;
    label.layer.shadowOpacity = 1;
    label.layer.shadowOffset = CGSizeMake(0, 1);
    label.layer.shadowRadius = 2;
    label.layer.shadowColor = ACCResourceColor(ACCColorTextReverse4).CGColor;
    label.text = @"换背景";
    [self.switchColorButton addSubview:label];
    ACCMasMaker(label, {
        make.centerX.equalTo(self.switchColorButton);
        make.bottom.equalTo(self.switchColorButton.mas_bottom).offset(-6);
    });
}

- (void)createAvatarView
{
    UIView *userAvatarBackgroudView = [[UIView alloc] init];
    CGFloat borderWidth = 4.f;
    userAvatarBackgroudView.layer.masksToBounds = YES;
    userAvatarBackgroudView.layer.cornerRadius = 160.f / 2 + borderWidth;
    userAvatarBackgroudView.backgroundColor = [UIColor colorWithRed:1.f green:1.f blue:1.f alpha:0.5f];
    [self.backgroundView addSubview:userAvatarBackgroudView];
    ACCMasMaker(userAvatarBackgroudView, {
        make.centerX.equalTo(self.backgroundView);
        make.top.equalTo(self.switchColorButton.mas_bottom).offset(55);
        make.size.mas_equalTo(CGSizeMake(168.f, 168.f));
    });
    [userAvatarBackgroudView addSubview:self.userAvatarImageView];
    ACCMasMaker(self.userAvatarImageView, {
        make.center.equalTo(userAvatarBackgroudView);
        make.size.mas_equalTo(CGSizeMake(160.f, 160.f));
    });
}

- (void)updateUserAvatar:(UIImage *)image{
    acc_dispatch_main_async_safe(^{
        self.userAvatarImageView.image = image;
    });
}

#pragma mark - action

- (void)switchColor
{
    [self.backgroundManager switchToNext];
    if (self.backgroundManager.currentBackground.isColorBackground) {
        [self.backgroundView bd_cancelImageLoad];
        self.backgroundView.image = nil;
        self.backgroundView.colors = self.backgroundManager.currentBackground.CGColors;
    } else {
        [self.backgroundView bd_cancelImageLoad];
        [self.backgroundView bd_setImageWithURLs:self.backgroundManager.currentBackground.backgroundImage.URLList placeholder:self.backgroundView.image options:BDImageRequestHighPriority transformer:nil progress:nil completion:^(BDWebImageRequest *request, UIImage *image, NSData *data, NSError *error, BDWebImageResultFrom from) {
            if (error) {
                ACCLog(@"bd_setImageWithURLs Failed, urls=%@, error: %@", self.backgroundManager.currentBackground.backgroundImage.URLList, error);
            }
        }];
    }
    ACCBLOCK_INVOKE(self.changeColor);
}

- (void)closeRecorder
{
    ACCBLOCK_INVOKE(self.close);
}

#pragma mark - <ACCCaptureButtonAnimationViewDelegate>

- (BOOL)animationShouldBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView {
    BOOL shouldBegin = YES;
    if ([self.delegate respondsToSelector:@selector(audioButtonAnimationShouldBegin:)]) {
        shouldBegin = [self.delegate audioButtonAnimationShouldBegin:animationView];
    }
    return shouldBegin;
}

- (void)animationDidBegin:(id<ACCCaptureButtonAnimationProtocol>)animationView {
    if ([self.delegate respondsToSelector:@selector(audioButtonAnimationDidBegin:)]) {
        [self.delegate audioButtonAnimationDidBegin:animationView];
    }
}

- (void)animationDidMoved:(CGPoint)touchPoint {
    if ([self.delegate respondsToSelector:@selector(audioButtonAnimationDidMoved:)]) {
        [self.delegate audioButtonAnimationDidMoved:touchPoint];
    }
}

- (void)animationDidEnd:(id<ACCCaptureButtonAnimationProtocol>)animationView {
    if ([self.delegate respondsToSelector:@selector(audioButtonAnimationDidEnd:)]) {
        [self.delegate audioButtonAnimationDidEnd:animationView];
    }
}

#pragma mark - file

- (UIImage *)p_getTemplateBackgroundImage
{
    ACCRecorderTextModeGradientView *backgroundView = [[ACCRecorderTextModeGradientView alloc] init];
    if (ACCConfigBool(kConfigBool_enable_1080p_photo_to_video)) {
        backgroundView.frame = CGRectMake(0, 0, 1080, 1920);
    } else {
        backgroundView.frame = CGRectMake(0, 0, 720, 1280);
    }
    UIImage *image;
    if (self.backgroundManager.currentBackground.isColorBackground) {
        backgroundView.colors = self.backgroundManager.currentBackground.CGColors;
    } else {
        backgroundView.contentMode = UIViewContentModeScaleAspectFill;
        [backgroundView setImage:self.backgroundView.image];
    }
    image = [backgroundView acc_imageWithViewOnScale:1.0];
    return image;
}

#pragma mark - getter

- (ACCLightningRecordAnimationView *)recordAnimationView{
    if (_recordAnimationView == nil) {
        ACCLightningRecordAnimationView *captureButtonAnimationView = [[ACCLightningRecordAnimationView alloc] initWithFrame:self.view.bounds];
        captureButtonAnimationView.animatedRecordButton.showMicroView = YES;
        captureButtonAnimationView.userInteractionEnabled = YES;
        captureButtonAnimationView.multipleTouchEnabled = YES;
        captureButtonAnimationView.isAccessibilityElement = NO;
        captureButtonAnimationView.delegate = self;
        [captureButtonAnimationView updateAnimatedRecordButtonCenter:self.recordButton.center];
        [captureButtonAnimationView addSubview:captureButtonAnimationView.animatedRecordButton];
        _recordAnimationView = captureButtonAnimationView;
    }
    return _recordAnimationView;
}

- (UIButton *)recordButton{
    if (!_recordButton) {
        _recordButton = [[UIButton alloc] initWithFrame:[self recordButtonFrame]];
        _recordButton.userInteractionEnabled = NO;
        _recordButton.backgroundColor = [UIColor clearColor];
    }
    return _recordButton;
}

- (CGRect)recordButtonFrame
{
    CGFloat shiftToTop = 14;
    if ([AWEXScreenAdaptManager needAdaptScreen] && !(ACCConfigEnum(kConfigInt_view_frame_optimize_type, ACCViewFrameOptimize) & ACCViewFrameOptimizeFullDisplay)) {
        shiftToTop = -12;
    }
    return CGRectMake((ACC_SCREEN_WIDTH - kRecordButtonWidth)/2, ACC_SCREEN_HEIGHT + [self.layoutGuide recordButtonBottomOffset] - kRecordButtonHeight + ([UIDevice acc_isIPhoneX] ? shiftToTop : 0), kRecordButtonWidth, kRecordButtonHeight);
}


- (ACCAnimatedButton *)switchColorButton{
    if (!_switchColorButton) {
        _switchColorButton = [[ACCAnimatedButton alloc] init];
        _switchColorButton.accessibilityLabel = @"更换背景";
        _switchColorButton.accessibilityTraits = UIAccessibilityTraitButton;
        [_switchColorButton addTarget:self action:@selector(switchColor) forControlEvents:UIControlEventTouchUpInside];
        
    }
    return _switchColorButton;
}

- (ACCAnimatedButton *)closeButton{
    if (!_closeButton) {
        _closeButton = [[ACCAnimatedButton alloc] init];
        _closeButton.accessibilityLabel = @"关闭";
        [_closeButton setImage:[UIImage acc_imageWithName:@"ic_titlebar_close_white"] forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeRecorder) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

- (UIImageView *)userAvatarImageView{
    if (!_userAvatarImageView) {
        _userAvatarImageView = [[UIImageView alloc] init];
        _userAvatarImageView.image = nil;
        _userAvatarImageView.layer.masksToBounds = YES;
        _userAvatarImageView.layer.cornerRadius = 160.f / 2;
    }
    return _userAvatarImageView;
}

- (LOTAnimationView *)audioAnimationView{
    if (!_audioAnimationView) {
        NSString *lottieName = @"audio_sound_animate.json";
        _audioAnimationView = [LOTAnimationView animationWithFilePath:ACCResourceFile(lottieName)];
        _audioAnimationView.hidden = YES;
        _audioAnimationView.loopAnimation = YES;
    }
    return _audioAnimationView;
}

@end
