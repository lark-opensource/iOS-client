//
//  CJPayDyPayCreateOrderRequest.h
//  Pods
//
//  Created by xutianxi on 2022/09/28
//

#import "CJPayBaseRequest+DyPay.h"
#import "CJPayBDCreateOrderResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayDyPayCreateOrderRequest : CJPayBaseRequest

+ (void)startWithMerchantId:(NSString *)merchantId
                  bizParams:(NSDictionary *)bizParams
                 completion:(void(^)(NSError *error, CJPayBDCreateOrderResponse *response))completionBlock;

// @xiongpeng: 此方法可以通过highPriority参数设置优先级，一般情况下不要使用。
+ (void)startWithMerchantId:(NSString *)merchantId
                  bizParams:(NSDictionary *)bizParams
               highPriority:(BOOL)highPriority
                 completion:(void(^)(NSError *error, CJPayBDCreateOrderResponse *response))completionBlock;

//需要给前端传相关bizcontent等相关参数。所以暴露该方法。
+ (NSDictionary *)buildRequestParamsWithMerchantId:(NSString *)merchantId
                                           bizParams:(NSDictionary *)bizParams;
@end

NS_ASSUME_NONNULL_END
