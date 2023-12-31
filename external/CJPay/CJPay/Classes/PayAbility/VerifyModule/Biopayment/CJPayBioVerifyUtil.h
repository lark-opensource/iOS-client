//
//  CJPayBioVerifyUtil.h
//  aweme_transferpay_opt
//
//  Created by shanghuaijun on 2023/6/3.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, BioPaymentAction) {
    BioPaymentActionNomal = 0,                  // 原有逻辑，有默认取消逻辑
    BioPaymentActionExchangeTitleCancelToPWD,   // 交换 fallbackTitle 和 cancelTitle，都拉起验密页
    BioPaymentActionCancelToPWD,                // fallback 和 cancel 都拉起验密页
};

typedef NS_ENUM(NSUInteger, BioPaymentClickType) {
    BioPaymentClickTypeNone = 0,
    BioPaymentClickTypeUserFallback,                    // 点击降级
    BioPaymentClickTypeUserCancel,                  // 取消
};

@interface CJPayBioVerifyUtil : NSObject

+ (NSString *)bioCNErrorMessageWithError:(NSError * _Nonnull)error;

@end

NS_ASSUME_NONNULL_END
