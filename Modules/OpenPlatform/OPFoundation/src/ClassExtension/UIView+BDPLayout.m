//
//  UIView+BDPLayout.m
//  Timor
//
//  Created by 傅翔 on 2019/3/8.
//

#import "UIView+BDPLayout.h"

@implementation UIView (BDPLayout)

- (NSArray<NSLayoutConstraint *> *)bdp_constraintEdgesEqualTo:(UIView *)view
                                                   withInsets:(UIEdgeInsets)insets
{
    _Pragma("clang diagnostic push")
    _Pragma("clang diagnostic ignored \"-Wunguarded-availability\"")

    NSLayoutConstraint *top = [self.topAnchor constraintEqualToAnchor:view.topAnchor
                                                             constant:insets.top];
    top.active = YES;
    NSLayoutConstraint *left = [self.leftAnchor constraintEqualToAnchor:view.leftAnchor
                                                               constant:insets.left];
    left.active = YES;
    NSLayoutConstraint *right = [self.rightAnchor constraintEqualToAnchor:view.rightAnchor
                                                                 constant:-insets.right];
    right.active = YES;
    NSLayoutConstraint *bottom = [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor
                                                                   constant:-insets.bottom];
    bottom.active = YES;
    
    return @[top, left, right, bottom];
    
    _Pragma("clang diagnostic pop")
}

@end
