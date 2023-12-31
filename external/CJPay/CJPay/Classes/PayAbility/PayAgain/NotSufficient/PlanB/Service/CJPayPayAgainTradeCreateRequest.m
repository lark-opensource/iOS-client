//
//  CJPayPayAgainTradeCreateRequest.m
//  Pods
//
//  Created by wangxiaohong on 2021/7/2.
//

#import "CJPayPayAgainTradeCreateRequest.h"

#import "CJPaySDKMacro.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayPayAgainTradeCreateResponse.h"

@implementation CJPayPayAgainTradeCreateRequest

+ (void)startWithParams:(NSDictionary *)params completion:(nonnull void (^)(NSError * _Nonnull, CJPayPayAgainTradeCreateResponse * _Nonnull))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestWithParams:params];
    
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayPayAgainTradeCreateResponse *response = [[CJPayPayAgainTradeCreateResponse alloc] initWithDictionary:jsonObj error:&err];
        
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/trade_create_again";
}

+ (NSDictionary *)p_buildRequestWithParams:(NSDictionary *)params {
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:[self p_buildBizParamsWithParams:params]];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}


+ (NSDictionary *)p_buildBizParamsWithParams:(NSDictionary *)params
{
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
        
    [bizContentParams cj_setObject:[params cj_dictionaryValueForKey:@"process_info"] forKey:@"process_info"];
    [bizContentParams cj_setObject:[params cj_stringValueForKey:@"business_scene"] forKey:@"business_scene"];
    [bizContentParams cj_setObject:[params cj_stringValueForKey:@"bank_card_id"]  forKey:@"bank_card_id"];
    [bizContentParams cj_setObject:[params cj_objectForKey:@"voucher_no_list"]  forKey:@"voucher_no_list"];
    [bizContentParams cj_setObject:[params cj_objectForKey:@"ext_param"] forKey:@"ext_param"];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:[params cj_objectForKey:@"credit_pay_installment"] forKey:@"credit_pay_installment"];
    [bizContentParams cj_setObject:[params cj_objectForKey:@"primary_pay_type"] forKey:@"primary_pay_type"];
    [bizContentParams cj_setObject:[params cj_objectForKey:@"combine_type"] forKey:@"combine_type"];

    return bizContentParams;
}

@end
