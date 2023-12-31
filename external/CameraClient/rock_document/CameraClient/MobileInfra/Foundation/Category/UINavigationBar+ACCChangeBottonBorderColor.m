//
//  UINavigationBar+ACCChangeBottonBorderColor.m
//  Aweme
//
//  Created by 郝一鹏 on 2017/3/28.
//  Copyright © 2017年 Bytedance. All rights reserved.
//

#import "UINavigationBar+ACCChangeBottonBorderColor.h"

@implementation UINavigationBar (ACCChangeBottonBorderColor)

- (void)setBottomBorderColor:(UIColor *)color height:(CGFloat)height {
    CGRect bottomBorderRect = CGRectMake(0, CGRectGetHeight(self.frame), CGRectGetWidth(self.frame), height);
    UIView *bottomBorder = [[UIView alloc] initWithFrame:bottomBorderRect];
    [bottomBorder setBackgroundColor:color];
    [self addSubview:bottomBorder];
}

@end
