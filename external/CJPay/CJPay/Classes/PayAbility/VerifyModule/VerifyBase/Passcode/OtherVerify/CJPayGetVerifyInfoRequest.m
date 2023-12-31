//
//  CJPayGetVerifyInfoRequest.m
//  Pods
//
//  Created by wangxinhua on 2021/7/30.
//

#import "CJPayGetVerifyInfoRequest.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayGetVerifyInfoRequest

+ (void)startVerifyInfoRequestWithAppid:(NSString *)appid merchantId:(NSString *)merchantId bizContentParams:(NSDictionary *)params completionBlock:(void(^)(NSError *error, CJPayVerifyInfoResponse *response))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithAppId:appid merchantId:merchantId bizParams:params];
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err;
        CJPayVerifyInfoResponse *response = [[CJPayVerifyInfoResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, err, response);
    }];
}


+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/get_verify_info";
}

//构造参数
+ (NSDictionary *)p_buildRequestParamsWithAppId:(NSString *)appId
                                     merchantId:(NSString *)merchantId
                                      bizParams:(NSDictionary *)bizParams {
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:[self p_buildBizParamsWithParams:bizParams]];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}


+ (NSDictionary *)p_buildBizParamsWithParams:(NSDictionary *)params
{
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
        
    [bizContentParams addEntriesFromDictionary:params];
    [bizContentParams cj_setObject:[CJPayRequestParam getMergeRiskInfoWithBizParams:bizContentParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:[CJPayRequestParam commonDeviceInfoDic] forKey:@"dev_info"];
    
    return bizContentParams;
}


@end
