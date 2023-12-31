//
//  CJPayBioPaymentCloseRequest.m
//  BDPay
//
//  Created by 易培淮 on 2020/7/17.
//


#import "CJPayBioPaymentCloseRequest.h"
#import "CJPaySafeManager.h"
#import "CJPayRequestParam.h"
#import "CJPayUIMacro.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPaySafeUtil.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayBioPaymentCheckRequest.h"

@implementation CJPayBioPaymentCloseResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicDict]];
}

@end

@implementation CJPayBioPaymentCloseRequest

+ (void)startWithModel:(CJPayBioPaymentBaseRequestModel *)requestModel
       withExtraParams:(NSDictionary *)extraParams
            completion:(void(^)(NSError *error, CJPayBioPaymentCloseResponse *response))completion{
    
    NSDictionary *requestParams = [CJPayBioPaymentCheckRequest buildRequestParams:requestModel
                                                                  withExtraParams:extraParams
                                                                     apiMethodDic:[self apiMethod]];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBioPaymentCloseResponse *response = [[CJPayBioPaymentCloseResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

+ (NSString *)apiPath{
    return @"/bytepay/member_product/disable_biometrics_pay";
}

@end
