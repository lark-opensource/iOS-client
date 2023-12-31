//
//  AWETextField.m
//  Aweme
//
//  Created by 旭旭 on 2017/9/14.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "AWETextField.h"

@implementation AWETextField

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    for (UIView *view in self.subviews) {
        if ([view isKindOfClass:[UIScrollView class]]) {
            CGPoint offset = ((UIScrollView *)view).contentOffset;
            offset.y = 0;
            ((UIScrollView *)view).contentOffset = offset;
            break;
        }
    }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    UIEdgeInsets hitTestEdgeInsets = self.hitTestEdgeInsets;
    if (UIEdgeInsetsEqualToEdgeInsets(hitTestEdgeInsets, UIEdgeInsetsZero) || !self.enabled || self.hidden || !self.alpha) {
        return [super pointInside:point withEvent:event];
    }
    CGRect hitFrame = UIEdgeInsetsInsetRect(self.bounds, hitTestEdgeInsets);
    return CGRectContainsPoint(hitFrame, point);
}

- (void)setPlaceHolderTextColor:(UIColor *)placeHolderTextColor {
    _placeHolderTextColor = placeHolderTextColor;
    NSMutableAttributedString *placeHolderMutStr = [[NSMutableAttributedString alloc] initWithString:self.placeholder ?: @""];
    [placeHolderMutStr addAttribute:NSForegroundColorAttributeName
                              value:placeHolderTextColor
                              range:NSMakeRange(0, self.placeholder.length)];
    self.attributedPlaceholder = [placeHolderMutStr copy];
}

@end
