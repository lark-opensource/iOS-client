//
//  CJPayNewCardPayRequest.h
//  CJPay
//
//  Created by 尚怀军 on 2019/12/23.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN


@class CJPayOrderConfirmResponse;
@class CJPayBDCreateOrderResponse;

@interface CJPayNewCardPayRequest : CJPayBaseRequest

+ (void)startWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse withExtraParams:(NSDictionary *)extraParams completion:(void(^)(NSError *error, CJPayOrderConfirmResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
