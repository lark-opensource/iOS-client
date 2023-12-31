//
//  CJPayECUpgradeSkipPwdRequest.m
//  Pods
//
//  Created by 孟源 on 2021/10/12.
//

#import "CJPayECUpgradeSkipPwdRequest.h"
#import "CJPayECUpgrateSkipPwdResponse.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayRequestParam.h"

@implementation CJPayECUpgradeSkipPwdRequest

+ (void)startWithUpgradeResponse:(CJPayBDCreateOrderResponse *)orderResponse
                     bizParams:(NSDictionary *)bizParams
                    completion:(void(^)(NSError *error, CJPayECUpgrateSkipPwdResponse *response))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithOrderResponse:orderResponse
                                                                    bizParams:bizParams];
    
    [self startRequestWithUrl:[self buildServerUrl]
                          requestParams:requestParams
                               callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayECUpgrateSkipPwdResponse *response = [[CJPayECUpgrateSkipPwdResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/modify_no_password";
}

+ (NSDictionary *)p_buildRequestParamsWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse
                                              bizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    NSDictionary *bizContentDic = [self p_buildBizParamsWithOrderResponse:orderResponse
                                                                   params:bizParams];
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentDic];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:CJString(orderResponse.merchant.appId) forKey:@"app_id"];
    [requestParams cj_setObject:CJString(orderResponse.merchant.merchantId) forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}


+ (NSDictionary *)p_buildBizParamsWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse
                                             params:(NSDictionary *)params {
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [bizContentParams cj_setObject:orderResponse.tradeInfo.tradeNo forKey:@"trade_no"]; //交易单号
    [bizContentParams cj_setObject:orderResponse.merchant.merchantId forKey:@"merchant_id"]; //商户号
    [bizContentParams cj_setObject:@"cashdesk.sdk.upgrade_no_password" forKey:@"method"];
    //处理process_info
    NSDictionary *processInfoParams = [orderResponse.processInfo toDictionary];
    [bizContentParams cj_setObject:processInfoParams forKey:@"process_info"];
    
    NSMutableDictionary *riskDict = [[CJPayRequestParam getMergeRiskInfoWithBizParams:bizContentParams] mutableCopy];
    [bizContentParams cj_setObject:[riskDict copy] forKey:@"risk_info"];
    
    return bizContentParams;
}

@end
