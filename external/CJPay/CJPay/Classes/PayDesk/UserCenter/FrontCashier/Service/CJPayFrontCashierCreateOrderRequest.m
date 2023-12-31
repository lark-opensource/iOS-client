//
//  CJPayFrontCashierCreateOrderRequest.m
//  CJPay
//
//  Created by 王新华 on 3/11/20.
//

#import "CJPayFrontCashierCreateOrderRequest.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayFrontCashierCreateOrderRequest

+ (void)startRequestWithAppid:(NSString *)appid merchantId:(NSString *)merchantID bizContentParams:(NSDictionary *)bizContentDic completion:(nonnull void (^)(NSError * _Nonnull, CJPayBDCreateOrderResponse * _Nullable))completionBlock{
    NSDictionary *params = [self p_buildRequestParams:@{@"app_id": CJString(appid), @"merchant_id": CJString(merchantID)} bizContnetParams:bizContentDic];
    [self startRequestWithUrl:[self buildServerUrl] requestParams:params callback:^(NSError *error, id jsonObj) {
        NSError *err;
        CJPayBDCreateOrderResponse *response = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/pre_trade";
}

//构造参数
+ (NSDictionary *)p_buildRequestParams:(NSDictionary *)bizParams
                    bizContnetParams:(NSDictionary *)bizContentPrams{
    NSString *service = [[bizContentPrams cj_objectForKey:@"params"] cj_objectForKey:@"service"];
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    [requestParams addEntriesFromDictionary:bizParams];
    
    NSMutableDictionary *mutableContentDic = [NSMutableDictionary dictionaryWithDictionary:bizContentPrams];
    [mutableContentDic cj_setObject:@"cashdesk.sdk.pay.pre_trade" forKey:@"method"];
//余额充值=prepay.balance.confirm；余额提现=prewithdraw.balance.confirm；前置支付=prepay.normal.confirm；前置提现= prewithdraw.normal.confirm
    [mutableContentDic cj_setObject:service forKey:@"service"];
    [mutableContentDic cj_setObject:[CJPayRequestParam getMergeRiskInfoWithBizParams:bizContentPrams] forKey:@"risk_info"];
    
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:mutableContentDic] forKey:@"biz_content"];
    
    return [requestParams copy];
}


@end
