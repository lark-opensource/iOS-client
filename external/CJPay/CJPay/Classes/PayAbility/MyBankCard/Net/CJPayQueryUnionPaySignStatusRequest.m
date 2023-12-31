//
//  CJPayQueryUnionPaySignStatusRequest.m
//  CJPay-5b542da5
//
//  Created by chenbocheng on 2022/8/31.
//

#import "CJPayQueryUnionPaySignStatusRequest.h"
#import "CJPayQueryUnionPaySignStatusResponse.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayQueryUnionPaySignStatusRequest

+ (void)startRequestWithParams:(NSDictionary *)params
                    completion:(void (^)(NSError * _Nonnull, CJPayQueryUnionPaySignStatusResponse * _Nonnull))completionBlock {
    NSDictionary *requestDic = [self buildParamsWithParams:params];
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestDic
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayQueryUnionPaySignStatusResponse *response = [[CJPayQueryUnionPaySignStatusResponse alloc] initWithDictionary:jsonObj error:&err];
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
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [requestParams cj_setObject:[params cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[params cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    //风控信息
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    [bizContentParams cj_setObject:riskDict forKey:@"risk_info"];
    [bizContentParams cj_setObject:[CJPayRequestParam commonDeviceInfoDic] forKey:@"dev_info"];
    [bizContentParams cj_setObject:@([params cj_boolValueForKey:@"need_query_show_union_pay"]) forKey:@"need_query_show_union_pay"];
    
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContentParams] forKey:@"biz_content"];
    return [requestParams copy];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/query_union_pay_sign_status";
}

@end
