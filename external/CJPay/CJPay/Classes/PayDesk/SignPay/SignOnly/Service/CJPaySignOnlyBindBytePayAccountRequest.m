//
//  CJPaySignOnlyBindBytePayAccountRequest.m
//  CJPay-1ab6fc20
//
//  Created by wangxiaohong on 2022/9/19.
//

#import "CJPaySignOnlyBindBytePayAccountRequest.h"

#import "CJPaySignOnlyBindBytePayAccountResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"
#import "CJPayPassKitSafeUtil.h"

@implementation CJPaySignOnlyBindBytePayAccountRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPaySignOnlyBindBytePayAccountResponse *response))completionBlock {
    NSDictionary *requestParams = [self buildRequestParamsWithBizParams: bizParams];
    
    [self startRequestWithUrl:[NSString stringWithFormat:@"%@/%@", [self buildServerUrl], @"bytepay/member_product/bind_byte_pay_account"] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        if ([jsonObj isKindOfClass:NSDictionary.class]) {
            CJPaySignOnlyBindBytePayAccountResponse *response = [[CJPaySignOnlyBindBytePayAccountResponse alloc] initWithDictionary:jsonObj error:&err];
            CJ_CALL_BLOCK(completionBlock, error, response);
        } else {
            CJ_CALL_BLOCK(completionBlock, error, nil);
        }
    }];
}

//构造参数
+ (NSDictionary *)buildRequestParamsWithBizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"2.0" needTimestamp:NO];
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    if (bizParams.count > 0) {
        [bizContentParams addEntriesFromDictionary:bizParams];
    }
    
    [bizContentParams cj_setObject:[CJPayPassKitSafeUtil pMemberSecureRequestParams:bizContentParams] forKey:@"secure_request_params"];
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:@"bytepay.member_product.bind_byte_pay_account" forKey:@"method"];
    [requestParams addEntriesFromDictionary:bizParams];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDict]] forKey:@"risk_info"];
    return [requestParams copy];
}

@end
