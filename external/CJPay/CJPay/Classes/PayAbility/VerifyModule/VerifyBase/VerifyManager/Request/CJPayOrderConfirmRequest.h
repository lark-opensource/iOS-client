//
//  CJPayOrderConfirmRequest.h
//  Pods
//
//  Created by wangxiaohong on 2020/2/19.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDCreateOrderResponse;
@class CJPayOrderConfirmResponse;
@interface CJPayOrderConfirmRequest : CJPayBaseRequest

+ (void)startWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse
               withExtraParams:(NSDictionary *)extraParams
                    completion:(void(^)(NSError *error, CJPayOrderConfirmResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
