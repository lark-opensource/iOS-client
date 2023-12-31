//
//  UIColor+TuringHex.m
//  BDTuring
//
//  Created by bob on 2019/8/28.
//

#import "UIColor+TuringHex.h"

@implementation UIColor (TuringHex)

+ (instancetype)turing_colorWithRGBString:(NSString *)hex alpha:(CGFloat)alpha {
    const char *hexChar = [hex cStringUsingEncoding:NSUTF8StringEncoding];
    UInt32 rgbHex;
    sscanf(hexChar, "%x", &rgbHex);
    
    return [self turing_colorWithRGB:rgbHex alpha:alpha];
}

+ (instancetype)turing_colorWithRGB:(UInt32)hex alpha:(CGFloat)alpha {
    CGFloat r = ((hex & 0xFF0000) >> 16) /255.0;
    CGFloat g = ((hex & 0x00FF00) >> 8) /255.0;
    CGFloat b = ((hex & 0x0000FF) >> 0) /255.0;
    return [UIColor colorWithRed:r green:g blue:b alpha:alpha];
}

@end
