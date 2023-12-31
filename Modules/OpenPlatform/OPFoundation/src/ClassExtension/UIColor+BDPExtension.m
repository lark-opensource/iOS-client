//
//  UIColor+BDPExtension.m
//  Timor
//
//  Created by muhuai on 2018/1/22.
//  Copyright © 2018年 muhuai. All rights reserved.
//

#import "UIColor+BDPExtension.h"
#import "UIColor+OPExtension.h"
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Weverything"
//some method have been implemeneted in OPFoundation/UIColor+OPExtension.m
//so let's supress the compile error or warnings here
@implementation UIColor (BDPExtension)

#pragma mark - BDPAppearance Color

+ (UIColor *)bdp_BlackColor1
{
    return [UIColor op_BlackColor1];
}

+ (UIColor *)bdp_BlackColor2
{
    return [UIColor op_BlackColor2];
}

+ (UIColor *)bdp_BlackColor3
{
    return [UIColor op_BlackColor3];
}

+ (UIColor *)bdp_BlackColor4
{
    return [UIColor op_BlackColor4];
}

+ (UIColor *)bdp_BlackColor5
{
    return [UIColor op_BlackColor5];
}

+ (UIColor *)bdp_BlackColor6
{
    return [UIColor op_BlackColor6];
}

+ (UIColor *)bdp_BlackColor7
{
    return [UIColor op_BlackColor7];
}

+ (UIColor *)bdp_BlackColor8
{
    return [UIColor op_BlackColor8];
}

+ (nonnull UIColor *)bdp_blackN900 {
    return [self colorWithHexString:@"#1F2329"];
}

+ (UIColor *)bdp_WhiteColor1
{
    return [UIColor op_WhiteColor1];
}

+ (UIColor *)bdp_WhiteColor2
{
    return [UIColor op_WhiteColor2];
}

+ (UIColor *)bdp_WhiteColor3
{
    return [UIColor op_WhiteColor3];
}

+ (UIColor *)bdp_WhiteColor4
{
    return [UIColor op_WhiteColor4];
}

+ (UIColor *)bdp_WhiteColor5
{
    return [UIColor op_WhiteColor5];
}

+ (UIColor *)bdp_negativeColor:(BDPNegativeColor)negativeColor
{
    UIColor *color = [UIColor bdp_BlackColor1];
    switch (negativeColor) {
        case BDPNegativeColorBlack1:
            color = [UIColor bdp_BlackColor1];
            break;
        case BDPNegativeColorBlack2:
            color = [UIColor bdp_BlackColor2];
            break;
        case BDPNegativeColorBlack3:
            color = [UIColor bdp_BlackColor3];
            break;
        case BDPNegativeColorBlack4:
            color = [UIColor bdp_BlackColor4];
            break;
        case BDPNegativeColorBlack5:
            color = [UIColor bdp_BlackColor5];
            break;
        case BDPNegativeColorBlack6:
            color = [UIColor bdp_BlackColor6];
            break;
        case BDPNegativeColorBlack7:
            color = [UIColor bdp_BlackColor7];
            break;
        case BDPNegativeColorBlack8:
            color = [UIColor bdp_BlackColor8];
            break;
        case BDPNegativeColorWhite1:
            color = [UIColor bdp_WhiteColor1];
            break;
        case BDPNegativeColorWhite2:
            color = [UIColor bdp_WhiteColor2];
            break;
        case BDPNegativeColorWhite3:
            color = [UIColor bdp_WhiteColor3];
            break;
        case BDPNegativeColorWhite4:
            color = [UIColor bdp_WhiteColor4];
            break;
        case BDPNegativeColorWhite5:
            color = [UIColor bdp_WhiteColor5];
            break;
    }
    
    return color;
}

@end
#pragma clang diagnostic pop
