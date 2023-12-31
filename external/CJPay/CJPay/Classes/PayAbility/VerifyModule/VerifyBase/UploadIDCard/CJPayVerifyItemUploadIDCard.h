//
//  CJPayVerifyItemUploadIDCard.h
//  CJPay
//
//  Created by 尚怀军 on 2020/3/30.
//

#import "CJPayVerifyItem.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVerifyItemUploadIDCard : CJPayVerifyItem

- (void)startUploadIDCardWithConfirmResponse:(CJPayOrderConfirmResponse *)response;
- (void)handleWebCloseCallBackWithData:(id _Nonnull)data;

@end

NS_ASSUME_NONNULL_END
