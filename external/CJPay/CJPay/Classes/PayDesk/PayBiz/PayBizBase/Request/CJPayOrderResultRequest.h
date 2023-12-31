//
//  CJPayOrderResultRequest.h
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import "CJPayBaseRequest.h"
#import "CJPayOrderResultResponse.h"

//订单查询
@interface CJPayOrderResultRequest : CJPayBaseRequest

+ (void)startWithTradeNo:(NSString *)tradeNo
             processInfo:(NSString *)processInfoStr
           bdProcessInfo:(NSString *)bdProcessInfo
              completion:(void(^)(NSError *error, CJPayOrderResultResponse *response))completionBlock;

+ (void)startWithTradeNo:(NSString *)tradeNo
             processInfo:(NSString *)processInfoStr
              completion:(void(^)(NSError *error, CJPayOrderResultResponse *response))completionBlock;

@end

