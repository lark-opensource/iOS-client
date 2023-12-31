//
//  CJPayNewCardPayRequest.m
//  CJPay
//
//  Created by 尚怀军 on 2019/12/23.
//

#import "CJPayNewCardPayRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayOrderConfirmResponse.h"
#import "CJPaySafeManager.h"

@implementation CJPayNewCardPayRequest

+ (void)startWithOrderResponse:(CJPayBDCreateOrderResponse *)orderResponse withExtraParams:(NSDictionary *)extraParams completion:(void(^)(NSError *error, CJPayOrderConfirmResponse *response))completionBlock{
    
    NSDictionary *requestParams = [self buildRequestParams:orderResponse withExtraParams:extraParams];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayOrderConfirmResponse *response = [[CJPayOrderConfirmResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/pay_new_card";
}

//构造参数
+ (NSDictionary *)buildRequestParams:(CJPayBDCreateOrderResponse *)orderResponse withExtraParams:(NSDictionary *)extraParams {
    if (orderResponse == nil) {
           return nil;
    }
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"1.0" needTimestamp:NO];
    [requestParams cj_setObject:CJString(orderResponse.merchant.appId) forKey:@"app_id"];
    [requestParams cj_setObject:CJString(orderResponse.merchant.merchantId) forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    [bizParams cj_setObject:@"cashdesk.wap.pay.pay_new_card" forKey:@"method"];
    [bizParams cj_setObject:CJString(orderResponse.merchant.merchantId) forKey:@"merchant_id"];
    [bizParams cj_setObject:CJString(orderResponse.merchant.appId) forKey:@"app_id"];
    [bizParams cj_setObject:@"pay_new_card" forKey:@"service"];
    [bizParams cj_setObject:[orderResponse.processInfo toDictionary] forKey:@"process_info"];
    [bizParams addEntriesFromDictionary:extraParams];
    [bizParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    // 加解密相关信息
    [bizParams cj_setObject:[self p_secureRequestParams:extraParams] forKey:@"secure_request_params"];
    
    NSString * bizContent = [CJPayCommonUtil dictionaryToJson:bizParams];
    [requestParams cj_setObject:bizContent forKey:@"biz_content"];
    
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
