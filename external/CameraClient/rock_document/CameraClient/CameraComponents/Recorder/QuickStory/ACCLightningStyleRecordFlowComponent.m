//
//  ACCLightningStyleRecordFlowComponent.m
//  CameraClient-Pods-CameraClient
//
//  Created by Howie He on 2021/3/2.
//

#import "AWERepoContextModel.h"
#import "ACCLightningStyleRecordFlowComponent.h"
#import <CreationKitArch/ACCVideoConfigProtocol.h>
#import <CreativeKit/ACCServiceLocator.h>
#import "ACCLightningRecordAnimationView.h"
#import <CreationKitArch/ACCRepoReshootModel.h>
#import <CreationKitArch/ACCRepoDraftModel.h>
#import <CreationKitArch/ACCRepoDuetModel.h>
#import <CameraClient/ACCRecordFlowConfigProtocol.h>
#import "ACCRecordFlowService.h"
#import "ACCRecordFlowConfigProtocol.h"
#import <CreationKitArch/ACCRecordSwitchModeService.h>
#import <CreationKitRTProtocol/ACCCameraService.h>
#import "ACCConfigKeyDefines.h"
#import <CameraClient/ACCRecordConfigService.h>
#import <CameraClient/ACCRecordMode+LiteTheme.h>

@interface ACCLightingStyleRecordFlowComponent () <ACCRecordConfigDurationHandler, ACCCaptureButtonAnimationViewDelegate>

@property (nonatomic) ACCLightningRecordAnimationView *recordAnimationView;
@property (nonatomic, strong) id<ACCVideoConfigProtocol> videoConfig;
@property (nonatomic, strong) id<ACCRecordFlowService> flowService;
@property (nonatomic, strong) id<ACCRecordFlowConfigProtocol> flowConfig;
@property (nonatomic, strong) id<ACCRecordSwitchModeService> switchModeService;
@property (nonatomic, strong) id<ACCCameraService> cameraService;
@property (nonatomic, strong) id<ACCRecordConfigService> configService;
@property (nonatomic, strong) RACSubject<NSNumber *> *switchModelSubject;

@end

@implementation ACCLightingStyleRecordFlowComponent

IESAutoInject(ACCBaseServiceProvider() , videoConfig, ACCVideoConfigProtocol)
IESAutoInject(self.serviceProvider, flowService, ACCRecordFlowService)
IESAutoInject(self.serviceProvider, flowConfig, ACCRecordFlowConfigProtocol)
IESAutoInject(self.serviceProvider, switchModeService, ACCRecordSwitchModeService)
IESAutoInject(self.serviceProvider, cameraService, ACCCameraService)
IESAutoInject(self.serviceProvider, configService, ACCRecordConfigService)


#pragma mark - LifeCycle

- (void)loadComponentView
{
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super loadComponentView];
    }
    [self updateLightingStyleRecordButtonLightingViewWithMode:self.switchModeService.currentRecordMode];
}

- (void)dealloc
{
    [self.switchModelSubject sendCompleted];
}

#pragma mark - ACCRecordFlowServiceSubscriber

- (void)flowServiceDidMarkDuration:(CGFloat)duration
{
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super flowServiceDidMarkDuration:duration];
    }
    
    [self updateProgressBar];
}

- (void)flowServiceDidRemoveLastSegment:(BOOL)isReactHasMerge
{
    [self updateProgressBar];
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super flowServiceDidRemoveLastSegment:isReactHasMerge];
    }
}

- (void)flowServiceDidRemoveAllSegment
{
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super flowServiceDidRemoveAllSegment];
    }
    [self updateProgressBar];
}

- (void)flowServiceDurationHasRestored
{
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super flowServiceDurationHasRestored];
    }
    if (self.repository.repoReshoot.isReshoot) {
        NSTimeInterval from = self.repository.repoReshoot.durationBeforeReshoot;
        NSTimeInterval to = from + self.repository.repoContext.maxDuration;
        NSTimeInterval total = to + self.repository.repoReshoot.durationAfterReshoot;
            [self.lightningProgressView setReshootTimeFrom:from to:to totalDuration:total];
        return;
    }
    if (self.repository.repoDraft.isDraft) {
        // 还原长视频模式下的15s提示的显示
        ACCRecordLengthMode mode = self.repository.repoContext.videoLenthMode;
        if (mode == ACCRecordLengthModeLong ||
            mode == ACCRecordLengthMode60Seconds) {
            BOOL showStandardDurationIndicator = YES;
            if (self.repository.repoDuet.isDuet) {
                showStandardDurationIndicator = NO;
            }
            [self.lightningProgressView updateStandardDurationIndicatorWithLongVideoEnabled:showStandardDurationIndicator standardDuration:[self.videoConfig standardVideoMaxSeconds] maxDuration:self.repository.repoContext.maxDuration];
        }
    }
}

- (void)flowServiceWillBeginLivePhoto
{
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super flowServiceWillBeginLivePhoto];
    }
    // 音量键启动拍摄时，未经由快门按钮UI交互，需要把状态补改为Recording
    self.recordAnimationView.animatedRecordButton.state = ACCRecordButtonRecording;
}

#pragma mark - ACCRecordSwitchModeServiceSubscriber

- (void)switchModeServiceDidChangeMode:(ACCRecordMode *)mode oldMode:(ACCRecordMode *)oldMode
{
    if ([[self superclass] instancesRespondToSelector:_cmd]) {
        [super switchModeServiceDidChangeMode:mode oldMode:oldMode];
    }
    
    [self updateLightingStyleRecordButtonLightingViewWithMode:mode];
}

#pragma mark - Overrides

- (void)updateStandardDurationIndicatorDisplay
{
    [super updateStandardDurationIndicatorDisplay];
    ACCRecordLengthMode lengthMode = [self.videoConfig currentVideoLenthMode];
    BOOL showStandardDurationIndicator = lengthMode == ACCRecordLengthModeLong || lengthMode == ACCRecordLengthMode60Seconds;
    if (self.repository.repoDuet.isDuet) {
        showStandardDurationIndicator = NO;
    }
    [self.lightningProgressView updateStandardDurationIndicatorWithLongVideoEnabled:showStandardDurationIndicator
                                                                standardDuration:[self.videoConfig standardVideoMaxSeconds]
                                                                     maxDuration:self.repository.repoContext.maxDuration];
}

- (void)updateProgressBar
{
    [self.lightningProgressView updateViewWithTimeSegments:self.flowService.markedTimes totalTime:self.repository.repoContext.maxDuration];
}

- (void)updateProgressAndMarksDisplay
{
    [super updateProgressAndMarksDisplay];
    double progress = ((NSTimeInterval)self.flowService.currentDuration) / self.repository.repoContext.maxDuration;
    if (progress >= 1) {
        [self.lightningProgressView setProgress:1 duration:self.flowService.currentDuration animated:NO];
    } else {
        BOOL animation = progress < self.lightningProgressView.progress;
        [self.lightningProgressView setProgress:progress duration:self.flowService.currentDuration animated:animation];
    }
}

- (ACCLightningRecordButton *)lightningProgressView
{
    return self.recordAnimationView.animatedRecordButton;
}

- (UIView<ACCCaptureButtonAnimationProtocol> *)buildCaptureButton
{
    return self.recordAnimationView;
}

- (ACCLightningRecordAnimationView *)recordAnimationView
{
    if (_recordAnimationView == nil) {
        ACCLightningRecordAnimationView *captureButtonAnimationView = [[ACCLightningRecordAnimationView alloc] init];
        captureButtonAnimationView.userInteractionEnabled = YES;
        captureButtonAnimationView.multipleTouchEnabled = YES;
        captureButtonAnimationView.isAccessibilityElement = NO;
        captureButtonAnimationView.delegate = self;
        [captureButtonAnimationView updateAnimatedRecordButtonCenter:self.recordButton.center];
        [captureButtonAnimationView addSubview:captureButtonAnimationView.animatedRecordButton];
        captureButtonAnimationView.animatedRecordButton.switchModelSubject = self.switchModelSubject;
        _recordAnimationView = captureButtonAnimationView;
    }
    return _recordAnimationView;
}

- (void)stopRecordButtonAnimationWithIgnoreProgress:(BOOL)ignoreProgress
{
    [self.recordAnimationView endCountdownModeIfNeed];
    [self.recordAnimationView stopWithIgnoreProgress:ignoreProgress];
}

#pragma mark - <ACCCaptureButtonAnimationViewDelegate>

- (void)animationViewDidSwitchToHoldSubtype
{
    if (ACCConfigBool(kConfigBool_quick_story_long_press_hold_60s)
        && self.switchModeService.currentRecordMode.isStoryStyleMode
        && !self.repository.repoContext.isIMRecord) {
        [self.switchModeService switchToLengthMode:ACCRecordLengthModeLong];
    }
}

- (void)animationViewDidReceiveTap
{
    // 点按拍照
    self.cameraService.recorder.cameraMode = HTSCameraModePhoto;
    [self.flowService takePicture];
    self.cameraService.recorder.cameraMode = HTSCameraModeVideo;
}

- (BOOL)canTakePhotoWithTap
{
    BOOL canTakePhoto = [self.flowConfig enableTapToTakePictureRecordMode:self.switchModeService.currentRecordMode.isStoryStyleMode];
    
    if ([self respondsToSelector:@selector(isTapAndHoldToRecordCase)]) {
        canTakePhoto = canTakePhoto || (![self isTapAndHoldToRecordCase] && self.switchModeService.currentRecordMode.isStoryStyleMode);
    }
    
    return canTakePhoto;
}

#pragma mark - <ACCRecordConfigDurationHandler>

- (void)didSetMaxDuration:(CGFloat)duration
{
    // 透传当前maxduration
    // 历史bug: 此处没有调用 super。高级设置需求将问题暴露，为了降低影响，使用AB进行控制，如果高级设置全量后没问题，可以删除条件判断。
    // https://bits.bytedance.net/meego/aweme/issue/detail/3132868
    if (ACCConfigBool(kConfigBool_tools_shoot_advanced_setting_panel)) {
        [super didSetMaxDuration:duration];
    }
    self.recordAnimationView.animatedRecordButton.maxDuration = duration;
}

#pragma mark - Private

- (void)updateLightingStyleRecordButtonLightingViewWithMode:(ACCRecordMode *)mode
{
    if ([self.flowConfig enableLightningStyleRecordButton]) {
        BOOL isInQuickShootTab = mode.isStoryStyleMode;
        if (ACCConfigBool(kConfigBool_white_lightning_shoot_button)) {
            self.lightningProgressView.showLightningView = NO;
        } else {
            self.lightningProgressView.showLightningView = isInQuickShootTab && !self.repository.repoContext.isIMRecord;
        }
    }
}

#pragma mark signal

- (RACSignal<NSNumber *> *)switchModelSignal
{
    return self.switchModelSubject;
}

- (RACSubject<NSNumber *> *)switchModelSubject
{
    if (!_switchModelSubject) {
        _switchModelSubject = [RACSubject subject];
    }
    return _switchModelSubject;
}


@end
