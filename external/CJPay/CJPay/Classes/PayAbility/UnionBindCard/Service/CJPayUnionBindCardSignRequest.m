//
//  CJPayUnionBindCardSignRequest.m
//  Pods
//
//  Created by chenbocheng on 2021/9/27.
//

#import "CJPayUnionBindCardSignRequest.h"

#import "CJPayUnionBindCardSignResponse.h"
#import "NSMutableDictionary+CJPay.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayPassKitSafeUtil.h"

@implementation CJPayUnionBindCardSignRequest

+ (void)startRequestWithAppId:(NSString *)appId
                   merchantId:(NSString *)merchantId
              bizContentParam:(NSDictionary *)bizParam
                   completion:(void (^)(NSError * _Nonnull, CJPayUnionBindCardSignResponse * _Nonnull))completionBlock {
    NSDictionary *requestDic = [self buildParamsWithAppId:appId merchantId:merchantId bizContentParam:bizParam];
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestDic
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayUnionBindCardSignResponse *response = [[CJPayUnionBindCardSignResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
    
}

+ (NSDictionary *)buildParamsWithAppId:(NSString *)appId
                            merchantId:(NSString *)merchantId
                       bizContentParam:(NSDictionary *)bizParam {
    NSMutableDictionary *requestParams = [NSMutableDictionary dictionary];
    //公共参数
    [requestParams cj_setObject:@"utf-8" forKey:@"charset"];
    [requestParams cj_setObject:@"JSON" forKey:@"format"];
    NSString *timeStamp = [NSString stringWithFormat:@"%.0lf",[[NSDate date]timeIntervalSince1970]];
    [requestParams cj_setObject:timeStamp forKey:@"timestamp"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    //业务参数
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:bizParam];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    //风控信息
//    [bizContentParams cj_setObject:[CJPayRequestParam fingerPrintDict] forKey:@"risk_info"];
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    [bizContentParams cj_setObject:riskDict forKey:@"risk_info"];
    
    [bizContentParams cj_setObject:[CJPayRequestParam commonDeviceInfoDic] forKey:@"dev_info"];
    [bizContentParams cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:bizContentParams] forKey:@"secure_request_params"];
    
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContentParams] forKey:@"biz_content"];
    return [requestParams copy];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/union_pay_sign";
}

@end
