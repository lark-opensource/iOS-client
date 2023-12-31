//
//  CJPayCardSignRequest.m
//  CJPay
//
//  Created by wangxiaohong on 2020/3/29.
//

#import "CJPayCardSignRequest.h"

#import "CJPaySDKMacro.h"
#import "CJPayCardSignResponse.h"
#import "CJPayProcessInfo.h"
#import "CJPayRequestParam.h"

@implementation CJPayCardSignRequest

+ (void)startWithAppId:(NSString *)appId
            merchantId:(NSString *)merchantId
            bankCardId:(NSString *)bankCardId
           processInfo:(CJPayProcessInfo *)processInfo
            completion:(void (^)(NSError * _Nonnull error, CJPayCardSignResponse * _Nonnull response))completionBlock
{
    NSDictionary *requestParams = [self p_buildRequestParamsWithAppId:appId
                                                           merchantId:merchantId
                                                           bankCardId:bankCardId
                                                          processInfo:processInfo];
    [self startRequestWithUrl:[self buildServerUrl] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayCardSignResponse *response = [[CJPayCardSignResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)apiPath {
    return @"/bytepay/cashdesk/card_sign";
}

+ (NSDictionary *)p_buildRequestParamsWithAppId:(NSString *)appId
                                     merchantId:(NSString *)merchantId
                                     bankCardId:(NSString *)bankCardId
                                    processInfo:(CJPayProcessInfo *)processInfo
{
    NSMutableDictionary *requestParams = [self buildBaseParams];

    NSString *bizContentString = [CJPayCommonUtil dictionaryToJson:[self p_buildBizContentParamsWithBankCardId:bankCardId processInfo:processInfo]];
    [requestParams cj_setObject:bizContentString forKey:@"biz_content"];
    [requestParams cj_setObject:appId forKey:@"app_id"];
    [requestParams cj_setObject:merchantId forKey:@"merchant_id"];
    [requestParams addEntriesFromDictionary:[self apiMethod]];
    return requestParams;
}

+ (NSDictionary *)p_buildBizContentParamsWithBankCardId:(NSString *)bankCardId
                                         processInfo:(CJPayProcessInfo *)processInfo {
    
    NSMutableDictionary *bizContentParams = [NSMutableDictionary dictionary];
    [bizContentParams cj_setObject:CJString(bankCardId) forKey:@"bank_card_id"];
    [bizContentParams cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];

    NSDictionary *processInfoParams = [processInfo toDictionary];
    [bizContentParams cj_setObject:processInfoParams forKey:@"process_info"];
    [bizContentParams cj_setObject:@"cashdesk.sdk.user.cardsign" forKey:@"method"];
    return [bizContentParams copy];
}

@end
