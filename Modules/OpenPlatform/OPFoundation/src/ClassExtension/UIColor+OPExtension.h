//
//  UIColor+BDPExtension.h
//  Timor
//
//  Created by muhuai on 2018/1/22.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIColor(OPExtension)

+ (UIColor *)colorWithHexString:(NSString *)hexString;
+ (UIColor *)colorWithHexString:(NSString *)hexString defaultValue:(NSString *)defaultValue;
- (BOOL)isEqualToColor:(UIColor *)otherColor;
+ (BOOL)isValidColorHexString:(NSString *)hexString;
// color mix c = c1*(1.0-p) + c2*p
+(UIColor *)colorBetweenColor:(UIColor *)c1
                     andColor:(UIColor *)c2
                   percentage:(float)p;
#pragma mark - BDPAppearance Color

+ (UIColor *)op_BlackColor1;
+ (UIColor *)op_BlackColor2;
+ (UIColor *)op_BlackColor3;
+ (UIColor *)op_BlackColor4;
+ (UIColor *)op_BlackColor5;
+ (UIColor *)op_BlackColor6;
+ (UIColor *)op_BlackColor7;
+ (UIColor *)op_BlackColor8;

+ (UIColor *)op_WhiteColor1;
+ (UIColor *)op_WhiteColor2;
+ (UIColor *)op_WhiteColor3;
+ (UIColor *)op_WhiteColor4;
+ (UIColor *)op_WhiteColor5;

@end
