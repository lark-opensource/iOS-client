//
//  CJPayDyPayCreateOrderRequest.m
//  Pods
//
//  Created by xutianxi on 2022/09/28
//

#import "CJPayDyPayCreateOrderRequest.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayRequestParam.h"
#import "CJPaySDKMacro.h"

static NSString *const kIsSignDownGrade = @"is_sign_downgrade";

@implementation CJPayDyPayCreateOrderRequest

+ (void)startWithMerchantId:(NSString *)merchantId
                  bizParams:(NSDictionary *)bizParams
                 completion:(void(^)(NSError *error, CJPayBDCreateOrderResponse *response))completionBlock {
    
    [self startWithMerchantId:merchantId bizParams:bizParams highPriority:NO completion:completionBlock];
}

+ (void)startWithMerchantId:(NSString *)merchantId
                  bizParams:(NSDictionary *)bizParams
               highPriority:(BOOL)highPriority
                 completion:(void(^)(NSError *error, CJPayBDCreateOrderResponse *response))completionBlock {
    __auto_type callbackBlock = ^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayBDCreateOrderResponse *response = [[CJPayBDCreateOrderResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    };
    
    NSDictionary *requestParams = [self buildRequestParamsWithMerchantId:merchantId
                                                                 bizParams:bizParams];
    if (highPriority) {
        [self startRequestWithUrl:[self buildDyPayServerUrl] method:@"POST" requestParams:requestParams headerFields:@{} serializeType:CJPayRequestSerializeTypeURLEncode callback:^(NSError * _Nullable error, id  _Nullable jsonObj) {
            CJ_CALL_BLOCK(callbackBlock, error, jsonObj);
        } needCommonParams:YES highPriority:YES];
    } else {
        [self startRequestWithUrl:[self buildDyPayServerUrl]
                    requestParams:requestParams
                         callback:^(NSError *error, id jsonObj) {
            CJ_CALL_BLOCK(callbackBlock, error, jsonObj);
        }];
    }
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/out_pre_trade_info_query";
}

//构造参数
+ (NSDictionary *)buildRequestParamsWithMerchantId:(NSString *)merchantId
                                         bizParams:(NSDictionary *)bizParams {
    NSMutableDictionary *requestParams = [self buildBaseParams];
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:[self p_buildBizParamsWithParams:bizParams]];
    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    if (Check_ValidString(merchantId)) {
        [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    }
//    [requestParams addEntriesFromDictionary:[self apiMethod]];
    [requestParams addEntriesFromDictionary:@{@"method" : @"bytepay.cashdesk.out_pre_trade_info_query"}];
//    [requestParams cj_setObject:@"bytepay.cashdesk.outer_pre_trade_info_query" forKey:@"method"];
    return [requestParams copy];
}

+ (NSDictionary *)p_buildBizParamsWithParams:(NSDictionary *)params
{
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    NSMutableDictionary *riskInfo = [NSMutableDictionary dictionaryWithDictionary:[CJPayRequestParam riskInfoDictWithFinanceRiskWithPath:[self apiPath]]];
    NSString *refer = [params cj_stringValueForKey:@"refer_url"];
    if (Check_ValidString(refer)) {
        [riskInfo addEntriesFromDictionary:@{@"refer":refer}];
    }
    NSDictionary *riskDict = @{@"risk_str":riskInfo};
    [bizContentParams cj_setObject:riskDict forKey:@"risk_info"];
    [bizContentParams cj_setObject:@"cashdesk.out.pay.create" forKey:@"method"];
    BOOL isSignDowngrade = [params cj_boolValueForKey:kIsSignDownGrade];
    [bizContentParams cj_setObject:@(isSignDowngrade) forKey:kIsSignDownGrade];
    NSString *invokeSource = [params cj_stringValueForKey:@"invoke_source"];
    NSMutableDictionary *mtbParams = [NSMutableDictionary dictionaryWithDictionary:params];
    if (Check_ValidString(invokeSource)) {
        [mtbParams removeObjectForKey:@"invoke_source"];
        [bizContentParams addEntriesFromDictionary:@{
            @"exts" : @{@"invoke_source":invokeSource}
        }];
    }
    [bizContentParams cj_setObject:[CJPayCommonUtil dictionaryToJson:mtbParams] forKey:@"params"];

    return bizContentParams;
}

@end
