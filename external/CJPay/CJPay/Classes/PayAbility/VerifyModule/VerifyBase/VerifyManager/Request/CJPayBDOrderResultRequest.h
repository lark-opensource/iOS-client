//
//  CJPayBDOrderResultRequest.h
//  CJPay
//
//  Created by wangxiaohong on 2020/2/21.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayProcessInfo;
@class CJPayBDOrderResultResponse;
@interface CJPayBDOrderResultRequest : CJPayBaseRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
               tradeNo:(NSString *)tradeNo
           processInfo:(CJPayProcessInfo *)processInfo
            completion:(void(^)(NSError *error, CJPayBDOrderResultResponse *response))completionBlock;

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
               tradeNo:(NSString *)tradeNo
           processInfo:(CJPayProcessInfo *)processInfo
                  exts:(NSDictionary *)exts
            completion:(void (^)(NSError * _Nonnull, CJPayBDOrderResultResponse * _Nonnull))completionBlock;

@end

NS_ASSUME_NONNULL_END
