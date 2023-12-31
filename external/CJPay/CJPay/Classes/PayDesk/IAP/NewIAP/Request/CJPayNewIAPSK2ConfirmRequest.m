//
//  CJPayNewIAPSK2ConfirmRequest.m
//  Pods
//
//  Created by 尚怀军 on 2022/3/8.
//

#import "CJPayNewIAPSK2ConfirmRequest.h"
#import "CJPayNewIAPConfirmResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayNewIAPSK2ConfirmRequest

+ (void)startRequest:(NSDictionary *)bizParams
    bizContentParams:(NSDictionary *)params
          completion:(void(^)(NSError *error, CJPayNewIAPConfirmResponse *response))completionBlock {
    NSDictionary *requestParams = [self buildWith:bizParams bizContentParms:params];
    [self startRequestWithUrl:[self p_buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayNewIAPConfirmResponse *response = [[CJPayNewIAPConfirmResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)p_buildServerUrl {
    return [NSString stringWithFormat:@"%@/%@",[self deskServerUrlString],@"cd-trade-sk2confirm"];
}

+ (NSDictionary *)buildWith:(NSDictionary *)extraBizParams bizContentParms: (NSDictionary *)params {
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"3.0" needTimestamp:NO];
    [requestParams cj_setObject:@"tp.subscribe.IapTradeConfirm" forKey:@"method"];
    [requestParams addEntriesFromDictionary:extraBizParams];
    
    NSMutableDictionary *bizContent = [NSMutableDictionary new];
    [bizContent cj_setObject:@"cashdesk.sdk.pay_iap.confirm" forKey:@"method"];
    [bizContent addEntriesFromDictionary:params];
    [bizContent cj_setObject:@"applepay_iap" forKey:@"pay_type"];
    [bizContent cj_setObject:@"APPLE_IAP_PAY" forKey:@"channel_pay_type"];
    [bizContent cj_setObject:[CJPayRequestParam commonDeviceInfoDic] forKey:@"dev_info"];
    
    [requestParams cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContent] forKey:@"biz_content"];
    
    return [requestParams copy];
}

+ (NSString *)deskServerUrlString {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
    if ([self respondsToSelector:@selector(intergratedConfigHost)]) {
        NSString *result = [self performSelector:@selector(intergratedConfigHost)];
        if (result && [result isKindOfClass:NSString.class] && Check_ValidString(result)) {
            return [NSString stringWithFormat:@"https://%@/gateway-u", result];
        }
    }
#pragma clang diagnostic pop
    return [super deskServerUrlString];
}

@end
