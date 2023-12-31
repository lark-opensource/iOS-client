//
//  CJPayUnionBindCardListRequest.m
//  Pods
//
//  Created by wangxiaohong on 2021/9/29.
//

#import "CJPayUnionBindCardListRequest.h"

#import "CJPayUIMacro.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPayUnionBindCardListResponse.h"

@implementation CJPayUnionBindCardListRequest

+ (void)startRequestWithParams:(NSDictionary *)params completion:(void (^)(NSError * _Nonnull, CJPayUnionBindCardListResponse * _Nonnull))completionBlock {
    NSDictionary *requestDic = [self buildParamsWithParams:params];
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestDic
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayUnionBindCardListResponse *response = [[CJPayUnionBindCardListResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSDictionary *)buildParamsWithParams:(NSDictionary *)params {
    
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    //公共参数
    [requestParams cj_setObject:@"utf-8" forKey:@"charset"];
    [requestParams cj_setObject:@"JSON" forKey:@"format"];
    NSString *timeStamp = [NSString stringWithFormat:@"%.0lf", [[NSDate date] timeIntervalSince1970]];
    [requestParams cj_setObject:timeStamp forKey:@"timestamp"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    //业务参数
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:params];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];

    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    [bizContentParams cj_setObject:riskDict forKey:@"risk_info"];
    
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContentParams] forKey:@"biz_content"];
    return [requestParams copy];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/get_union_pay_bank_list";
}

@end
