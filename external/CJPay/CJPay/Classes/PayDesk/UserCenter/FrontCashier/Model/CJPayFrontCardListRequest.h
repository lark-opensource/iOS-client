//
//  CJPayFrontCardListRequest.h
//  CJPay
//
//  Created by wangxiaohong on 2020/3/12.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayBDCreateOrderResponse;
@interface CJPayFrontCardListRequest : CJPayBaseRequest

+ (void)startWithParams:(NSDictionary *)params
             completion:(void(^)(NSError *error, CJPayBDCreateOrderResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
