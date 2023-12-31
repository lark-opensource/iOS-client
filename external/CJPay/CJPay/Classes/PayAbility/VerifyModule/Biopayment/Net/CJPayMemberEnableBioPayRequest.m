//
//  CJPayMemberEnableBioPayRequest.m
//  BDPay
//
//  Created by 易培淮 on 2020/7/17.
//

#import "CJPayMemberEnableBioPayRequest.h"
#import "CJPayEnvManager.h"
#import "CJPaySafeManager.h"
#import "CJPayRequestParam.h"
#import "CJPayUIMacro.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPaySafeUtil.h"
#import "CJPayBaseRequest+BDPay.h"

@implementation CJPayBioSafeModel

- (instancetype)initWithTokenFile:(NSString *)tokenFile {
    self = [super init];
    if (!tokenFile || tokenFile.length < 1) {
        return self;
    }
    NSArray<NSString *> *datas = [tokenFile componentsSeparatedByString:@"|"];
    if (datas.count != 9) {
        return self;
    }
    self.magicStr = [datas btd_objectAtIndex:0];
    self.version = [datas btd_objectAtIndex:1];
    self.serialNum = [datas btd_objectAtIndex:2];
    self.seedHexString = [datas btd_objectAtIndex:3];
    self.vendor = [datas btd_objectAtIndex:4];
    if ([datas btd_objectAtIndex:5].length >= 1) {
        self.tokenLength = [[datas btd_objectAtIndex:5] substringFromIndex:1].integerValue;
    }
    self.expireTime = [datas btd_objectAtIndex:6];
    self.timeStep = [datas btd_objectAtIndex:7].integerValue;
    self.pwdType = [datas btd_objectAtIndex:8].integerValue;
    return self;
}

- (BOOL)isValid {
    return (
            Check_ValidString(self.magicStr)
            && Check_ValidString(self.version)
            && Check_ValidString(self.vendor)
            && Check_ValidString(self.seedHexString)
            && Check_ValidString(self.expireTime)
            && (self.pwdType == 1 || self.pwdType == 2)
            && (self.tokenLength == 6 || self.tokenLength == 8)
            && (self.timeStep <= 60 && self.timeStep >= 30)
            );
}

@end

@implementation CJPayMemberEnableBioPayResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{
               @"tokenFileStr" : @"response.token_file_str",
               @"buttonInfo": @"response.button_info"
       }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

@end


@implementation CJPayMemberEnableBioPayRequest

+ (void)startWithModel:(CJPayBioPaymentBaseRequestModel *)requestModel
       withExtraParams:(NSDictionary *)extraParams
            completion:(void(^)(NSError *error, CJPayMemberEnableBioPayResponse *response))completion{
    
    NSDictionary *requestParams = [self p_buildRequestParams: requestModel withExtraParams: extraParams];
    
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayMemberEnableBioPayResponse *response = [[CJPayMemberEnableBioPayResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

+ (NSDictionary *)p_buildRequestParams:(CJPayBioPaymentBaseRequestModel *)model
                       withExtraParams:(NSDictionary *)extraParams{
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"1.0" needTimestamp:NO];
    [requestParams cj_setObject:model.appId forKey:@"app_id"];
    [requestParams cj_setObject:model.merchantId forKey:@"merchant_id"];
    [requestParams cj_setObject:CJString(model.signType) forKey:@"sign_type"];
    [requestParams cj_setObject:CJString(model.timestamp) forKey:@"timestamp"];
    [requestParams cj_setObject:CJString(model.sign) forKey:@"sign"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    
    [bizContentParams cj_setObject:model.uid forKey:@"uid"]; //交易单号
    [bizContentParams cj_setObject:model.merchantId forKey:@"merchant_id"]; //商户号
    [bizContentParams cj_setObject:model.appId forKey:@"app_id"];
   
    [bizContentParams cj_setObject:[CJPayRequestParam gAppInfoConfig].appId forKey:@"aid"];
    
    NSString *isJailBroken = [[CJPayEnvManager shared] isSafeEnv] ? @"false" : @"true";
    [bizContentParams cj_setObject:isJailBroken forKey:@"is_jail_broken"];
    
    if (Check_ValidString(model.memberBizOrderNo)) {
        [bizContentParams cj_setObject:model.memberBizOrderNo forKey:@"member_biz_order_no"];
    }
    
    if (extraParams != nil) {
        [bizContentParams addEntriesFromDictionary:extraParams];
    }
    
    [bizContentParams cj_setObject:[CJPayRequestParam getMergeRiskInfoWithBizParams:bizContentParams] forKey:@"risk_info"];
    
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    [dic addEntriesFromDictionary:[CJPaySafeManager secureInfo]];
    NSMutableArray *fields = [NSMutableArray array];
    
    if ([[bizContentParams allKeys] containsObject:@"key"]) {
        [fields btd_addObject:@"key"];
    } else if ([[bizContentParams allKeys] containsObject:@"mobile_pwd"]) {
        [fields btd_addObject:@"mobile_pwd"];
    }
    
    [dic cj_setObject:fields forKey:@"fields"];
    [bizContentParams cj_setObject:dic forKey:@"secure_request_params"];
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    
    return [requestParams copy];

}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/enable_biometrics_pay";
}

@end
