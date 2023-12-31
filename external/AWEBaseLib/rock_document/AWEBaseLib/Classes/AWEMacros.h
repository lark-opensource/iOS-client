//
//  AWEMacros.h
//  Aweme
//
//  Created by willorfang on 16/8/8.
//  Copyright © 2016年 Bytedance. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIDevice+AWEAdditions.h"
#import "AWESafeAssertMacro.h"
#import <objc/runtime.h>
#import <ByteDanceKit/BTDMacros.h>

#define SSLocalScheme @"sslocal://"
#define APP_ID [[NSBundle mainBundle].infoDictionary objectForKey:@"SSAppID"]
#define APP_SCHEMA ([NSString stringWithFormat:@"snssdk%@://", APP_ID])
#define APP_STORE_APP_ID [[NSBundle mainBundle].infoDictionary objectForKey:@"APP_STORE_APP_ID"]
#define APP_GROUP_NAME [[NSBundle mainBundle].infoDictionary objectForKey:@"APP_GROUP_NAME"]

#define AWEME_HOST ((NSString *)[[NSBundle mainBundle].infoDictionary objectForKey:@"API_HOST"])
#define AWEME_DOMAIN [@"https://" stringByAppendingString:AWEME_HOST]

#define AWEColorFromRGB(r, g, b) AWEColorFromRGBA((r), (g), (b), 1)
#define AWEColorFromRGBA(r, g, b, a) [UIColor colorWithRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:(a)]
#define UIColorFromRGBA(__rgb__, __alpha__) \
[UIColor colorWithRed:((float)(((__rgb__) & 0xFF0000) >> 16))/255.0 \
                green:((float)(((__rgb__) & 0xFF00) >> 8))/255.0 \
                blue:((float)((__rgb__) & 0xFF))/255.0 \
                alpha:(__alpha__)]

#define DynamicCast(x, c) ((c *)([x isKindOfClass:[c class]] ? x : nil))

#define UIColorFromRGB(__rgb__) UIColorFromRGBA((__rgb__), 1.0)

FOUNDATION_EXPORT CGFloat getSrceenWidth();
FOUNDATION_EXPORT CGFloat getSrceenHeight();


#define SCREEN_WIDTH getSrceenWidth()
#define SCREEN_HEIGHT getSrceenHeight()


#define SCREEN_SCALE [[UIScreen mainScreen] scale]

#define ROOT_VC_HEIGHT ([UIApplication sharedApplication].delegate.window.rootViewController.view.frame.size.height)

#define STATUS_BAR_HEIGHT [UIApplication sharedApplication].statusBarFrame.size.height
#define STATUS_BAR_NORMAL_HEIGHT (20 + NAVIGATION_BAR_OFFSET)
#define TAB_BAR_HEIGHT          (49 + IPHONE_X_BOTTOM_OFFSET)
#define NAVIGATION_BAR_HEIGHT   (64 + NAVIGATION_BAR_OFFSET)
#define NAVIGATION_BAR_OFFSET   ([UIDevice awe_isIPhoneX] ? (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 4 : 24) : 0)
#define IPHONE_X_BOTTOM_OFFSET ([UIDevice awe_isIPhoneX] ? (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 20 : 34) : 0)
#define IPHONE_X_BOTTOM_OFFSET_FOR_LANDSCAPE ([UIDevice awe_isIPhoneX] ? (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 20 : 21) : 0)
#define IPHONE_X_LEFT_OFFSET_FOR_LANDSCAPE (([UIDevice awe_isIPhoneX] && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) ? 44 : 0)
#define IPHONE_X_RIGHT_OFFSET_FOR_LANDSCAPE (([UIDevice awe_isIPhoneX] && (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)) ? 44 : 0)
#define VIDEO_FILL_MAX_RATO (9.2f / 16.0f) //播放视频时影响contentMode,精确值为9.0/16.0,因为部分导入的视频会有几个像素值的偏差，故设置为9.2/16.0 做容错。

//同步-慎用
#ifndef aweme_dispatch_queue_sync_safe
#define aweme_dispatch_queue_sync_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
    block();\
} else {\
    dispatch_sync(queue, block);\
}
#endif

//异步-
#ifndef aweme_dispatch_queue_async_safe
#define aweme_dispatch_queue_async_safe(queue, block)\
if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {\
    block();\
} else {\
    dispatch_async(queue, block);\
}
#endif

#ifndef aweme_dispatch_main_async_safe
#define aweme_dispatch_main_async_safe(block) aweme_dispatch_queue_async_safe(dispatch_get_main_queue(), block)
#endif


#ifndef isEmptyString
#define isEmptyString(str) (!str || ![str isKindOfClass:[NSString class]] || str.length == 0)
#endif

#define degreesToRadians(x) (M_PI*(x)/180.0)

#define FLOAT_ZERO                      0.00001f
#define FLOAT_EQUAL_ZERO(a)             (fabs(a) <= FLOAT_ZERO)
#define FLOAT_GREATER_THAN(a, b)        ((a) - (b) >= FLOAT_ZERO)
#define FLOAT_EQUAL_TO(a, b)            FLOAT_EQUAL_ZERO((a) - (b))
#define FLOAT_LESS_THAN(a, b)           ((a) - (b) <= -FLOAT_ZERO)

#define AWEBLOCK_INVOKE(block, ...) (block ? block(__VA_ARGS__) : 0)

#ifndef BTD_isEmptyString
#define BTD_isEmptyString(param)        ( !(param) ? YES : ([(param) isKindOfClass:[NSString class]] ? (param).length == 0 : NO) )
#endif

#ifndef BTD_isEmptyArray
#define BTD_isEmptyArray(param)         ( !(param) ? YES : ([(param) isKindOfClass:[NSArray class]] ? (param).count == 0 : NO) )
#endif

#ifndef btd_keywordify
#if DEBUG
#define btd_keywordify autoreleasepool {}
#else
#define btd_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
#if __has_feature(objc_arc)
#define weakify(object) btd_keywordify __weak __unused __typeof__(object) weak##_##object = object;
#else
#define weakify(object) btd_keywordify __block __unused __typeof__(object) block##_##object = object;
#endif
#endif

#ifndef strongify
#if __has_feature(objc_arc)
#define strongify(object) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    btd_keywordify __unused __typeof__(object) object = weak##_##object; \
    _Pragma("clang diagnostic pop")
#else
#define strongify(object) \
    _Pragma("clang diagnostic push") \
    _Pragma("clang diagnostic ignored \"-Wshadow\"") \
    btd_keywordify __unused __typeof__(object) object = block##_##object; \
    _Pragma("clang diagnostic pop")
#endif
#endif

#ifndef onExit

#define onExit \
btd_keywordify __strong void(^block)(void) __attribute__((cleanup(blockCleanUp), unused)) = ^

#endif

#ifndef AWE_MUTEX_LOCK
#define AWE_MUTEX_LOCK(lock) \
pthread_mutex_lock(&(lock)); \
@onExit{ \
pthread_mutex_unlock(&(lock)); \
};
#endif

#define ALP_IGNORE
#define ALP_FILE_IGNORE_07B0A1
#define ALP_FORCE_TRANSLATE
#define ALP_UNSAFE_ALLOW_NOT_TRANSLATED
#define AWEBase64Decode(str) [[NSString alloc] initWithData:[[NSData alloc] initWithBase64EncodedString:str options:0] encoding:NSUTF8StringEncoding]
#define AWEContextString(str, context) ALPContextString(str, context)

#define AWESelectorString(sel) NSStringFromSelector(@selector(sel))
#define AWEClassString(sel) NSStringFromClass([(sel) class])

#ifndef DYNAMIC_PROPERTY_OBJECT
#define DYNAMIC_PROPERTY_OBJECT(_getter_, _setter_, _association_, _type_) \
- (void)_setter_ : (_type_)object { \
[self willChangeValueForKey:@#_getter_]; \
objc_setAssociatedObject(self, _cmd, object, OBJC_ASSOCIATION_ ## _association_); \
[self didChangeValueForKey:@#_getter_]; \
} \
- (_type_)_getter_ { \
return objc_getAssociatedObject(self, @selector(_setter_:)); \
}
#endif


#ifndef AWE_SELSTR
/**
 * 根据 SEL 生成 NSString
 * @discussion 支持合法性检测，打包时直接生成常量，没有性能损耗
 * @param sel 方法名
 * @return 方法名字符串
 */
# define AWE_SELSTR(sel) ((NO && NSStringFromSelector(@selector(sel))), @#sel)
#endif

#ifndef AWE_CLSSTR
/**
 * 根据 Class 生成 NSString
 * @discussion 支持合法性检测，打包时直接生成常量，没有性能损耗
 * @param cls 类名，注意：直接使用 CLSSTR(MyObject) 即可，不能 CLSSTR(MyObject.class)
 * @return 类名字符串
 */
# define AWE_CLSSTR(cls) ((void)(NO && (cls *)nil), NO && NSStringFromClass([cls class]), @#cls)
#endif
