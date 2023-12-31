//
//  UIColor+BDPExtension.h
//  Timor
//
//  Created by muhuai on 2018/1/22.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BDPNegativeColor.h"

@interface UIColor(BDPExtension)

+ (UIColor *)colorWithHexString:(NSString *)hexString;
+ (UIColor *)colorWithHexString:(NSString *)hexString defaultValue:(NSString *)defaultValue;
- (BOOL)isEqualToColor:(UIColor *)otherColor;
+ (BOOL)isValidColorHexString:(NSString *)hexString;
// color mix c = c1*(1.0-p) + c2*p
+(UIColor *)colorBetweenColor:(UIColor *)c1
                     andColor:(UIColor *)c2
                   percentage:(float)p;


#pragma mark - BDPAppearance Color

+ (UIColor *)bdp_BlackColor1;
+ (UIColor *)bdp_BlackColor2;
+ (UIColor *)bdp_BlackColor3;
+ (UIColor *)bdp_BlackColor4;
+ (UIColor *)bdp_BlackColor5;
+ (UIColor *)bdp_BlackColor6;
+ (UIColor *)bdp_BlackColor7;
+ (UIColor *)bdp_BlackColor8;
+ (nonnull UIColor *)bdp_blackN900;

+ (UIColor *)bdp_WhiteColor1;
+ (UIColor *)bdp_WhiteColor2;
+ (UIColor *)bdp_WhiteColor3;
+ (UIColor *)bdp_WhiteColor4;
+ (UIColor *)bdp_WhiteColor5;
+ (UIColor *)bdp_negativeColor:(BDPNegativeColor)negativeColor;

@end
