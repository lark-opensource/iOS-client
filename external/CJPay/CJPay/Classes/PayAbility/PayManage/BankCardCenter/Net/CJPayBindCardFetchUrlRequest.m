//
//  CJPayBindCardFetchUrlRequest.m
//  Pods
//
//  Created by youerwei on 2022/4/25.
//

#import "CJPayBindCardFetchUrlRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayBindCardFetchUrlResponse.h"
#import "CJPayRequestParam.h"
#import "CJPayBindPageInfoResponse.h"

@implementation CJPayBindCardFetchUrlRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
              bizParam:(NSDictionary *)bizParam
            completion:(void (^)(NSError * _Nonnull, CJPayBindCardFetchUrlResponse * _Nonnull))completion {
    NSDictionary *requestParam = [self p_buildParamWithAppId:appId merchantId:merchantId bizParam:bizParam];
    [self startRequestWithUrl:[self deskServerUrlString] requestParams:requestParam callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBindCardFetchUrlResponse *response = [[CJPayBindCardFetchUrlResponse alloc] initWithDictionary:jsonObj error:&err];
        [self p_cacheBankListSignature:@"fetch_url" bankListSignature:CJString(response.bindPageInfoResponse.bankListSignature)];
        
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

+ (NSDictionary *)p_buildParamWithAppId:(NSString *)appId
                             merchantId:(NSString *)merchantId
                               bizParam:(NSDictionary *)bizParam {
    NSMutableDictionary *param = [self buildBaseParams];
    [param cj_setObject:appId forKey:@"app_id"];
    [param cj_setObject:merchantId forKey:@"merchant_id"];
    [param cj_setObject:@"tp.customer.fetch_url" forKey:@"method"];
    NSMutableDictionary *bizContent = [bizParam mutableCopy];
    [bizContent cj_setObject:[CJPayRequestParam commonDeviceInfoDic] forKey:@"dev_info"];
    NSString *bankListSignature = [[NSUserDefaults standardUserDefaults] objectForKey:@"cjpay_fetch_url_bank_list_signature_6.5.4"];
    [bizContent cj_setObject:CJString(bankListSignature) forKey:@"bank_list_signature"];
    
    NSDictionary *riskInfo = [CJPayRequestParam riskInfoDict];
    [bizContent cj_setObject:[CJPayCommonUtil dictionaryToJson:riskInfo] forKey:@"risk_info"];
    [param cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContent] forKey:@"biz_content"];
    
    return param;
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
