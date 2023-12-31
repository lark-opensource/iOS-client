//
//  DVEColorMacro.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/11/19.
//

#ifndef DVEColorMacro_h
#define DVEColorMacro_h

#import "UIColor+DVE.h"
#import "DVECustomResourceProvider.h"

#pragma mark - Common

FOUNDATION_STATIC_INLINE UIColor * DVEColorWithHex(NSString *hex)
{
    return [UIColor dve_colorWithHex:hex];
}

FOUNDATION_STATIC_INLINE UIColor * DVEColorWithHexAlpha(NSString *hex, CGFloat alpha)
{
    return [UIColor dve_colorWithHex:hex alpha:alpha];
}

FOUNDATION_STATIC_INLINE UIColor * DVEColorWithRGB(CGFloat red, CGFloat green, CGFloat blue)
{
    return [UIColor dve_colorWithRed:red green:green blue:blue];
}

FOUNDATION_STATIC_INLINE UIColor * DVEColorWithRGBA(CGFloat red, CGFloat green, CGFloat blue, CGFloat alpha)
{
    return [UIColor dve_colorWithRed:red green:green blue:blue alpha:alpha];
}

FOUNDATION_STATIC_INLINE UIColor * DVEColorWithARGBInt(uint32_t colorValue) {
    return [UIColor dve_colorWithARGBInt:colorValue];
}

#pragma mark - External

// 用于提取 color.json 中注入的信息
FOUNDATION_STATIC_INLINE UIColor * DVEColorWithKey(NSString *key)
{
    return [[DVECustomResourceProvider shareManager] colorWithKey:key];
}

#endif /* DVEColorMacro_h */
