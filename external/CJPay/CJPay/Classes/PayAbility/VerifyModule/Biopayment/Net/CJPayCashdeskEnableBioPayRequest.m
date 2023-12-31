//
//  CJPayCashdeskEnableBioPayRequest.m
//  Pods
//
//  Created by 利国卿 on 2021/7/28.
//

#import "CJPayCashdeskEnableBioPayRequest.h"
#import "CJPayEnvManager.h"
#import "CJPaySafeManager.h"
#import "CJPayRequestParam.h"
#import "CJPayUIMacro.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPaySafeUtil.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayBioManager.h"

@implementation CJPayCashdeskEnableBioPayResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
               @"tokenFileStr" : @"response.token_file_str",
               @"buttonInfo": @"response.button_info"
       }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end


@implementation CJPayCashdeskEnableBioPayRequest

+ (void)startWithModel:(NSDictionary *)requestModel
       withExtraParams:(NSDictionary *)extraParams
            completion:(void(^)(NSError *error, CJPayCashdeskEnableBioPayResponse *response, BOOL result))completion{
    
    NSDictionary *requestParams = [self p_buildRequestParams: requestModel withExtraParams: extraParams];
    
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayCashdeskEnableBioPayResponse *response = [[CJPayCashdeskEnableBioPayResponse alloc] initWithDictionary:jsonObj error:&err];
        NSString *tokenStr = [CJPaySafeUtil objDecryptContentFromH5:response.tokenFileStr engimaEngine:[requestModel cj_objectForKey:@"engimaEngine"]];
        CJPayBioSafeModel *model = [[CJPayBioSafeModel alloc] initWithTokenFile:tokenStr];
        BOOL result = NO;
        if ([response isSuccess] && [model isValid]) {
            [CJPayBioManager saveTokenStrInKey:tokenStr uid:[requestModel cj_objectForKey:@"uid"]];
            result = YES;
        }
        CJ_CALL_BLOCK(completion, error, response, result);
    }];
}

+ (NSDictionary *)p_buildRequestParams:(NSDictionary *)model
                       withExtraParams:(NSDictionary *)extraParams{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [requestParams cj_setObject:[model cj_objectForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[model cj_objectForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams cj_setObject:@"MD5" forKey:@"sign_type"];
    [requestParams cj_setObject:@"" forKey:@"sign"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:[CJPayRequestParam commonDeviceInfoDic] forKey:@"dev_info"];
    
    NSDictionary *processInfo = [extraParams cj_objectForKey:@"process_info"];
    [bizContentParams cj_setObject:processInfo forKey:@"process_info"];
    
    NSString *tradeNo = [[extraParams cj_objectForKey:@"exts"] cj_objectForKey:@"trade_no"];
    NSString *safeTradeNo = [NSString stringWithFormat:@"%@%@", tradeNo,[processInfo cj_objectForKey:@"process_id"]];
    [bizContentParams cj_setObject:[CJPaySafeUtil objEncryptField:safeTradeNo engimaEngine:[model cj_objectForKey:@"engimaEngine"]] forKey:@"trade_no"];
    
    NSString *pwdType = [extraParams cj_objectForKey:@"pwd_type"];
    [bizContentParams cj_setObject:pwdType forKey:@"pwd_type"];
    
    [bizContentParams cj_setObject:@"" forKey:@"exts"];
    
    [bizContentParams cj_setObject:[self p_secureRequestParams:bizContentParams] forKey:@"secure_request_params"];
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    
    return [requestParams copy];
}

+ (NSDictionary *)p_secureRequestParams:(NSDictionary *)contentDic{
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    [dic cj_setObject:@"1" forKey:@"check"];
    NSMutableArray *fields = [NSMutableArray array];
    if ([contentDic valueForKeyPath:@"trade_no"]) {
        [fields addObject:@"trade_no"];
    }
    [dic cj_setObject:fields forKey:@"fields"];
    return dic;
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/enable_biometrics_pay";
}

@end
