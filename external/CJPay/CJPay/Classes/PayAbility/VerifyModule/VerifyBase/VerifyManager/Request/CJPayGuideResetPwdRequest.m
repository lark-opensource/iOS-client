//
//  CJPayGuideResetPwdRequest.m
//  Aweme
//
//  Created by 尚怀军 on 2022/12/2.
//

#import "CJPayGuideResetPwdRequest.h"
#import "CJPayGuideResetPwdResponse.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayRequestParam.h"

@implementation CJPayGuideResetPwdRequest

+ (void)startWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse
                    completion:(void(^)(NSError *error, CJPayGuideResetPwdResponse *response))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithOrderResponse:orderResponse];
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayGuideResetPwdResponse *response = [[CJPayGuideResetPwdResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/reset_pwd";
}

+ (NSDictionary *)p_buildRequestParamsWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse {
    NSMutableDictionary *bizContentParams = [NSMutableDictionary new];
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [bizContentParams cj_setObject:CJString(orderResponse.tradeInfo.tradeNo) forKey:@"trade_no"];
    [bizContentParams cj_setObject:[orderResponse.processInfo toDictionary] forKey:@"process_info"];
    [bizContentParams cj_setObject:@"" forKey:@"exts"];
    
    NSMutableDictionary *riskDict = [[CJPayRequestParam getMergeRiskInfoWithBizParams:bizContentParams] mutableCopy];
    [bizContentParams cj_setObject:[riskDict copy] forKey:@"risk_info"];
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:CJString(orderResponse.merchant.appId) forKey:@"app_id"];
    [requestParams cj_setObject:CJString(orderResponse.merchant.merchantId) forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

@end
