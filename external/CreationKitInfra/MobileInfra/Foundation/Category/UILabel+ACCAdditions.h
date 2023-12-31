//
//  UILabel+ACCAdditions.h
//  ACCFoundation
//
// Created by Hao Yipeng on December 29, 2017
//  Copyright  ©  Byedance. All rights reserved, 2017
//

#import <UIKit/UIKit.h>

@interface UILabel (ACCAdditions)

- (instancetype)acc_initWithFont:(UIFont *)font textColor:(UIColor *)textColor text:(NSString *)text;

- (instancetype)acc_initWithFontSize:(CGFloat)fontSize isBold:(BOOL)isBold textColor:(UIColor *)textColor text:(NSString *)text;

- (void)acc_addShadowWithShadowColor:(UIColor *)color shadowOffset:(CGSize)offset shadowRadius:(CGFloat)shadowRadius;

- (void)acc_addShadowWithShadowColor:(UIColor *)color shadowOffset:(CGSize)offset shadowRadius:(CGFloat)shadowRadius shadowOpacity:(CGFloat)shadowOpacity;

- (void)acc_sizeToFitWidth:(CGFloat)width;

@end
