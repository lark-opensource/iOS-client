//
//  CJPayOrderConfirmRequest.m
//  Pods
//
//  Created by wangxiaohong on 2020/2/19.
//

#import "CJPayOrderConfirmRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPayRequestParam.h"
#import "CJPaySDKMacro.h"
#import "CJPaySafeManager.h"
#import "CJPayPrivateServiceHeader.h"

@implementation CJPayOrderConfirmRequest

+ (void)startWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse withExtraParams:(NSDictionary *)extraParams completion:(void(^)(NSError *error, CJPayOrderConfirmResponse *response))completionBlock{
    
    NSDictionary *requestParams = [self buildRequestParams:orderResponse withExtraParams:extraParams];
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
    return  @"/bytepay/cashdesk/trade_confirm";
}

+ (NSDictionary *)buildRequestParams:(CJPayBDCreateOrderResponse *)orderResponse withExtraParams:(NSDictionary *)extraParams
{
    if (orderResponse == nil) {
           return nil;
    }
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [requestParams cj_setObject:orderResponse.merchant.appId forKey:@"app_id"];
    [requestParams cj_setObject:orderResponse.merchant.merchantId forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    [bizContentParams cj_setObject:orderResponse.tradeInfo.tradeNo forKey:@"trade_no"]; //交易单号
    [bizContentParams cj_setObject:@(orderResponse.tradeInfo.tradeAmount) forKey:@"trade_amount"]; //交易金额
    [bizContentParams cj_setObject:orderResponse.payInfo.realTradeAmount forKey:@"pay_amount"];   ////优惠后用户真正支付金额，如果没有优惠，同trade_amount一致
    [bizContentParams cj_setObject:orderResponse.merchant.merchantId forKey:@"merchant_id"]; //商户号
    
    //处理process_info
    NSDictionary *processInfoParams = [orderResponse.processInfo toDictionary];
    [bizContentParams cj_setObject:processInfoParams forKey:@"process_info"];
    
    id<CJPaySecService> secImpl = CJ_OBJECT_WITH_PROTOCOL(CJPaySecService);
    NSDictionary *secDict = @{};
    if (secImpl && [secImpl respondsToSelector:@selector(buildSafeInfo:context:)]) {
        secDict = [secImpl buildSafeInfo:@{}context:@{
            @"path" : CJString([self apiPath]),
        }];
    }
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParamsWith:secDict] forKey:@"risk_info"];
    
    // 加解密相关信息
    [bizContentParams cj_setObject:[self p_secureRequestParams:extraParams] forKey:@"secure_request_params"];

    [bizContentParams cj_setObject:@"cashdesk.sdk.pay.confirm" forKey:@"method"];
    [bizContentParams cj_setObject:@"NATIVE" forKey:@"channel_pay_type"];

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
