//
//  CJPayServerEventPostRequest.m
//  Pods
//
//  Created by 王新华 on 2021/8/9.
//

#import "CJPayServerEventPostRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest.h"

@implementation CJPayServerEvent

- (NSString *)toStrForUpload {
    NSMutableDictionary *mutableDic = [NSMutableDictionary new];
    
    [mutableDic cj_setObject:self.intergratedMerchantId forKey:@"merchant_id"];
    [mutableDic cj_setObject:self.eventName forKey:@"event_code"];
    [mutableDic cj_setObject:[CJPayCommonUtil dictionaryToJson:self.extra] forKey:@"params"];
    return [CJPayCommonUtil dictionaryToJson:[mutableDic copy]];
}

@end


@implementation CJPayServerEventPostRequest

+ (void)postEvents:(NSArray<CJPayServerEvent *> *)events completion:(nonnull void (^)(NSError * _Nonnull error, CJPayBaseResponse *response))completion {
    NSMutableDictionary *mutableDic = [NSMutableDictionary new];
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    [mutableDic cj_setObject:[CJPayCommonUtil dictionaryToJson:riskDict] forKey:@"risk_info"];
    CJPayServerEvent *serverEvent = events.firstObject;
    [mutableDic cj_setObject:[serverEvent toStrForUpload] forKey:@"biz_content"];
    
    [self startRequestWithUrl:[NSString stringWithFormat:@"%@/%@", [self cashierServerUrlString], @"tp/cashier/event_upload"] requestParams:[mutableDic copy] callback:^(NSError *error, id jsonObj) {
        CJPayBaseResponse *response = [[CJPayBaseResponse alloc] initWithDictionary:jsonObj error:nil];
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

@end
