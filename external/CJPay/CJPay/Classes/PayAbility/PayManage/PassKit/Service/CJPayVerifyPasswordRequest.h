//
//  CJPayVerifyPasswordRequest.h
//  CJPay
//
//  Created by 王新华 on 2019/5/20.
//

#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"
#import "CJPayPassKitBizRequestModel.h"
#import "CJPayVerifyPassCodeResponse.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayVerifyPasswordRequest : CJPayBaseRequest

+ (void)startWithParams:(NSDictionary *)params
             completion:(void (^)(NSError *error, CJPayVerifyPassCodeResponse *response))completion;


@end

NS_ASSUME_NONNULL_END
