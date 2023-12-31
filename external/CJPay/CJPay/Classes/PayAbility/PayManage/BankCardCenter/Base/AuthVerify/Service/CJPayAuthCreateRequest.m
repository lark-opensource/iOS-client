//
//  CJPayAuthCreateRequest.m
//  CJPay
//
//  Created by wangxiaohong on 2020/5/26.
//

#import "CJPayAuthCreateRequest.h"

#import "CJPayAuthCreateResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayAuthCreateRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams
                completion:(void (^)(NSError * _Nonnull, CJPayAuthCreateResponse * _Nonnull))completionBlock
{
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    
    [self startRequestWithUrl:[self deskServerUrlString] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayAuthCreateResponse *response = [[CJPayAuthCreateResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams
{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContentParams cj_setObject:@"tp.customer.api_create_authorization" forKey:@"method"];
    [bizContentParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [bizContentParams cj_setObject:[bizParams cj_objectForKey:@"authorize_item"] forKey:@"authorize_item"];
    
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:@"tp.customer.api_create_authorization" forKey:@"method"];
    return [requestParams copy];
}

@end
