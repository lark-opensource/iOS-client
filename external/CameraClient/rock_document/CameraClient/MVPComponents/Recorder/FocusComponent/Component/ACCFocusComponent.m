//
//  ACCFocusComponent.m
//  CameraClient-Pods-Aweme
//
//  Created by liujinze on 2020/12/30.
//

#import "ACCFocusComponent.h"

#import <AVFoundation/AVCaptureSessionPreset.h>
#import <CreativeKit/ACCWeakProxy.h>
#import <CreativeKit/NSTimer+ACCAdditions.h>

#import <CreativeKit/ACCRecorderViewContainer.h>
#import "ACCPropViewModel.h"
#import "ACCRecordFrameSamplingServiceProtocol.h"
#import <CreationKitRTProtocol/ACCCameraControlEvent.h>
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWECameraPreviewContainerView.h"
#import "ACCExposureSlider.h"
#import "ACCFocusViewModel.h"
#import "ACCRecordPropService.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitArch/ACCRepoDuetModel.h>

static NSString * const kAWEExposureSliderFadeOutAnimationKey = @"FadeOutAnimationKey";

@interface ACCFocusComponent () <ACCRecordConfigAudioHandler, ACCCameraLifeCircleEvent, ACCCameraControlEvent, CAAnimationDelegate, ACCRecordSwitchModeServiceSubscriber>

@property (nonatomic, strong) id<ACCRecorderViewContainer> viewContainer;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;

@property (nonatomic, assign) BOOL isFirstAppear;
@property (nonatomic, weak, readonly) ACCFocusViewModel *viewModel;
@property (nonatomic, strong) ACCExposureSlider *exposureSlider;
@property (nonatomic, strong) UIImageView *focusImageView;
@property (nonatomic, strong) NSTimer *exposureSliderHideTimer;
@property (nonatomic, strong) CAKeyframeAnimation *fadeOutAnimation;
@property (nonatomic, assign) NSInteger removeActionVersion;

@end

@implementation ACCFocusComponent


IESAutoInject(self.serviceProvider, viewContainer, ACCRecorderViewContainer)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)

#pragma mark - ACCComponentProtocol

- (void)bindServices:(id<IESServiceProvider>)serviceProvider
{
    [IESAutoInline(self.serviceProvider, ACCRecordConfigService) registAudioHandler:self];
    [self.cameraService addSubscriber:self];
    [self.cameraService.cameraControl addSubscriber:self];
    [self.cameraService.message addSubscriber:self];
    [self.switchModeService addSubscriber:self];
}

#pragma mark - ACCFeatureComponent

- (ACCFeatureComponentLoadPhase)preferredLoadPhase
{
    return ACCFeatureComponentLoadPhaseEager;
}

- (void)componentDidMount
{
    self.isFirstAppear = YES;
    [self p_readExistData];
    [self p_bindViewModels];
}

- (void)componentWillAppear
{
    if (self.switchModeService.currentRecordMode.modeId != ACCRecordModeLive) {
        if (ACCConfigBool(kConfigBool_enable_exposure_compensation)) {
            [self.cameraService.cameraControl resetExposureBias];
        }
    }
}

- (void)componentDidAppear
{
    if (self.isFirstAppear) {
        self.isFirstAppear = NO;
    }
}

- (void)componentDidUnmount
{
    [self cancelExposureSliderHideTimer];
}

#pragma mark - init methods

- (void)p_readExistData
{
    if ([self propViewModel].currentSelectEffectPack) {
        [self p_didSetEffectWithPack:[self propViewModel].currentSelectEffectPack];
    }
}

- (void)p_bindViewModels
{
    @weakify(self);
    [[self propViewModel].didSetCurrentStickerSignal.deliverOnMainThread subscribeNext:^(ACCRecordSelectEffectPack _Nullable x) {
        @strongify(self);
        [self p_didSetEffectWithPack:x];
    }];
}

- (void)p_didSetEffectWithPack:(ACCRecordSelectEffectPack _Nullable)pack
{
    if (ACCConfigBool(kConfigBool_enable_exposure_compensation) && !self.repository.repoDuet.isDuet) {
        [self hideFocusAndExposureSlider];
    }
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if (flag) {
        [self hideFocusAndExposureSlider];
        [self cancelExposureSliderFadeOutAnimation];
    }
}
#pragma mark - action methods

- (void)willFocusAtPoint:(CGPoint)focusPoint
{
    if (self.viewContainer.switchModeContainerView.isPanned) {
        return;
    }
    NSInteger version = ++self.removeActionVersion;
    self.focusImageView.center = [self.viewContainer.rootView convertPoint:focusPoint fromView:self.cameraService.cameraPreviewView];
    self.focusImageView.transform = CGAffineTransformMakeScale(1.6, 1.6);
    [self.viewContainer.rootView insertSubview:self.focusImageView aboveSubview:self.viewContainer.interactionView];
    
    [UIView animateWithDuration:0.4 animations:^{
        self.focusImageView.transform = CGAffineTransformIdentity;
    } completion:^(BOOL finished) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSInteger currentVersion = self.removeActionVersion;
            if (version == currentVersion) {
                [self.focusImageView removeFromSuperview];
            }
        });
    }];
}

- (void)willFocusAndExposureAtPoint:(CGPoint)point
{
    if (self.viewContainer.switchModeContainerView.isPanned) {
        return ;
    }
    NSInteger version = ++self.removeActionVersion;
    CGPoint focusCenter = [self.viewContainer.rootView convertPoint:point fromView:self.cameraService.cameraPreviewView];
    CGPoint exposureCenter = focusCenter;
    CGPoint exposureAnimateCenter = exposureCenter;
    if (exposureAnimateCenter.x > CGRectGetWidth(self.viewContainer.rootView.frame) - 64) {
        exposureAnimateCenter.x -= 80;
        exposureCenter.x -= 50;
    } else {
        exposureAnimateCenter.x += 80;
        exposureCenter.x += 50;
    }

    [self cancelExposureSliderFadeOutAnimation];

    self.focusImageView.center = focusCenter;
    self.focusImageView.transform = CGAffineTransformMakeScale(1.6, 1.6);
    self.focusImageView.alpha = 1.0;
    [self.viewContainer.rootView insertSubview:self.focusImageView aboveSubview:self.viewContainer.interactionView];

    self.exposureSlider.center = exposureAnimateCenter;
    self.exposureSlider.value = 0.5;
    self.exposureSlider.alpha = 1.0;
    self.exposureSlider.trackAlpha = 0.0;
    CGAffineTransform originTransform = self.exposureSlider.transform;
    self.exposureSlider.transform = CGAffineTransformScale(originTransform, 1.6, 1.6);
    [self.viewContainer.rootView insertSubview:self.exposureSlider aboveSubview:self.viewContainer.interactionView];

    [UIView animateWithDuration:0.4 animations:^{
        self.focusImageView.transform = CGAffineTransformIdentity;

        self.exposureSlider.transform = originTransform;
        self.exposureSlider.center = exposureCenter;
    } completion:^(BOOL finished) {
        if (finished) {
            self.viewModel.exposureCompensationGestureEnabled = YES;
            [self startExposureSliderHideTimerWithVersion:version];
        }
    }];
}

- (void)hideFocusAndExposureSlider
{
    [self.focusImageView removeFromSuperview];

    [self.exposureSlider removeFromSuperview];
    self.viewModel.exposureCompensationGestureEnabled = NO;
}

- (void)startExposureSliderHideTimerWithVersion:(NSInteger)version
{
    [self cancelExposureSliderHideTimer];
    @weakify(self);
    self.exposureSliderHideTimer = [NSTimer acc_timerWithTimeInterval:1.5 block:^(NSTimer * _Nonnull timer) {
        @strongify(self);
        if (version == self.removeActionVersion) {
            [self hideFocusAndExposureSlider];
        }
    } repeats:NO];
    [[NSRunLoop currentRunLoop] addTimer:self.exposureSliderHideTimer forMode:NSRunLoopCommonModes];
}

- (void)cancelExposureSliderHideTimer
{
    if (self.exposureSliderHideTimer != nil) {
        [self.exposureSliderHideTimer invalidate];
        self.exposureSliderHideTimer = nil;
    }
}

- (void)startExposureSliderFadeOutAnimation
{
    [self.focusImageView.layer addAnimation:self.fadeOutAnimation forKey:kAWEExposureSliderFadeOutAnimationKey];
    [self.exposureSlider.layer addAnimation:self.fadeOutAnimation forKey:kAWEExposureSliderFadeOutAnimationKey];
}

- (void)cancelExposureSliderFadeOutAnimation
{
    [self.focusImageView.layer removeAnimationForKey:kAWEExposureSliderFadeOutAnimationKey];
    [self.exposureSlider.layer removeAnimationForKey:kAWEExposureSliderFadeOutAnimationKey];
}

#pragma mark - ACCCameraControlEvent

- (void)onDidManuallyAdjustFocusPoint:(CGPoint)focusPoint
{
    focusPoint.x *= CGRectGetWidth(self.cameraService.cameraPreviewView.frame);
    focusPoint.y *= CGRectGetHeight(self.cameraService.cameraPreviewView.frame);

    [self willFocusAtPoint:focusPoint];
}

- (void)onDidManuallyAdjustFocusAndExposurePoint:(CGPoint)point
{
    point.x *= CGRectGetWidth(self.cameraService.cameraPreviewView.frame);
    point.y *= CGRectGetHeight(self.cameraService.cameraPreviewView.frame);
    [self willFocusAndExposureAtPoint:point];
}

- (void)onDidManuallyAdjustExposureBiasWithRatio:(float)ratio
{
    if (!ACCConfigBool(kConfigBool_enable_exposure_compensation) || self.repository.repoDuet.isDuet) {
        return ;
    }
    [self cancelExposureSliderHideTimer];
    [self cancelExposureSliderFadeOutAnimation];
    self.exposureSlider.trackAlpha = 1.0;
    float newValue = self.exposureSlider.value + ratio;
    self.exposureSlider.value = newValue > 1 ? 1 : (newValue < 0 ? 0 : newValue);
    [self.exposureSlider setThumbScale:0.85 + 0.3 * self.exposureSlider.value];

    [self startExposureSliderFadeOutAnimation];
}

- (void)onWillSwitchToCameraPosition:(AVCaptureDevicePosition)position
{
    if (ACCConfigBool(kConfigBool_enable_exposure_compensation) && !self.repository.repoDuet.isDuet) {
        [self.cameraService.cameraControl resetExposureBias];
        [self hideFocusAndExposureSlider];
    } else {
        [self.focusImageView removeFromSuperview];
    }
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceWillChangeToMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if (ACCConfigBool(kConfigBool_enable_exposure_compensation)) {
        if (mode.modeId == ACCRecordModeLive) {
            [self.cameraService.cameraControl resetExposureBias];
        }

        if (mode.modeId == ACCRecordModeLive || mode.modeId == ACCRecordModeMV) {
            [self hideFocusAndExposureSlider];
        }
    }
}

#pragma mark - getter

- (ACCFocusViewModel *)viewModel
{
    ACCFocusViewModel *vm = [self getViewModel:ACCFocusViewModel.class];
    NSAssert(vm, @"should not be nil");
    return vm;
}

- (ACCPropViewModel *)propViewModel
{
    ACCPropViewModel *propViewModel = [self getViewModel:ACCPropViewModel.class];
    NSAssert(propViewModel, @"should not be nil");
    return propViewModel;
}

- (UIImageView *)focusImageView
{
    if (!_focusImageView) {
        _focusImageView = [[UIImageView alloc] initWithImage:ACCResourceImage(@"focusing_button")];
    }
    return _focusImageView;
}

- (ACCExposureSlider *)exposureSlider
{
    if (!_exposureSlider) {
        _exposureSlider = [[ACCExposureSlider alloc] init];
        _exposureSlider.maximumTrackTintColor = [UIColor whiteColor];
        _exposureSlider.minimumTrackTintColor = [UIColor whiteColor];
        [_exposureSlider setThumbImage:ACCResourceImage(@"icon_camera_exposure") forState:UIControlStateNormal];
        [_exposureSlider setAcc_width:120];
        [_exposureSlider setAcc_height:20];
        _exposureSlider.trackHeight = 1.5;
        // so the real slider's width is (width - thumbSize/2) = 110,
        // this value should sync with panGesture's ratio in ACCRecordGestureComponet.
        _exposureSlider.thumbSize = CGSizeMake(20, 20);
        _exposureSlider.direction = ACCExposureSliderDirectionUp;
        _exposureSlider.thumbBackgroundClear = YES;
        _exposureSlider.maximumValue = 1;
        _exposureSlider.minimumValue = 0;
        _exposureSlider.userInteractionEnabled = NO;
    }
    return _exposureSlider;
}

- (CAKeyframeAnimation *)fadeOutAnimation
{
    if (_fadeOutAnimation == nil) {
        CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        animation.duration = 2.5;
        animation.values = @[@(1.0), @(1.0), @(0.5), @(0.5), @(0.0)];
        animation.keyTimes = @[@(0.0), @(0.2), @(0.6), @(0.8), @(1.0)];
        animation.removedOnCompletion = NO;
        animation.fillMode = kCAFillModeForwards;
        animation.delegate = (id<CAAnimationDelegate>)[ACCWeakProxy proxyWithTarget:self];
        _fadeOutAnimation = animation;
    }

    return _fadeOutAnimation;
}
@end
