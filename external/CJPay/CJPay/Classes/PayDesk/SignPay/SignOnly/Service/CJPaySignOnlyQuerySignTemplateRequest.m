//
//  CJPaySignOnlyQuerySignTemplateRequest.m
//  Pods
//
//  Created by wangxiaohong on 2022/9/9.
//

#import "CJPaySignOnlyQuerySignTemplateRequest.h"

#import "CJPaySignOnlyQuerySignTemplateResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"

@implementation CJPaySignOnlyQuerySignTemplateRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPaySignOnlyQuerySignTemplateResponse *response))completionBlock {
    NSDictionary *requestParams = [self buildRequestParamsWithBizParams: bizParams];
    
    [self startRequestWithUrl:[NSString stringWithFormat:@"%@/%@", [self buildServerUrl], @"bytepay/member_product/query_sign_template"] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        if ([jsonObj isKindOfClass:NSDictionary.class]) {
            CJPaySignOnlyQuerySignTemplateResponse *response = [[CJPaySignOnlyQuerySignTemplateResponse alloc] initWithDictionary:jsonObj error:&err];
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
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams addEntriesFromDictionary:bizParams];
    [requestParams cj_setObject:@"bytepay.member_product.query_sign_template" forKey:@"method"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDict]] forKey:@"risk_info"];
    return [requestParams copy];
}

@end
