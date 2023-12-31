//
//  CJPaySignSetMemberFirstPayTypeRequest.m
//  Pods
//
//  Created by wangxiaohong on 2022/9/9.
//

// 目前先放在payComponent里面，等signpay合到dyPay后，就放回dyPay

#import "CJPaySignSetMemberFirstPayTypeRequest.h"

#import "CJPaySignSetMemberFirstPayTypeResponse.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPaySignSetMemberFirstPayTypeRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void(^)(NSError *error, CJPaySignSetMemberFirstPayTypeResponse *response))completionBlock {
    NSDictionary *requestParams = [self buildRequestParamsWithBizParams: bizParams];
    
    [self startRequestWithUrl:[NSString stringWithFormat:@"%@/%@", [self buildServerUrl], @"bytepay/member_product/set_member_first_pay_type"] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        if ([jsonObj isKindOfClass:NSDictionary.class]) {
            CJPaySignSetMemberFirstPayTypeResponse *response = [[CJPaySignSetMemberFirstPayTypeResponse alloc] initWithDictionary:jsonObj error:&err];
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
    [requestParams cj_setObject:@"bytepay.member_product.set_member_first_pay_type" forKey:@"method"];
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDict]] forKey:@"risk_info"];
    return [requestParams copy];
}

@end
