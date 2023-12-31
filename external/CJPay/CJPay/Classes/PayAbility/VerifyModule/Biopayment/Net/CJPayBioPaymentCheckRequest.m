//
//  CJPayBioPaymentCheckRequest.m
//  BDPay
//
//  Created by 易培淮 on 2020/7/17.
//

#import "CJPayBioPaymentCheckRequest.h"
#import "CJPayEnvManager.h"
#import "CJPayUIMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayPassKitSafeUtil.h"

@implementation CJPayBioPaymentCheckResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
               @"fingerPrintPay": @"response.fingerprint_pay",
               @"faceIdPay": @"response.faceid_pay"
       }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

@end

@implementation CJPayBioPaymentCheckRequest

+ (void)startWithModel:(CJPayBioPaymentBaseRequestModel *)requestModel
       withExtraParams:(NSDictionary *)extraParams
            completion:(void(^)(NSError *error, CJPayBioPaymentCheckResponse *response))completion{
    NSDictionary *requestParams = [self buildRequestParams:requestModel
                                           withExtraParams:extraParams
                                              apiMethodDic:[self apiMethod]];
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBioPaymentCheckResponse *response = [[CJPayBioPaymentCheckResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

//构造参数
+ (NSDictionary *)buildRequestParams:(CJPayBioPaymentBaseRequestModel *)model
                     withExtraParams:(NSDictionary *)extraParams
                        apiMethodDic:(NSDictionary *)apiMethodDic {
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    [requestParams cj_setObject:model.appId forKey:@"app_id"];
    [requestParams cj_setObject:model.merchantId forKey:@"merchant_id"];
    [requestParams cj_setObject:CJString(model.signType) forKey:@"sign_type"];
    [requestParams cj_setObject:CJString(model.timestamp) forKey:@"timestamp"];
    [requestParams cj_setObject:CJString(model.sign) forKey:@"sign"];
    [requestParams addEntriesFromDictionary:apiMethodDic];
    
    [bizContentParams cj_setObject:model.uid forKey:@"uid"]; //交易单号
    [bizContentParams cj_setObject:model.merchantId forKey:@"merchant_id"]; //商户号
    [bizContentParams cj_setObject:model.appId forKey:@"app_id"];
    
    //设备id 公司install服务统一生成的宿主的设备id
    if ([CJPayRequestParam gAppInfoConfig].deviceIDBlock) {
        [bizContentParams cj_setObject:[CJPayRequestParam gAppInfoConfig].deviceIDBlock() forKey:@"did"];
    } else {
        [bizContentParams cj_setObject:@" " forKey:@"did"];
    }
    [bizContentParams cj_setObject:[CJPayRequestParam gAppInfoConfig].appId forKey:@"aid"];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    
    if (extraParams != nil) {
        [bizContentParams addEntriesFromDictionary:extraParams];
    }
    
    [bizContentParams cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:bizContentParams]
                            forKey:@"secure_request_params"];
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    
    return [requestParams copy];

}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/query_biometrics_pay_status";
}

@end
