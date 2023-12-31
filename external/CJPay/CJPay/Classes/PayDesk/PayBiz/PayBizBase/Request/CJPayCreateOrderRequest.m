//
//  CJPayCreateOrderRequest.m
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import "CJPayCreateOrderRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"
#import "CJPayKVContext.h"

@implementation CJPayCreateOrderRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                    bizUrl:(nullable NSString *)url
                completion:(void(^)(NSError *error, CJPayCreateOrderResponse *response))completionBlock {
    NSDictionary *requestParams = [self buildRequestParamsWithBizParams: bizParams bizUrl:url];
    
    [self startRequestWithUrl:[NSString stringWithFormat:@"%@/%@", [self customDeskServerUrlString], @"tp/cashier/trade_create"] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayCreateOrderResponse *response = [[CJPayCreateOrderResponse alloc] initWithDictionary:jsonObj error:&err];
        response.originJsonString = CJString([jsonObj cj_toStr]);
        [[self class] p_setTrackerCommonParams:response];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

//构造参数
+ (NSDictionary *)buildRequestParamsWithBizParams:(NSDictionary *)bizParams bizUrl:(NSString *)bizUrl {
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"2.0" needTimestamp:NO];
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    if (bizParams.count > 0) {
        [bizContentParams cj_setObject:bizParams forKey:@"params"];
    }
    if (Check_ValidString(bizUrl)) {
        [bizContentParams cj_setObject:bizUrl forKey:@"cd_raw_url"];
    }
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:@"" forKey:@"scene"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDictWithFinanceRiskWithPath:@"tp/cashier/trade_create"]] forKey:@"risk_info"];
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

