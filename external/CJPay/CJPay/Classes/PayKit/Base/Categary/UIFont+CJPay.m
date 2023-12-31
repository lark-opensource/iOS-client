//
//  UIFont+CJPay.m
//  CJPay
//
//  Created by 王新华 on 2/24/20.
//

#import "UIFont+CJPay.h"
#import "NSBundle+CJPay.h"
#import "CJPaySDKMacro.h"
#import "UIFont+CJPay.h"
#import <CoreText/CTFontManager.h>
#import <objc/runtime.h>
#import "CJPaySettingsManager.h"

static NSString *cjpayFontScaleNameKey = @"cjpayFontScaleNameKey";

@implementation UIFont(CJPay)

+ (UIFont *)cj_boldByteNumberFontOfSize:(CGFloat) fontSize {
    CGFloat fontSizeWithScale = fontSize * [UIFont cjpayFontScale];
    UIFont *font = [UIFont fontWithName:@"ByteNumber-Bold" size:fontSizeWithScale];
    if (font == nil) {
        [[self class] cj_dynamicallyLoadFontNamed:@"ByteNumber-Bold.ttf"];
        font = [UIFont fontWithName:@"ByteNumber-Bold" size:fontSizeWithScale];
    }
    if (font == nil) {
        font = [UIFont boldSystemFontOfSize:fontSizeWithScale];
    }
    return font;
}

+ (void)cj_dynamicallyLoadFontNamed:(NSString *)fontTypeStr
{
    NSBundle *bd = [NSBundle cj_customPayBundle];
    NSData *data = [NSData dataWithContentsOfURL:[NSURL fileURLWithPath:[NSString stringWithFormat:@"%@/%@",bd.bundlePath,fontTypeStr]]];
    if (!data) return;
    CFErrorRef err;
    CGDataProviderRef dataPro = CGDataProviderCreateWithCFData((CFDataRef)data);
    CGFontRef ft = CGFontCreateWithDataProvider(dataPro);
    if (!CTFontManagerRegisterGraphicsFont(ft, &err)) {
        CFStringRef err_ = CFErrorCopyDescription(err);
        CJPayLogInfo(@"Cannot load the font: %@", err_);
        CFRelease(err_);
    }
    CFRelease(ft);
    CFRelease(dataPro);
}

+ (UIFont *)cj_fontOfSize:(CGFloat) fontSize {
    CGFloat scaleFontSize = fontSize * [self cjpayFontScale];
    
    UIFont *font = [UIFont fontWithName:@"PingFangSC-Regular" size:scaleFontSize];
    if (font == nil) {
        font = [UIFont systemFontOfSize:scaleFontSize];
    }
    return font;
}

+ (UIFont *)cj_fontWithoutFontScaleOfSize:(CGFloat) fontSize {
    
    UIFont *font = [UIFont fontWithName:@"PingFangSC-Regular" size:fontSize];
    if (font == nil) {
        font = [UIFont systemFontOfSize:fontSize];
    }
    return font;
}

+ (UIFont *)cj_boldFontOfSize:(CGFloat) fontSize {
    CGFloat scaleFontSize = fontSize * [self cjpayFontScale];
    
    UIFont *font = [UIFont fontWithName:@"PingFangSC-Medium" size:scaleFontSize];
    if (font == nil) {
        font = [UIFont boldSystemFontOfSize:scaleFontSize];
    }
    return font;
}

+ (UIFont *)cj_boldFontWithoutFontScaleOfSize:(CGFloat)fontSize {
    
    UIFont *font = [UIFont fontWithName:@"PingFangSC-Medium" size:fontSize];
    if (font == nil) {
        font = [UIFont boldSystemFontOfSize:fontSize];
    }
    return font;
}

+ (UIFont *)cj_denoiseBoldFontOfSize:(CGFloat)fontSize {
    CGFloat fontSizeWithScale = fontSize * [UIFont cjpayFontScale];
    return [self cj_getFontForUse:fontSizeWithScale];
}

+ (UIFont *)cj_denoiseBoldFontWithoutFontScaleOfSize:(CGFloat)fontSize {
    return [self cj_getFontForUse:fontSize];
}

+ (UIFont *)cj_monospacedDigitSystemFontOfSize:(CGFloat)fontSize {
    CGFloat fontSizeWithScale = fontSize * [UIFont cjpayFontScale];
    return [UIFont monospacedDigitSystemFontOfSize:fontSizeWithScale weight:UIFontWeightRegular];
}

+ (UIFont *)cj_getFontForUse:(CGFloat)fontSize {
    UIFont *font = [UIFont fontWithName:@"DINPro-Medium" size:fontSize];
    if (font == nil) {
        [[self class] cj_dynamicallyLoadFontNamed:@"DINPro-Medium.ttf"];
        font = [UIFont fontWithName:@"DINPro-Medium" size:fontSize];
    }
    
    if (font == nil) {
        font = [UIFont fontWithName:@"PingFangSC-Medium" size:fontSize];
    }
    
    if (font == nil) {
        font = [UIFont boldSystemFontOfSize:fontSize];
    }
    return font;
}

//PingFangSC-Semibold

+ (UIFont *)cj_semiboldFontOfSize:(CGFloat) fontSize {
    CGFloat scaleFontSize = fontSize * [self cjpayFontScale];
    
    UIFont *font = [UIFont fontWithName:@"PingFangSC-Semibold" size:scaleFontSize];
    if (font == nil) {
        font = [UIFont boldSystemFontOfSize:scaleFontSize];
    }
    return font;
}

+ (void)setCjpayFontScale:(CGFloat)fontScale {
    NSNumber *fontScaleNumber = [NSNumber numberWithFloat:fontScale];
    objc_setAssociatedObject(self, &cjpayFontScaleNameKey, fontScaleNumber, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

+ (CGFloat)cjpayFontScale {
    NSNumber *fontScaleNumber = objc_getAssociatedObject(self, &cjpayFontScaleNameKey) ?: @(1.0);
    return [fontScaleNumber floatValue];
}

+ (CJPayFontMode)cjpayFontMode {
    CJPayFontMode mode = CJPayFontModeUndefined;
    CGFloat fontScale = [self cjpayFontScale];
    CGFloat cjpayMinError = 1e-6;
    
    if (fabs(fontScale - 1.0) < cjpayMinError) {
        mode = CJPayFontModeNormal;
    } else if (fabs(fontScale - 1.15) < cjpayMinError) {
        mode = CJPayFontModeMiddle;
    } else if (fabs(fontScale - 1.3) < cjpayMinError) {
        mode = CJPayFontModeLarge;
    }
    
    return mode;
}

+ (NSString * _Nonnull)cjpayPercentFontScale {
    switch ([self cjpayFontMode]) {
        case CJPayFontModeNormal:
            return @"100";
        case CJPayFontModeMiddle:
            return @"115";
        case CJPayFontModeLarge:
            return @"130";
        default:
            return @"100";
    }
}

@end
