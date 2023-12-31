/**
 * @file UIColor
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief UIColor的扩展
 */

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#ifndef UIColorWithRGB
#define UIColorWithRGB(r, g, b) [UIColor colorWithRed:(r)/255.f green:(g)/255.f blue:(b)/255.f alpha:1.f]
#endif

#ifndef UIColorWithRGBA
#define UIColorWithRGBA(r, g, b, a) [UIColor colorWithRed:(r)/255.f green:(g)/255.f blue:(b)/255.f alpha:(a) * 1.f]
#endif

#ifndef UIColorWithHexRGB
#define UIColorWithHexRGB(rgbValue) [UIColor btd_colorWithRGB:rgbValue]
#endif

#ifndef UIColorWithHexRGBA
#define UIColorWithHexRGBA(rgbaValue) [UIColor btd_colorWithRGBA:rgbValue]
#endif

#ifndef UIColorWithHexARGB
#define UIColorWithHexARGB(argbValue) [UIColor btd_colorWithARGB:argbValue]
#endif

#ifndef UIColorWithHexString
#define UIColorWithHexString(hexString) [UIColor btd_colorWithHexString:hexString]
#endif

@interface UIColor (BTDAdditions)
/**
 由一个以＃开头的16进至的色彩字串产生一个UIColor类实例，静态方法

 @param hexString 一个以#开头的16进制的字符串
 @return 返回 UIColor 对象
 */
+ (UIColor *)btd_colorWithHexString:(NSString *)hexString;

+ (UIColor *)btd_colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

/// 用RGB hex格式构建color
/// @param rgbValue RGB格式 例如0x0066cc
+ (UIColor *)btd_colorWithRGB:(uint32_t)rgbValue;

/// 用RGB hex格式和alpha构建color
/// @param rgbValue RGB格式 例如0x0066cc
/// @param alpha 透明度 0-1
+ (UIColor *)btd_colorWithRGB:(uint32_t)rgbValue alpha:(CGFloat)alpha;

/// 用RGBA hex格式构建color
/// @param rgbaValue RGBA格式 例如0x0066ccff
+ (UIColor *)btd_colorWithRGBA:(uint32_t)rgbaValue;


/// Initialize a UIColor with the RGBA hex value.
/// @param argbValue  A ARGB hex value. For example, 0xff0066cc.
+ (UIColor *)btd_colorWithARGB:(uint32_t)argbValue;

/// @param hexString A hexadecimal string beginning with '#','0x' or '0X'. The length of the string after removing the prefix is 3,6 or 8. If the length of hexString is 8, the first two characters represent transparency, otherwise transparency defaults to 1.0.
/// @return A UIColor.
+ (UIColor *)btd_colorWithARGBHexString:(NSString *)hexString;

/// Return the RGB hex string of the color. For example, 0x0066cc. Return nil if the color is not in RGB color space.
- (nullable NSString *)btd_hexString;

/// 返回RGBA色值的hex格式 例如0066ccff; 如果颜色空间非RGB则返回nil
- (nullable NSString *)btd_hexStringWithAlpha;


@end

NS_ASSUME_NONNULL_END
