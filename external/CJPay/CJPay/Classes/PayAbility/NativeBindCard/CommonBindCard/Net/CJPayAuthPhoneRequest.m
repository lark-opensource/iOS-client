//
//  CJPayAuthPhoneRequest.m
//  Pods
//
//  Created by wangxiaohong on 2020/10/25.
//

#import "CJPayAuthPhoneRequest.h"

#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"
#import "CJPaySDKMacro.h"

@implementation CJPayAuthPhoneResponse

+ (JSONKeyMapper *)keyMapper {
    NSMutableDictionary *dict = [self basicDict];
    [dict addEntriesFromDictionary:@{@"mobile" : @"response.mobile",
                                    }];
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[dict copy]];
}

@end

@implementation CJPayAuthPhoneRequest

+ (void)startWithParams:(NSDictionary *)params completion:(void (^)(NSError * _Nullable, CJPayAuthPhoneResponse * _Nonnull))completionBlock
{
    NSDictionary *requestParams = [self p_buildRequestParamsWithBizParams:params];
    [self startRequestWithUrl:[self deskServerUrlString] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayAuthPhoneResponse *response = [[CJPayAuthPhoneResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock,error,response);
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithBizParams:(NSDictionary *)bizParams
{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:@(YES) forKey:@"need_plain"];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    
    if ([[bizParams allKeys] containsObject:@"need_encrypt"]) {
        [bizContentParams cj_setObject:[bizParams cj_objectForKey:@"need_encrypt"] forKey:@"need_encrypt"];
    }
    
    [requestParams cj_setObject:[bizContentParams cj_toStr] forKey:@"biz_content"];
    [requestParams cj_setObject:[bizParams cj_objectForKey:@"merchant_id"] forKey:@"merchant_id"];
    [requestParams cj_setObject:[bizParams cj_objectForKey:@"app_id"] forKey:@"app_id"];
    [requestParams cj_setObject:@"tp.passport.query_mobile_by_uid" forKey:@"method"];

    return [requestParams copy];
}

@end
