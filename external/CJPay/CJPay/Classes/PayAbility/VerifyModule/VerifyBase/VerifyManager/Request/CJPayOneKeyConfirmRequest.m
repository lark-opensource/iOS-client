//
//  CJPayOneKeyConfirmRequest.m
//  Pods
//
//  Created by 尚怀军 on 2021/5/17.
//

#import "CJPayOneKeyConfirmRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPaySafeManager.h"
#import "CJPayRequestParam.h"

@implementation CJPayOneKeyConfirmRequest

+ (void)startWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse
               withExtraParams:(NSDictionary *)extraParams
                    completion:(void(^)(NSError *error, CJPayOrderConfirmResponse *response))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParams:orderResponse
                                             withExtraParams:extraParams];
    
    [self startRequestWithUrl:[self buildServerUrl]
                          requestParams:requestParams
                               callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayOrderConfirmResponse *response = [[CJPayOrderConfirmResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath
{
    return  @"/bytepay/cashdesk/verify_and_one_key_pay";
}

+ (NSDictionary *)p_buildRequestParams:(CJPayBDCreateOrderResponse *)orderResponse
                       withExtraParams:(NSDictionary *)extraParams {
    if (!orderResponse) {
        return nil;
    }
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [requestParams cj_setObject:orderResponse.merchant.appId forKey:@"app_id"];
    [requestParams cj_setObject:orderResponse.merchant.merchantId forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    
    [bizContentParams cj_setObject:orderResponse.merchant.merchantId forKey:@"merchant_id"]; //商户号
    [bizContentParams cj_setObject:@"cashdesk.sdk.pay.verify_and_one_key_pay" forKey:@"method"];
    
    //处理process_info
    NSDictionary *processInfoParams = [orderResponse.processInfo toDictionary];
    [bizContentParams cj_setObject:processInfoParams forKey:@"process_info"];
    [bizContentParams cj_setObject:[CJPayRequestParam getMergeRiskInfoWithBizParams:bizContentParams] forKey:@"risk_info"];
    
    // 加解密相关信息
    [bizContentParams cj_setObject:[self p_secureRequestParams:extraParams] forKey:@"secure_request_params"];

    if (extraParams != nil) {
        [bizContentParams addEntriesFromDictionary:extraParams];
    }
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    
    return [requestParams copy];
}

+ (NSDictionary *)p_secureRequestParams:(NSDictionary *)contentDic {
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    NSMutableArray *fields = [NSMutableArray array];
    if ([contentDic valueForKeyPath:@"pwd"]) {
        [fields addObject:@"pwd"];
        [dic cj_setObject:@"1" forKey:@"check"];
    }
    
    if ([contentDic valueForKeyPath:@"cert_code"]) {
        [fields addObject:@"cert_code"];
    }
    
    if ([contentDic valueForKeyPath:@"one_time_pwd.token_code"]) {
        [fields addObject:@"one_time_pwd.token_code"];
    }
    
    if ([contentDic valueForKeyPath:@"one_time_pwd.serial_num"]) {
        [fields addObject:@"one_time_pwd.serial_num"];
    }
    
    if ([contentDic valueForKeyPath:@"face_verify_params.face_sdk_data"]) {
        [fields addObject:@"face_verify_params.face_sdk_data"];
    }
    
    [dic cj_setObject:fields forKey:@"fields"];
    return dic;
}

@end
