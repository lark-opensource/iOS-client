//
//  UIView+AWEStudioAdditions.m
//  AWEStudio
//
//  Created by jindulys on 2019/1/4.
//  Copyright © 2019 Bytedance. All rights reserved.
//

#import "UIView+AWEStudioAdditions.h"

@implementation UIView (AWEStudioAdditions)

- (void)acc_counterClockwiseRotate
{
    [UIView animateKeyframesWithDuration:0.3
                                   delay:0
                                 options:UIViewKeyframeAnimationOptionBeginFromCurrentState | UIViewKeyframeAnimationOptionCalculationModeLinear
                              animations:^{
                                  [UIView addKeyframeWithRelativeStartTime:0.0
                                                          relativeDuration:(0.5)
                                                                animations:^{
                                                                    self.transform = CGAffineTransformRotate(self.transform, M_PI_2 * -1);
                                                                }];
                                  [UIView addKeyframeWithRelativeStartTime:(0.5)
                                                          relativeDuration:(0.5)
                                                                animations:^{
                                                                    self.transform = CGAffineTransformRotate(self.transform, M_PI_2 * -1);
                                                                }];
                              }
                              completion:nil];
}

@end
