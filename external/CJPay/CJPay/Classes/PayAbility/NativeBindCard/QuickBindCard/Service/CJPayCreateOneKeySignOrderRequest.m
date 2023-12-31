//
//  CJPayCreateOneKeySignOrderRequest.m
//  Pods
//
//  Created by 王新华 on 2020/10/14.
//

#import "CJPayCreateOneKeySignOrderRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayCreateOneKeySignOrderResponse.h"
#import "CJPayRequestParam.h"

@implementation CJPayCreateOneKeySignOrderRequest

+ (void)startRequestWithParams:(NSDictionary *)params completion:(void (^)(NSError * _Nonnull, CJPayCreateOneKeySignOrderResponse * _Nonnull))completionBlock {
    
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:params];
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        CJPayCreateOneKeySignOrderResponse *response = [[CJPayCreateOneKeySignOrderResponse alloc] initWithDictionary:jsonObj error:nil];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/create_one_key_sign_order";
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams
{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:bizParams];
    NSDictionary *riskDict = [NSDictionary dictionaryWithObject:[CJPayRequestParam riskInfoDict] forKey:@"risk_str"];
    [bizContentParams cj_setObject:riskDict forKey:@"risk_info"];
    
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

@end
