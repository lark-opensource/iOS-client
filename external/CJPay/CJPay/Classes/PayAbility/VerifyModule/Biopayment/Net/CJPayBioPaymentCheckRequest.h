//
//  CJPayBioPaymentCheckRequest.h
//  BDPay
//
//  Created by 易培淮 on 2020/7/17.
//

#import "CJPayBaseRequest.h"
#import "CJPayBaseResponse.h"
#import "CJPayCommonSafeHeader.h"
#import <JSONModel/JSONModel.h>
#import "CJPayBioPaymentBaseRequestModel.h"

NS_ASSUME_NONNULL_BEGIN

@interface CJPayBioPaymentCheckResponse : CJPayBaseResponse

@property (nonatomic, assign) BOOL fingerPrintPay;
@property (nonatomic, assign) BOOL faceIdPay;

@end

@interface CJPayBioPaymentCheckRequest : CJPayBaseRequest

// pwd_type 字段 1：指纹支付 2：人脸支付
+ (void)startWithModel:(CJPayBioPaymentBaseRequestModel *)requestModel
       withExtraParams:(NSDictionary *)extraParams
            completion:(void(^)(NSError *error, CJPayBioPaymentCheckResponse *response))completion;

+ (NSDictionary *)buildRequestParams:(CJPayBioPaymentBaseRequestModel *)model
                     withExtraParams:(NSDictionary *)extraParams
                        apiMethodDic:(NSDictionary *)apiMethodDic;

@end

NS_ASSUME_NONNULL_END
