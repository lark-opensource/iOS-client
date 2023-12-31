//
//  BDCTBiggerButton.m
//  byted_cert-Pods-AwemeCore
//
//  Created by chenzhendong.ok@bytedance.com on 2021/12/12.
//

#import "BDCTBiggerButton.h"


@implementation BDCTBiggerButton

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    CGRect bounds = self.bounds;
    // 若原来点击区域小于 44 x 44，则放大点击区域，否则保持原大小不变
    CGFloat widthDelta = MAX(44.0 - bounds.size.width, 0);
    CGFloat heightDelta = MAX(44.0 - bounds.size.height, 0);
    bounds = CGRectInset(bounds, -0.8 * widthDelta, -0.8 * heightDelta);
    return CGRectContainsPoint(bounds, point);
}

@end
