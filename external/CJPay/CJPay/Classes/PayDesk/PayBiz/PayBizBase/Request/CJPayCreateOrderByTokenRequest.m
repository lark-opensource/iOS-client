//
//  CJPayCreateOrderRequest.m
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import "CJPayCreateOrderByTokenRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"
#import "CJPayKVContext.h"

@implementation CJPayCreateOrderByTokenRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                    bizUrl:(nullable NSString *)url
                completion:(void(^)(NSError *error, CJPayCreateOrderResponse *response))completionBlock {
    [self startWithBizParams:bizParams bizUrl:url highPriority:NO completion:completionBlock];
}

+ (void)startWithBizParams:(NSDictionary *)bizParams
                    bizUrl:(nullable NSString *)url
              highPriority:(BOOL)highPriority
                completion:(void(^)(NSError *error, CJPayCreateOrderResponse *response))completionBlock {
    __auto_type callbackBlock = ^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayCreateOrderResponse *response = [[CJPayCreateOrderResponse alloc] initWithDictionary:jsonObj error:&err];
        [[self class] p_setTrackerCommonParams:response];
        CJ_CALL_BLOCK(completionBlock, error, response);
    };
    
    NSDictionary *requestParams = [self buildRequestParamsWithBizParams:bizParams bizUrl:url];
    NSString *requestUrl = [NSString stringWithFormat:@"%@/%@", [self customDeskServerUrlString], @"tp/cashier/trade_create_by_token"];
    if (highPriority) {
        [self startRequestWithUrl:requestUrl method:@"POST" requestParams:requestParams headerFields:@{} serializeType:CJPayRequestSerializeTypeURLEncode callback:^(NSError * _Nullable error, id  _Nullable jsonObj) {
            CJ_CALL_BLOCK(callbackBlock, error, jsonObj);
        } needCommonParams:YES highPriority:YES];
    } else {
        [self startRequestWithUrl:requestUrl requestParams:requestParams callback:^(NSError *error, id jsonObj) {
            CJ_CALL_BLOCK(callbackBlock, error, jsonObj);
        }];
    }
}

//构造参数
+ (NSDictionary *)buildRequestParamsWithBizParams:(NSDictionary *)bizParams bizUrl:(NSString *)bizUrl {
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"2.0" needTimestamp:NO];
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    if (bizParams.count > 0) {
        [bizContentParams addEntriesFromDictionary:bizParams];
    }
    if (Check_ValidString(bizUrl)) {
        [bizContentParams cj_setObject:bizUrl forKey:@"cd_raw_url"];
    }
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:@"" forKey:@"scene"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDict]] forKey:@"risk_info"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam commonDeviceInfoDic]] forKey:@"devinfo"];
    return [requestParams copy];
}

+ (void)p_setTrackerCommonParams:(CJPayCreateOrderResponse *)response {
    [CJPayKVContext kv_setValue:CJString(response.payInfo.isCreditPayAvailable) forKey:CJPayTrackerCommonParamsIsCreavailable];
    if (response.payInfo.isCreditPayAvailable && !Check_ValidString(response.payInfo.creditPayStageListStr)) {
        [CJPayKVContext kv_setValue:@"1" forKey:CJPayTrackerCommonParamsCreditStageList];
    } else {
        [CJPayKVContext kv_setValue:CJString(response.payInfo.creditPayStageListStr) forKey:CJPayTrackerCommonParamsCreditStageList];
    }
}

@end

