//
//  AWEAnimatedRecordButton.m
//  AWEStudio
//
// Created by Hao Yipeng on December 10, 2018
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "AWEAnimatedRecordButton.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWEAnimatedRecordShapeLayer.h"
#import <CreativeKit/ACCWeakProxy.h>
#import "CKConfigKeysDefines.h"
#import <CreativeKit/ACCLanguageProtocol.h>
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIColor+CameraClientResource.h>

static CGFloat innerLayerInitRadius = 80.0f;
static CGFloat outterLayerInitRadius = 80.0f;

static CGFloat innerLayerNormalStateSmallRadius = 64.0f;
static CGFloat innerLayerNormalStateBigRadius = 80.0f;
static CGFloat innerLayerNormalStateHollowRatio = 0.0 / 80.0f;

static CGFloat outterLayerNormalStateRadius = 80.0f;
static CGFloat outterLayerNormalStateHollowRatio = 68.0 / 80.0f;

static CGFloat outterLayerAnimationStateRadius = 140.0f;
static CGFloat outterLayerAnimationStateSmallHollowRatio = 110.0 / 140.0f;
static CGFloat outterLayerAnimationStateBigHollowRatio = 130.0 / 140.0f;

static CFTimeInterval normalAnimationDuration = 0.3;
static CFTimeInterval breathAnimationDuration = 0.5;

@interface AWEAnimatedRecordButton () <CAAnimationDelegate>

@end

@implementation AWEAnimatedRecordButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self addSubviews];
    }
    return self;
}

- (void)addSubviews
{
    [self.layer addSublayer:self.innerLayer];
    [self.layer addSublayer:self.outterLayer];
}

- (void)setType:(AWEAnimatedRecordButtonType)type
{
    if (_type != type) {
        _type = type;
        [self p_performBeforeSwitchActionAnimation];
        switch (type) {
            case AWEAnimatedRecordButtonTypeHoldVideo: {
                [self p_switchToHoldVideoType];
                break;
            }
            case AWEAnimatedRecordButtonTypeTapVideo: {
                [self p_switchToTapVideoType];
                break;
            }
            case AWEAnimatedRecordButtonTypeTapPicture: {
                [self p_switchToTapPictureType];
                break;
            }
            case AWEAnimatedRecordButtonTypeCountDown: {
                [self p_switchToCountDownType];
                break;
            }
            case AWEAnimatedRecordButtonTypeMixTapHoldVideo: {
                [self p_switchToMixTapHoldVideoType];
            }
            default:
                break;
        }
    }
}

- (void)p_performBeforeSwitchActionAnimation
{
    [UIView animateKeyframesWithDuration:normalAnimationDuration delay:0.0 options:UIViewKeyframeAnimationOptionBeginFromCurrentState animations:^{
        [UIView addKeyframeWithRelativeStartTime:0.0 relativeDuration:0.5 animations:^{
            self.transform = CGAffineTransformMakeScale(0.8, 0.8);
        }];
        [UIView addKeyframeWithRelativeStartTime:normalAnimationDuration relativeDuration:0.5 animations:^{
            self.transform = CGAffineTransformIdentity;
        }];
    } completion:nil];
}

- (void)p_switchToHoldVideoType
{
    self.userInteractionEnabled = NO;
    self.innerLayer.hidden = YES;
    void(^animtionBlock)(void) = ^{
        self.outterLayer.backgroundColor = [ACCResourceColor(ACCUIColorConstPrimary) colorWithAlphaComponent:0.5].CGColor;
        self.innerLayer.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary).CGColor;
        self.innerLayer.transform = CATransform3DMakeScale(innerLayerNormalStateBigRadius / innerLayerInitRadius, innerLayerNormalStateBigRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.transform = CATransform3DMakeScale(outterLayerNormalStateRadius / innerLayerInitRadius, outterLayerNormalStateRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.opacity = 0.0f;
    };
    if ([self acc_isDisplayedOnScreen]) {
        [UIView animateWithDuration:normalAnimationDuration animations:animtionBlock completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    } else {
        ACCBLOCK_INVOKE(animtionBlock);
        self.userInteractionEnabled = YES;
    }
}

- (void)p_switchToTapVideoType
{
    self.userInteractionEnabled = NO;
    void(^animtionBlock)(void) = ^{
        self.innerLayer.hidden = YES;
        self.outterLayer.backgroundColor = [ACCResourceColor(ACCUIColorConstPrimary) colorWithAlphaComponent:0.5].CGColor;
        self.innerLayer.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary) .CGColor;
        self.innerLayer.transform = CATransform3DMakeScale(innerLayerNormalStateSmallRadius / innerLayerInitRadius, innerLayerNormalStateSmallRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.transform = CATransform3DMakeScale(outterLayerNormalStateRadius / innerLayerInitRadius, outterLayerNormalStateRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.opacity = 1.0f;
    };
    if ([self acc_isDisplayedOnScreen]) {
        [UIView animateWithDuration:normalAnimationDuration animations:animtionBlock completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    } else {
        ACCBLOCK_INVOKE(animtionBlock);
        self.userInteractionEnabled = YES;
    }
}

- (void)p_switchToTapPictureType
{
    self.userInteractionEnabled = NO;
    self.innerLayer.hidden = YES;
    void(^animtionBlock)(void) = ^{
        self.outterLayer.backgroundColor = [ACCResourceColor(ACCUIColorConstBGContainer) colorWithAlphaComponent:0.5].CGColor;
        self.innerLayer.backgroundColor = ACCResourceColor(ACCUIColorConstBGContainer).CGColor;
        self.innerLayer.transform = CATransform3DMakeScale(innerLayerNormalStateSmallRadius / innerLayerInitRadius, innerLayerNormalStateSmallRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.transform = CATransform3DMakeScale(outterLayerNormalStateRadius / innerLayerInitRadius, outterLayerNormalStateRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.opacity = 1.0f;
    };
    if ([self acc_isDisplayedOnScreen]) {
        [UIView animateWithDuration:normalAnimationDuration animations:animtionBlock completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    } else {
        ACCBLOCK_INVOKE(animtionBlock);
        self.userInteractionEnabled = YES;
    }
}

- (void)p_switchToCountDownType
{
    self.innerLayer.hidden = YES;
    void (^animationBlock)(void) = ^{
        self.outterLayer.backgroundColor = [ACCResourceColor(ACCUIColorConstPrimary)  colorWithAlphaComponent:0.5].CGColor;
        self.innerLayer.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary) .CGColor;
        self.innerLayer.transform = CATransform3DMakeScale(innerLayerNormalStateSmallRadius / innerLayerInitRadius, innerLayerNormalStateSmallRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.transform = CATransform3DMakeScale(outterLayerNormalStateRadius / innerLayerInitRadius, outterLayerNormalStateRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.opacity = 1.0f;
    };
    
    if ([self acc_isDisplayedOnScreen]) {
        [UIView animateWithDuration:normalAnimationDuration animations:animationBlock];
    } else {
        ACCBLOCK_INVOKE(animationBlock);
    }
}

- (void)p_switchToMixTapHoldVideoType
{
    self.userInteractionEnabled = NO;
    void(^animtionBlock)(void) = ^{
        self.innerLayer.hidden = YES;
        if (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
            self.outterLayer.backgroundColor = [UIColor whiteColor].CGColor;
        } else {
            self.outterLayer.backgroundColor = [ACCResourceColor(ACCUIColorConstPrimary) colorWithAlphaComponent:0.5].CGColor;
        }
        self.innerLayer.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary) .CGColor;
        self.innerLayer.transform = CATransform3DMakeScale(innerLayerNormalStateSmallRadius / innerLayerInitRadius, innerLayerNormalStateSmallRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.transform = CATransform3DMakeScale(outterLayerNormalStateRadius / innerLayerInitRadius, outterLayerNormalStateRadius / innerLayerInitRadius, 1.0);
        self.outterLayer.opacity = 1.0f;
    };
    if ([self acc_isDisplayedOnScreen]) {
        [UIView animateWithDuration:normalAnimationDuration animations:animtionBlock completion:^(BOOL finished) {
            self.userInteractionEnabled = YES;
        }];
    } else {
        ACCBLOCK_INVOKE(animtionBlock);
        self.userInteractionEnabled = YES;
    }
}

#pragma mark - hit test

- (UIView*)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView* tmpView = [super hitTest:point withEvent:event];
    if (tmpView == self) {
        return nil;
    }
    return tmpView;
}

#pragma mark - begin animation

- (void)beginAnimation
{
    switch (self.type) {
        case AWEAnimatedRecordButtonTypeHoldVideo: {
            [self p_beginHoldVideoAnimation];
            break;
        }
        case AWEAnimatedRecordButtonTypeTapVideo: {
            [self p_beginTapVideoAnimation];
            break;
        }
        case AWEAnimatedRecordButtonTypeTapPicture: {
            [self p_beginTapPictureAnimation];
            break;
        }
        case AWEAnimatedRecordButtonTypeCountDown: {
            [self p_beginCountDownAnimation];
            break;
        }
        case AWEAnimatedRecordButtonTypeMixTapHoldVideo: {
            [self p_beginMixHoldTapAnimation];
            break;
        }
        default:
            break;
    }
}

- (void)p_beginHoldVideoAnimation
{
    self.innerLayer.hidden = NO;
    // Zoom in on the animation
    CABasicAnimation *scaleAnimation = [self.innerLayer createScaleAnimationWithRatio:outterLayerAnimationStateRadius / innerLayerNormalStateBigRadius duration:normalAnimationDuration];
    [self.innerLayer addAnimation:scaleAnimation forKey:@"scale_transform_animation_key"];
    
    // Hollow out animation
    CABasicAnimation *animation = [self.innerLayer createHollowOutAnimationWithRatio:outterLayerAnimationStateBigHollowRatio duration:normalAnimationDuration];
    [animation setValue:@"inner_hollow_out_animation_begin" forKey:@"animation_key"];
    animation.delegate = (id <CAAnimationDelegate>)[ACCWeakProxy proxyWithTarget:self];
    [self.innerLayer.maskLayer addAnimation:animation forKey:@"location_animation_key"];
}

- (void)p_beginTapVideoAnimation
{
    // Zoom in on the animation
    CABasicAnimation *scaleAnimation = [self.outterLayer createScaleAnimationWithRatio:outterLayerAnimationStateRadius / outterLayerNormalStateRadius duration:normalAnimationDuration];
    [self.outterLayer addAnimation:scaleAnimation forKey:@"scale_transform_animation_key"];
    
    // Hollow out animation
    CABasicAnimation *animation = [self.outterLayer createHollowOutAnimationWithRatio:outterLayerAnimationStateBigHollowRatio duration:normalAnimationDuration];
    [animation setValue:@"outter_hollow_out_animation_begin" forKey:@"animation_key"];
    animation.delegate = (id <CAAnimationDelegate>)[ACCWeakProxy proxyWithTarget:self];
    [self.outterLayer.maskLayer addAnimation:animation forKey:@"location_animation_key"];
}

- (void)p_beginTapPictureAnimation
{
    
}

- (void)p_beginCountDownAnimation
{
    // Zoom in on the animation
    CABasicAnimation *scaleAnimation = [self.outterLayer createScaleAnimationWithRatio:outterLayerAnimationStateRadius / outterLayerNormalStateRadius duration:normalAnimationDuration];
    [self.outterLayer addAnimation:scaleAnimation forKey:@"scale_transform_animation_key"];
    
    // Hollow out animation
    CABasicAnimation *animation = [self.outterLayer createHollowOutAnimationWithRatio:outterLayerAnimationStateBigHollowRatio duration:normalAnimationDuration];
    [animation setValue:@"outter_hollow_out_animation_begin" forKey:@"animation_key"];
    animation.delegate = (id <CAAnimationDelegate>)[ACCWeakProxy proxyWithTarget:self];
    [self.outterLayer.maskLayer addAnimation:animation forKey:@"location_animation_key"];
}

- (void)p_beginMixHoldTapAnimation
{
    // Zoom in on the animation
    CABasicAnimation *scaleAnimation = [self.outterLayer createScaleAnimationWithRatio:outterLayerAnimationStateRadius / outterLayerNormalStateRadius duration:normalAnimationDuration];
    [self.outterLayer addAnimation:scaleAnimation forKey:@"scale_transform_animation_key"];
    
    // Hollow out animation
    CABasicAnimation *animation = [self.outterLayer createHollowOutAnimationWithRatio:outterLayerAnimationStateBigHollowRatio duration:normalAnimationDuration];
    [animation setValue:@"outter_hollow_out_animation_begin" forKey:@"animation_key"];
    animation.delegate = (id <CAAnimationDelegate>)[ACCWeakProxy proxyWithTarget:self];
    [self.outterLayer.maskLayer addAnimation:animation forKey:@"location_animation_key"];

    if (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
        self.outterLayer.backgroundColor = [ACCResourceColor(ACCUIColorConstPrimary) colorWithAlphaComponent:0.5].CGColor;
    }
}

#pragma mark - end animation

- (void)endAnimation
{
    switch (self.type) {
        case AWEAnimatedRecordButtonTypeHoldVideo: {
            [self p_endHoldVideoAnimation];
            break;
        }
        case AWEAnimatedRecordButtonTypeTapVideo: {
            [self p_endTapVideoAnimation];
            break;
        }
        case AWEAnimatedRecordButtonTypeTapPicture: {
            [self p_endTapPictureAnimation];
            break;
        }
        case AWEAnimatedRecordButtonTypeCountDown: {
            [self p_endCountDownAnimation];
            break;
        }
        case AWEAnimatedRecordButtonTypeMixTapHoldVideo: {
            [self p_endMixHoldTapAnimation];
            break;
        }
        default:
            break;
    }
}

- (void)p_endHoldVideoAnimation
{
    // End zoom in animation
    CABasicAnimation *scaleAnimation = [self.innerLayer createScaleAnimationWithRatio:innerLayerNormalStateBigRadius / innerLayerNormalStateBigRadius duration:normalAnimationDuration];
    [self.innerLayer addAnimation:scaleAnimation forKey:@"scale_transform_animation_key"];
    
    // End hollowed out animation
    CABasicAnimation *animation = [self.innerLayer createHollowOutAnimationWithRatio:innerLayerNormalStateHollowRatio duration:normalAnimationDuration];
    [animation setValue:@"inner_hollow_out_animation_end" forKey:@"animation_key"];
    animation.delegate = (id <CAAnimationDelegate>)[ACCWeakProxy proxyWithTarget:self];
    [self.innerLayer.maskLayer addAnimation:animation forKey:@"location_animation_key"];
}

- (void)p_endTapVideoAnimation
{
    // End zoom in animation
    CABasicAnimation *scaleAnimation = [self.outterLayer createScaleAnimationWithRatio:outterLayerNormalStateRadius / outterLayerNormalStateRadius duration:normalAnimationDuration];
    [self.outterLayer addAnimation:scaleAnimation forKey:@"scale_transform_animation_key"];
    
    // End hollowed out animation
    CABasicAnimation *animation = [self.outterLayer createHollowOutAnimationWithRatio:outterLayerNormalStateHollowRatio duration:normalAnimationDuration];
    [animation setValue:@"outter_hollow_out_animation_end" forKey:@"animation_key"];
    animation.delegate = (id <CAAnimationDelegate>)[ACCWeakProxy proxyWithTarget:self];
    [self.outterLayer.maskLayer addAnimation:animation forKey:@"location_animation_key"];
}

- (void)p_endTapPictureAnimation
{
    
}

- (void)p_endCountDownAnimation
{
    // End zoom in animation
    CABasicAnimation *scaleAnimation = [self.outterLayer createScaleAnimationWithRatio:outterLayerNormalStateRadius / outterLayerNormalStateRadius duration:normalAnimationDuration];
    [self.outterLayer addAnimation:scaleAnimation forKey:@"scale_transform_animation_key"];
    
    // End hollowed out animation
    CABasicAnimation *animation = [self.outterLayer createHollowOutAnimationWithRatio:outterLayerNormalStateHollowRatio duration:normalAnimationDuration];
    [animation setValue:@"outter_hollow_out_animation_end" forKey:@"animation_key"];
    animation.delegate = (id <CAAnimationDelegate>)[ACCWeakProxy proxyWithTarget:self];
    [self.outterLayer.maskLayer addAnimation:animation forKey:@"location_animation_key"];
}

- (void)p_endMixHoldTapAnimation
{
    // End zoom in animation
    CABasicAnimation *scaleAnimation = [self.outterLayer createScaleAnimationWithRatio:outterLayerNormalStateRadius / outterLayerNormalStateRadius duration:normalAnimationDuration];
    [self.outterLayer addAnimation:scaleAnimation forKey:@"scale_transform_animation_key"];
    
    // End hollowed out animation
    CABasicAnimation *animation = [self.outterLayer createHollowOutAnimationWithRatio:outterLayerNormalStateHollowRatio duration:normalAnimationDuration];
    [animation setValue:@"outter_hollow_out_animation_end" forKey:@"animation_key"];
    animation.delegate = (id <CAAnimationDelegate>)[ACCWeakProxy proxyWithTarget:self];
    [self.outterLayer.maskLayer addAnimation:animation forKey:@"location_animation_key"];
    
    [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        if (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
            self.outterLayer.backgroundColor = [UIColor whiteColor].CGColor;
        } else {
            self.outterLayer.backgroundColor = [ACCResourceColor(ACCUIColorConstPrimary) colorWithAlphaComponent:0.5].CGColor;
        }
    } completion:nil];
}

#pragma mark - lazy init property

- (CALayer<AWEAnimatedRecordLayerProtocol> *)acc_innerLayer
{
    if (!_innerLayer) {
        CGRect frame = CGRectMake(0, 0, innerLayerInitRadius, innerLayerInitRadius);
        _innerLayer = [[AWEAnimatedRecordShapeLayer alloc] initWithFrame:frame];
        _innerLayer.backgroundColor = ACCResourceColor(ACCUIColorConstPrimary) .CGColor;
        [_innerLayer setInitialHollowRatio:innerLayerNormalStateHollowRatio];
    }
    return _innerLayer;
}

- (CALayer<AWEAnimatedRecordLayerProtocol> *)outterLayer
{
    if (!_outterLayer) {
        CGRect frame = CGRectMake(0, 0, outterLayerInitRadius, outterLayerInitRadius);
        _outterLayer = [[AWEAnimatedRecordShapeLayer alloc] initWithFrame:frame];
        if (ACCConfigBool(kConfigBool_enable_story_tab_in_recorder)) {
            _outterLayer.backgroundColor = [UIColor whiteColor].CGColor;
        } else {
            _outterLayer.backgroundColor = [ACCResourceColor(ACCUIColorConstPrimary) colorWithAlphaComponent:0.5].CGColor;
        }
        [_outterLayer setInitialHollowRatio:outterLayerNormalStateHollowRatio];
    }
    return _outterLayer;
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([[anim valueForKey:@"animation_key"] isEqualToString:@"inner_hollow_out_animation_begin"] && flag) {
        CABasicAnimation *breathAnimation = [self.innerLayer createBreathingAnimationWithFromRatio:outterLayerAnimationStateBigHollowRatio toRatio:outterLayerAnimationStateSmallHollowRatio duration:breathAnimationDuration];
        [self.innerLayer.maskLayer addAnimation:breathAnimation forKey:@"location_animation_key"];
    }
    
    if ([[anim valueForKey:@"animation_key"] isEqualToString:@"outter_hollow_out_animation_begin"] && flag) {
        CABasicAnimation *breathAnimation = [self.outterLayer createBreathingAnimationWithFromRatio:outterLayerAnimationStateBigHollowRatio toRatio:outterLayerAnimationStateSmallHollowRatio duration:breathAnimationDuration];
        [self.outterLayer.maskLayer addAnimation:breathAnimation forKey:@"location_animation_key"];
    }
    
    if ([[anim valueForKey:@"animation_key"] isEqualToString:@"inner_hollow_out_animation_end"] && flag) {
        self.innerLayer.hidden = YES;
    }
}

@end
