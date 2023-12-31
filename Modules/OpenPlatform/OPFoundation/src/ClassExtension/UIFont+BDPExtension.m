//
//  UIFont+BDPExtension.m
//  Timor
//
//  Created by 王浩宇 on 2018/12/5.
//

#import "UIFont+BDPExtension.h"
#import <ByteDanceKit/BTDMacros.h>

static NSString *const kSystemFontName = @"sans-serif";

@implementation UIFont (BDPExtension)

+ (UIFont *)fontWithFamilyName:(NSString *)familyName weight:(UIFontWeight)fontWeight size:(CGFloat)fontSize
{
    NSArray *fontNames = [UIFont fontNamesForFamilyName:familyName];
    NSString *fontWeightType = [self fontWeightType:fontWeight];
    NSString *fontWeightTypeDefault = @"Regular";
    
    UIFont *font, *fontDefault;
    for (NSString *fontName in fontNames) {
        if ([fontName rangeOfString:fontWeightTypeDefault options:NSCaseInsensitiveSearch].location != NSNotFound) {
            fontDefault = [UIFont fontWithName:fontName size:fontSize];
        }
        if ([fontName rangeOfString:fontWeightType options:NSCaseInsensitiveSearch].location != NSNotFound) {
            font = [UIFont fontWithName:fontName size:fontSize];
            return font;
        }
    }
    return fontDefault;
}

+ (UIFont *)bdp_pingFongSCWithWeight:(UIFontWeight)fontWeight size:(CGFloat)fontSize
{
    NSString *fontNameStr = @"PingFangSC";
    NSString *fontWeightStr = [self fontWeightType:fontWeight];
    NSString *fontName = [NSString stringWithFormat:@"%@-%@", fontNameStr, fontWeightStr];
    UIFont *font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
//    if (!font) {
//        font = [UIFont systemFontOfSize:fontSize weight:fontWeight];
//    }
    
    return font;
}

+ (NSString *)fontWeightType:(UIFontWeight)fontWeight
{
    NSString *weightType = @"Regular";
    if (fontWeight == UIFontWeightUltraLight) {
        weightType = @"UltraLight";
    } else if (fontWeight == UIFontWeightThin) {
        weightType = @"Thin";
    } else if (fontWeight == UIFontWeightLight) {
        weightType = @"Light";
    } else if (fontWeight == UIFontWeightRegular) {
        weightType = @"Regular";
    } else if (fontWeight == UIFontWeightMedium) {
        weightType = @"Medium";
    } else if (fontWeight == UIFontWeightSemibold) {
        weightType = @"Semibold";
    } else if (fontWeight == UIFontWeightBold) {
        weightType = @"Bold";
    } else if (fontWeight == UIFontWeightHeavy) {
        weightType = @"Heavy";
    } else if (fontWeight == UIFontWeightBlack) {
        weightType = @"Black";
    }
    return weightType;
}

+ (UIFontWeight)fontWeightWithStr:(NSString * _Nullable)str
{
    UIFontWeight fontWeight = UIFontWeightRegular;
    if (BTD_isEmptyString(str)) {
        return fontWeight;
    }
    NSString *input = [str lowercaseString];
    if ([input isEqualToString:@"regular"]) {
        // use regular
    } else if ([input isEqualToString:@"normal"]) { // css的normal和iOS的regular对齐
        // use regular
    } else if ([input isEqualToString:@"medium"]) {
        fontWeight = UIFontWeightMedium;
    } else if ([input isEqualToString:@"bold"]) {
        fontWeight = UIFontWeightBold;
    } else if ([input isEqualToString:@"thin"]) {
        fontWeight = UIFontWeightThin;
    } else if ([input isEqualToString:@"light"]) {
        fontWeight = UIFontWeightLight;
    } else if ([input isEqualToString:@"lighter"]) { // css的lighter和iOS的light对齐
        fontWeight = UIFontWeightLight;
    } else if ([input isEqualToString:@"ultralight"]) {
        fontWeight = UIFontWeightUltraLight;
    } else if ([input isEqualToString:@"semibold"]) {
        fontWeight = UIFontWeightSemibold;
    } else if ([input isEqualToString:@"heavy"]) {
        fontWeight = UIFontWeightHeavy;
    } else if ([input isEqualToString:@"bolder"]) { // css的bolder和iOS的heavy对齐
        fontWeight = UIFontWeightHeavy;
    } else if ([input isEqualToString:@"black"]) {
        fontWeight = UIFontWeightBlack;
    }
    return fontWeight;
}

+ (instancetype)bdp_fontWithName:(NSString *)name size:(CGFloat)size
{
    UIFont *font = nil;
    if ([name.uppercaseString isEqualToString:kSystemFontName.uppercaseString]) {
        font = [UIFont systemFontOfSize:size];
    }
    
    font = [UIFont fontWithName:name size:size];
    
    return font;
}

@end
