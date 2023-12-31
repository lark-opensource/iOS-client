//
//  UIFont+ACCAdditions.m
//  CameraClient-Pods-Aweme
//
//  Created by yuanchang on 2020/8/28.
//

#import "UIFont+ACCAdditions.h"
#import <objc/runtime.h>

static BOOL enableUbuntu = NO;

@implementation UIFont (ACCAdditions)

+ (void)acc_setEnableUbuntuFont:(BOOL)_enableUbuntu
{
    enableUbuntu = _enableUbuntu;
}

+ (BOOL)acc_enableUbuntu
{
    return enableUbuntu;
}

+ (UIFont *)acc_boldItalicFontWithSize:(CGFloat)fontSize
{
    UIFont *font = [UIFont acc_systemFontOfSize:fontSize];
    UIFontDescriptor * fontD = [font.fontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold | UIFontDescriptorTraitItalic];
    return [UIFont fontWithDescriptor:fontD size:0];
}

+ (UIFontWeight)_transformFontWeight:(ACCFontWeight)fontWeight
{
    if (@available(iOS 8.2, *)) {
        switch (fontWeight) {
            case ACCFontWeightUltraLight:
                return UIFontWeightUltraLight;
            case ACCFontWeightThin:
                return UIFontWeightThin;
            case ACCFontWeightLight:
                return UIFontWeightLight;
            case ACCFontWeightRegular:
                return UIFontWeightRegular;
            case ACCFontWeightMedium:
                return UIFontWeightMedium;
            case ACCFontWeightSemibold:
                return UIFontWeightSemibold;
            case ACCFontWeightBold:
                return UIFontWeightBold;
            case ACCFontWeightHeavy:
                return UIFontWeightHeavy;
            case ACCFontWeightBlack:
                return UIFontWeightBlack;
            default:
                return 0;
        }
    } else {
        return 0;
    }
}

+ (UIFont *)acc_systemFontOfSize:(CGFloat)fontSize
{
    if ([self acc_enableUbuntu]) {
        CGFloat standardFontSize = [self accui_standardFontSizeForSize:fontSize];
        return [UIFont accui_fontWithName:@"ProximaNova-Regular" size:standardFontSize] ?: [self systemFontOfSize:standardFontSize];
    } else {
        return [UIFont systemFontOfSize:fontSize];
    }
}

+ (UIFont *)acc_systemFontOfSize:(CGFloat)fontSize weight:(ACCFontWeight)weight
{
    if ([self acc_enableUbuntu]) {
        NSString *fontName = @"ProximaNova-Regular";
        CGFloat standardFontSize = [self accui_standardFontSizeForSize:fontSize];
        if (@available(iOS 8.2, *)) {
            if (weight == ACCFontWeightBlack || weight == ACCFontWeightHeavy || weight == ACCFontWeightBold) {
                fontName = @"ProximaNova-Bold";
            } else if (weight == ACCFontWeightMedium || weight == ACCFontWeightSemibold) {
                fontName = @"ProximaNova-Semibold";
            }
            return [UIFont accui_fontWithName:fontName size:standardFontSize] ?: [self systemFontOfSize:standardFontSize weight:[self _transformFontWeight:weight]];
        } else {
            return [UIFont accui_fontWithName:fontName size:standardFontSize] ?: [self systemFontOfSize:standardFontSize];
        }
    } else {
        if (@available(iOS 8.2, *)) {
            return [UIFont systemFontOfSize:fontSize weight:[self _transformFontWeight:weight]];
        } else {
            return [UIFont systemFontOfSize:fontSize];
        }
    }
}

+ (UIFont *)acc_boldSystemFontOfSize:(CGFloat)fontSize
{
    if ([self acc_enableUbuntu]) {
        CGFloat standardFontSize = [self accui_standardFontSizeForSize:fontSize];
        return [UIFont accui_fontWithName:@"ProximaNova-Bold" size:[self accui_standardFontSizeForSize:fontSize]] ?: [self boldSystemFontOfSize:standardFontSize];
    } else {
        return [self boldSystemFontOfSize:fontSize];
    }
}

+ (UIFont *)acc_semiBoldSystemFontOfSize:(CGFloat)fontSize
{
    return [self acc_systemFontOfSize:fontSize weight:ACCFontWeightSemibold];
}

+ (UIFont *)acc_italicSystemFontOfSize:(CGFloat)fontSize
{
    if ([self acc_enableUbuntu]) {
        CGFloat standardFontSize = [self accui_standardFontSizeForSize:fontSize];
        return [UIFont accui_fontWithName:@"ProximaNova-Regular" size:[self accui_standardFontSizeForSize:fontSize]] ?: [self italicSystemFontOfSize:standardFontSize];
    } else {
        return [self italicSystemFontOfSize:fontSize];
    }
}

@end
