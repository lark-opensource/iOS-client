//
//  CJPayFrontCashierCreateOrderRequest.h
//  CJPay
//
//  Created by 王新华 on 3/11/20.
//

#import "CJPayBaseRequest+BDPay.h"
#import "CJPayBDCreateOrderResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayFrontCashierCreateOrderRequest : CJPayBaseRequest

+ (void)startRequestWithAppid:(NSString *)appid merchantId:(NSString *)merchantID bizContentParams:(NSDictionary *)bizContentDic completion:(void(^)(NSError * _Nullable error, CJPayBDCreateOrderResponse * _Nullable response))completionBlock;

@end

NS_ASSUME_NONNULL_END
