//
//  CJPayBankCardAddRequest.m
//  CJPay
//
//  Created by 尚怀军 on 2019/10/12.
//

#import "CJPayBankCardAddRequest.h"
#import "CJPayUIMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayBindPageInfoResponse.h"

@implementation CJPayBankCardAddRequest

+ (void)startRequestWithBizParams:(NSDictionary *)bizParams
                 completion:(void(^)(NSError * _Nullable error, CJPayBankCardAddResponse *response))completionBlock {
    NSDictionary *params = [self p_buildRequestParams:bizParams];

    [self startRequestWithUrl:[self buildServerUrl] requestParams:params callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBankCardAddResponse *response = [[CJPayBankCardAddResponse alloc] initWithDictionary:jsonObj error:&err];
        [self p_cacheBankListSignature:@"card_add" bankListSignature:CJString(response.bindPageInfoResponse.bankListSignature)];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/card_add";
}


//构造参数
+ (NSDictionary *)p_buildRequestParams:(NSDictionary *)params {
    
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"1.0" needTimestamp:NO];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:@"cashdesk.wap.user.cardadd" forKey:@"method"];
    NSString *bankListSignature = [[NSUserDefaults standardUserDefaults] objectForKey:@"cjpay_card_add_bank_list_signature_6.5.4"];
    [bizContentParams cj_setObject:CJString(bankListSignature) forKey:@"bank_list_signature"];
    
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[params cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[params cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
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
