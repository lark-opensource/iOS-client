//
//  CJPaySignRequestUtil.m
//  AlipaySDK-AlipaySDKBundle
//
//  Created by 王新华 on 2022/9/14.
//

#import "CJPaySignRequestUtil.h"
#import "CJPayCommonUtil.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+CJPayCustomHost.h"

@implementation CJPaySignCreateResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicMapperWith:@{
        @"signTypeInfo": @"data",
        @"merchantInfo": @"data.merchant_info",
    }]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPaySignConfirmResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicMapperWith:@{
        @"channelData": @"data.pay_params.data",
        @"ptCode": @"data.pay_params.ptcode",
        @"tradeType": @"data.pay_params.trade_type"
    }]];
}

- (NSDictionary *)payDataDict {
    return [CJPayCommonUtil jsonStringToDictionary:self.channelData];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPaySignQueryResponse

+ (JSONKeyMapper *)keyMapper {
    return [[JSONKeyMapper alloc] initWithModelToJSONDictionary:[self basicMapperWith:@{
        @"paymentDescInfo": @"data.payment_desc_infos",
        @"ptCode": @"data.ptcode",
        @"signStatus": @"data.sign_status",
        @"signOrderStatus": @"data.sign_order_status"
    }]];
}

+ (BOOL)propertyIsOptional:(NSString *)propertyName {
    return YES;
}

@end

@implementation CJPaySignRequestUtil

+ (void)startSignCreateRequestWithParams:(NSDictionary *)params completion:(nonnull void (^)(NSError * _Nonnull, CJPaySignCreateResponse * _Nonnull))completionBlock {
    NSMutableDictionary *bizContentDic = [NSMutableDictionary new];
    [bizContentDic cj_setObject:params forKey:@"params"];
    [self startRequestWithUrl:[self p_buildSignRequestUrlWith:@"tp/cashier/sign_create"] requestParams:[self buildSignRequestParams:[bizContentDic copy]] callback:^(NSError *error, id jsonObj) {
        CJPaySignCreateResponse *response = [[CJPaySignCreateResponse alloc] initWithDictionary:jsonObj error:nil];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (void)startSignConfirmRequestWithParams:(NSDictionary *)requestParams bizContentParams:(NSDictionary *)bizContentParams completion:(nonnull void (^)(NSError * _Nonnull, CJPaySignConfirmResponse * _Nonnull))completionBlock {
    NSMutableDictionary *mutableParams = [[self buildSignRequestParams:bizContentParams] mutableCopy];
    [mutableParams addEntriesFromDictionary:requestParams];
    [self startRequestWithUrl:[self p_buildSignRequestUrlWith:@"tp/cashier/sign_confirm"] requestParams:[mutableParams copy] callback:^(NSError *error, id jsonObj) {
        CJPaySignConfirmResponse *response = [[CJPaySignConfirmResponse alloc] initWithDictionary:jsonObj error:nil];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (void)startSignQueryRequestWithParams:(NSDictionary *)requestParams completion:(nonnull void (^)(NSError * _Nonnull, CJPaySignQueryResponse * _Nonnull))completionBlock {
    NSMutableDictionary *mutableParams = [[self buildSignRequestParams:@{}] mutableCopy];
    [mutableParams addEntriesFromDictionary:requestParams];
    [self startRequestWithUrl:[self p_buildSignRequestUrlWith:@"tp/cashier/sign_query"] requestParams:[mutableParams copy] callback:^(NSError *error, id jsonObj) {
        CJPaySignQueryResponse *response = [[CJPaySignQueryResponse alloc] initWithDictionary:jsonObj error:nil];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)p_buildSignRequestUrlWith:(NSString *)path {
    return [NSString stringWithFormat:@"%@/%@", [self customDeskServerUrlString], path];
}

+ (NSDictionary *)buildSignRequestParams:(NSDictionary *)bizContent {
    NSMutableDictionary *mutableDic = [NSMutableDictionary new];
    [mutableDic cj_setObject:@"utf-8" forKey:@"charset"];
    [mutableDic cj_setObject:@"JSON" forKey:@"format"];
    [mutableDic cj_setObject:@"2.0" forKey:@"version"];
    [mutableDic cj_setObject:[CJPayCommonUtil dictionaryToJson:[CJPayRequestParam riskInfoDict]] forKey:@"risk_info"];
    [mutableDic cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContent] forKey:@"biz_content"];
    return [mutableDic copy];
}

@end
