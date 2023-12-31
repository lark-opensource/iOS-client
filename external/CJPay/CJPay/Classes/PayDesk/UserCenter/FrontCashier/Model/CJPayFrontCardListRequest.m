//
//  CJPayFrontCardListRequest.m
//  CJPay
//
//  Created by wangxiaohong on 2020/3/12.
//

#import "CJPayFrontCardListRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayRequestParam.h"
#import "CJPaySDKMacro.h"


@implementation CJPayFrontCardListRequest

+ (void)startWithParams:(NSDictionary *)params
             completion:(void(^)(NSError *error, CJPayBDCreateOrderResponse *response))completionBlock {
    
    NSDictionary *requestParams = [self p_buildRequestParams:params];
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBDCreateOrderResponse *response = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath
{
    return @"/bytepay/cashdesk/pre_trade";
}

+ (NSDictionary *)p_bizContentMethodParam
{
    return @{@"method" : @"cashdesk.sdk.pay.pre_trade_card_list"};
}

//构造参数
+ (NSDictionary *)p_buildRequestParams:(NSDictionary *)params{
    
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [requestParams cj_setObject:CJString(appId) forKey:@"app_id"];
    [requestParams cj_setObject:CJString(merchantId) forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];

    NSMutableDictionary *mutableContentDic = [NSMutableDictionary dictionaryWithDictionary:@{@"params": params ?: @{}}];
    [mutableContentDic addEntriesFromDictionary:[self p_bizContentMethodParam]];
    NSString *service = [params cj_objectForKey:@"service"];
    [mutableContentDic cj_setObject:CJString(service) forKey:@"service"];
    [mutableContentDic cj_setObject:[CJPayRequestParam getMergeRiskInfoWithBizParams:params] forKey:@"risk_info"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:mutableContentDic] forKey:@"biz_content"];
    
    return [requestParams copy];
}

@end
