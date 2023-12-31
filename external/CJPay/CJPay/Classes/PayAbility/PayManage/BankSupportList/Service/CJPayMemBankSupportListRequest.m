//
//  CJPayMemBankSupportListRequest.m
//  Pods
//
//  Created by 尚怀军 on 2020/2/19.
//

#import "CJPayMemBankSupportListRequest.h"
#import "CJPayMemBankSupportListResponse.h"
#import "CJPayUIMacro.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"

@implementation CJPayMemBankSupportListRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
     specialMerchantId:(NSString *)specialMerchantId
           signOrderNo:(NSString *)signOrderNo
            completion:(void (^)(NSError * _Nullable, CJPayMemBankSupportListResponse * _Nonnull))completionBlock {
    [self startWithAppId:appId
              merchantId:merchantId
       specialMerchantId:specialMerchantId
             signOrderNo:signOrderNo
                    exts:@{}
              completion:completionBlock];

}

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
     specialMerchantId:(NSString *)specialMerchantId
           signOrderNo:(NSString *)signOrderNo
                  exts:(NSDictionary *)exts
            completion:(void (^)(NSError * _Nullable, CJPayMemBankSupportListResponse * _Nonnull))completionBlock {
    NSDictionary *requestParam = [self p_buildRequestParams:appId
                                                 merchantId:merchantId
                                          specialMerchantId:specialMerchantId
                                                signOrderNo:signOrderNo
                                                       exts:exts];

    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParam callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayMemBankSupportListResponse *response = [[CJPayMemBankSupportListResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
     specialMerchantId:(NSString *)specialMerchantId
           signOrderNo:(NSString *)signOrderNo
             queryType:(NSString *)queryType
            completion:(void (^)(NSError * _Nullable, CJPayMemBankSupportListResponse * _Nonnull))completionBlock {
    NSDictionary *requestParam = [self p_buildRequestParams:appId
                                                 merchantId:merchantId
                                          specialMerchantId:specialMerchantId
                                                signOrderNo:signOrderNo
                                                  queryType:queryType
                                                       exts:nil];

    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParam callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayMemBankSupportListResponse *response = [[CJPayMemBankSupportListResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

//构造参数
+ (NSDictionary *)p_buildRequestParams:(NSString *)appId
                            merchantId:(NSString *)merchantId
                     specialMerchantId:(NSString *)specialMerchantId
                           signOrderNo:(NSString *)signOrderNo
                                  exts:(NSDictionary *)exts
{
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [requestParams cj_setObject:CJString(appId) forKey:@"app_id"];
    [requestParams cj_setObject:CJString(merchantId) forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    
    [bizParams cj_setObject:CJString(signOrderNo) forKey:@"sign_order_no"];
    [bizParams cj_setObject:CJString(specialMerchantId) forKey:@"smch_id"];
    
    NSString *promotionTag = [exts cj_stringValueForKey:@"promotion_experiment_tag"];
    NSString *promotionStr = @"";
    if ([promotionTag isEqualToString:@"0"]) {
        promotionStr = @"compared";
    } else if ([promotionTag isEqualToString:@"1"]) {
        promotionStr = @"experimentOne";
    } else if ([promotionTag isEqualToString:@"2"]) {
        promotionStr = @"experimentTwo";
    }
    
    if (Check_ValidString(promotionStr)) {
        NSMutableDictionary *mutableDict = [NSMutableDictionary dictionaryWithDictionary:exts];
        [mutableDict cj_setObject:promotionStr forKey:@"promotion_experiment_tag"];
        exts = [mutableDict copy];
    }
    
    [bizParams cj_setObject:CJString([exts cj_toStr]) forKey:@"exts"];

    //风控相关参数
    [bizParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    
    NSString * bizContent = [CJPayCommonUtil dictionaryToJson:bizParams];
    [requestParams cj_setObject:bizContent forKey:@"biz_content"];
    
    return [requestParams copy];
}

+ (NSDictionary *)p_buildRequestParams:(NSString *)appId
                            merchantId:(NSString *)merchantId
                     specialMerchantId:(NSString *)specialMerchantId
                           signOrderNo:(NSString *)signOrderNo
                             queryType:(NSString *)queryType
                                  exts:(NSString *)exts {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    [requestParams cj_setObject:CJString(appId) forKey:@"app_id"];
    [requestParams cj_setObject:CJString(merchantId) forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    NSMutableDictionary *bizParams = [NSMutableDictionary dictionary];
    
    [bizParams cj_setObject:CJString(signOrderNo) forKey:@"sign_order_no"];
    [bizParams cj_setObject:CJString(specialMerchantId) forKey:@"smch_id"];
    [bizParams cj_setObject:CJString(exts) forKey:@"exts"];
    [bizParams cj_setObject:CJString(queryType) forKey:@"bank_query_type"];

    //风控相关参数
    [bizParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    
    NSString * bizContent = [CJPayCommonUtil dictionaryToJson:bizParams];
    [requestParams cj_setObject:bizContent forKey:@"biz_content"];
    
    return [requestParams copy];
}

+ (NSString *)apiPath {
    return @"/bytepay/member_product/get_bank_list";
}

@end
