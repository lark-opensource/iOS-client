//
//  UIFont+CJPay.h
//  CJPay
//
//  Created by 王新华 on 2/24/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, CJPayFontMode) {
    CJPayFontModeUndefined = 0,
    CJPayFontModeNormal, // 1x
    CJPayFontModeMiddle, // 1.15x
    CJPayFontModeLarge, // 1.3x
    CJPayFontModeUltraLarge // 1.6x not used.
};

@interface UIFont(CJPay)

+ (UIFont *)cj_boldByteNumberFontOfSize:(CGFloat) fontSize;

+ (UIFont *)cj_fontOfSize:(CGFloat) fontSize;

+ (UIFont *)cj_fontWithoutFontScaleOfSize:(CGFloat) fontSize;

+ (UIFont *)cj_boldFontOfSize:(CGFloat) fontSize;

+ (UIFont *)cj_boldFontWithoutFontScaleOfSize:(CGFloat)fontSize;

+ (UIFont *)cj_denoiseBoldFontOfSize:(CGFloat)fontSize;

+ (UIFont *)cj_denoiseBoldFontWithoutFontScaleOfSize:(CGFloat)fontSize;

+ (UIFont *)cj_semiboldFontOfSize:(CGFloat) fontSize;

// 数字字体等宽 00:00跟11:11等宽
+ (UIFont *)cj_monospacedDigitSystemFontOfSize:(CGFloat)fontSize;

+ (CGFloat)cjpayFontScale;

+ (void)setCjpayFontScale:(CGFloat)fontScale;

+ (CJPayFontMode)cjpayFontMode;

+ (NSString * _Nonnull)cjpayPercentFontScale;

@end

NS_ASSUME_NONNULL_END
