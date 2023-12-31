/**
 * @file UIColor
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief UIColor's category.
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
#define UIColorWithHexRGBA(rgbaValue) [UIColor btd_colorWithRGBA:rgbaValue]
#endif

#ifndef UIColorWithHexString
#define UIColorWithHexString(hexString) [UIColor btd_colorWithHexString:hexString]
#endif

@interface UIColor (BTDAdditions)
/**
 Convert a hexadecimal string beginning with '#','0x' or '0X' to A UIColor instance.
 */

/// @param hexString A hexadecimal string beginning with '#','0x' or '0X'. The length of the string after removing the prefix is 3,6 or 8. For example, 0xFFF, #123456, 0X12345678.
/// @return A UIColor.
+ (UIColor *)btd_colorWithHexString:(NSString *)hexString;

/// @param hexString A hexadecimal string beginning with '#','0x' or '0X'. The length of the string after removing the prefix is 3,6 or 8. For example, 0xFFF, #123456, 0X12345678.
/// @param alpha The transparency. The value of the alpha is from 0 to 1.
/// @return A UIColor.
+ (UIColor *)btd_colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha;

/// Initialize a UIColor with the RGB hex value.
/// @param rgbValue A RGB hex value. For example, 0x0066cc.
+ (UIColor *)btd_colorWithRGB:(uint32_t)rgbValue;

/// Initialize a UIColor with the RGB hex value and alpha.
/// @param rgbValue A RGB hex value. For example, 0x0066cc.
/// @param alpha The transparency. The value of the alpha is from 0 to 1.
+ (UIColor *)btd_colorWithRGB:(uint32_t)rgbValue alpha:(CGFloat)alpha;

/// Initialize a UIColor with the RGBA hex value.
/// @param rgbaValue  A RGBA hex value. For example, 0x0066ccff.
+ (UIColor *)btd_colorWithRGBA:(uint32_t)rgbaValue;

/// Return the RGB hex string of the color. For example, 0x0066cc. Return nil if the color is not in RGB color space.
- (nullable NSString *)btd_hexString;

/// Return the RGBA hex string of the color. For example, 0x0066ccff. Return nil if the color is not in RGBA color space.
- (nullable NSString *)btd_hexStringWithAlpha;


@end

NS_ASSUME_NONNULL_END
