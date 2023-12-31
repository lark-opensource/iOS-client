//
//  UINavigationBar+Navigation.m
//  Timor
//
//  Created by tujinqiu on 2019/10/8.
//

#import "UINavigationBar+Navigation.h"
#import <ECOInfra/NSString+BDPExtension.h>

@implementation UINavigationBar (Navigation)

// _UIBarBackground
+ (NSString *)bdp_backgroundViewClassString
{
    return @"_UIBarBackground"; //[NSString bdp_stringFromBase64String:@"X1VJQmFyQmFja2dyb3VuZA=="];
}

// _backgroundView
+ (NSString *)bdp_backgroundViewPropertyString
{
    return @"_backgroundView";// [NSString bdp_stringFromBase64String:@"X2JhY2tncm91bmRWaWV3"];
}

- (UIView *)bdp_getBackgroundView
{
    return [self valueForKey:[UINavigationBar bdp_backgroundViewPropertyString]];
}

@end
