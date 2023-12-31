//
//  CJPayBDCreateOrderRequest.m
//  Pods
//
//  Created by wangxiaohong on 2020/2/19.
//

#import "CJPayBDCreateOrderRequest.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayRequestParam.h"
#import "CJPaySDKMacro.h"

@implementation CJPayBDCreateOrderRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
             bizParams:(NSDictionary *)bizParams
            completion:(void(^)(NSError *error, CJPayBDCreateOrderResponse *response))completionBlock {
    
    NSDictionary *requestParams = [self p_buildRequestParamsWithAppId:appId
                                                           merchantId:merchantId
                                                            bizParams:bizParams];
    
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBDCreateOrderResponse *response = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/trade_create";
}

//构造参数
+ (NSDictionary *)p_buildRequestParamsWithAppId:(NSString *)appId
                                     merchantId:(NSString *)merchantId
                                      bizParams:(NSDictionary *)bizParams {
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:[self p_buildBizParamsWithParams:bizParams]];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}


+ (NSDictionary *)p_buildBizParamsWithParams:(NSDictionary *)params
{
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *newBizParams = [params mutableCopy];
    [bizContentParams cj_setObject:newBizParams forKey:@"params"];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:@"cashdesk.sdk.pay.create" forKey:@"method"];

    return bizContentParams;
}

@end
