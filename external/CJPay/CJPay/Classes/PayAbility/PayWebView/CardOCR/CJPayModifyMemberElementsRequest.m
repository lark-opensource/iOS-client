//
//  CJPayModifyMemberElementsRequest.m
//  CJPay
//
//  Created by youerwei on 2022/6/22.
//

#import "CJPayModifyMemberElementsRequest.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"

@implementation CJPayModifyMemberElementsRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams completion:(void (^)(NSError * _Nonnull, CJPayModifyMemberElementsResponse * _Nonnull))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayModifyMemberElementsResponse *response = [[CJPayModifyMemberElementsResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [bizParams mutableCopy];
    [bizContentParams cj_setObject:[CJPayRequestParam getMergeRiskInfoWithBizParams:bizParams] forKey:@"risk_info"];
    
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/modify_member_elements";
}

@end
