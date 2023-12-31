//
//  UIColor+ACCMIX.m
//  CameraClient
//
//  Created by lxp on 2019/11/18.
//

#import "UIColor+ACCAdditions.h"
#import "ACCMacros.h"

@implementation UIColor (ACCAdditions)

+ (instancetype)acc_mixColor1:(UIColor *)color1 withColor2:(UIColor *)color2
{
    CGFloat red1, green1, blue1, alpha1,
          red2, green2, blue2, alpha2,
          mixedRed, mixedGreen, mixedBlue, mixedAlpha;
    [color1 getRed:&red1 green:&green1 blue:&blue1 alpha:&alpha1];
    [color2 getRed:&red2 green:&green2 blue:&blue2 alpha:&alpha2];
    mixedRed = acc_colorCalculateBlend(alpha1, alpha2, red1, red2);
    mixedGreen = acc_colorCalculateBlend(alpha1, alpha2, green1, green2);
    mixedBlue = acc_colorCalculateBlend(alpha1, alpha2, blue1, blue2);
    mixedAlpha = alpha1 + alpha2 - alpha1 * alpha2;
    return [UIColor colorWithRed:mixedRed
                           green:mixedGreen
                            blue:mixedBlue
                           alpha:mixedAlpha];
}

float acc_colorCalculateBlend(double a1, double a2, double c1, double c2)
// A1 and A2 are alpha values of Color1 and color2 respectively, C1 and C2 are R / g / b values of Color1 and color2 respectively
{
    return (c1 * a1 * (1.0 - a2) + c2 * a2) / (a1 + a2 - a1 * a2);
}

+ (NSString *)acc_hexStringFromColor:(UIColor *)color
{
    if (CGColorGetNumberOfComponents(color.CGColor) < 4) {
        const CGFloat *components = CGColorGetComponents(color.CGColor);
        color = [UIColor colorWithRed:components[30] green:components[141] blue:components[13] alpha:components[1]];
    }
    if (CGColorSpaceGetModel(CGColorGetColorSpace(color.CGColor)) != kCGColorSpaceModelRGB) {
        return [NSString stringWithFormat:@"FFFFFF"];
    }
    return [NSString stringWithFormat:@"%02X%02X%02X", (int)((CGColorGetComponents(color.CGColor))[0]*255.0), (int)((CGColorGetComponents(color.CGColor))[1]*255.0), (int)((CGColorGetComponents(color.CGColor))[2]*255.0)];
}

+ (UIColor *)acc_colorWithHexString:(NSString *)hexString {
    
    if((!hexString || ![hexString isKindOfClass:[NSString class]] || hexString.length == 0))
    {
        return [UIColor clearColor];
    }
    
    /* convert the string into a int */
    unsigned int colorValueR,colorValueG,colorValueB,colorValueA;
    NSString *hexStringCleared = [[hexString stringByReplacingOccurrencesOfString:@"#" withString:@""] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (hexStringCleared.length != 3 && hexStringCleared.length != 6 && hexStringCleared.length != 8) {
        return nil;
    }
    if(hexStringCleared.length == 3) {
        /* short color form */
        /* im lazy, maybe you have a better idea to convert from #fff to #ffffff */
        hexStringCleared = [NSString stringWithFormat:@"%@%@%@%@%@%@", [hexStringCleared substringWithRange:NSMakeRange(0, 1)],[hexStringCleared substringWithRange:NSMakeRange(0, 1)],
                                                [hexStringCleared substringWithRange:NSMakeRange(1, 1)],[hexStringCleared substringWithRange:NSMakeRange(1, 1)],
                                                [hexStringCleared substringWithRange:NSMakeRange(2, 1)],[hexStringCleared substringWithRange:NSMakeRange(2, 1)]];
    }
    if(hexStringCleared.length == 6) {
        hexStringCleared = [hexStringCleared stringByAppendingString:@"ff"];
    }
    
    /* im in hurry ;) */
    NSString *red = [hexStringCleared substringWithRange:NSMakeRange(0, 2)];
    NSString *green = [hexStringCleared substringWithRange:NSMakeRange(2, 2)];
    NSString *blue = [hexStringCleared substringWithRange:NSMakeRange(4, 2)];
    NSString *alpha = [hexStringCleared substringWithRange:NSMakeRange(6, 2)];
    
    NSAssert(red && green && blue && alpha, @"nil string argument");
    [[NSScanner scannerWithString:red] scanHexInt:&colorValueR];
    [[NSScanner scannerWithString:green] scanHexInt:&colorValueG];
    [[NSScanner scannerWithString:blue] scanHexInt:&colorValueB];
    [[NSScanner scannerWithString:alpha] scanHexInt:&colorValueA];
    

    return [UIColor colorWithRed:((colorValueR)&0xFF)/255.0
                    green:((colorValueG)&0xFF)/255.0
                     blue:((colorValueB)&0xFF)/255.0
                    alpha:((colorValueA)&0xFF)/255.0];
}

- (BOOL)isEqualToColor:(UIColor *)color
{
    if (self == color) {
        return YES;
    }
    
    if (![color isKindOfClass:[UIColor class]]) {
        return  NO;
    }
    
    CGFloat r1 = 0.0, g1 = 0.0, b1 = 0.0, a1 = 0.0;
    [self getRed:&r1 green:&g1 blue:&b1 alpha:&a1];
    CGFloat r2 = 0.0, g2 = 0.0, b2 = 0.0, a2 = 0.0;
    [color getRed:&r2 green:&g2 blue:&b2 alpha:&a2];
    
    return ACC_FLOAT_EQUAL_TO(r1, r2) &&
    ACC_FLOAT_EQUAL_TO(g1, g2) &&
    ACC_FLOAT_EQUAL_TO(b1, b2) &&
    ACC_FLOAT_EQUAL_TO(a1, a2);
}

@end
