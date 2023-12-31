//
//  CJPayMemCreateBizOrderRequest.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/13.
//

#import "CJPayMemCreateBizOrderRequest.h"

#import "CJPayMemCreateBizOrderResponse.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBindPageInfoResponse.h"

@implementation CJPayMemCreateBizOrderRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void (^)(NSError * _Nonnull, CJPayMemCreateBizOrderResponse * _Nonnull))completionBlock
{
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayMemCreateBizOrderResponse *response = [[CJPayMemCreateBizOrderResponse alloc] initWithDictionary:jsonObj error:&err];
        [self p_cacheBankListSignature:@"create_biz_order" bankListSignature:CJString(response.bindPageInfoResponse.bankListSignature)];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath{
    return @"/bytepay/member_product/create_biz_order";
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams
{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:bizParams];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    NSString *bankListSignature = [[NSUserDefaults standardUserDefaults] objectForKey:@"cjpay_create_biz_order_bank_list_signature_6.5.4"];
    [bizContentParams cj_setObject:CJString(bankListSignature) forKey:@"bank_list_signature"];
    
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

+ (void)p_cacheBankListSignature:(NSString *)apiType bankListSignature:(NSString *)bankListSignature {
    if (([bankListSignature isEqualToString:@""])) {
        return;
    }
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSString *bankListSignatureKey = [NSString stringWithFormat:@"cjpay_%@_bank_list_signature_6.5.4",apiType];
    NSString *oldBankListSignature = [userDefaults objectForKey:bankListSignatureKey];
    NSMutableDictionary *params = [[NSMutableDictionary alloc] init];
    [params cj_setObject:apiType forKey:@"api_type"];
    if (oldBankListSignature) {
        if (![oldBankListSignature isEqualToString:bankListSignature]) {
            [userDefaults setObject:bankListSignature forKey:bankListSignatureKey];
            [params cj_setObject:@"0" forKey:@"is_same"];
        } else {
            [params cj_setObject:@"1" forKey:@"is_same"];
        }
        [self p_trackerWithEventName:@"wallet_rd_bank_list_signature" params:[params copy]];
    } else {
        [userDefaults setObject:bankListSignature forKey:bankListSignatureKey];
    }
}

+ (void)p_trackerWithEventName:(NSString *)eventName params:(NSDictionary *)params {
    [CJTracker event:eventName params:params];
}

@end
