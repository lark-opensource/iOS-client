//
//  CJPayMemProtocolListRequest.m
//  Pods
//
//  Created by xiuyuanLee on 2020/10/13.
//

#import "CJPayMemProtocolListRequest.h"

#import "CJPayMemProtocolListResponse.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayMemProtocolListRequest

+ (void)startWithBizParams:(NSDictionary *)bizParams completion:(void (^)(NSError * _Nonnull, CJPayMemProtocolListResponse * _Nonnull))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:bizParams];
    
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayMemProtocolListResponse *response = [[CJPayMemProtocolListResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock,error,response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/query_protocol_list";
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionaryWithDictionary:bizParams];
    
    [requestParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:[bizParams cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    
    return [requestParams copy];
}

@end
