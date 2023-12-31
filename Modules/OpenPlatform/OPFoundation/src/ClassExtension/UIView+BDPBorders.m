//
//  UIView+BDPBorders.m
//  Timor
//
//  Created by liuxiangxin on 2019/3/25.
//

#import "UIView+BDPBorders.h"
#import <objc/runtime.h>

@implementation UIView (BDPBorders)

- (void)bdp_addBorderForEdges:(UIRectEdge)edges width:(CGFloat)width color:(UIColor *)color
{
    [self bdp_removeViewForEdges:edges];
    
    if (edges & UIRectEdgeTop) {
        UIView *border = [self bdp_viewWithColor:color];
        [self insertSubview:border atIndex:0];
        [self bdp_setupConstraintsForView:border edge:UIRectEdgeTop width:width];
        self.bdp_topBorder = border;
    }
    
    if (edges & UIRectEdgeLeft) {
        UIView *border = [self bdp_viewWithColor:color];
        [self insertSubview:border atIndex:0];
        [self bdp_setupConstraintsForView:border edge:UIRectEdgeLeft width:width];
        self.bdp_leftBorder = border;
    }
    
    if (edges & UIRectEdgeBottom) {
        UIView *border = [self bdp_viewWithColor:color];
        [self insertSubview:border atIndex:0];
        [self bdp_setupConstraintsForView:border edge:UIRectEdgeBottom width:width];
        self.bdp_bottomBorder = border;
    }
    
    if (edges & UIRectEdgeRight) {
        UIView *border = [self bdp_viewWithColor:color];
        [self insertSubview:border atIndex:0];
        [self bdp_setupConstraintsForView:border edge:UIRectEdgeRight width:width];
        self.bdp_rightBorder = border;
    }
}

- (void)bdp_setupConstraintsForView:(UIView *)view edge:(UIRectEdge)edge width:(CGFloat)width
{
    if (edge & UIRectEdgeTop) {
        [view.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
        [view.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        [view.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
        [view.heightAnchor constraintEqualToConstant:width].active = YES;
        return;
    }
    
    if (edge & UIRectEdgeLeft) {
        [view.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        [view.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
        [view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [view.widthAnchor constraintEqualToConstant:width].active = YES;
        return;
    }
    
    if (edge & UIRectEdgeBottom) {
        [view.leftAnchor constraintEqualToAnchor:self.leftAnchor].active = YES;
        [view.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
        [view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [view.heightAnchor constraintEqualToConstant:width].active = YES;
        return;
    }
    
    if (edge & UIRectEdgeRight) {
        [view.topAnchor constraintEqualToAnchor:self.topAnchor].active = YES;
        [view.rightAnchor constraintEqualToAnchor:self.rightAnchor].active = YES;
        [view.bottomAnchor constraintEqualToAnchor:self.bottomAnchor].active = YES;
        [view.widthAnchor constraintEqualToConstant:width].active = YES;
        return;
    }
}

- (UIView *)bdp_viewWithColor:(UIColor *)color
{
    UIView *view = [UIView new];
    view.backgroundColor = color;
    view.translatesAutoresizingMaskIntoConstraints = NO;
    return view;
}

- (void)bdp_removeViewForEdges:(UIRectEdge)edges
{
    if (edges & UIRectEdgeTop) {
        [self.bdp_topBorder removeFromSuperview];
        self.bdp_topBorder = nil;
    }
    
    if (edges & UIRectEdgeLeft) {
        [self.bdp_leftBorder removeFromSuperview];
        self.bdp_leftBorder = nil;
    }
    
    if (edges & UIRectEdgeBottom) {
        [self.bdp_bottomBorder removeFromSuperview];
        self.bdp_bottomBorder = nil;
    }
    
    if (edges & UIRectEdgeRight) {
        [self.bdp_rightBorder removeFromSuperview];
        self.bdp_rightBorder = nil;
    }
}

#pragma mark - getter && setter

- (UIView *)bdp_topBorder
{
    return objc_getAssociatedObject(self, @selector(bdp_topBorder));
}

- (void)setBdp_topBorder:(UIView *)topBorder
{
    objc_setAssociatedObject(self, @selector(bdp_topBorder), topBorder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)bdp_leftBorder
{
    return objc_getAssociatedObject(self, @selector(bdp_leftBorder));
}

- (void)setBdp_leftBorder:(UIView *)leftBorder
{
    objc_setAssociatedObject(self, @selector(bdp_leftBorder), leftBorder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)bdp_bottomBorder
{
    return objc_getAssociatedObject(self, @selector(bdp_bottomBorder));
}

- (void)setBdp_bottomBorder:(UIView *)bottomBorder
{
    objc_setAssociatedObject(self, @selector(bdp_bottomBorder), bottomBorder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (UIView *)bdp_rightBorder
{
    return objc_getAssociatedObject(self, @selector(bdp_rightBorder));
}

- (void)setBdp_rightBorder:(UIView *)rightBorder
{
    objc_setAssociatedObject(self, @selector(bdp_rightBorder), rightBorder, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end


@implementation UITabBar (BDPBorders)

/** 修复iOS 13上修改tabBar border style时出现的crash
Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'Cannot modify constraints for UITabBar managed by a controller'
 */
- (void)bdp_setupConstraintsForView:(UIView *)view edge:(UIRectEdge)edge width:(CGFloat)width
{
    if (edge & UIRectEdgeTop) {
        view.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), width);
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
        return;
    }

    if (edge & UIRectEdgeLeft) {
        view.frame = CGRectMake(0, 0, width, CGRectGetHeight(self.frame));
        view.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleHeight;
        return;
    }

    if (edge & UIRectEdgeBottom) {
        view.frame = CGRectMake(0, 0, CGRectGetWidth(self.frame), width);
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin;
        return;
    }

    if (edge & UIRectEdgeRight) {
        view.frame = CGRectMake(0, 0, width, CGRectGetHeight(self.frame));
        view.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight;
        return;
    }
}

@end
