//
//  UIView+BDPAppearance.m
//  Timor
//
//  Created by liuxiangxin on 2019/4/30.
//

#import "UIView+BDPAppearance.h"
#import "UIView+BDPExtension.h"
#import "NSObject+BDPExtension.h"

#import "BDPMethodSwizzledUtilsDefine.h"
#import "BDPBootstrapHeader.h"
#import "BDPCascadeStyleManager.h"

#import <objc/runtime.h>

@implementation UIView (BDPAppearance)

#pragma mark - Property Extension

- (void)bdp_updateCornerRadius
{
    CGFloat minEdge = MIN(self.bdp_width, self.bdp_height);
    
    CGFloat cornerRadius = self.layer.cornerRadius;
    if (self.bdp_cornerRadiusRatio > 0.f) {
        cornerRadius = minEdge * self.bdp_cornerRadiusRatio;
    }
    cornerRadius = MIN(cornerRadius, minEdge / 2.f);
    cornerRadius = MAX(cornerRadius, 0.f);
    
    self.layer.cornerRadius = cornerRadius;
}

- (void)bdp_updateRectCorners
{
    UIRectCorner corners = self.bdp_rectCorners;
    if (corners == UIRectCornerAllCorners) {
        return;
    }
    
    CGSize cornerRadii = self.bdp_cornerRadii;

    UIBezierPath *rounded = [UIBezierPath bezierPathWithRoundedRect:self.bounds
                                                  byRoundingCorners:corners
                                                        cornerRadii:cornerRadii];
    CAShapeLayer *shape = [CAShapeLayer new];
    shape.frame = self.bounds;
    shape.path = rounded.CGPath;
    self.layer.mask = shape;
}

- (CGFloat)bdp_cornerRadiusRatio
{
    NSNumber *ratioNumber = objc_getAssociatedObject(self, @selector(bdp_cornerRadiusRatio));
    if (!ratioNumber || ![ratioNumber isKindOfClass:NSNumber.class]) {
        return BDPCornerRadiusRatioNoExisted;
    }
    
    return [ratioNumber doubleValue];
}

- (void)setBdp_cornerRadiusRatio:(CGFloat)bdp_cornerRadiusRatio
{
    objc_setAssociatedObject(self, @selector(bdp_cornerRadiusRatio), @(bdp_cornerRadiusRatio), OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self setNeedsLayout];
}

- (void)setBdp_rectCorners:(UIRectCorner)bdp_rectCorners
{
    objc_setAssociatedObject(self, @selector(bdp_rectCorners), @(bdp_rectCorners), OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self setNeedsLayout];
}

- (UIRectCorner)bdp_rectCorners
{
    NSNumber *cornerNumber = objc_getAssociatedObject(self, @selector(bdp_rectCorners));
    UIRectCorner corner = UIRectCornerAllCorners;
    if (cornerNumber) {
        corner = [cornerNumber unsignedIntegerValue];
    }
    
    return corner;
}

- (CGFloat)bdp_cornerRadius
{
    return self.layer.cornerRadius;
}

- (void)setBdp_cornerRadius:(CGFloat)bdp_cornerRadius
{
    self.layer.cornerRadius = bdp_cornerRadius;
    
    [self setNeedsLayout];
}

- (CGSize)bdp_cornerRadii
{
    NSNumber *radiiNumber = objc_getAssociatedObject(self, @selector(bdp_cornerRadii));
    return [radiiNumber CGSizeValue];
}

- (void)setBdp_cornerRadii:(CGSize)bdp_cornerRadii
{
    objc_setAssociatedObject(self, @selector(bdp_cornerRadii), @(bdp_cornerRadii), OBJC_ASSOCIATION_COPY_NONATOMIC);
    
    [self setNeedsLayout];
}

@end
