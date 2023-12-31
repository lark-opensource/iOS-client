//
//  CJPayVerifyItemBioPayment.h
//  CJPay
//
//  Created by 王新华 on 2019/6/27.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseVerifyManager.h"
#import "CJPayCommonSafeHeader.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBioSafeModel;
@class CJPayEvent;

@interface CJPayVerifyItemBioPayment : CJPayVerifyItem

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
