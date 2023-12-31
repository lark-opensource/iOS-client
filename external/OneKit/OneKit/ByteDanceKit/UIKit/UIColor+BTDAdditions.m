/**
 * @file UIColor
 * @author David<gaotianpo@songshulin.net>
 *
 * @brief UIColor's category.
 */

#import "UIColor+BTDAdditions.h"

@implementation UIColor (BTDAdditions)

+ (UIColor *)btd_colorWithHexString:(NSString *)hexString {
    NSString *cString = [UIColor _btd_getColorStringFromHexString:hexString];
    
    // The Last 2 characters is the transparency if the length of cString is 8.
    if([cString length] == 8){
        unsigned int alpha;
        [[NSScanner scannerWithString:[cString substringWithRange:NSMakeRange(6, 2)]] scanHexInt:&alpha];
        return [UIColor _btd_colorWithColorString: [cString substringWithRange:NSMakeRange(0, 6)] alpha:((float)alpha / 255.0f)];
    }
    return [UIColor _btd_colorWithColorString:cString alpha:1.0];
}

+ (UIColor *)btd_colorWithHexString:(NSString *)hexString alpha:(CGFloat)alpha {
    NSString *cString = [UIColor _btd_getColorStringFromHexString:hexString];
    return [UIColor _btd_colorWithColorString:cString alpha:alpha];
}

+ (UIColor *)btd_colorWithRGB:(uint32_t)rgbValue {
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0f
                           green:((rgbValue & 0xFF00) >> 8) / 255.0f
                            blue:(rgbValue & 0xFF) / 255.0f
                           alpha:1];
}

+ (UIColor *)btd_colorWithRGB:(uint32_t)rgbValue alpha:(CGFloat)alpha {
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16) / 255.0f
                           green:((rgbValue & 0xFF00) >> 8) / 255.0f
                            blue:(rgbValue & 0xFF) / 255.0f
                           alpha:alpha];
}

+ (UIColor *)btd_colorWithRGBA:(uint32_t)rgbaValue {
    return [UIColor colorWithRed:((rgbaValue & 0xFF000000) >> 24) / 255.0f
                           green:((rgbaValue & 0xFF0000) >> 16) / 255.0f
                            blue:((rgbaValue & 0xFF00) >> 8) / 255.0f
                           alpha:(rgbaValue & 0xFF) / 255.0f];
}

- (NSString *)btd_hexString {
    return [self btd_hexStringWithAlpha:NO];
}

- (NSString *)btd_hexStringWithAlpha {
    return [self btd_hexStringWithAlpha:YES];
}

- (NSString *)btd_hexStringWithAlpha:(BOOL)withAlpha {
    CGColorRef color = self.CGColor;
    size_t count = CGColorGetNumberOfComponents(color);
    const CGFloat *components = CGColorGetComponents(color);
    static NSString *stringFormat = @"%02x%02x%02x";
    NSString *hex = nil;
    if (count == 2) {
        NSUInteger white = (NSUInteger)(components[0] * 255.0f);
        hex = [NSString stringWithFormat:stringFormat, white, white, white];
    } else if (count == 4) {
        hex = [NSString stringWithFormat:stringFormat,
               (NSUInteger)(components[0] * 255.0f),
               (NSUInteger)(components[1] * 255.0f),
               (NSUInteger)(components[2] * 255.0f)];
    }
    
    if (hex && withAlpha) {
        hex = [hex stringByAppendingFormat:@"%02lx",
               (unsigned long)(CGColorGetAlpha(color) * 255.0 + 0.5)];
    }
    return hex;
}

// Removing hexString's prefix(0x, 0X, #) and the white space.
+ (NSString *)_btd_getColorStringFromHexString:(NSString *)hexString{
    if (!hexString || ![hexString isKindOfClass:[NSString class]] || hexString.length == 0) {
        return @"";
    }
    // Removing the white space.删除字符串中的空格
    NSString *cString = [[hexString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] uppercaseString];

    // Removing 0X if it appears in the beginning.
    if ([cString hasPrefix:@"0X"]) {
        cString = [cString substringFromIndex:2];
    }
    
    // Removing # if it appears in the beginning.
    if ([cString hasPrefix:@"#"]) {
        cString = [cString substringFromIndex:1];
    }
    return cString;
}

// Convert the cString to a UIColor.The length of the cString should be 3 or 6.
+ (UIColor *)_btd_colorWithColorString:(NSString *)cString alpha:(CGFloat)alpha {
    
    // String should be 3 or 6 characters
    if ([cString length] != 3 && [cString length] != 6) {
        NSAssert(NO, @"ColorString %@ should be 3 or 6 characters.", cString);
        return [UIColor clearColor];
    }
    
    if([cString length] == 3) {
        /* short color form */
        /* im lazy, maybe you have a better idea to convert from #fff to #ffffff */
        cString = [NSString stringWithFormat:@"%@%@%@%@%@%@",
                   [cString substringWithRange:NSMakeRange(0, 1)],[cString substringWithRange:NSMakeRange(0, 1)],
                   [cString substringWithRange:NSMakeRange(1, 1)],[cString substringWithRange:NSMakeRange(1, 1)],
                   [cString substringWithRange:NSMakeRange(2, 1)],[cString substringWithRange:NSMakeRange(2, 1)]];
    }
    
    // Separate into r, g, b substrings
    NSRange range;
    range.location = 0;
    range.length = 2;
    //r
    NSString *rString = [cString substringWithRange:range];
    //g
    range.location = 2;
    NSString *gString = [cString substringWithRange:range];
    //b
    range.location = 4;
    NSString *bString = [cString substringWithRange:range];
    
    // Scan values
    unsigned int r, g, b;
    [[NSScanner scannerWithString:rString] scanHexInt:&r];
    [[NSScanner scannerWithString:gString] scanHexInt:&g];
    [[NSScanner scannerWithString:bString] scanHexInt:&b];
    return [UIColor colorWithRed:((float)r / 255.0f) green:((float)g / 255.0f) blue:((float)b / 255.0f) alpha:alpha];
}

@end

