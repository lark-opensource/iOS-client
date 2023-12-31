//
//  CJPaySignPayQuerySignInfoRequest.m
//  Pods
//
//  Created by chenbocheng on 2022/7/12.
//

#import "CJPaySignPayQuerySignInfoRequest.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"
#import "CJPaySignPayQuerySignInfoResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPaySignPayQuerySignInfoRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPaySignPayQuerySignInfoResponse *response))completionBlock {
    NSDictionary *requestParams = [self buildRequestParamsWithBizParams: bizParams];
    
    [self startRequestWithUrl:[NSString stringWithFormat:@"%@/%@", [self customDeskServerUrlString], @"tp/cashier/query_sign_info"] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        if ([jsonObj isKindOfClass:NSDictionary.class]) {
            CJPaySignPayQuerySignInfoResponse *response = [[CJPaySignPayQuerySignInfoResponse alloc] initWithDictionary:jsonObj error:&err];
            CJ_CALL_BLOCK(completionBlock, error, response);
        } else {
            CJ_CALL_BLOCK(completionBlock, error, nil);
        }
    }];
}

//构造参数
+ (NSDictionary *)buildRequestParamsWithBizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"2.0" needTimestamp:NO];
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    if (bizParams.count > 0) {
        [bizContentParams addEntriesFromDictionary:bizParams];
    }
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:@"" forKey:@"scene"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDict]] forKey:@"risk_info"];
    return [requestParams copy];
}

@end
