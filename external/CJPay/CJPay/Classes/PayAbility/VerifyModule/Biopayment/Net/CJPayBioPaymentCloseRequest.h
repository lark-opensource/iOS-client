//
//  CJPayBioPaymentCloseRequest.h
//  BDPay
//
//  Created by 易培淮 on 2020/7/17.
//

#import <Foundation/Foundation.h>
#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"
#import "CJPayCommonSafeHeader.h"
#import <JSONModel/JSONModel.h>
#import "CJPayBioPaymentBaseRequestModel.h"


NS_ASSUME_NONNULL_BEGIN

@interface CJPayBioPaymentCloseResponse : CJPayBaseResponse


@end

@interface CJPayBioPaymentCloseRequest : CJPayBaseRequest

// 需要包括serial_num ,pwd_type, key
+ (void)startWithModel:(CJPayBioPaymentBaseRequestModel *)requestModel
       withExtraParams:(NSDictionary *)extraParams
            completion:(void(^)(NSError *error, CJPayBioPaymentCloseResponse *response))completion;

@end

NS_ASSUME_NONNULL_END
