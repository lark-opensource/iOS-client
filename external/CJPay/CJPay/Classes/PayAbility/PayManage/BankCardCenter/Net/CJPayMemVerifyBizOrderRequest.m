//
//  CJPayMemVerifyBizOrderRequest.m
//  Pods
//
//  Created by xiuyuanLee on 2020/10/13.
//

#import "CJPayMemVerifyBizOrderRequest.h"

#import "CJPayMemVerifyBizOrderResponse.h"
#import "CJPaySafeUtil.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"
#import "CJPayPassKitSafeUtil.h"
#import "CJPaySDKMacro.h"

@implementation CJPayMemVerifyBizOrderRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams completion:(void (^)(NSError * _Nonnull, CJPayMemVerifyBizOrderResponse * _Nonnull))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayMemVerifyBizOrderResponse *response = [[CJPayMemVerifyBizOrderResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/verify_identity_info";
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    NSMutableDictionary *encParams = [NSMutableDictionary dictionary];
    
    [encParams cj_setObject:[CJPaySafeUtil encryptField:[bizParams cj_stringValueForKey:@"name"]] forKey:@"name"];
    [encParams cj_setObject:[bizParams cj_stringValueForKey:@"identity_type"] forKey:@"identity_type"];
    [encParams cj_setObject:[CJPaySafeUtil encryptField:[bizParams cj_stringValueForKey:@"identity_code"]] forKey:@"identity_code"];
    
    [bizContentParams cj_setObject:encParams forKey:@"enc_params"];
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"member_biz_order_no"] forKey:@"member_biz_order_no"];
    
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:bizContentParams] forKey:@"secure_request_params"];

    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

@end
