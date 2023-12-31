//
//  CJPayUnlockBankCardRequest.m
//  Aweme
//
//  Created by youerwei on 2023/6/7.
//

#import "CJPayUnlockBankCardRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayBaseResponse.h"

@implementation CJPayUnlockBankCardRequest

+ (void)startRequestWithBizParam:(NSDictionary *)bizParam completion:(void (^)(NSError *error, CJPayBaseResponse * _Nonnull))completion {
    NSDictionary *param = [self p_requestParamWithBizParam:bizParam];
    [self startRequestWithUrl:[self buildServerUrl] requestParams:param callback:^(NSError * _Nullable error, id  _Nullable jsonObj) {
        NSError *err = nil;
        CJPayBaseResponse *response = [[CJPayBaseResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completion, err, response);
    }];
}

+ (NSDictionary *)p_requestParamWithBizParam:(NSDictionary *)bizParam {
    NSMutableDictionary *baseParam = [self buildBaseParams];
    NSMutableDictionary *bizContent = bizParam.mutableCopy;
    [bizContent cj_setObject:CJPayRequestParam.getRiskInfoParams forKey:@"risk_info"];
    [bizContent cj_setObject:CJPayRequestParam.commonDeviceInfoDic forKey:@"dev_info"];
    
    NSString *appId = [bizContent cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [bizContent cj_stringValueForKey:@"merchant_id"];
    [baseParam addEntriesFromDictionary:[self apiMethod]];
    [baseParam cj_setObject:appId forKey:@"app_id"];
    [baseParam cj_setObject:merchantId forKey:@"merchant_id"];
    [baseParam cj_setObject:bizContent.cj_toStr forKey:@"biz_content"];
    return baseParam;
}

+ (NSString *)apiPath {
    return  @"/bytepay/member_product/unlock_member_bankcard";
}

@end
