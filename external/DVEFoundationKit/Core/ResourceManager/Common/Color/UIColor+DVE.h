//
//  UIColor+DVE.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/11/19.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIColor (DVE)

+ (UIColor *)dve_colorWithARGBInt:(uint32_t)colorValue;

+ (UIColor *)dve_colorWithHex:(NSString *)hexString;

+ (UIColor *)dve_colorWithHex:(NSString *)hexString alpha:(CGFloat)alpha;

+ (UIColor *)dve_colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue;

+ (UIColor *)dve_colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;

@end

NS_ASSUME_NONNULL_END
