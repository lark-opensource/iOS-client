//
//  CJPayUnionBindCardAuthorizationRequest.m
//  Pods
//
//  Created by chenbocheng on 2021/9/28.
//

#import "CJPayUnionBindCardAuthorizationRequest.h"

#import "CJPaySDKMacro.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"

@implementation CJPayUnionBindCardAuthorizationRequest

+ (void)startRequestWithParams:(NSDictionary *)params
                   completion:(void (^)(NSError * _Nonnull, CJPayUnionBindCardAuthorizationResponse * _Nonnull))completionBlock {
    NSDictionary *requestDict = [self buildParamsWithParams:params];
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestDict
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayUnionBindCardAuthorizationResponse *response = [[CJPayUnionBindCardAuthorizationResponse alloc]initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSDictionary *)buildParamsWithParams:(NSDictionary *)params {
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    NSString *memberbizOrderNo = [params cj_stringValueForKey:@"member_biz_order_no"];
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    //公共参数
    [requestParams cj_setObject:@"utf-8" forKey:@"charset"];
    [requestParams cj_setObject:@"JSON" forKey:@"format"];
    NSString *timeStamp = [NSString stringWithFormat:@"%.0lf",[[NSDate date]timeIntervalSince1970]];
    [requestParams cj_setObject:timeStamp forKey:@"timestamp"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    //业务参数
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:@{@"member_biz_order_no":CJString(memberbizOrderNo)}];

    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    [bizContentParams cj_setObject:riskDict forKey:@"risk_info"];
    
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContentParams] forKey:@"biz_content"];
    
    return [requestParams copy];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/query_union_pay_authorization";
}

@end
