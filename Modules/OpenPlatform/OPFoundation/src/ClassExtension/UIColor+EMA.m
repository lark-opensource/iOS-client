//
//  UIColor+EMA.m
//  EEMicroAppSDK
//
//  Created by yinyuan on 2019/1/4.
//

#import "UIColor+EMA.h"


@implementation UIColor (EMA)

+ (nonnull UIColor *(^)(Byte red, Byte green, Byte blue))ema_rgb {
    return ^UIColor *(Byte red, Byte green, Byte blue) {
        return self.ema_rgba(red, green, blue, 1);
    };
}

+ (nonnull UIColor *(^)(Byte red, Byte green, Byte blue, Byte alpha))ema_rgba {
    return ^UIColor *(Byte red, Byte green, Byte blue, Byte alpha) {
        return [UIColor colorWithRed:red/255.0 green:green/255.0 blue:blue/255.0 alpha:alpha/255.0];
    };
}

+ (nonnull UIColor *(^)(Byte alpha, Byte red, Byte green, Byte blue))ema_argb {
    return ^UIColor *(Byte alpha, Byte red, Byte green, Byte blue) {
        return self.ema_rgba(red, green, blue, alpha);
    };
}

- (CGFloat)ema_alpha {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return alpha;
}

- (CGFloat)ema_red {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return red;
}

- (CGFloat)ema_green {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return green;
}

- (CGFloat)ema_blue {
    CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
    [self getRed:&red green:&green blue:&blue alpha:&alpha];
    return blue;
}


+ (nonnull UIColor *)ema_grey0 {
    return [self colorWithHexString:@"#FFFFFF"];
}

+ (nonnull UIColor *)ema_grey1 {
    return [self colorWithHexString:@"#FAFAFC"];
}

+ (nonnull UIColor *)ema_grey2 {
    return [self colorWithHexString:@"#F4F5F9"];
}

+ (nonnull UIColor *)ema_grey3 {
    return [self colorWithHexString:@"#E9EAF2"];
}

+ (nonnull UIColor *)ema_grey4 {
    return [self colorWithHexString:@"#D7DAE0"];
}

+ (nonnull UIColor *)ema_grey5 {
    return [self colorWithHexString:@"#B7BEC7"];
}

+ (nonnull UIColor *)ema_grey6 {
    return [self colorWithHexString:@"#8691A3"];
}

+ (nonnull UIColor *)ema_grey7 {
    return [self colorWithHexString:@"#69758A"];
}

+ (nonnull UIColor *)ema_grey8 {
    return [self colorWithHexString:@"#3F4F66"];
}

+ (nonnull UIColor *)ema_grey9 {
    return [self colorWithHexString:@"#27374D"];
}

+ (nonnull UIColor *)ema_grey10 {
    return [self colorWithHexString:@"#18263C"];
}

+ (nonnull UIColor *)ema_grey11 {
    return [self colorWithHexString:@"#DEE0E3"];
}

+ (nonnull UIColor *)ema_grey12 {
    return [self colorWithHexString:@"#8F959E"];
}

+ (nonnull UIColor *)ema_blue4 {
    return [self colorWithHexString:@"#3388FF"];
}

+ (nonnull UIColor *)ema_blue5 {
    return [self colorWithHexString:@"#006AFF"];
}

+ (nonnull UIColor *)ema_aqua4 {
    return [self colorWithHexString:@"#33CBFF"];
}

+ (nonnull UIColor *)ema_aqua5 {
    return [self colorWithHexString:@"#00BEFF"];
}

+ (nonnull UIColor *)ema_teal4 {
    return [self colorWithHexString:@"#04E0C3"];
}

+ (nonnull UIColor *)ema_teal5 {
    return [self colorWithHexString:@"#00D0B6"];
}

+ (nonnull UIColor *)ema_green4 {
    return [self colorWithHexString:@"#7CE868"];
}

+ (nonnull UIColor *)ema_green5 {
    return [self colorWithHexString:@"#66DC50"];
}

+ (nonnull UIColor *)ema_lime4 {
    return [self colorWithHexString:@"#E4EB2F"];
}

+ (nonnull UIColor *)ema_lime5 {
    return [self colorWithHexString:@"#D9E000"];
}

+ (nonnull UIColor *)ema_yellow4 {
    return [self colorWithHexString:@"#FFCD05"];
}

+ (nonnull UIColor *)ema_yellow5 {
    return [self colorWithHexString:@"#FFC400"];
}

+ (nonnull UIColor *)ema_orange4 {
    return [self colorWithHexString:@"#FF9733"];
}

+ (nonnull UIColor *)ema_orange5 {
    return [self colorWithHexString:@"#FF7D00"];
}

+ (nonnull UIColor *)ema_red4 {
    return [self colorWithHexString:@"#FF6661"];
}

+ (nonnull UIColor *)ema_red5 {
    return [self colorWithHexString:@"#FF3C36"];
}

+ (nonnull UIColor *)ema_red6 {
    return [self colorWithHexString:@"#FF5B4C"];
}

+ (nonnull UIColor *)ema_magenta4 {
    return [self colorWithHexString:@"#FF66A8"];
}

+ (nonnull UIColor *)ema_magenta5 {
    return [self colorWithHexString:@"#FF328C"];
}

+ (nonnull UIColor *)ema_purple4 {
    return [self colorWithHexString:@"#9B64ED"];
}

+ (nonnull UIColor *)ema_purple5 {
    return [self colorWithHexString:@"#8240E6"];
}

+ (nonnull UIColor *)ema_black0 {
    return [self colorWithHexString:@"#1F2329"];
}

@end
