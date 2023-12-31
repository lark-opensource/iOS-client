//
//  CJPayMemberSignRequest.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/18.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayMemberSignResponse;
@class CJPaySignSMSResponse;
@interface CJPayMemberSignRequest : CJPayBaseRequest

// 三方支付验证短信签约绑卡
+ (void)startWithBDPayVerifySMSBaseParam:(NSDictionary *)baseParam
                                bizParam:(NSDictionary *)bizParam
                completion:(void(^)(NSError *error, CJPaySignSMSResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
