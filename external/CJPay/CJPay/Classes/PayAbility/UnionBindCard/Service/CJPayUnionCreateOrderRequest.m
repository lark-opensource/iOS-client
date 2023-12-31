//
//  CJPayUnionCreateOrder.m
//  Pods
//
//  Created by xutianxi on 2021/10/8.
//

#import "CJPayUnionCreateOrderRequest.h"
#import "CJPayBaseRequest+BDPay.h"

#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"


@implementation CJPayUnionCreateOrderRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void (^)(NSError * _Nonnull, CJPayUnionCreateOrderResponse * _Nonnull))completionBlock
{
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayUnionCreateOrderResponse *response = [[CJPayUnionCreateOrderResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams
{
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:bizParams];
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    [bizContentParams cj_setObject:riskDict forKey:@"risk_info"];
    
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:@"utf-8" forKey:@"charset"];
    [requestParams cj_setObject:@"JSON" forKey:@"format"];
    [requestParams cj_setObject:[NSString stringWithFormat:@"%.0lf",[[NSDate date]timeIntervalSince1970]] forKey:@"timestamp"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/create_union_pay_sign_order";
}

@end
