//
//  CJPayGuideResetPwdRequest.h
//  Aweme
//
//  Created by 尚怀军 on 2022/12/2.
//

#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayBDCreateOrderResponse;
@class CJPayGuideResetPwdResponse;
@interface CJPayGuideResetPwdRequest : CJPayBaseRequest

+ (void)startWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse
                    completion:(void(^)(NSError *error, CJPayGuideResetPwdResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
