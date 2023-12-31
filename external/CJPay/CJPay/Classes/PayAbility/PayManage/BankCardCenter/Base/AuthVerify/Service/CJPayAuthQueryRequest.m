//
//  CJPayAuthQueryRequest.m
//  CJPay
//
//  Created by wangxiaohong on 2020/5/25.
//

#import "CJPayAuthQueryRequest.h"

#import "CJPayRequestParam.h"
#import "CJPayAuthQueryResponse.h"
#import "CJPaySDKMacro.h"


@implementation CJPayAuthQueryRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams completion:(void (^)(NSError * _Nonnull, CJPayAuthQueryResponse * _Nonnull))completionBlock
{
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    
    [self startRequestWithUrl:[self deskServerUrlString] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayAuthQueryResponse *response = [[CJPayAuthQueryResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock,error,response);
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams
{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
 
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:@"tp.customer.query_auth_info" forKey:@"method"];
    [bizContentParams cj_setObject:CJString([bizParams cj_stringValueForKey:@"merchant_id"]) forKey:@"merchant_id"];
    NSDictionary *p_temp_data = [bizParams cj_dictionaryValueForKey:@"data"];
    [bizContentParams cj_setObject:CJString([p_temp_data cj_stringValueForKey:@"scene"]) forKey:@"scene"];
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:@"tp.customer.query_auth_info" forKey:@"method"];
    return [requestParams copy];
}
@end
