//
//  AWECameraFeatureButtonPassThroughView.m
//  CameraClient-Pods-Aweme
//
//  Created by fengming.shi on 2020/12/8 11:04.
//	Copyright © 2020 Bytedance. All rights reserved.

#import "AWECameraFeatureButtonPassThroughView.h"

@implementation AWECameraFeatureButtonPassThroughView

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *hitView = [super hitTest:point withEvent:event];
    if (hitView == self) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(handleFeatureButtionPassThroughHitTest)]) {
            [self.delegate handleFeatureButtionPassThroughHitTest];
        }
        return nil;
    }
    return hitView;
}

@end
