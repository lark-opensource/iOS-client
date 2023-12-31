//
//  AWEStickerBaseContainerView.m
//  AAWELaunchMainPlaceholder-iOS8.0
//
//  Created by li xingdong on 2019/5/22.
//

#import "AWEStickerBaseContainerView.h"

@implementation AWEStickerBaseContainerView

- (void)makeMaskLayerForMaskViewOneWithRadius:(CGFloat)radius
{
    CGRect frame = self.maskViewOne.bounds;
    CAShapeLayer *layer = [CAShapeLayer layer];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame), CGRectGetMinY(frame))];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame))];
    [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMaxY(frame)) radius:radius startAngle:0 endAngle:-(M_PI * 0.5) clockwise:NO];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame) - radius)];
    [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMaxY(frame)) radius:radius startAngle:-(M_PI * 0.5) endAngle:-M_PI clockwise:NO];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame))];
    
    layer.path = path.CGPath;
    self.maskViewOne.layer.mask = layer;
}

- (void)makeMaskLayerForMaskViewTwoWithRadius:(CGFloat)radius
{
    CGRect frame = self.maskViewTwo.bounds;
    CAShapeLayer *layer = [CAShapeLayer layer];
    
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame))];
    [path addArcWithCenter:CGPointMake(CGRectGetMinX(frame) + radius, CGRectGetMinY(frame)) radius:radius startAngle:-M_PI endAngle:-(M_PI * 1.5) clockwise:NO];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame) + radius)];
    [path addArcWithCenter:CGPointMake(CGRectGetMaxX(frame) - radius, CGRectGetMinY(frame)) radius:radius startAngle:-(M_PI * 1.5) endAngle:-(M_PI * 2.0) clockwise:NO];
    [path addLineToPoint:CGPointMake(CGRectGetMaxX(frame), CGRectGetMaxY(frame))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMaxY(frame))];
    [path addLineToPoint:CGPointMake(CGRectGetMinX(frame), CGRectGetMinY(frame))];
    
    layer.path = path.CGPath;
    self.maskViewTwo.layer.mask = layer;
}

@end
