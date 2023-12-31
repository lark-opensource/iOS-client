//
//  CJPayCardSignRequest.h
//  CJPay
//
//  Created by wangxiaohong on 2020/3/29.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayProcessInfo;
@class CJPayCardSignResponse;
@interface CJPayCardSignRequest : CJPayBaseRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
            bankCardId:(NSString *)bankCardId
           processInfo:(CJPayProcessInfo *)processInfo
            completion:(void (^)(NSError * _Nonnull error, CJPayCardSignResponse * _Nonnull response))completionBlock;


@end

NS_ASSUME_NONNULL_END
