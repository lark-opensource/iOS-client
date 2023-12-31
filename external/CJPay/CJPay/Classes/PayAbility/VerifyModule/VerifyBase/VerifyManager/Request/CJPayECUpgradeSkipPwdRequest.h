//
//  CJPayECUpgradeSkipPwdRequest.h
//  Pods
//
//  Created by 孟源 on 2021/10/12.
//

#import "CJPayBaseRequest.h"
@class CJPayECUpgrateSkipPwdResponse;
@class CJPayBDCreateOrderResponse;
NS_ASSUME_NONNULL_BEGIN

@interface CJPayECUpgradeSkipPwdRequest : CJPayBaseRequest

+ (void)startWithUpgradeResponse:(CJPayBDCreateOrderResponse *)orderResponse
                       bizParams:(NSDictionary *)bizParams
                      completion:(void(^)(NSError *error, CJPayECUpgrateSkipPwdResponse *response))completionBlock;
@end

NS_ASSUME_NONNULL_END
