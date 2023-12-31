//
//  CJPayBDCreateOrderRequest.h
//  Pods
//
//  Created by wangxiaohong on 2020/2/19.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDCreateOrderResponse;
@interface CJPayBDCreateOrderRequest : CJPayBaseRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
             bizParams:(NSDictionary *)bizParams
            completion:(void(^)(NSError *error, CJPayBDCreateOrderResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
