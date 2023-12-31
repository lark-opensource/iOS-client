//
//  CJPayOpenSkipPwdRequest.h
//  Pods
//
//  Created by 尚怀军 on 2021/3/11.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN

@class CJPayOpenSkipPwdResponse;
@class CJPayBDCreateOrderResponse;
@interface CJPayOpenSkipPwdRequest : CJPayBaseRequest

+ (void)startWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse
                     bizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPayOpenSkipPwdResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
