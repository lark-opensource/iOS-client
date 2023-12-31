//
//  ACCLightningRecordAnimationView.m
//  CameraClient-Pods-Aweme
//
//  Created by shaohua yang on 8/6/20.
//

#import "ACCLightningRecordAnimationView.h"
#import "ACCConfigKeyDefines.h"
#import "ACCRecordMode+MeteorMode.h"
#import <CreationKitInfra/ACCLogHelper.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreationKitArch/AWEFeedBackGenerator.h>
#import "ACCCaptureScreenAnimationView.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>

@implementation ACCLightningRecordAnimationViewConfig


@end

@interface ACCLightningRecordAnimationView ()

@property (nonatomic, assign) BOOL isShowingCaptureAnimating;
@property (nonatomic, strong, readwrite) ACCRecordMode *recordMode;
@property (nonatomic, assign, readwrite) AWERecordModeMixSubtype mixSubtype;
@property (nonatomic, assign) CGPoint touchBeginPoint;
@property (nonatomic, assign) NSTimeInterval tapStartTime;
@property (nonatomic, strong) ACCCaptureScreenAnimationView *scrnAnimView;

@end


@implementation ACCLightningRecordAnimationView

@synthesize delegate = _delegate;
@synthesize trackRecordVideoEventBlock = _trackRecordVideoEventBlock;
@synthesize isCountdowning = _isCountdowning;
@synthesize forbidUserPause = _forbidUserPause;
@synthesize supportGestureWhenHidden = _supportGestureWhenHidden;

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _animatedRecordButton = [ACCLightningRecordButton new];

        [self addSubview:_animatedRecordButton];
        _animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"com_mig_shoot_a_video_2rlslg", @"拍视频");;
        _animatedRecordButton.accessibilityHint = ACCLocalizedString(@"record_mode_combine_tip", @"单击或按住拍摄视频");
    }
    return self;
}

- (void)setConfig:(ACCLightningRecordAnimationViewConfig *)config
{
    _config = config;
    if (config != nil) {
        self.animatedRecordButton.redView.idleColor = config.idleCenterColor;
        self.animatedRecordButton.ringView.progressColor = config.recordingProgressColor;
    }
}

- (void)setForbidUserPause:(BOOL)forbidUserPause
{
    _forbidUserPause = forbidUserPause;
    [self.animatedRecordButton hideCenterViewWhenRecording:forbidUserPause];
}

- (void)updateAnimatedRecordButtonCenter:(CGPoint)center
{
    self.animatedRecordButton.center = center;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL shouldNotHandleEvent = self.alpha == 0 || self.userInteractionEnabled == NO;
    if (!self.supportGestureWhenHidden) {
        shouldNotHandleEvent = self.hidden || shouldNotHandleEvent;
    }
    if (!shouldNotHandleEvent && event.type == UIEventTypeTouches) {
        if (CGRectContainsPoint(self.animatedRecordButton.frame, point)) {
            if ([self isAccordWithMixHoldTapAndMixSubtypeTap] && self.isShowingCaptureAnimating) {
                return self;
            } else {
                BOOL shoulBegin = YES;
                if ([self.delegate respondsToSelector:@selector(animationShouldBegin:)]) {
                    shoulBegin = [self.delegate animationShouldBegin:self];
                }
                if (shoulBegin) {
                    return self;
                }
            }
        }
    }

    UIView *tmpView = [super hitTest:point withEvent:event];
    if (tmpView == self) {
        return nil;
    }

    return tmpView;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    [self executeTouchesBeganTask];
}

#pragma mark 执行 touchesBegan 任务
- (void)executeTouchesBeganTask {
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    self.tapStartTime = NSDate.timeIntervalSinceReferenceDate;
    BOOL isLivePhotoMode = self.recordMode.buttonType == AWEVideoRecordButtonTypeLivePhoto;

    if( ACCConfigBool(kConfigInt_enable_haptic)){
        if(@available(ios 10.0, *)){
            UISelectionFeedbackGenerator *selection = [[UISelectionFeedbackGenerator alloc] init];
            [selection selectionChanged];
        }
    } else {
        [[AWEFeedBackGenerator sharedInstance] doFeedback];
    }

    BOOL canTakePhotoWithTap = NO;
    if ([self.delegate respondsToSelector:@selector(canTakePhotoWithTap)]) {
        canTakePhotoWithTap = [self.delegate canTakePhotoWithTap];
    }
    if (self.isShowingCaptureAnimating && [self isAccordWithMixHoldTapAndMixSubtypeTap]) {
        if (self.forbidUserPause) {
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(animationDidEnd:)]) {
            [self.delegate animationDidEnd:self];
        }
        [self stop];
    } else {
        if ([UIApplication sharedApplication].applicationState != UIApplicationStateActive) {
            return;
        }

        if (self.isCountdowning) {
            self.isShowingCaptureAnimating = YES;
            self.animatedRecordButton.state = ACCRecordButtonRecording;
        } else {
            if (canTakePhotoWithTap) {
                NSTimeInterval const delay = 0.2;
                // switchToHoldSubtype 内会更新录制时间（60s），必须早于 animationDidBegin 被调用，
                // 否则录制已经开始，再去设置录制时长就无效了!
                [self performSelector:@selector(switchToHoldSubtype) withObject:nil afterDelay:delay];

                if ([self.delegate respondsToSelector:@selector(animationDidBegin:)]) {
                    [(NSObject *)self.delegate performSelector:@selector(animationDidBegin:) withObject:self afterDelay:delay];
                }
                // delay for faster photo
            } else if (self.recordMode.isVideo) {
                self.isShowingCaptureAnimating = YES;
                self.animatedRecordButton.state = ACCRecordButtonRecording;
                [self performSelector:@selector(switchToHoldSubtype) withObject:nil afterDelay:0.3];
            }
        }
        if (!canTakePhotoWithTap || self.isCountdowning) {
            if (isLivePhotoMode) {
                self.animatedRecordButton.state = ACCRecordButtonRecording;
            }
            if ([self.delegate respondsToSelector:@selector(animationDidBegin:)]) {
                [self.delegate animationDidBegin:self];
            }
        }
        if (self.supportGestureWhenHidden && self.hidden) {
            self.hidden = NO;
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    BOOL isLivePhotoMode = self.recordMode.buttonType == AWEVideoRecordButtonTypeLivePhoto;
  
    if ([self isAccordWithMixHoldTapAndMixSubtypeHold] || isLivePhotoMode) {
        if ([self.delegate respondsToSelector:@selector(animationDidMoved:)]) {
            [self.delegate animationDidMoved:[touches.anyObject locationInView:self]];
        }
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    [self executeTouchesEndTask];
}

#pragma mark 执行 touchesEnd 任务
- (void)executeTouchesEndTask {
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    if( ACCConfigBool(kConfigInt_enable_record_touchup_haptic)){
        if(@available(ios 10.0, *)){
            UISelectionFeedbackGenerator *selection = [[UISelectionFeedbackGenerator alloc] init];
            [selection selectionChanged];
        }
    }
    BOOL canTakePhotoWithTap = NO;

    if ([self.delegate respondsToSelector:@selector(canTakePhotoWithTap)]) {
        canTakePhotoWithTap = [self.delegate canTakePhotoWithTap];
    }

    NSTimeInterval tapTimeSpan = NSDate.timeIntervalSinceReferenceDate - self.tapStartTime;
    NSTimeInterval timeThreshold = 0.15;
    if (canTakePhotoWithTap && tapTimeSpan < timeThreshold) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self.delegate selector:@selector(animationDidBegin:) object:self];
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToHoldSubtype) object:nil];
        if ([self.delegate respondsToSelector:@selector(animationViewDidReceiveTap)]) {
            [self.delegate animationViewDidReceiveTap];
            ACCBLOCK_INVOKE(self.trackRecordVideoEventBlock); // 埋点 - record_video 事件
        }
    }
    
    if (self.forbidUserPause) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToHoldSubtype) object:nil]; // do not switch to hold subtype if forbid user mannully pause record.
        if (self.isShowingCaptureAnimating) {
            ACCBLOCK_INVOKE(self.trackRecordVideoEventBlock); // 埋点 - record_video 事件
        }
        return;
    }

    if ([self isAccordWithMixHoldTapAndMixSubtypeTap]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToHoldSubtype) object:nil];
        if (self.isShowingCaptureAnimating) {
            ACCBLOCK_INVOKE(self.trackRecordVideoEventBlock); // 埋点 - record_video 事件
        }
        
        BOOL shouldRespondsToAnimationDidEnd = NO;
        if ([self.delegate respondsToSelector:@selector(shouldRespondsToAnimationDidEnd:)]) {
            shouldRespondsToAnimationDidEnd = [self.delegate shouldRespondsToAnimationDidEnd:self];
        }
        if (shouldRespondsToAnimationDidEnd) {
            if ([self.delegate respondsToSelector:@selector(animationDidEnd:)]) {
                [self.delegate animationDidEnd:self];
            }
        }

        return;
    }

    if ([self.delegate respondsToSelector:@selector(animationDidEnd:)]) {
        [self.delegate animationDidEnd:self];
    }

    [self stop];
}

- (void)touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];

    if (self.forbidUserPause) {
        return;
    }

    if ([self.delegate respondsToSelector:@selector(animationDidEnd:)]) {
        [self.delegate animationDidEnd:self];
    }

    [self stop];
}

- (void)p_performBeforeSwitchActionAnimation
{
    [UIView animateKeyframesWithDuration:0.3 delay:0.0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            self.animatedRecordButton.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.3 relativeDuration:0.5 animations:^{
            self.animatedRecordButton.transform = CGAffineTransformIdentity;
        }];
    } completion:nil];
}

- (void)p_performBeforeSwitchMeteorModeAnimation
{
    [UIView animateKeyframesWithDuration:0.1 delay:0.0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            self.animatedRecordButton.transform = CGAffineTransformMakeScale(0.97, 0.97);
        }];
        [UIView addKeyframeWithRelativeStartTime:0.5 relativeDuration:0.5 animations:^{
            self.animatedRecordButton.transform = CGAffineTransformIdentity;
        }];
    } completion:nil];
}

- (void)stop
{
    [self stopWithIgnoreProgress:NO];
}

- (void)stopWithIgnoreProgress:(BOOL)ignoreProgress;
{
    self.isShowingCaptureAnimating = NO;

    if (self.recordMode.isVideo) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToHoldSubtype) object:nil];
        self.mixSubtype = AWERecordModeMixSubtypeTap;

        BOOL shouldPauseByProgress = ignoreProgress || self.animatedRecordButton.progress > 0;
        if ((!self.recordMode.isStoryStyleMode && self.recordMode.modeId != ACCRecordModeAudio && shouldPauseByProgress) || self.animatedRecordButton.reshootMode) {
            self.animatedRecordButton.state = ACCRecordButtonPaused;
        } else {
            self.animatedRecordButton.state = ACCRecordButtonBegin;
        }
    }
    
    if (self.recordMode.modeId == ACCRecordModeLivePhoto) {
        self.animatedRecordButton.state = ACCRecordButtonBegin;
    }
}

- (void)updateRecordButtonState:(BOOL)isReshoot
{
    if ((!self.recordMode.isStoryStyleMode && self.animatedRecordButton.progress > 0) || self.animatedRecordButton.reshootMode) {
        self.animatedRecordButton.state = ACCRecordButtonPaused;
    } else {
        self.animatedRecordButton.state = ACCRecordButtonBegin;
    }
}

- (BOOL)isSwitchVideoLengthOnly:(ACCRecordMode *)recordMode {
   ACCRecordMode *oldMode = self.recordMode;
    BOOL isSwitchToLongVideo = [self recordModeIsStandVideo:oldMode] && [self recordModeIsLongVideo:recordMode];
    BOOL isSwitchToStandVideo = [self recordModeIsLongVideo:oldMode] && [self recordModeIsStandVideo:recordMode];
    return isSwitchToStandVideo || isSwitchToLongVideo;
}

- (BOOL)recordModeIsStandVideo:(ACCRecordMode *)recordMode
{
    return recordMode.lengthMode == ACCRecordLengthModeStandard;
}

- (BOOL)recordModeIsLongVideo:(ACCRecordMode *)recordMode
{
    return recordMode.lengthMode != ACCRecordLengthModeStandard && recordMode.lengthMode != ACCRecordLengthModeUnknown;
}

- (void)setRecordMode:(ACCRecordMode *)recordMode
{
    _recordMode = recordMode;
    self.animatedRecordButton.recordMode = recordMode;
}

- (void)switchToMode:(ACCRecordMode *)recordMode
{
    [self switchToMode:recordMode force:NO];
}

- (void)switchToMode:(ACCRecordMode *)recordMode force:(BOOL)force
{
    static BOOL lastMeteorModeStatus = NO;
    BOOL isMeteorModeChanged = recordMode.isMeteorMode != lastMeteorModeStatus;
    lastMeteorModeStatus = recordMode.isMeteorMode; 
    
    if (!force && recordMode == self.recordMode && !isMeteorModeChanged) {
        return;
    }

    if (isMeteorModeChanged) {
        [self p_performBeforeSwitchMeteorModeAnimation];
    } else if (self.recordMode && ![self isSwitchVideoLengthOnly:recordMode]) {
        [self p_performBeforeSwitchActionAnimation];
    } else if (recordMode.buttonType == AWEVideoRecordButtonTypeAudio){
        //音频模式动画效果
        [self p_performBeforeSwitchActionAnimation];
    }

    if (recordMode.isPhoto) {
        self.recordMode = recordMode;
        
        if (self.recordMode.buttonType == AWEVideoRecordButtonTypeLivePhoto) {
            [self switchToLivePhotoMode];
            self.animatedRecordButton.accessibilityLabel = @"动图";
            self.animatedRecordButton.accessibilityHint.accessibilityHint = @"";
        }
        else {
            [self switchToTakePictureMode];
            self.animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"record_mode_shot", @"拍照");
            self.animatedRecordButton.accessibilityHint.accessibilityHint = @"";
        }
        return;
    }
    
    if (recordMode.isVideo) {
        [self switchToMixHoldTapRecordMode:recordMode];
        if (recordMode.buttonType == AWEVideoRecordButtonTypeAudio) {
            self.animatedRecordButton.accessibilityLabel = @"录制语音";
            self.animatedRecordButton.accessibilityHint = @"单击或按住录制音频";
            return;
        } else {
            self.animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"com_mig_shoot_a_video_2rlslg", @"拍视频");
            self.animatedRecordButton.accessibilityHint = ACCLocalizedString(@"record_mode_combine_tip", @"单击或按住拍摄视频");
        }
        return;
    }
    
    self.animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"com_mig_shoot_a_video_2rlslg", @"拍视频");
    self.animatedRecordButton.accessibilityHint = @"";
}

- (void)startCountdownMode
{
    self.animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"com_mig_shoot_a_video_2rlslg", @"拍视频");
    self.animatedRecordButton.accessibilityHint.accessibilityHint = @"";
    
    if (self.isCountdowning) {
        return;
    }

    self.isShowingCaptureAnimating = YES;
    self.isCountdowning = YES;
    self.animatedRecordButton.state = ACCRecordButtonRecording;
    self.hidden = NO;
}

- (void)switchToTakePictureMode
{
    self.animatedRecordButton.state = ACCRecordButtonPicture;
}

- (void)switchToMixHoldTapRecordMode:(ACCRecordMode *)recordMode
{
    self.recordMode = recordMode;
    self.mixSubtype = AWERecordModeMixSubtypeTap;

    if (self.animatedRecordButton.progress > 0 || self.animatedRecordButton.reshootMode) {
        self.animatedRecordButton.state = ACCRecordButtonPaused;
    } else {
        self.animatedRecordButton.state = ACCRecordButtonBegin;
    }
}

- (void)switchToLivePhotoMode
{
    self.animatedRecordButton.state = ACCRecordButtonBegin;
    [self scrnAnimView];
}

- (BOOL)isAccordWithMixHoldTapAndMixSubtypeTap {
    if (self.recordMode.isVideo && self.mixSubtype == AWERecordModeMixSubtypeTap) {
        return YES;
    }
    return NO;
}

- (BOOL)isAccordWithMixHoldTapAndMixSubtypeHold {
    if (self.forbidUserPause) {
        return NO;
    }
    
    if (self.recordMode.isVideo && self.mixSubtype == AWERecordModeMixSubtypeHold) {
        return YES;
    }
    return NO;
}

#pragma mark - subtype

- (void)switchToHoldSubtype
{
    if (self.mixSubtype == AWERecordModeMixSubtypeHold) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(animationViewDidSwitchToHoldSubtype)]) {
        [self.delegate animationViewDidSwitchToHoldSubtype];
    }

    self.mixSubtype = AWERecordModeMixSubtypeHold;
    ACCBLOCK_INVOKE(self.trackRecordVideoEventBlock); // 埋点 - record_video 事件

    // delayed for `tap to take picture`
    if (self.animatedRecordButton.state != ACCRecordButtonRecording) {
        self.animatedRecordButton.state = ACCRecordButtonRecording;
    }
    [self.animatedRecordButton hideCenterView];
}

#pragma mark -
- (void)endCountdownModeIfNeed
{
    if (!self.isCountdowning) {
        return;
    }
    
    self.isShowingCaptureAnimating = NO;
    [self switchToMode:self.recordMode force:YES];
    self.isCountdowning = NO;
}

- (void)setMixSubtype:(AWERecordModeMixSubtype)mixSubtype
{
    _mixSubtype = mixSubtype;
    self.animatedRecordButton.mixSubtype = mixSubtype;
}

#pragma mark - flash animation

- (UIView *)scrnAnimView
{
    if (_scrnAnimView == nil) {
        _scrnAnimView = [[ACCCaptureScreenAnimationView alloc] initWithFrame:self.bounds];
        _scrnAnimView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self insertSubview:_scrnAnimView atIndex:0];
    }
    return _scrnAnimView;
}

- (void)startLoadingAnimation
{
    [self.scrnAnimView startLoadingAnimation];
}

- (void)stopLoadingAnimation
{
    [_scrnAnimView stopLoadingAnimation];
}

@end
