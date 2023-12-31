//
//  IESLiveResouceBundle+Color.m
//  Pods
//
//  Created by Zeus on 2016/12/21.
//
//

#import "IESLiveResouceBundle+Color.h"
#import "NSString+IESLiveResouceBundle.h"

@implementation IESLiveResouceBundle (Color)

- (UIColor * (^)(NSString *key))color {
    return ^(NSString *key) {
        NSString *colorName = self.colorName(key);
        NSArray *colorArr = [colorName componentsSeparatedByString:@"/"];
        if (colorArr.count == 2) {
            NSString *colorExcludeAlpha = colorArr.firstObject;
            CGFloat alpha = [colorArr.lastObject doubleValue];
            return [colorExcludeAlpha ies_lr_colorFromRGBHexStringWithAlpha:alpha];
        } else {
            return [colorName ies_lr_colorFromARGBHexString];
        }
    };
}

- (NSString * (^)(NSString *key))colorName {
    return ^(NSString *key) {
        NSString *hex = [self objectForKey:key type:@"color"];
        if ([hex hasPrefix:@"@color/"]) {
            return self.colorName([hex substringFromIndex:7]);
        }
        return (NSString *)[self objectForKey:key type:@"color"];
    };
}

- (IESLiveResouceAlphaColor)alphaColor
{
    return ^(NSString *key, CGFloat alpha) {
        return [self.colorName(key) ies_lr_colorFromRGBHexStringWithAlpha:alpha];
    };
}

@end
