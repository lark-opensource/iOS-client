//
//  UIFont+BDPExtension.h
//  Timor
//
//  Created by 王浩宇 on 2018/12/5.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIFont (BDPExtension)

+ (UIFont *)fontWithFamilyName:(NSString *)familyName weight:(UIFontWeight)fontWeight size:(CGFloat)fontSize;
+ (UIFont *)bdp_pingFongSCWithWeight:(UIFontWeight)fontWeight size:(CGFloat)fontSize;
+ (instancetype)bdp_fontWithName:(NSString *)name size:(CGFloat)size;
+ (UIFontWeight)fontWeightWithStr:(NSString * _Nullable)str;

@end

NS_ASSUME_NONNULL_END
