//
//  CJPayUIMacro.h
//  CJPay
//
//  Created by 王新华 on 12/9/19.
//

#ifndef CJPayUIMacro_h
#define CJPayUIMacro_h

#import "CJPaySDKMacro.h"
#import "CJPayToast.h"
#import "UIImage+CJPay.h"
#import "UIColor+CJPay.h"
#import "CJPayButton.h"
#import "UIFont+CJPay.h"
#import "UIImageView+CJPay.h"
#import "UIViewController+CJPay.h"
#import "UIView+CJPayMasonry.h"
#import "UIView+CJTheme.h"
#import "NSObject+CJPay.h"
#import "BDImageView+CJPay.h"
#import "UIView+CJPay.h"
#import "UIView+CJLayout.h"
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayABTestManager.h"
#import "CJPayEnumUtil.h"

//Category
#import "NSArray+CJPay.h"
#import "UIDevice+CJPay.h"
#import "NSString+CJPay.h"
#import "NSDictionary+CJPay.h"
#import "NSMutableDictionary+CJPay.h"
#import "UIButton+CJPay.h"
#import "NSMutableAttributedString+CJPay.h"
//Util
#import "CJPayCommonUtil.h"
#import "CJPayPerformanceTracker.h"
#import <Masonry/Masonry.h>
#import "CJPayKeyboardManager.h"

#include <stdarg.h>
#include <stdio.h>
#include <string.h>

#define CJPI 3.14159265358979323846
//屏幕相关参数

#define CJ_MAX(A, B) (A < B ? B : A)

#define CJ_IPhoneX [UIDevice cj_isIPhoneX]
#define CJ_STATUSBAR_HEIGHT (CJ_Pad ? 0 : (CJ_IPhoneX ? 44 : 20))
#define CJ_STATUS_AND_NAVIGATIONBAR_HEIGHT (CJ_STATUSBAR_HEIGHT + 44)
#define CJ_TabBarSafeBottomMargin  (CJ_IPhoneX ? 34.0 : 0.0)
#define CJ_NewTabBarSafeBottomMargin  (CJ_IPhoneX ? 34.0 : 8.0)
#define CJ_PIXEL_WIDTH 1 / [UIScreen mainScreen].scale

//x机型在 非x机型 的基础上增加34px高度
#define CJ_HALF_SCREEN_HEIGHT_LOW (CJ_IPhoneX ? 504 : 470)
#define CJ_HALF_SCREEN_HEIGHT_MIDDLE (CJ_IPhoneX ? 540 : 516)
#define CJ_HALF_SCREEN_HEIGHT_HIGH (CJ_IPhoneX ? 614 : 580)

#define CJ_Pad [UIDevice cj_isPad]
#define CJ_Pad_Support_Multi_Window [UIDevice cj_supportMultiWindow] && CJ_Pad
#define CJ_BUTTON_HEIGHT 44
#define CJ_SIZE_FONT_SAFE(size) (size * [UIFont cjpayFontScale])
#define CJ_SMALL_SCREEN [UIDevice btd_is480Screen] || [UIDevice btd_is568Screen]

#ifndef CJStartLoading

#define CJStartLoading( object ) cj_keywordify {      \
    CJPayLogAssert([object conformsToProtocol:@protocol(CJPayBaseLoadingProtocol)], @"Object don't implement CJPayBaseLoadingProtocol");       \
    if ([object conformsToProtocol:@protocol(CJPayBaseLoadingProtocol)]) {  \
        [object startLoading];                                              \
    }                                                                       \
}

#endif

#ifndef CJStopLoading

#define CJStopLoading( object ) cj_keywordify {      \
    CJPayLogAssert([object conformsToProtocol:@protocol(CJPayBaseLoadingProtocol)], @"Object don't implement CJPayBaseLoadingProtocol");       \
    if ([object conformsToProtocol:@protocol(CJPayBaseLoadingProtocol)]) {  \
        [object stopLoading];                                              \
    }                                                                       \
}

#endif

#endif /* CJPayUIMacro_h */
