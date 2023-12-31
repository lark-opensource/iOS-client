//
//  AWECircleMaskLayer.m
//  AWEAnimatedLayer
//
// Created by Hao Yipeng on May 20, 2019
//  Copyright  ©  Hao Yipeng. All rights reserved
//

#import "AWEAnimatedRecordShapeLayer.h"

@implementation AWEAnimatedRecordShapeLayer

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super init];
    if (self) {
        self.backgroundColor = [UIColor blackColor].CGColor;
        self.frame = frame;
        self.cornerRadius = 40;
        [self addCirclelayer];
    }
    return self;
}

- (void)addCirclelayer
{
    self.maskLayer.frame = self.bounds;
    self.mask = self.maskLayer;
}

- (void)setInitialHollowRatio:(CGFloat)ratio
{
    ((CAShapeLayer *)self.maskLayer).lineWidth = [self calculateMaskLayerLineWidthWithRatio:ratio];
}

- (void)layoutSublayers
{
    [super layoutSublayers];
    self.maskLayer.frame = self.bounds;
}

#pragma mark - public method

- (CABasicAnimation *)createColorChangeAnimationWithColor:(UIColor *)color duration:(CFTimeInterval)duration
{
    CABasicAnimation *colorChangeAnimation = [[CABasicAnimation alloc] init];
    colorChangeAnimation.keyPath = @"backgroundColor";
    colorChangeAnimation.fromValue = (__bridge id)self.presentationLayer.backgroundColor;
    colorChangeAnimation.toValue = (__bridge id)color.CGColor;
    colorChangeAnimation.duration = duration;
    colorChangeAnimation.removedOnCompletion = NO;
    colorChangeAnimation.fillMode = kCAFillModeForwards;
    return colorChangeAnimation;
}

- (CABasicAnimation *)createHollowOutAnimationWithRatio:(CGFloat)ratio duration:(CFTimeInterval)duration
{
    CABasicAnimation *hollowOutAnimation  = [[CABasicAnimation alloc] init];
    hollowOutAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [hollowOutAnimation setValue:@"hollow_out_animation" forKey:@"animation_key"];
    hollowOutAnimation.keyPath = @"lineWidth";
    hollowOutAnimation.fromValue = @(((CAShapeLayer *)self.maskLayer).presentationLayer.lineWidth);
    hollowOutAnimation.toValue = @([self calculateMaskLayerLineWidthWithRatio:ratio]);
    hollowOutAnimation.duration = duration;
    hollowOutAnimation.removedOnCompletion = NO;
    hollowOutAnimation.fillMode = kCAFillModeForwards;
    return hollowOutAnimation ;
}

- (CABasicAnimation *)createScaleAnimationWithRatio:(CGFloat)ratio duration:(CFTimeInterval)duration
{
    CABasicAnimation *scaleAnimation = [[CABasicAnimation alloc] init];
    scaleAnimation.keyPath = @"transform";
    [scaleAnimation setValue:@"scale_animation" forKey:@"animation_key"];
    CATransform3D toTransform = CATransform3DScale(CATransform3DIdentity, ratio, ratio, 1.0);
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:self.presentationLayer.transform];
    scaleAnimation.toValue = [NSValue valueWithCATransform3D:toTransform];
    scaleAnimation.duration = duration;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.removedOnCompletion = NO;
    return scaleAnimation;
}

- (CABasicAnimation *)createBreathingAnimationWithFromRatio:(CGFloat)startRatio toRatio:(CGFloat)toRatio duration:(CFTimeInterval)duration
{
    CABasicAnimation *animation = [[CABasicAnimation alloc] init];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    [animation setValue:@"breath_animation" forKey:@"animation_key"];
    animation.keyPath = @"lineWidth";
    animation.fromValue = @([self calculateMaskLayerLineWidthWithRatio:startRatio]);
    animation.toValue = @([self calculateMaskLayerLineWidthWithRatio:toRatio]);
    animation.autoreverses = YES;
    animation.duration = duration;
    animation.repeatCount = HUGE;
    return animation;
}

- (CABasicAnimation *)createCornerRadiusAnimationWithCornerRadius:(CGFloat)cornerRadius duration:(CFTimeInterval)duration
{
    CABasicAnimation *scaleAnimation = [[CABasicAnimation alloc] init];
    scaleAnimation.keyPath = @"cornerRadius";
    [scaleAnimation setValue:@"cornerRadius_animation" forKey:@"animation_key"];
    scaleAnimation.fromValue = [NSValue valueWithCATransform3D:self.presentationLayer.transform];
    scaleAnimation.toValue = @(cornerRadius);
    scaleAnimation.duration = duration;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.removedOnCompletion = NO;
    return scaleAnimation;
}

#pragma mark - private method

- (CGFloat)calculateMaskLayerLineWidthWithRatio:(CGFloat)ratio
{
    return (1 - ratio) * self.frame.size.width; // Radius (self. Frame. Size. Width / 2) * ratio of half line width to radius ((1 - ratio)) * 2
}

#pragma mark - mask layer

- (CALayer *)maskLayer
{
    if (!_maskLayer) {
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithArcCenter:CGPointMake(self.frame.size.width / 2, self.frame.size.width / 2) radius:self.frame.size.width / 2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
        CAShapeLayer *maskLayer = [CAShapeLayer layer];
        maskLayer.fillColor = [UIColor clearColor].CGColor;
        maskLayer.strokeColor = [UIColor blackColor].CGColor;
        maskLayer.lineWidth = self.frame.size.width / 2;
        maskLayer.strokeStart = 0;
        maskLayer.strokeEnd = 1;
        maskLayer.lineCap = kCALineCapRound;
        maskLayer.path = bezierPath.CGPath;
        _maskLayer = maskLayer;
    }
    return _maskLayer;
}

@synthesize maskLayer = _maskLayer;

@end
