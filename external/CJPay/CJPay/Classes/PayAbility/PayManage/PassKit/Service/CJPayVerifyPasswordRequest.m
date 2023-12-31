//
//  CJPayVerifyPasswordRequest.m
//  CJPay
//
//  Created by 王新华 on 2019/5/20.
//

#import "CJPayVerifyPasswordRequest.h"
#import "CJPayUIMacro.h"
#import "CJPaySafeManager.h"
#import "CJPayRequestParam.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPaySafeUtil.h"
#import "CJPayBaseRequest+BDPay.h"

@implementation CJPayVerifyPasswordRequest

+ (void)startWithParams:(NSDictionary *)params completion:(void (^)(NSError * _Nonnull, CJPayVerifyPassCodeResponse * _Nonnull))completion {
    
    NSMutableDictionary *bizContent = [params mutableCopy];
    [bizContent cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContent cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:bizContent] forKey:@"secure_request_params"];
    
    NSMutableDictionary *requestParams = [params mutableCopy];
    [requestParams addEntriesFromDictionary:[self buildBaseParams]];
    [requestParams cj_setObject:CJString([bizContent cj_toStr]) forKey:@"biz_content"];
    
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:[requestParams copy] callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayVerifyPassCodeResponse *response = [[CJPayVerifyPassCodeResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/verify_password";
}

@end
