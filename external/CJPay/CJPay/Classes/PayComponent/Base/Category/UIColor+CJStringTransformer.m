//
//  UIColor+CJStringTransformer.m
//  CJComponents
//
//  Created by liyu on 2019/11/19.
//

#import "UIColor+CJStringTransformer.h"

@implementation UIColor (CJStringTransformer)

- (NSString *)cj_argbHexString {
    CGFloat r, g, b, a;
    [self getRed:&r green:&g blue:&b alpha:&a];

    unsigned int aInt = (unsigned int)(a * 255.0f);
    unsigned int rInt = (unsigned int)(r * 255.0f);
    unsigned int gInt = (unsigned int)(g * 255.0f);
    unsigned int bInt = (unsigned int)(b * 255.0f);
    unsigned int argb = aInt<<24 | rInt<<16 | gInt<<8 | bInt<<0;
    return [NSString stringWithFormat:@"#%08x", argb];
}

@end
