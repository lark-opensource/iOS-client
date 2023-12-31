//
//  CJPayQueryMergeBindRelationRequest.m
//  CJPaySandBox
//
//  Created by 王晓红 on 2023/9/25.
//

#import "CJPayQueryMergeBindRelationRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"

@implementation CJPayQueryMergeBindRelationRequest

+ (void)startWithParams:(NSDictionary *)params completion:(void (^)(NSError * _Nonnull, CJPayQueryMergeBindRelationResponse * _Nonnull))completionBlock {
    NSDictionary *requestDic = [self buildParamsWithParams:params];
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestDic
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayQueryMergeBindRelationResponse *response = [[CJPayQueryMergeBindRelationResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
    
}

+ (NSDictionary *)buildParamsWithParams:(NSDictionary *)params {
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    //公共参数
    [requestParams cj_setObject:@"utf-8" forKey:@"charset"];
    [requestParams cj_setObject:@"JSON" forKey:@"format"];
    NSString *timeStamp = [NSString stringWithFormat:@"%.0lf",[[NSDate date]timeIntervalSince1970]];
    [requestParams cj_setObject:timeStamp forKey:@"timestamp"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    //业务参数
    [requestParams cj_setObject:[params cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[params cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:[CJPayRequestParam commonDeviceInfoDic] forKey:@"dev_info"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContentParams] forKey:@"biz_content"];
    return [requestParams copy];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/query_merge_bind_relation";
}

@end
