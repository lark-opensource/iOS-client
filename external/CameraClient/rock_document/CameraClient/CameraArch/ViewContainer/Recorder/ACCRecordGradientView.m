//
//  ACCRecordGradientView.m
//  Pods
//
//  Created by songxiangwu on 2019/7/29.
//

#import "ACCRecordGradientView.h"

@implementation ACCRecordGradientView

- (void)setGradientLayer:(CAGradientLayer *)gradientLayer
{
    if (_gradientLayer != gradientLayer) {
        if (_gradientLayer) {
            [_gradientLayer removeFromSuperlayer];
        }
        _gradientLayer = gradientLayer;
        if (gradientLayer) {
            [self.layer addSublayer:gradientLayer];
        }
    }
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.gradientLayer.frame = self.bounds;
}

@end
