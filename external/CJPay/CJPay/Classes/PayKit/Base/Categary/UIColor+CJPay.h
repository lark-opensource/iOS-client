//
//  UIColor+CJPay.h
//  CJPay
//
//  Created by 王新华 on 2/24/20.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor(CJPay)

+ (UIColor *)cj_222222ff;
+ (UIColor *)cj_cacacaff;
+ (UIColor *)cj_999999ff;
+ (UIColor *)cj_d8d8d8ff;
+ (UIColor *)cj_f85959ff;
+ (UIColor *)cj_0000007f;
+ (UIColor *)cj_00000033;
+ (UIColor *)cj_000000ea;
+ (UIColor *)cj_cececeff;
+ (UIColor *)cj_e8e8e87f;
+ (UIColor *)cj_e8e8e8ff;
+ (UIColor *)cj_f4f5f6ff;
+ (UIColor *)cj_e9e9e9ff;
+ (UIColor *)cj_505050ff;
+ (UIColor *)cj_ff4e33ff;
+ (UIColor *)cj_333333ff;
+ (UIColor *)cj_04498dff;
+ (UIColor *)cj_406499ff;
+ (UIColor *)cj_00d35bb2;
+ (UIColor *)cj_00d35bff;
+ (UIColor *)cj_2c2f36ff;
+ (UIColor *)cj_969ba5ff;
+ (UIColor *)cj_ff325aff;
+ (UIColor *)cj_c8cad0ff;
+ (UIColor *)cj_f5f7faff;
+ (UIColor *)cj_4a90e2ff;
+ (UIColor *)cj_17a37eff;
+ (UIColor *)cj_418f82ff;
+ (UIColor *)cj_e1fbf8ff;
+ (UIColor *)cj_e8eaeeff;
+ (UIColor *)cj_fff7eaff;
+ (UIColor *)cj_f39926ff;
+ (UIColor *)cj_4c99f3ff;
+ (UIColor *)cj_ff9f00ff;
+ (UIColor *)cj_f8f8f8ff;
+ (UIColor *)cj_d1d3d8ff;
+ (UIColor *)cj_fe2c55ff;
+ (UIColor *)cj_ff264aff;
+ (UIColor *)cj_404040ff;
+ (UIColor *)cj_2a90d7ff;
+ (UIColor *)cj_00000072;
+ (UIColor *)cj_161823ff;
+ (UIColor *)cj_fe3824ff;
+ (UIColor *)cj_ff6e26ff;
+ (UIColor *)cj_ff938aff;
+ (UIColor *)cj_fe496aff;
+ (UIColor *)cj_eff3f5ff;
+ (UIColor *)cj_17a37eWithAlpha:(CGFloat)alpha;
+ (UIColor *)cj_ff6f28WithAlpha:(CGFloat)alpha;
+ (UIColor *)cj_161823WithAlpha:(CGFloat)alpha;
+ (UIColor *)cj_fe2c55WithAlpha:(CGFloat)alpha;
+ (UIColor *)cj_f5f5f5WithAlpha:(CGFloat)alpha;
+ (UIColor *)cj_fe3824WithAlpha:(CGFloat)alpha;

+ (UIColor *)cj_face15ff;
+ (UIColor *)cj_face15WithAlpha:(CGFloat)alpha;

+ (UIColor *)cj_ff7a38ff;

+ (UIColor *)cj_393b44ff;
+ (UIColor *)cj_393b44WithAlpha:(CGFloat)alpha;

+ (UIColor *)cj_245df1ffWithAlpha:(CGFloat)alpha;
+ (UIColor *)cj_12c6c7ffWithAlpha:(CGFloat)alpha;

+ (UIColor *)cj_fafafaff;

+ (UIColor *)cj_ffffffWithAlpha:(CGFloat)alpha;

+ (UIColor *)cj_divideLineColor;
+ (UIColor *)cj_douyinBlueColor;
+ (UIColor *)cj_skeletonScreenColor;
+ (UIColor *)cj_maskColor;
+ (UIColor *)cj_forgetPWDColor;
+ (UIColor *)cj_forgetPWDSelectColor;

+ (UIColor *)cj_colorWithRed:(CGFloat)red
                    green:(CGFloat)green
                     blue:(CGFloat)blue
                    alpha:(CGFloat)alpha;

+ (UIColor *)cj_colorWithHexString:(NSString *)color;
+ (UIColor *)cj_colorFromHexString:(NSString *)color defaultColor:(UIColor *)defaultColor;
+ (UIColor *)cj_colorWithHexString:(NSString *)color alpha:(CGFloat)alpha;
- (UIColor *)cj_NewColorWith:(UIColor *)color alpha:(CGFloat)alpha;
+ (UIColor *)cj_colorWithHexRGBA:(NSString *)colorRGBA;

@end

NS_ASSUME_NONNULL_END
