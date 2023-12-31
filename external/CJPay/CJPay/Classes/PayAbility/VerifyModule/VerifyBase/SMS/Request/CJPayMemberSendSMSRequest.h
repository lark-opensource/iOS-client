//
//  CJPayMemberSendSMSRequest.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/17.
//

#import "CJPayBaseRequest+BDPay.h"

NS_ASSUME_NONNULL_BEGIN
@class CJPayMemberSignResponse;
@class CJPaySendSMSResponse;
@interface CJPayMemberSendSMSRequest : CJPayBaseRequest

// 三方支付绑卡发短信接口
+ (void)startWithBDPaySendSMSBaseParam:(NSDictionary *)baseParam
                                  bizParam:(NSDictionary *)bizParam
                            completion:(void(^)(NSError *error, CJPaySendSMSResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
