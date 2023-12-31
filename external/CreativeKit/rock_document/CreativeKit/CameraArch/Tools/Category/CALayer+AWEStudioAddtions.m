//
//  CALayer+AWEStudioAddtions.m
//  AWEStudio
//
//  Created by Hao Yipeng on 2018/4/13.
//  Copyright © 2018 bytedance. All rights reserved.
//

#import "CALayer+AWEStudioAddtions.h"

NSString * const AWECAlayerRotationKey = @"AWECAlayerRotationKey";

@implementation CALayer (AWEStudioAddtions)

+ (CAShapeLayer *)acc_topLeftRightRoundedLayerWithRect:(CGRect)rect {
    CAShapeLayer *layer = [CAShapeLayer layer];
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:rect byRoundingCorners:UIRectCornerTopLeft|UIRectCornerTopRight cornerRadii:CGSizeMake(9, 9)];
    layer.path = path.CGPath;
    return layer;
}

- (void)acc_addRotateAnimation
{
    [self addAnimation:[self p_rotationAnimation] forKey:AWECAlayerRotationKey];
}

- (CABasicAnimation *)p_rotationAnimation
{
    CABasicAnimation *rotationAnimation = [[CABasicAnimation alloc] init];
    rotationAnimation.keyPath = @"transform.rotation";
    rotationAnimation.fromValue = @0;
    rotationAnimation.toValue = @(2 * M_PI);
    rotationAnimation.repeatCount = FLT_MAX;
    rotationAnimation.duration = 0.5;
    rotationAnimation.removedOnCompletion = NO;
    return rotationAnimation;
}

- (void)acc_fadeShow {
    [self acc_fadeShowWithDuration:0.3];
}

- (void)acc_fadeHidden {
    [self acc_fadeHiddenDuration:0.3];
}

- (void)acc_fadeShowWithDuration:(NSTimeInterval)duration {
    [self acc_fadeShow:YES duration:duration];
}

- (void)acc_fadeHiddenDuration:(NSTimeInterval)duration {
    [self acc_fadeShow:NO duration:duration];
}

- (void)acc_fadeShow:(BOOL)show duration:(NSTimeInterval)duration {

    if (show) {
        self.hidden = NO;
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.opacity = 1.0;
        } completion:nil];
    } else if (!show) {
        [UIView animateWithDuration:duration delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.opacity = 0.0;
        } completion:^(BOOL finished) {
            if (finished && self.opacity == 0.0) {
                self.hidden = YES;
            } else {
                self.hidden = NO;
            }
        }];
    }
}

@end
