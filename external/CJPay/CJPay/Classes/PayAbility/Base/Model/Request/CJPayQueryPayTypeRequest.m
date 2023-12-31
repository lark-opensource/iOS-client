//
//  CJPayQueryPayTypeRequest.m
//  Pods
//
//  Created by wangxiaohong on 2021/7/2.
//

#import "CJPayQueryPayTypeRequest.h"

#import "CJPaySDKMacro.h"
#import "CJPayBDCreateOrderResponse.h"
#import "CJPayRequestParam.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayIntegratedChannelModel.h"
#import "CJPayQueryPayTypeResponse.h"

@implementation CJPayQueryPayTypeRequest

+ (void)startWithParams:(NSDictionary *)params completion:(nonnull void (^)(NSError * _Nonnull, CJPayQueryPayTypeResponse * _Nonnull))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestWithParams:params];
    
    [self startRequestWithUrl:[self buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayQueryPayTypeResponse *response = [[CJPayQueryPayTypeResponse alloc] initWithDictionary:jsonObj error:&err];
        
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/query_pay_type";
}

+ (NSDictionary *)p_buildRequestWithParams:(NSDictionary *)params {
    NSString *appId = [params cj_stringValueForKey:@"app_id"];
    NSString *merchantId = [params cj_stringValueForKey:@"merchant_id"];
    NSDictionary *processInfo = [params cj_dictionaryValueForKey:@"process_info"];
    NSDictionary *preTradeParams = [params cj_dictionaryValueForKey:@"pre_trade_params"];
    
    NSMutableDictionary *requestParams = [self buildBaseParams];
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary new];
    [bizContentParams setObject:processInfo ?: @{} forKey:@"process_info"];
    if (Check_ValidDictionary(preTradeParams)) {
        [bizContentParams cj_setObject:preTradeParams ?: @{} forKey:@"pre_trade_params"];
    }
    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:bizContentParams];

    [requestParams cj_setObject:CJString(bizContentString) forKey:@"biz_content"];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return [requestParams copy];
}

@end
