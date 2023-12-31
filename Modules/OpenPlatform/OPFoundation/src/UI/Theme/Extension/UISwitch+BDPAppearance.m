//
//  UISwitch+BDPAppearance.m
//  Timor
//
//  Created by liuxiangxin on 2019/5/13.
//

#import "UISwitch+BDPAppearance.h"

@implementation UISwitch (BDPAppearance)

- (void)setPositiveColor:(UIColor *)positiveColor
{
    [self setOnTintColor:positiveColor];
}

- (UIColor *)positiveColor
{
    return [self onTintColor];
}

- (void)setNegativeColor:(UIColor *)negativeColor
{
    [self setTintColor:negativeColor];
}

- (UIColor *)negativeColor
{
    return [self tintColor];
}

@end
