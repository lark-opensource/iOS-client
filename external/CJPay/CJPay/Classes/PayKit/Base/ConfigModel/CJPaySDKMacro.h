//
//  CJPaySDKMacro.h
//  CJPay
//
//  Created by jiangzhongping on 2018/8/20.
//

#ifndef CJPaySDKMacro_h
#define CJPaySDKMacro_h

#import "CJPayTracker.h"
#import "CJPayBizParam.h"
#import "CJPayMonitor.h"
#import "CJSDKParamConfig.h"
#import "NSArray+CJPay.h"
#import "NSDictionary+CJPay.h"
#import "NSMutableDictionary+CJPay.h"
#import "NSString+CJPay.h"
#import "NSURL+CJPay.h"
#import "CJPayCommonUtil.h"
#import "CJPayCommonSafeHeader.h"
#include <stdarg.h>
#include <stdio.h>
#include <string.h>
#import <ByteDanceKit/ByteDanceKit.h>
#import "CJPayBrandPromoteABTestManager.h"
#import "CJPaySettings.h"
#import "CJPayJsonParseTracker.h"
#import "CJPayLocalizedUtil.h"
#import "CJPayProtocolManager.h"
#import "CJPaySDKDefine.h"
#import <ByteDanceKit/NSString+BTDAdditions.h>

//校验
#define AS(obj,clz) ((clz *)obj)
#define IS(obj,clz) [obj isKindOfClass:[clz class]]
#define CheckObjcClass(objc,dClass) [objc isKindOfClass:[dClass class]]
#define Check_ValidArray(x)  (x != nil && [x isKindOfClass:[NSArray class]] && x.count > 0)
#define CJString(x)  ((x == nil || x.length == 0) ? @"" : x)
#define Check_ValidString(x)  (x != nil && [x isKindOfClass:[NSString class]] && x.length > 0)
#define Check_ValidDictionary(x)  (x != nil && [x isKindOfClass:[NSDictionary class]])
#define CJOptionsHasValue(options, value) (((options) & (value)) != 0x00)

#define CJ_SCREEN_WIDTH [UIScreen mainScreen].bounds.size.width
#define CJ_SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height

#define CJPayLocalizedStr(str) [CJPayLocalizedUtil localizableStringWithKey:str]

#define CJPayNoNetworkMessage CJPayLocalizedStr(@"网络不给力，请检查后重试")
#define CJPayDYPayTitleMessage Check_ValidString([CJPayBrandPromoteABTestManager shared].model.cashierTitle) ? CJPayLocalizedStr([CJPayBrandPromoteABTestManager shared].model.cashierTitle) : CJPayLocalizedStr(@"抖音支付")

#define CJPayDYPayLoadingTitle [[CJPayBrandPromoteABTestManager shared] isHitTest] ? CJPayLocalizedStr(@"抖音支付中") : CJPayLocalizedStr(@"支付中")

static NSString *const CJPayNetworkBusyMessage = @"系统繁忙，请稍后再试";

#define CJConfigAppName ((NSString *)[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"])

#define CJPayAppName Check_ValidString([CJPayBizParam shared].appName) ? [CJPayBizParam shared].appName : CJString(CJConfigAppName)

#define CJConcatStr(firstStr,...) [NSString cj_joinedWithSubStrings:firstStr,__VA_ARGS__,nil]

#define CJ_DelayEnableView(view)       \
do                                     \
{                                      \
    view.userInteractionEnabled = NO;  \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ view.userInteractionEnabled = YES; });          \
}while(0)

#define CJ_SafeDelayEnableView(view)       \
do                                     \
{                                      \
    [view cj_setUserInteractionEnabled:NO];  \
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{ [view cj_setUserInteractionEnabled:YES]; });          \
}while(0)

#define CJ_ModalOpenOnCurrentView do \
{                                    \
    [self cj_responseViewController].view.userInteractionEnabled = NO; \
    [self cj_responseViewController].view.window.userInteractionEnabled = NO; \
}while(0)

#define CJ_ModalCloseOnCurrentView \
{                                    \
    [self cj_responseViewController].view.userInteractionEnabled = YES; \
    [self cj_responseViewController].view.window.userInteractionEnabled = YES; \
}while(0)

// host protocol

#import "CJPayLoggerDefine.h"

#import "CJPayTracker.h"
#import "CJPayMonitor.h"

#import <Gaia/Gaia.h>

#define CJPayGaiaRegisterComponentKey "CJPayGaiaRegisterComponentKey"
#define CJPayGaiaRegisterComponentFunction GAIA_FUNCTION(CJPayGaiaRegisterComponentKey)
#define CJPayGaiaRegisterComponentMethod GAIA_METHOD(CJPayGaiaRegisterComponentKey);

#define CJPayGaiaRegisterPluginInitKey "CJPayGaiaRegisterPluginInitKey"
#define CJPayGaiaRegisterPluginMethod GAIA_METHOD(CJPayGaiaRegisterPluginInitKey);

#define CJPayGaiaInitClassRegisterKey "CJPayGaiaInitClassRegisterKey"
#define CJPayGaiaInitClassRegisterMethod GAIA_METHOD(CJPayGaiaInitClassRegisterKey);

#define CJPAY_REGISTER_PLUGIN(codes) + (void)registerPlugin { \
    CJPayGaiaRegisterPluginMethod                           \
    do {                                               \
        codes;                                         \
    } while(0);   \
}

#define CJPAY_REGISTER_COMPONENTS(codes) + (void)registerComponents { \
    CJPayGaiaRegisterComponentMethod                           \
    do {                                               \
        codes;                                         \
    } while(0);   \
}


#ifndef CJ_CALL_BLOCK
#define CJ_CALL_BLOCK(block, ...) (!block ?: block(__VA_ARGS__))
#endif

#ifndef CJ_CALL_BLOCK_RETURN
#define CJ_CALL_BLOCK_RETURN(block,Return)
#endif



#ifndef cj_keywordify
#if DEBUG
#define cj_keywordify autoreleasepool {}
#else
#define cj_keywordify try {} @catch (...) {}
#endif
#endif

#ifndef CJWeakify
#if __has_feature(objc_arc)

#define CJWeakify( object ) cj_keywordify __weak __typeof__(object) weak_##object = object;

#else

#define CJWeakify( object ) cj_keywordify __block __typeof__(object) block_##object = object;


#endif
#endif

#ifndef CJStrongify
#if __has_feature(objc_arc)

#define CJStrongify( object ) cj_keywordify __typeof__(object) object = weak_##object;

#else

#define CJStrongify( object ) cj_keywordify __typeof__(object) object = block_##object;

#endif
#endif

#define CJPayTransactionRun(action, completion) {\
    [CATransaction begin]; \
    [CATransaction setCompletionBlock:^{ \
        CJ_CALL_BLOCK(completion); \
    }]; \
    CJ_CALL_BLOCK(action); \
    [CATransaction commit]; \
}
#define CJ_PRAGMA_IGNORE_UNKNOWN_SEL(codes) {                              \
    do {                                                                   \
        codes                                                              \
    } while (0);                                                           \
}

#define CJ_PRAGMA_IGNORE_PERFORM_SEL_LEAKS(codes) {                        \
    do {                                                                   \
        codes                                                              \
    } while (0);                                                           \
}

#ifndef CJFenTransToYuan
#define CJFenTransToYuan( Amount ) [Amount decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"]]
#endif

#ifndef let
#if defined(__cplusplus)
#define let auto const
#else
#define let const __auto_type
#endif
#endif

#define CN_zfb [@"5pSv5LuY5a6d" btd_base64DecodedString]
#define EN_zfb [@"YWxpcGF5" btd_base64DecodedString]
#define CN_WX [@"5b6u5L+h" btd_base64DecodedString]
#define EN_WX [@"d2VpeGlu" btd_base64DecodedString]
#define EN_WX2 [@"d2VjaGF0" btd_base64DecodedString]
#define UP_Gecko [@"R2Vja28=" btd_base64DecodedString]
#define DW_gecko [@"Z2Vja28=" btd_base64DecodedString]

#endif /* CJPaySDKMacro_h */
