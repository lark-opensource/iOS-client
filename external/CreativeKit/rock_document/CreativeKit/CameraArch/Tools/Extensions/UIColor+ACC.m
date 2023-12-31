//
//  UIColor+ACC.m
//  CameraClient
//
//  Created by luochaojing on 2019/12/23.
//

#import "UIColor+ACC.h"

@implementation UIColor (ACC)

+ (UIColor *)acc_colorWithHex:(NSString *)hexString {
    return [self acc_colorWithHex:hexString alpha:1.0];
}

+ (UIColor *)acc_colorWithHex:(NSString *)hexString alpha:(CGFloat)alpha {
    CGFloat red = 0.0;
    CGFloat green = 0.0;
    CGFloat blue = 0.0;
    CGFloat mAlpha = alpha;
    NSInteger minusLength = 0;
    NSScanner *scanner = [NSScanner scannerWithString:hexString];
    
    if ([hexString hasPrefix:@"#"]) {
        scanner.scanLocation = 1;
        minusLength = 1;
    }
    if ([hexString hasPrefix:@"0x"]) {
        scanner.scanLocation = 2;
        minusLength = 2;
    }
    unsigned int hexValue = 0;
    [scanner scanHexInt:&hexValue];
    switch (hexString.length - minusLength) {
        case 3:
            mAlpha = 1.0;
            red = ((hexValue & 0xF00) >> 8) / 15.0;
            green = ((hexValue & 0x0F0) >> 4) / 15.0;
            blue = (hexValue & 0x00F) / 15.0;
            break;
        case 4:
            red = ((hexValue & 0xF000) >> 12) / 15.0;
            green = ((hexValue & 0x0F00) >> 8) / 15.0;
            blue = ((hexValue & 0x00F0) >> 4) / 15.0;
            mAlpha = (hexValue & 0x00F) / 15.0;
            break;
        case 6:
            red = ((hexValue & 0xFF0000) >> 16) / 255.0;
            green = ((hexValue & 0x00FF00) >> 8) / 255.0;
            blue = (hexValue & 0x0000FF) / 255.0;
            break;
        case 8:
            red = ((hexValue & 0xFF000000) >> 24) / 255.0;
            green = ((hexValue & 0x00FF0000) >> 16) / 255.0;
            blue = ((hexValue & 0x0000FF00) >> 8) / 255.0;
            mAlpha = (hexValue & 0x000000FF) / 255.0;
            break;
        default:
            break;
    }
    return [UIColor colorWithRed:red green:green blue:blue alpha:mAlpha];
}

@end
