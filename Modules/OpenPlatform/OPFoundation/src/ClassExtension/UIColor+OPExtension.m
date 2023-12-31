//
//  UIColor+BDPExtension.m
//  Timor
//
//  Created by muhuai on 2018/1/22.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "UIColor+OPExtension.h"
#import "OPUtils.h"

#define BLACK_COLOR(ALPHA) ({[UIColor colorWithRed:0 green:0 blue:0 alpha:ALPHA];})
#define WHITE_COLOR(ALPHA) ({[UIColor colorWithRed:1 green:1 blue:1 alpha:ALPHA];})

@implementation UIColor (BDPExtension)

+ (UIColor *)colorWithString:(NSString *)hexString
{
    if ((!hexString || ![hexString isKindOfClass:[NSString class]] || hexString.length == 0)) {
        return nil;
    }
    if ([hexString hasPrefix:@"0x"]) {
        hexString = [hexString substringFromIndex:2];
    }
    if ([hexString hasPrefix:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }

    if (hexString.length == 3) {
        // 处理F12 为 FF1122
        NSString *index0 = [hexString substringWithRange:NSMakeRange(0, 1)];
        NSString *index1 = [hexString substringWithRange:NSMakeRange(1, 1)];
        NSString *index2 = [hexString substringWithRange:NSMakeRange(2, 1)];
        hexString = [NSString stringWithFormat:@"%@%@%@%@%@%@", index0, index0, index1, index1, index2, index2];
    }
    unsigned int alpha = 0xFF;
    
    if (hexString.length < 6) {
        return nil;
    }
    
    NSString *rgbString = [hexString substringToIndex:6];
    NSString *alphaString = [hexString substringFromIndex:6];
    // 存在Alpha
    if (alphaString.length > 0) {
        NSScanner *scanner = [NSScanner scannerWithString:alphaString];
        if (![scanner scanHexInt:&alpha]) {
            alpha = 0xFF;
        }
    }
    
    unsigned int rgb = 0;
    NSScanner *scanner = [NSScanner scannerWithString:rgbString];
    if (![scanner scanHexInt:&rgb]) {
        return nil;
    }
    return [self colorWithRed:(CGFloat)((rgb & 0xFF0000) >> 16) / 255.0
                        green:(CGFloat)((rgb & 0x00FF00) >> 8) / 255.0f
                         blue:(CGFloat)(rgb & 0x0000FF) / 255.0
                        alpha:alpha / 255.0];
}

+ (UIColor *)colorWithHexString:(NSString *)hexString
{
    return [self colorWithString:hexString];
}

+ (UIColor *)colorWithHexString:(NSString *)hexString defaultValue:(NSString *)defaultValue
{
    UIColor *color = [self colorWithString:hexString];
    if (color) {
        return color;
    }
    return [self colorWithString:defaultValue];
}

- (BOOL)isEqualToColor:(UIColor *)otherColor
{
    if(!otherColor || ![otherColor isKindOfClass:[UIColor class]]) {
        return NO;
    }
    CGFloat r1, g1, b1, a1, r2, g2, b2, a2;
    [self getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    [otherColor getRed:&r2 green:&g2 blue:&b2 alpha:&a2];

    return (NSInteger)((r1 - r2)*255) == 0 &&
           (NSInteger)((g1 - g2)*255) == 0 &&
           (NSInteger)((b1 - b2)*255) == 0 &&
           (NSInteger)((a1 - a2)*255) == 0 ;
}

///#09af09 、#09af09ff 、#fff
+ (BOOL)isValidColorHexString:(NSString *)hexString
{
    if (OPIsEmptyString(hexString)) {
        return NO;
    }

    if ([hexString hasPrefix:@"#"]) {
        hexString = [hexString substringFromIndex:1];
    }

    if ([hexString hasPrefix:@"0x"]) {
        hexString = [hexString substringFromIndex:2];
    }

    if([hexString length] != 6 && [hexString length] != 8 && [hexString length] != 3) {
        return NO;
    }

    for(int i =0; i < [hexString length]; i++)
    {
        unichar c = [hexString characterAtIndex:i];
        BOOL valid = (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F');
        if(!valid) {
            return NO;
        }
    }

    return YES;
}

+(UIColor *)colorBetweenColor:(UIColor *)c1
                     andColor:(UIColor *)c2
                   percentage:(float)p
{
    float p1 = 1.0 - p;
    float p2 = p;
    
    const CGFloat *components = CGColorGetComponents([c1 CGColor]);
    CGFloat r1,g1,b1,a1;
    [c1 getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    
    
    components = CGColorGetComponents([c2 CGColor]);
    CGFloat r2,g2,b2,a2;
    [c2 getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    return [UIColor colorWithRed:r1*p1 + r2*p2
                           green:g1*p1 + g2*p2
                            blue:b1*p1 + b2*p2
                           alpha:a1*p1 + a2*p2];
}

#pragma mark - BDPAppearance Color

+ (UIColor *)op_BlackColor1
{
    return BLACK_COLOR(1.f);
}

+ (UIColor *)op_BlackColor2
{
    return BLACK_COLOR(.8f);
}

+ (UIColor *)op_BlackColor3
{
    return BLACK_COLOR(.6f);
}

+ (UIColor *)op_BlackColor4
{
    return BLACK_COLOR(.4f);
}

+ (UIColor *)op_BlackColor5
{
    return BLACK_COLOR(.2f);
}

+ (UIColor *)op_BlackColor6
{
    return BLACK_COLOR(.12f);
}

+ (UIColor *)op_BlackColor7
{
    return BLACK_COLOR(.08f);
}

+ (UIColor *)op_BlackColor8
{
    return BLACK_COLOR(.04f);
}

+ (UIColor *)op_WhiteColor1
{
    return WHITE_COLOR(1.f);
}

+ (UIColor *)op_WhiteColor2
{
    return WHITE_COLOR(.8f);
}

+ (UIColor *)op_WhiteColor3
{
    return WHITE_COLOR(.6f);
}

+ (UIColor *)op_WhiteColor4
{
    return WHITE_COLOR(.4f);
}

+ (UIColor *)op_WhiteColor5
{
    return WHITE_COLOR(.2f);
}

@end
