//
//  CJPayCreateOneKeySignOrderRequest.h
//  Pods
//
//  Created by 王新华 on 2020/10/14.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayCreateOneKeySignOrderResponse;
@interface CJPayCreateOneKeySignOrderRequest : CJPayBaseRequest


///  一键绑卡下单
/// @param params [ card_type, bank_code, return_url, source]
/// @param completionBlock 结果回调
+ (void)startRequestWithParams:(NSDictionary *)params completion:(void(^)(NSError *error, CJPayCreateOneKeySignOrderResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
