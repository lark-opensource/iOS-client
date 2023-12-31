//
//  CJPayDeductAgainRequest.h
//  CJPaySandBox
//
//  Created by 高航 on 2023/1/4.
//

#import "CJPayBaseResponse.h"
#import "CJPayBaseRequest.h"

NS_ASSUME_NONNULL_BEGIN
//极速付二次支付下单

@interface CJPayDeductAgainResponse : CJPayBaseResponse

@property (nonatomic, copy) NSString *payStatus;
@property (nonatomic, copy) NSString *outTradeNo;

@end

@interface CJPayDeductAgainRequest : CJPayBaseRequest

+ (void)startWithRequestparams:(NSDictionary *)requestParams
                  completion:(void (^)(NSError * _Nonnull, CJPayDeductAgainResponse * _Nonnull))completionBlock;


@end

NS_ASSUME_NONNULL_END
