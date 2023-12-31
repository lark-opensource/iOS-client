//
//  DVEFontMacro.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/11/18.
//

#ifndef DVEFontMacro_h
#define DVEFontMacro_h

#import "UIFont+DVE.h"
#import "DVECustomResourceProvider.h"

#pragma mark - Common

FOUNDATION_STATIC_INLINE UIFont * DVEFont(CGFloat size)
{
    return [UIFont dve_systemFontOfSize:size];
}

FOUNDATION_STATIC_INLINE UIFont * DVEFontWithWeight(CGFloat size, UIFontWeight weight)
{
    return [UIFont dve_systemFontOfSize:size weight:weight];
}

FOUNDATION_STATIC_INLINE UIFont * DVEBoldFont(CGFloat size)
{
    return [UIFont dve_boldSystemFontOfSize:size];
}

FOUNDATION_STATIC_INLINE UIFont * DVEPingFangRegularFont(CGFloat size)
{
    return [UIFont dve_pingFangRegular:size];
}

FOUNDATION_STATIC_INLINE UIFont * DVEPingFangMediumFont(CGFloat size)
{
    return [UIFont dve_pingFangMedium:size];
}

FOUNDATION_STATIC_INLINE UIFont * DVEPingFangSemiboldFont(CGFloat size)
{
    return [UIFont dve_pingFangSemibold:size];
}

FOUNDATION_STATIC_INLINE UIFont * DVEHelBoldFont(CGFloat size)
{
    return [UIFont dve_helveticaBold:size];
}

#pragma mark - External

// 用于提取 font.json 中注入的信息
FOUNDATION_STATIC_INLINE UIFont * DVEFontWithKey(NSString *fontKey, NSString *sizeKey)
{
    return [[DVECustomResourceProvider shareManager] fontWithFontKey:fontKey sizeKey:sizeKey];
}

#endif /* DVEFontMacro_h */
