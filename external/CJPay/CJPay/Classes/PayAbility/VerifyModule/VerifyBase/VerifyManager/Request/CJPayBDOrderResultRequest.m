//
//  CJPayBDOrderResultRequest.m
//  CJPay
//
//  Created by wangxiaohong on 2020/2/21.
//

#import "CJPayBDOrderResultRequest.h"
#import "CJPayBDOrderResultResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayBDOrderResultRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
               tradeNo:(NSString *)tradeNo
           processInfo:(CJPayProcessInfo *)processInfo
                  exts:(NSDictionary *)exts
            completion:(void (^)(NSError * _Nonnull, CJPayBDOrderResultResponse * _Nonnull))completionBlock
{
    NSDictionary *requestParams = [self p_buildRequestParamsWithAppId:appId
                                                           merchantId:merchantId
                                                              tradeNo:tradeNo
                                                          processInfo:processInfo
                                                                 exts:(NSDictionary *)exts];
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBDOrderResultResponse *response = [[CJPayBDOrderResultResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
               tradeNo:(NSString *)tradeNo
           processInfo:(CJPayProcessInfo *)processInfo
            completion:(void (^)(NSError * _Nonnull, CJPayBDOrderResultResponse * _Nonnull))completionBlock
{
    [CJPayBDOrderResultRequest startWithAppId:appId merchantId:merchantId tradeNo:tradeNo processInfo:processInfo exts:@{} completion:completionBlock];
}

+ (NSString *)apiPath
{
    return @"/bytepay/cashdesk/trade_query";
}

+ (NSDictionary *)p_buildRequestParamsWithAppId:(NSString *)appId
                                     merchantId:(NSString *)merchantId
                                        tradeNo:(NSString *)tradeNo
                                    processInfo:(CJPayProcessInfo *)processInfo
                                           exts:(NSDictionary *)exts
{
    NSMutableDictionary *requestParams = [self buildBaseParams];

    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:[self p_buildBizContentParamsWithTradeNo:tradeNo processInfo:processInfo exts:exts]];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return requestParams;
}

+ (NSDictionary *)p_buildBizContentParamsWithTradeNo:(NSString *)tradeNo
                                         processInfo:(CJPayProcessInfo *)processInfo
                                                exts:(NSDictionary *)exts{
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:CJString(tradeNo) forKey:@"trade_no"]; //交易单号
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];

    NSDictionary *processInfoParams = [processInfo toDictionary];
    [bizContentParams cj_setObject:processInfoParams forKey:@"process_info"];
    [bizContentParams cj_setObject:@"cashdesk.sdk.pay.query" forKey:@"method"];
    
    // 外部商户唤端支付时，需重设method字段
    NSMutableDictionary *realExts = [exts mutableCopy];
    if ([exts objectForKey:@"method"] && [exts cj_boolValueForKey:@"pay_outer_merchant"]) {
        [bizContentParams cj_setObject:[exts cj_stringValueForKey:@"method"] forKey:@"method"];
        [realExts removeObjectsForKeys:@[@"pay_outer_merchant", @"method"]]; //移除exts内无需上报的字段
    }
//    [bizContentParams cj_setObject:exts forKey:@"exts"];
    [bizContentParams cj_setObject:[realExts copy] forKey:@"exts"];
    return [bizContentParams copy];
}


@end
