//
//  CJPayQueryOneKeySignRequest.m
//  Pods
//
//  Created by 王新华 on 2020/10/14.
//

#import "CJPayQueryOneKeySignRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayQueryOneKeySignResponse.h"
#import "CJPayBaseRequest+BDPay.h"

@implementation CJPayQueryOneKeySignRequest

+ (void)startRequestWithParams:(NSDictionary *)params completion:(void (^)(NSError * _Nonnull, CJPayQueryOneKeySignResponse * _Nonnull))completionBlock
{
    [self startRequestWithUrl:[self buildServerUrl] requestParams:[self p_buildRequestParamsWithBizParams:params] callback:^(NSError *error, id jsonObj) {
           CJPayQueryOneKeySignResponse *response = [[CJPayQueryOneKeySignResponse alloc] initWithDictionary:jsonObj error:nil];
        CJ_CALL_BLOCK(completionBlock, error, response);
       }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/query_one_key_sign";
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams
{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:bizParams];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

@end
