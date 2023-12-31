//
//  AWEVideoGameCameraContainerView.m
//  AWEStudio
//
//  Created by lixingdong on 2018/8/15.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import <CreationKitInfra/UIView+ACCMasonry.h>
#import "AWEVideoGameCameraContainerView.h"
#import <CreationKitInfra/UIView+ACCUIKit.h>
#import "AWEXScreenAdaptManager.h"
#import <CreativeKit/ACCMacros.h>
#import <CreativeKit/UIImage+CameraClientResource.h>
#import <Masonry/View+MASAdditions.h>


static NSString * const kAnimationType      = @"animationType";
static NSString * const kAppearAnimation    = @"GameAppearAnimation";
static NSString * const kDisappearAnimation = @"GameDisappearAnimation";

@interface AWEVideoGameCameraContainerView()<CAAnimationDelegate>

@property (nonatomic, strong) UIView *blurEffectView;
@property (nonatomic, strong) CAKeyframeAnimation *animation;
@property (nonatomic, strong) AWEVideoGameAppearCompletion appearCompletion;
@property (nonatomic, strong) AWEVideoGameAppearCompletion disappearCompletion;

@end

@implementation AWEVideoGameCameraContainerView

- (instancetype)init
{
    self = [super initWithFrame:CGRectMake(0, 0, ACC_SCREEN_WIDTH, ACC_SCREEN_HEIGHT)];
    
    if (self) {
        [self setupUI];
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)setupUI
{
    [self addSubview:self.blurEffectView];
    [self addSubview:self.closeBtn];
    ACCMasMaker(self.closeBtn, {
        make.left.equalTo(self.mas_left).offset(15);
        make.top.equalTo(self.mas_top).offset(31.5 + ACC_NAVIGATION_BAR_OFFSET);
        make.size.mas_equalTo(CGSizeMake(31, 31));
    });
    
    CGFloat offset = -39.5;
    if ([AWEXScreenAdaptManager needAdaptScreen]) {
        offset = offset - 58.0;
    }
}

- (void)showWithAnimated:(BOOL)animated completion:(AWEVideoGameAppearCompletion)completion
{
    if (animated) {
        [self.animation setValue:kAppearAnimation forKey:kAnimationType];

        self.appearCompletion = completion;
        [self.blurEffectView.layer addAnimation:self.animation forKey:nil];
    } else {
        ACCBLOCK_INVOKE(completion);
    }
}

- (void)dismissWithAnimated:(BOOL)animated completion:(AWEVideoGameAppearCompletion)completion
{
    if (animated) {
        [self.animation setValue:kDisappearAnimation forKey:kAnimationType];

        self.disappearCompletion = completion;
        [self.blurEffectView.layer addAnimation:self.animation forKey:nil];
    } else {
        ACCBLOCK_INVOKE(completion);
    }
}

#pragma mark - hit events
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (self.isShowingForEffectControlGame && view == self) {
        return nil;
    }
    return view;
}

#pragma mark - setter/getter

- (UIView *)blurEffectView
{
    if (!_blurEffectView) {
        _blurEffectView = [[UIView alloc] initWithFrame:self.bounds];
        _blurEffectView.backgroundColor = [UIColor clearColor];
        _blurEffectView.alpha = 0;
        [_blurEffectView acc_addBlurEffect];
    }
    
    return _blurEffectView;
}

- (ACCAnimatedButton *)closeBtn
{
    if (!_closeBtn) {
        UIImage *image = ACCResourceImage(@"icon_game_close_white");
        _closeBtn = [[ACCAnimatedButton alloc] init];
        _closeBtn.enabled = NO;
        [_closeBtn setImage:image forState:UIControlStateNormal];
        [_closeBtn setImage:image forState:UIControlStateHighlighted];
    }
    
    return _closeBtn;
}

- (CAKeyframeAnimation *)animation
{
    if (!_animation) {
        
        _animation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
        _animation.duration = 0.8;
        _animation.keyTimes = @[@(0), @(0.1), @(0.9), @(1.0)];
        _animation.values = @[@(0), @(1.0), @(1.0), @(0)];
        _animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
        _animation.delegate = self;
        _animation.removedOnCompletion = NO;
        _animation.fillMode = kCAFillModeForwards;
    }
    
    return _animation;
}

#pragma mark - CAAnimationDelegate

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    if ([[anim valueForKey:kAnimationType] isEqualToString:kAppearAnimation]) {
        self.hidden = NO;
        ACCBLOCK_INVOKE(self.appearCompletion);
    }
    
    if ([[anim valueForKey:kAnimationType] isEqualToString:kDisappearAnimation]) {
        self.hidden = YES;
        ACCBLOCK_INVOKE(self.disappearCompletion);
    }
}

- (void)setIsShowingForEffectControlGame:(BOOL)isShowingForEffectControlGame
{
    _isShowingForEffectControlGame = isShowingForEffectControlGame;
}

@end
