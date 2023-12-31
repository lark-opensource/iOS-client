//
//  CJPaySettingPasswordRequest.m
//  CJPay
//
//  Created by 王新华 on 2019/5/20.
//

#import "CJPaySettingPasswordRequest.h"
#import "CJPayUIMacro.h"
#import "CJPaySafeManager.h"
#import "CJPayRequestParam.h"
#import "CJPayPassKitBaseResponse.h"
#import "CJPaySDKDefine.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPaySafeUtil.h"
#import "CJPayBaseRequest+BDPay.h"

@implementation CJPaySettingPasswordResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self.basicDict mutableCopy];
    [dict addEntriesFromDictionary:@{@"token": @"response.token",
                                     @"bankCardInfo": @"response.card_info"
    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:dict];
}

@end


@implementation CJPaySettingPasswordRequest

+ (void)startWithParams:(NSDictionary *)params completion:(void (^)(NSError * _Nonnull, CJPaySettingPasswordResponse * _Nonnull))completion {
    
    NSMutableDictionary *bizContent = [params mutableCopy];
    
    [bizContent cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContent cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:bizContent] forKey:@"secure_request_params"];
    
    NSMutableDictionary *requestParams = [params mutableCopy];
    [requestParams addEntriesFromDictionary:[self buildBaseParams]];
    [requestParams cj_setObject:CJString([bizContent cj_toStr]) forKey:@"biz_content"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:[requestParams copy] callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPaySettingPasswordResponse *response = [[CJPaySettingPasswordResponse alloc] initWithDictionary:jsonObj error:&err];
        if (response.isSuccess) {
            [[NSNotificationCenter defaultCenter] postNotificationName:CJPayPassCodeChangeNotification object:response];
        }
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/set_password";
}

@end
