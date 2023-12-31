//
//  UIView+Animation.m
//  CameraClient
//
//  Created by ZhangYuanming on 2019/12/17.
//

#import "UIView+Animation.h"


@implementation UIView (Animation)

- (void)animateScaleFrom:(CGFloat)scale
                 toScale:(CGFloat)toScale
                duration:(NSTimeInterval)duration
                  repeat:(BOOL)repeat {
    CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform.scale"];
    
    scaleAnimation.duration = duration;
    scaleAnimation.fromValue = @(scale);
    scaleAnimation.toValue = @(toScale);
    scaleAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    scaleAnimation.autoreverses = NO;
    scaleAnimation.fillMode = kCAFillModeForwards;
    scaleAnimation.repeatCount = repeat ? HUGE_VALF : 0;
    
    [self.layer addAnimation:scaleAnimation forKey:@"sacleAnimate"];
}

@end
