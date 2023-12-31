//
//  ACCMacros.h
//  Pods
//
//  Created by chengfei xiao on 2019/7/24.
//

#ifndef ACCMacros_h
#define ACCMacros_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "UIDevice+ACCHardware.h"
#import "UIApplication+ACC.h"
#import "UIColor+ACC.h"
#import "ACCLogger.h"
#import "ACCFunctionUtils.h"
#import "ACCMacrosTool.h"
#import "ACCPadUIAdapter.h"

#define ACCSYSTEM_VERSION_LESS_THAN(v)                        ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

// color
#define ACCColorFromRGB(r, g, b)        ACCColorFromRGBA((r), (g), (b), 1)
#define ACCColorFromRGBA(r, g, b, a)    [UIColor colorWithRed:(r) / 255.0 green:(g) / 255.0 blue:(b) / 255.0 alpha:(a)]
#define ACCUIColorFromRGBA(__rgb__, __alpha__) \
[UIColor colorWithRed:((float)(((__rgb__) & 0xFF0000) >> 16))/255.0 \
                green:((float)(((__rgb__) & 0xFF00) >> 8))/255.0 \
                blue:((float)((__rgb__) & 0xFF))/255.0 \
                alpha:(__alpha__)]
#define ACCColorFromHexString(hexString) [UIColor acc_colorWithHex:hexString]

// screen
#define ACC_SCREEN_WIDTH    (([UIDevice acc_isIPad] && !ACC_FLOAT_EQUAL_ZERO([ACCPadUIAdapter iPadScreenWidth])) ? [ACCPadUIAdapter iPadScreenWidth] : [UIApplication acc_currentWindow].bounds.size.width)
#define ACC_SCREEN_HEIGHT   (([UIDevice acc_isIPad] && !ACC_FLOAT_EQUAL_ZERO([ACCPadUIAdapter iPadScreenHeight])) ? [ACCPadUIAdapter iPadScreenHeight] : [UIApplication acc_currentWindow].bounds.size.height)
#define ACC_SCREEN_SCALE    ([[UIApplication acc_currentWindow].screen scale])
#define ACC_ROOT_VC_HEIGHT  ([UIApplication acc_currentWindow].rootViewController.view.frame.size.height)

#define ACC_SafeAreaInsets  [UIApplication acc_safeAreaInsets]

// size
#define ACC_STATUS_BAR_HEIGHT          [UIApplication sharedApplication].statusBarFrame.size.height
#define ACC_NAVIGATION_BAR_OFFSET      ([UIDevice acc_isIPhoneX] ? (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 4 : 24) : 0)
#define ACC_IPHONE_X_BOTTOM_OFFSET     ([UIDevice acc_isIPhoneX] ? (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad ? 20 : 34) : 0)
#define ACC_STATUS_BAR_NORMAL_HEIGHT   (20 + ACC_NAVIGATION_BAR_OFFSET)
#define ACC_NAVIGATION_BAR_HEIGHT      (64 + ACC_NAVIGATION_BAR_OFFSET)

// weakify
#ifndef btd_keywordify
#if DEBUG
    #define btd_keywordify autoreleasepool {}
#else
    #define btd_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef weakify
    #if __has_feature(objc_arc)
        #define weakify(object) btd_keywordify __weak __typeof__(object) weak##_##object = object;
    #else
        #define weakify(object) btd_keywordify __block __typeof__(object) block##_##object = object;
    #endif
#endif

#ifndef strongify
    #if __has_feature(objc_arc)
        #define strongify(object) btd_keywordify __typeof__(object) object = weak##_##object;
    #else
        #define strongify(object) btd_keywordify __typeof__(object) object = block##_##object;
    #endif
#endif

// float
#define ACC_FLOAT_ZERO                      0.00001f
#define ACC_FLOAT_EQUAL_ZERO(a)             (fabs(a) <= ACC_FLOAT_ZERO)
#define ACC_FLOAT_GREATER_THAN(a, b)        ((a) - (b) >= ACC_FLOAT_ZERO)
#define ACC_FLOAT_EQUAL_TO(a, b)            ACC_FLOAT_EQUAL_ZERO((a) - (b))
#define ACC_FLOAT_LESS_THAN(a, b)           ((a) - (b) <= -ACC_FLOAT_ZERO)


#ifndef ACC_CLAMP
#define ACC_CLAMP(_x_, _low_, _high_)  (((_x_) > (_high_)) ? (_high_) : (((_x_) < (_low_)) ? (_low_) : (_x_)))
#endif

// block
#define ACCBLOCK_INVOKE(block, ...)   (block ? block(__VA_ARGS__) : 0)

#ifndef ALP_IGNORE
#define ALP_IGNORE
#endif



#ifndef ACC_MUTEX_LOCK
#define ACC_MUTEX_LOCK(lock) \
pthread_mutex_lock(&(lock)); \
@onExit{ \
pthread_mutex_unlock(&(lock)); \
};
#endif


// let
#if defined(__cplusplus)
#define let auto const
#else
#define let const __auto_type
#endif

// var
#if defined(__cplusplus)
#define var auto
#else
#define var __auto_type
#endif

#ifndef ACCAssert
#define ACCAssert( condition, ... ) NSCAssert( (condition) , ##__VA_ARGS__)
#endif // ACCAssert

#ifndef ACCFailAssert
#define ACCFailAssert( ... ) ACCAssert( (NO) , ##__VA_ARGS__)
#endif // ACCFailAssert

#ifndef ACCParameterAssert
#define ACCParameterAssert( condition ) ACCAssert( (condition) , @"Invalid parameter not satisfying: %@", @#condition)
#endif // ACCParameterAssert

#ifndef ACCAssertMainThread
#define ACCAssertMainThread() ACCAssert( ([NSThread isMainThread] == YES), @"Must be on the main thread")
#endif // ACCAssertMainThread

// print
#ifdef DEBUG
  #define ACCLog(FORMAT, ...)  fprintf(stderr, "[%s(%d):%s]\t%s\n",[[[NSString stringWithUTF8String:__FILE__] lastPathComponent] UTF8String], __LINE__, __func__, [[NSString stringWithFormat:FORMAT, ##__VA_ARGS__] UTF8String]);
#else
  #define ACCLog(FORMAT, ...)  nil
#endif

#define ACCContextId(A) void * const A = (void *)&A;
#define ACCStaticContextId(A) static void * const A = (void *)&A;

#define ACCDynamicCast(x, c) ((c *)([x isKindOfClass:[c class]] ? x : nil))



// let
#if defined(__cplusplus)
#define acc_let auto const
#else
#define acc_let const __auto_type
#endif

#ifndef ACCSafeForwardedClass
#define ACCSafeForwardedClass(s) (((void)(NO && (s *)nil)), NSClassFromString(@#s))
#endif

// async
NS_INLINE void acc_infra_queue_async_safe(dispatch_queue_t queue, dispatch_block_t block) {
    if (dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL) == dispatch_queue_get_label(queue)) {
        block();
    } else {
        dispatch_async(queue, block);
    }
}

NS_INLINE void acc_infra_main_async_safe(dispatch_block_t block) {
    acc_infra_queue_async_safe(dispatch_get_main_queue(), block);
}

#endif /* ACCMacros_h */
