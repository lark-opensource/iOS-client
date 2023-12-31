//
//  DVEMacros.h
//  DVEFoundationKit
//
//  Created by bytedance on 2021/3/31.
//

#ifndef DVEMacros_h
#define DVEMacros_h

#import "DVEFontMacro.h"
#import "DVEColorMacro.h"
#import "DVEImageMacro.h"
#import "DVEStringMacro.h"
#import "NSArray+DVE.h"
#import "NSDictionary+DVE.h"
#import "DVEPadUIAdapter.h"
#import "UIView+DVE.h"

#define NLELocalizedString(key, placeholder) (DVEStringWithKey(key,placeholder))

#define DVE_SCREEN_WIDTH DVEScreenWidth()

#define DVE_SCREEN_HEIGHT DVEScreenHeight()

#define SINGLE_LINE_WIDTH           (1 / [UIScreen mainScreen].scale)

#ifndef weakify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define weakify(object) autoreleasepool{} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) autoreleasepool{} __block __typeof__(object) block##_##object = object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define weakify(object) try{} @finally{} {} __weak __typeof__(object) weak##_##object = object;
        #else
        #define weakify(object) try{} @finally{} {} __block __typeof__(object) block##_##object = object;
        #endif
    #endif
#endif

#ifndef strongify
    #if DEBUG
        #if __has_feature(objc_arc)
        #define strongify(object) autoreleasepool{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) autoreleasepool{} __typeof__(object) object = block##_##object;
        #endif
    #else
        #if __has_feature(objc_arc)
        #define strongify(object) try{} @finally{} __typeof__(object) object = weak##_##object;
        #else
        #define strongify(object) try{} @finally{} __typeof__(object) object = block##_##object;
        #endif
    #endif
#endif

// float
#define DVE_FLOAT_ZERO                      0.00001f
#define DVE_FLOAT_EQUAL_ZERO(a)             (fabs(a) <= DVE_FLOAT_ZERO)
#define DVE_FLOAT_GREATER_THAN(a, b)        ((a) - (b) >= DVE_FLOAT_ZERO)
#define DVE_FLOAT_EQUAL_TO(a, b)            DVE_FLOAT_EQUAL_ZERO((a) - (b))
#define DVE_FLOAT_LESS_THAN(a, b)           ((a) - (b) <= -DVE_FLOAT_ZERO)

// block
#define DVEBLOCK_INVOKE(block, ...)   (block ? block(__VA_ARGS__) : 0)

//empty
#ifndef DVE_isEmptyString
#define DVE_isEmptyString(param)      ( !(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO) )
#endif

#define isIphoneX DVEIsIphoneX()

FOUNDATION_STATIC_INLINE BOOL DVEIsIphoneX()
{
    BOOL isIPhoneX = NO;
    if (@available(iOS 11.0, *)) {
        isIPhoneX = [UIView dve_currentWindow].safeAreaInsets.bottom > 0.0;
    }
    return isIPhoneX;
}

FOUNDATION_STATIC_INLINE CGFloat DVEScreenWidth()
{
    if ([DVEPadUIAdapter dve_isIPad] && !DVE_FLOAT_EQUAL_ZERO([DVEPadUIAdapter dve_iPadScreenWidth])) {
        return [DVEPadUIAdapter dve_iPadScreenWidth];
    } else {
        return [UIView dve_currentWindow].bounds.size.width;
    }
}

FOUNDATION_STATIC_INLINE CGFloat DVEScreenHeight()
{
    if ([DVEPadUIAdapter dve_isIPad] && !DVE_FLOAT_EQUAL_ZERO([DVEPadUIAdapter dve_iPadScreenHeight])) {
        return [DVEPadUIAdapter dve_iPadScreenHeight];
    } else {
        return [UIView dve_currentWindow].bounds.size.height;
    }
}

#endif /* DVEMacros_h */
