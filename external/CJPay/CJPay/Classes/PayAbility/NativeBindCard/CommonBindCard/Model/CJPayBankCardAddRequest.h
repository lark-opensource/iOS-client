//
//  CJPayBankCardAddRequest.h
//  CJPay
//
//  Created by 尚怀军 on 2019/10/12.
//

#import "CJPayBaseRequest+BDPay.h"
#import "CJPayBankCardAddResponse.h"
#import "CJPayProcessInfo.h"
#import "CJPayCardManageModule.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBankCardAddRequest : CJPayBaseRequest

+ (void)startRequestWithBizParams:(NSDictionary *)bizParams
                 completion:(void(^)(NSError * _Nullable error, CJPayBankCardAddResponse *response))completionBlock;

@end

NS_ASSUME_NONNULL_END
