//
//  CJPayOrderResultRequest.m
//  CJPay
//
//  Created by 王新华 on 4/2/20.
//

#import "CJPayOrderResultRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayKVContext.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"
#import "CJPayKVContext.h"

@implementation CJPayOrderResultRequest

+ (void)startWithTradeNo:(NSString *)tradeNo processInfo:(NSString *)processInfoStr completion:(void (^)(NSError *, CJPayOrderResultResponse *))completionBlock {
    [self startWithTradeNo:tradeNo processInfo:processInfoStr bdProcessInfo:@"" completion:completionBlock];
}

+ (void)startWithTradeNo:(NSString *)tradeNo processInfo:(NSString *)processInfoStr bdProcessInfo:(NSString *)bdProcessInfoStr completion:(void (^)(NSError *, CJPayOrderResultResponse *))completionBlock {
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];

    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:@{@"trade_no": CJString(tradeNo),
                                                                     @"byte_pay_param":CJString(bdProcessInfoStr)
                                                                   }];
    NSString *processId = [CJPayKVContext kv_valueForKey:CJPaySignPayRetainProcessId];
    [requestParams cj_setObject:processInfoStr forKey:@"process"];
    [requestParams cj_setObject:CJString(processId) forKey:@"process_id"];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam commonDeviceInfoDic]] forKey:@"devinfo"];
    [requestParams cj_setObject:@"" forKey:@"scene"];
    
    [self startRequestWithUrl:[NSString stringWithFormat:@"%@/%@", [self customDeskServerUrlString], @"tp/cashier/trade_query"] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayOrderResultResponse *response = [[CJPayOrderResultResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

@end
