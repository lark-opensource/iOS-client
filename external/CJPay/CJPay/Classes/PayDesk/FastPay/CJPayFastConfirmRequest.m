//
//  CJPayFastConfirmRequest.m
//  Pods
//
//  Created by bytedance on 2021/5/21.
//

#import "CJPayFastConfirmRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"

@implementation CJPayFastConfirmRequest

+ (void)startFastWithBizParams:(NSDictionary *)bizParams
                    bizUrl:(nullable NSString *)url
                completion:(void(^)(NSError *error, CJPayOrderResultResponse *response))completionBlock {
    NSDictionary *requestParams = [self buildRequestParamsWithBizParams: bizParams bizUrl:url];
    
    [self startRequestWithUrl:[NSString stringWithFormat:@"%@/%@", [self customDeskServerUrlString], @"tp/cashier/direct_confirm"] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayOrderResultResponse *response = [[CJPayOrderResultResponse alloc] initWithDictionary:jsonObj error:&err];
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
    [bizContentParams cj_setObject:@"bytepay" forKey:@"ptcode"];
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:@"" forKey:@"scene"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDict]] forKey:@"risk_info"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam commonDeviceInfoDic]] forKey:@"devinfo"];
    return [requestParams copy];
}

@end
