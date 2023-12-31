//
//  CJPayVerifyItemAddPhoneNum.h
//  CJPay
//
//  Created by 尚怀军 on 2020/3/30.
//

#import "CJPayVerifyItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVerifyItemAddPhoneNum : CJPayVerifyItem

- (void)startAddPhoneNumWithConfirmResponse:(CJPayOrderConfirmResponse *)response;
- (void)startLynxAddPhoneNumWithConfirmResponse:(CJPayOrderConfirmResponse *)response;
- (void)startH5AddPhoneNumWithConfirmResponse:(CJPayOrderConfirmResponse *)response;


@end

NS_ASSUME_NONNULL_END
