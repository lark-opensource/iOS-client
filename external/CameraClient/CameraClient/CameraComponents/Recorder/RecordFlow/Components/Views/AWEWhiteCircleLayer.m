//
//  AWEWhiteCircleLayer.m
//  AWEStudio
//
//  Created by 郝一鹏 on 2018/2/4.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "AWEWhiteCircleLayer.h"
#import <CreativeKit/UIColor+CameraClientResource.h>

@implementation AWEWhiteCircleLayer

- (void)drawCircleInContext:(CGContextRef)c
{
    CGMutablePathRef arc = CGPathCreateMutable();
    CGPoint center = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds));
    CGFloat r = MIN(CGRectGetWidth(self.bounds),CGRectGetHeight(self.bounds))/2.0;
    CGFloat lineWidth = r * (1.0 - self.innerFragment);
    r = r - lineWidth / 2.0;

    CGPathAddArc(arc, NULL, center.x, center.y, r, 2*M_PI,0,YES);
    CGPathRef strokedArc = CGPathCreateCopyByStrokingPath(arc, NULL,lineWidth,
                                                          kCGLineCapRound,
                                                          kCGLineJoinMiter,
                                                          10);

    CGContextAddPath(c, strokedArc);
    CGContextSetStrokeColorWithColor(c, [UIColor clearColor].CGColor);
    CGContextSetFillColorWithColor(c, ACCResourceColor(ACCUIColorBGContainer6).CGColor);
    CGContextDrawPath(c, kCGPathFillStroke);

    CGPathRelease(arc);
    CGPathRelease(strokedArc);
}

@end
