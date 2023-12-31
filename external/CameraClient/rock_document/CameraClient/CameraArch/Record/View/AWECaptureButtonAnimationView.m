//
//  AWECaptureButtonAnimationView.m
//  Aweme
//
//  Created by Liu Bing on 11/28/16.
//  Copyright © 2016 Bytedance. All rights reserved.
//

#import "AWECaptureButtonAnimationView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/UIColor+CameraClientResource.h>
#import <KVOController/NSObject+FBKVOController.h>
#import <CreationKitInfra/ACCLogHelper.h>
#import "ACCCaptureScreenAnimationView.h"
#import <CameraClient/ACCRecordMode+LiteTheme.h>
#import <CameraClientModel/AWEVideoRecordButtonType.h>
#import "ACCUIReactTrackProtocol.h"

static CGFloat tapModeRecordSize = 64.0;
static CGFloat outerTapCircleSize = 80.0;
static CGFloat tapModePauseSize = 42.0;

@interface AWECaptureButtonAnimationView()

@property (nonatomic, assign) BOOL isShowingCaptureAnimating;
@property (nonatomic, strong, readwrite) ACCRecordMode *recordMode;
@property (nonatomic, assign, readwrite) AWERecordModeMixSubtype mixSubtype;
@property (nonatomic, assign) CGPoint touchBeginPoint;
@property (nonatomic, strong) ACCCaptureScreenAnimationView *scrnAnimView;

@end

@implementation AWECaptureButtonAnimationView
@synthesize delegate = _delegate;
@synthesize trackRecordVideoEventBlock = _trackRecordVideoEventBlock;
@synthesize isCountdowning = _isCountdowning;
@synthesize forbidUserPause = _forbidUserPause;
@synthesize supportGestureWhenHidden = _supportGestureWhenHidden;

- (instancetype)init
{
    self = [super init];
    if (self) {
        _animatedRecordButton = [[AWEAnimatedRecordButton alloc] initWithFrame:CGRectMake(0, 0, 80, 80)];
        [self addSubview:_animatedRecordButton];
        [self.KVOController observe:self.animatedRecordButton.innerLayer
                            keyPath:FBKVOClassKeyPath(CALayer, hidden)
                            options:NSKeyValueObservingOptionNew
                              block:^(typeof(self) _Nullable observer,typeof(self.animatedRecordButton.innerLayer)_Nonnull object,NSDictionary<NSString *, id> *_Nonnull change) {
                                  observer.captureButton.hidden = !object.hidden;
                              }];
        _animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"com_mig_shoot_a_video_2rlslg", nil);;
        _animatedRecordButton.accessibilityHint = ACCLocalizedString(@"record_mode_combine_tip", nil);
    }
    return self;
}

- (void)updateAnimatedRecordButtonCenter:(CGPoint)center
{
    self.animatedRecordButton.center = center;
}

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    BOOL shouldNotHandleEvent = self.alpha == 0 || self.userInteractionEnabled == NO;
    if (!self.supportGestureWhenHidden) {
        shouldNotHandleEvent = self.hidden || shouldNotHandleEvent;
    }
    if (!shouldNotHandleEvent && event.type == UIEventTypeTouches) {
            CGRect captureButtonArea = [self.captureButton convertRect:self.captureButton.bounds toView:self];

        if (captureButtonArea.size.width < 100 && self.isShowingCaptureAnimating) {
            CGFloat diff = captureButtonArea.size.width - 100;
            captureButtonArea = CGRectInset(captureButtonArea, diff, diff);
        }

        if (!self.isShowingCaptureAnimating && [self isAccordWithMixHoldTapAndMixSubtypeTap]) {
            [self stop];
        }

        if (CGRectContainsPoint(captureButtonArea, point) &&
            self.captureButton.enabled ) {

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

    UIView* tmpView = [super hitTest:point withEvent:event];
    if (tmpView == self) {
        return nil;
    }
    
    return tmpView;
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    
    if (self.isShowingCaptureAnimating && [self isAccordWithMixHoldTapAndMixSubtypeTap]) {
        if (self.forbidUserPause) {
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(animationDidEnd:)]) {
            [self.delegate animationDidEnd:self];
        }
        [self stop];
    } else {
        self.touchBeginPoint = [touches.anyObject locationInView:self];
        
        if (self.isCountdowning) {
            self.isShowingCaptureAnimating = YES;
            [self.animatedRecordButton beginAnimation];
            self.animatedRecordButton.center = [touches.anyObject locationInView:self];
        } else {
            if (self.recordMode.isPhoto) {
                self.captureButton.alpha = 0.5;
            }
            
            if (self.recordMode.isVideo) {
                [ACCToolUIReactTrackService() eventBegin:kAWEUIEventClickRecord];
                if (self.recordMode.isStoryStyleMode) {
                    [self checkNormalImageForButton:self.captureButton setAlpha:0];
                }
                
                CGFloat scale = tapModePauseSize/outerTapCircleSize;
                
                self.isShowingCaptureAnimating = YES;
                [UIView animateWithDuration:0.3 animations:^{
                    self.captureButton.transform = CGAffineTransformMakeScale(scale, scale);
                    self.captureButton.layer.cornerRadius = 8.0;
                }];
                [self.animatedRecordButton beginAnimation];
                // Todo: check the problem of carton and change it back to 0.3s
                [self performSelector:@selector(switchToHoldSubtype) withObject:nil afterDelay:0.5];
            }
        }

        if ([self.delegate respondsToSelector:@selector(animationDidBegin:)]) {
            [self.delegate animationDidBegin:self];
        }
        if (self.supportGestureWhenHidden && self.hidden) {
            self.hidden = NO;
        }
    }
}

#pragma mark 执行 touchesBegan 任务
- (void)executeTouchesBeganTask
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    if (self.isShowingCaptureAnimating && [self isAccordWithMixHoldTapAndMixSubtypeTap]) {
        if (self.forbidUserPause) {
            return;
        }
        
        if ([self.delegate respondsToSelector:@selector(animationDidEnd:)]) {
            [self.delegate animationDidEnd:self];
        }
        [self stop];
    } else {
        if (self.isCountdowning) {
            self.isShowingCaptureAnimating = YES;
            [self.animatedRecordButton beginAnimation];
        } else {
            if (self.recordMode.isPhoto) {
                self.captureButton.alpha = 0.5;
            }
            
            if (self.recordMode.isVideo) {
                if (self.recordMode.isStoryStyleMode) {
                    [self checkNormalImageForButton:self.captureButton setAlpha:0];
                }
                
                CGFloat scale = tapModePauseSize/outerTapCircleSize;
                
                self.isShowingCaptureAnimating = YES;
                [UIView animateWithDuration:0.3 animations:^{
                    self.captureButton.transform = CGAffineTransformMakeScale(scale, scale);
                    self.captureButton.layer.cornerRadius = 8.0;
                }];
                [self.animatedRecordButton beginAnimation];
                // Todo: check the problem of carton and change it back to 0.3s
                [self performSelector:@selector(switchToHoldSubtype) withObject:nil afterDelay:0.5];
            }
        }

        if ([self.delegate respondsToSelector:@selector(animationDidBegin:)]) {
            [self.delegate animationDidBegin:self];
        }
        if (self.supportGestureWhenHidden && self.hidden) {
            self.hidden = NO;
        }
    }
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    
    if ([self isAccordWithMixHoldTapAndMixSubtypeTap] && self.isShowingCaptureAnimating) {
        CGPoint location = [touches.anyObject locationInView:self];
        self.animatedRecordButton.center = location;
        self.captureButton.center = location;
        if (sqrt(pow((location.x - self.touchBeginPoint.x), 2) + pow((location.y - self.touchBeginPoint.y), 2)) > 50) {
            [self switchToHoldSubtype];
            return;
        }
    }
    
    if ([self isAccordWithMixHoldTapAndMixSubtypeHold]) {
        self.animatedRecordButton.center = [touches.anyObject locationInView:self];
        self.captureButton.center = [touches.anyObject locationInView:self];
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
- (void)executeTouchesEndTask
{
    AWELogToolInfo(AWELogToolTagRecord, @"volumebutton|%s.", __PRETTY_FUNCTION__);
    if (self.forbidUserPause) {
        return;
    }
    
    self.captureButton.alpha = 1.0f;
    
    if ([self isAccordWithMixHoldTapAndMixSubtypeTap]) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToHoldSubtype) object:nil];
        if (self.isShowingCaptureAnimating) {
            ACCBLOCK_INVOKE(self.trackRecordVideoEventBlock); // Buried point - record_ Video events
        }
        [UIView animateWithDuration:0.3 animations:^{
            self.animatedRecordButton.center = self.captureShowTipButton.center;
            self.captureButton.center = self.captureShowTipButton.center;
        }];

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

- (void)stop
{
    self.isShowingCaptureAnimating = NO;
    
    if (self.recordMode.isVideo) {
        
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(switchToHoldSubtype) object:nil];
        [self.animatedRecordButton endAnimation];
        CGFloat scale = tapModeRecordSize/outerTapCircleSize;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.captureButton.transform = CGAffineTransformMakeScale(scale, scale);
            self.captureButton.layer.cornerRadius = outerTapCircleSize/2.0;
            self.animatedRecordButton.center = self.captureShowTipButton.center;
            self.captureButton.center = self.captureShowTipButton.center;

            if (self.recordMode.isStoryStyleMode) {
                [self checkNormalImageForButton:self.captureButton setAlpha:1];
            }
        }];
        self.mixSubtype = AWERecordModeMixSubtypeTap;
    } else {
        if (self.animatedRecordButton.innerLayer.hidden && self.animatedRecordButton.type == AWEAnimatedRecordButtonTypeHoldVideo) {
            return;
        }
        
        [self.animatedRecordButton endAnimation];
        
        CGPoint center = [self.captureShowTipButton.superview convertPoint:self.captureShowTipButton.center toView:self];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.animatedRecordButton.center = center;
        }];
    }
}

- (void)startCountdownMode
{
    self.animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"com_mig_shoot_a_video_2rlslg", nil);
    self.animatedRecordButton.accessibilityHint.accessibilityHint = @"";
    
    if (self.isCountdowning) {
        return;
    }

    self.isShowingCaptureAnimating = YES;
    [self acc_fadeShow];

    self.isCountdowning = YES;
    self.animatedRecordButton.center = self.captureShowTipButton.center;
    
    self.animatedRecordButton.type = AWEAnimatedRecordButtonTypeCountDown;
    
    CGFloat scale = tapModePauseSize/outerTapCircleSize;
    
    void (^animationBlock)(void) = ^{
        self.captureButton.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
        self.captureButton.transform = CGAffineTransformMakeScale(scale, scale);
        self.captureButton.layer.cornerRadius = 8.0;
        self.captureButton.titleLabel.alpha = 0.0;
        [self checkNormalImageForButton:self.captureButton setAlpha:0.0];
    };
    
    if ([self acc_isDisplayedOnScreen]) {
        [UIView animateWithDuration:0.3 animations:animationBlock];
    } else {
        ACCBLOCK_INVOKE(animationBlock);
    }
    [self.animatedRecordButton beginAnimation];
}

- (void)switchToMode:(ACCRecordMode *)recordMode
{
    [self switchToMode:recordMode force:NO];
}

- (void)switchToMode:(ACCRecordMode *)recordMode force:(BOOL)force
{
    if (!force && recordMode.modeId == self.recordMode.modeId) {
        return;
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
            
            self.animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"record_mode_shot", @"nil");
            self.animatedRecordButton.accessibilityHint.accessibilityHint = @"";
        }
        return;
    }
    
    if (recordMode.isVideo) {
        [self switchToMixHoldTapRecordMode:recordMode];
        self.animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"com_mig_shoot_a_video_2rlslg", @"nil");
        self.animatedRecordButton.accessibilityHint = ACCLocalizedString(@"record_mode_combine_tip", @"nil");
        return;
    }
    
    self.animatedRecordButton.accessibilityLabel = ACCLocalizedString(@"com_mig_shoot_a_video_2rlslg", @"nil");
    self.animatedRecordButton.accessibilityHint = @"";
}

- (void)switchToTakePictureMode
{
    self.animatedRecordButton.center = self.captureShowTipButton.center;

    CGFloat scale = tapModeRecordSize/outerTapCircleSize;

    self.animatedRecordButton.type = AWEAnimatedRecordButtonTypeTapPicture;
    
    void (^animationBlock)(void) = ^{
        self.captureButton.backgroundColor = ACCResourceColor(ACCUIColorBGContainer6);
        self.captureButton.transform = CGAffineTransformMakeScale(scale, scale);
        self.captureButton.titleLabel.alpha = 0.0;
        [self checkNormalImageForButton:self.captureButton setAlpha:0.0];
        self.captureButton.layer.cornerRadius = outerTapCircleSize/2.0;
    };
    
    if ([self acc_isDisplayedOnScreen]) {
        [UIView animateWithDuration:0.3 animations:animationBlock completion:nil];
    } else {
        ACCBLOCK_INVOKE(animationBlock);
    }
}

- (void)switchToMixHoldTapRecordMode:(ACCRecordMode *)recordMode
{
    if (self.recordMode.isVideo && !self.isCountdowning) {
        self.recordMode = recordMode;
        return;
    }
    
    [self.animatedRecordButton endAnimation];
    // The default type of the first initialization is accrecordmodetakepicture, so the update type cannot be deleted
    self.recordMode = recordMode;
    self.mixSubtype = AWERecordModeMixSubtypeTap;
    self.animatedRecordButton.center = self.captureShowTipButton.center;
    self.animatedRecordButton.type = AWEAnimatedRecordButtonTypeMixTapHoldVideo;
    
    CGFloat scale = tapModeRecordSize / outerTapCircleSize;
    void (^animationBlock)(void) = ^{
        self.captureButton.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
        self.captureButton.transform = CGAffineTransformMakeScale(scale, scale);
        self.captureButton.titleLabel.alpha = 0.0;

        if (!self.recordMode.isStoryStyleMode) {
            [self checkNormalImageForButton:self.captureButton setAlpha:0.0];
        }

        self.captureButton.layer.cornerRadius = outerTapCircleSize/2.0;
    };
    
    if ([self acc_isDisplayedOnScreen]) {
        [UIView animateWithDuration:0.3 animations:animationBlock completion:nil];
    } else {
        ACCBLOCK_INVOKE(animationBlock);
    }
}

- (void)switchToLivePhotoMode
{
    // UI跟拍照一致
    [self switchToTakePictureMode];
    // 加载闪屏动画视图
    [self scrnAnimView];
}

- (BOOL)isAccordWithMixHoldTapAndMixSubtypeTap {
    // workaround. in avoid of deleting all the logic about touchmoved
    if (self.forbidUserPause) {
        return NO;
    }
    
    if (self.recordMode.isVideo && self.mixSubtype == AWERecordModeMixSubtypeTap) {
        return YES;
    }
    return NO;
}

- (BOOL)isAccordWithMixHoldTapAndMixSubtypeHold {
    if (self.forbidUserPause) {
        return NO;
    }
    
    if (self.recordMode.isVideo && !self.isCountdowning && self.mixSubtype == AWERecordModeMixSubtypeHold) {
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

    self.mixSubtype = AWERecordModeMixSubtypeHold;
    ACCBLOCK_INVOKE(self.trackRecordVideoEventBlock); // Buried point - record_ Video events
    [UIView animateKeyframesWithDuration:0.2 delay:0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:0.5 animations:^{
            self.captureButton.layer.cornerRadius = outerTapCircleSize / 2.0;
        }];
        [UIView addKeyframeWithRelativeStartTime:0 relativeDuration:1.0 animations:^{
            self.animatedRecordButton.outterLayer.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary).CGColor;
            self.captureButton.layer.transform = CATransform3DMakeScale(0.0001, 0.0001, 0.0001);
            self.captureButton.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary);
        }];
    } completion:nil];
}

#pragma mark -

// If the image of normal state is set, alpha is set
- (void)checkNormalImageForButton:(UIButton *)button setAlpha:(CGFloat)alpha
{
    if ([button imageForState:UIControlStateNormal]) {
        button.imageView.alpha = alpha;
    }
}

- (void)endCountdownModeIfNeed
{
    if (!self.isCountdowning) {
        return;
    }
    
    self.isShowingCaptureAnimating = NO;
    [self switchToMode:self.recordMode force:YES];
    self.isCountdowning = NO;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.animatedRecordButton.center = self.captureShowTipButton.center;
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
