//
//  CJPayPayBannerRequest.h
//  Pods
//
//  Created by chenbocheng on 2021/8/3.
//

#import "CJPayBaseRequest.h"
#import "CJPayPayBannerResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayPayBannerRequest : CJPayBaseRequest

//支付有礼轮询接口
+ (void)startRequestWithAppId:(NSString *)appId
                   outTradeNo:(NSString *)outTradeNo
                   merchantId:(NSString *)merchantId
                          uid:(NSString *)uid
                       amount:(NSInteger)amount
                   completion:(void(^)(NSError *error, CJPayPayBannerResponse *bannerResponse))completionBlock;

@end

NS_ASSUME_NONNULL_END
