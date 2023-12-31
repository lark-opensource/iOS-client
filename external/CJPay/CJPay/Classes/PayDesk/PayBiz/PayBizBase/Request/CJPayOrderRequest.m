//
//  CJPayOrderRequest.m
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import "CJPayOrderRequest.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayOrderRequest

+ (void)startConfirmWithParams:(NSDictionary *)params
                     traceId:(NSString *)traceId
               processInfoStr:(NSString *)processStr
                   completion:(void (^)(NSError *, CJPayOrderResponse *))completionBlock {
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    if (params != nil) {
        [bizContentParams addEntriesFromDictionary:params];
    }

    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    [requestParams cj_setObject:processStr forKey:@"process"];
    [requestParams cj_setObject:CJString(traceId) forKey:@"trace_id"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDictWithFinanceRiskWithPath:@"tp/cashier/trade_confirm"]] forKey:@"risk_info"];
    [requestParams cj_setObject:@"ALI_APP,ALI_H5,WX_APP,WX_H5" forKey:@"channel_support_scene"];

    [self startRequestWithUrl:[NSString stringWithFormat:@"%@/%@", [self customDeskServerUrlString], @"tp/cashier/trade_confirm"] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayOrderResponse *response = [[CJPayOrderResponse alloc] initWithDictionary:jsonObj error:&err];

        CJ_CALL_BLOCK(completionBlock,error,response);
    }];
}

@end
