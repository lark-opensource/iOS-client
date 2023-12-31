//
//  NSString+IESLiveResouceBundle.m
//  Pods
//
//  Created by Zeus on 2016/12/29.
//
//

#import "NSString+IESLiveResouceBundle.h"

@implementation NSString (IESLiveResouceBundle)

- (UIColor *)ies_lr_colorFromARGBHexString {
    unsigned argbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setScanLocation:1]; // pass '#' character
    [scanner scanHexInt:&argbValue];
    unsigned alphaValue = (argbValue & 0xFF000000) >> 24;
    CGFloat alpha = alphaValue > 0 ? alphaValue/255.0 : 1;
    return [UIColor colorWithRed:((argbValue & 0xFF0000) >> 16)/255.0 green:((argbValue & 0xFF00) >> 8)/255.0 blue:(argbValue & 0xFF)/255.0 alpha:alpha];
}

- (UIColor *)ies_lr_colorFromRGBHexStringWithAlpha:(CGFloat)alpha
{
    unsigned argbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:self];
    [scanner setScanLocation:1]; // pass '#' character
    [scanner scanHexInt:&argbValue];
    
    return [UIColor colorWithRed:((argbValue & 0xFF0000) >> 16)/255.0 green:((argbValue & 0xFF00) >> 8)/255.0 blue:(argbValue & 0xFF)/255.0 alpha:alpha];
}

- (NSString *)ies_lr_formatWithParams:(NSDictionary *)params {
    NSString *string = [NSString stringWithString:self];
    for (NSString *key in params.allKeys) {
        string = [string stringByReplacingOccurrencesOfString:[NSString stringWithFormat:@"<%%=(\\s)*(%@)+(\\s)*%%>", key]
                                                   withString:[NSString stringWithFormat:@"%@", params[key]]
                                                      options:NSRegularExpressionSearch
                                                        range:NSMakeRange(0, string.length)];
    }
    return [string stringByReplacingOccurrencesOfString:@"<%=(\\s)*.*?(\\s)*%>"
                                             withString:@""
                                                options:NSRegularExpressionSearch
                                                  range:NSMakeRange(0, string.length)];
}

@end
