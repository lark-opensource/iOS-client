//
//  CJPayVerifyItemStandardBioPayment.h
//  aweme_transferpay_opt
//
//  Created by shanghuaijun on 2023/6/3.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseVerifyManager.h"
#import "CJPayCommonSafeHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBioSafeModel;
@class CJPayEvent;
@interface CJPayVerifyItemStandardBioPayment : CJPayVerifyItem

- (void)bioPayWithResponse:(CJPayBDCreateOrderResponse *)response
                     model:(CJPayBioSafeModel *)model
           localizedReason:(NSString *)localizedReason
         isSkipPwdSelected:(BOOL)isSkipPwdSelected
                completion:(void (^ __nullable)(BOOL isUserCancel))completion;

// 根据降级原因（主动/被动）和文案来构造CJPayEvent
- (CJPayEvent *)buildEventSwitchToPasswordWithReason:(nullable NSString *)reasonTip isActive:(BOOL)isActive;

- (void)verifyTypeSwitchToPassCode:(CJPayBDCreateOrderResponse *)response
                             event:(nullable CJPayEvent *)event;

- (void)setConfirmButtonEnableStatus:(BOOL)isEnable;

@end

NS_ASSUME_NONNULL_END
