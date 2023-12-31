//
//  CJPayOneKeyConfirmRequest.h
//  Pods
//
//  Created by 尚怀军 on 2021/5/17.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDCreateOrderResponse;
@class CJPayOrderConfirmResponse;
@interface CJPayOneKeyConfirmRequest : CJPayBaseRequest

+ (void)startWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse
               withExtraParams:(NSDictionary *)extraParams
                    completion:(void(^)(NSError *error, CJPayOrderConfirmResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
