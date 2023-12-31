//
//  JSONValueTransformer+CustomTransformer.m
//  CJPay
//
//  Created by wangxiaohong on 2019/11/1.
//

#import "JSONValueTransformer+CustomTransformer.h"
#import "UIColor+CJPay.h"
#import "UIColor+CJStringTransformer.h"
#import "NSString+CJColorTransformer.h"

@implementation JSONValueTransformer (CustomTransformer)

- (UIColor *)UIColorFromNSString:(NSString *)string
{
    return [string cj_colorWithDefaultColor:nil];
}

- (NSString *)JSONObjectFromUIColor:(UIColor *)color
{
    return [color cj_argbHexString];
}

@end
