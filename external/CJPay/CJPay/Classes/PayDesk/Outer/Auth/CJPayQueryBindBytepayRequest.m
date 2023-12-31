//
//  CJPayQueryBindBytepayRequest.m
//  Pods
//
//  Created by 徐天喜 on 2022/8/31.
//

#import "CJPayQueryBindBytepayRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayBaseRequest+BDPay.h"
#import "CJPayQueryBindBytepayResponse.h"
#import "CJPayRequestParam.h"

@implementation CJPayQueryBindBytepayRequest

+ (void)startWithAppId:(NSString *)appId
              bizParam:(NSDictionary *)bizParam
            completion:(void (^)(NSError * _Nonnull, CJPayQueryBindBytepayResponse * _Nonnull))completion {
    NSDictionary *requestParam = [self p_buildParamWithAppId:appId bizParam:bizParam];
    [self startRequestWithUrl:[self deskServerUrlString] requestParams:requestParam callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayQueryBindBytepayResponse *response = [[CJPayQueryBindBytepayResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completion, error, response);
    }];
}

+ (NSDictionary *)p_buildParamWithAppId:(NSString *)appId
                               bizParam:(NSDictionary *)bizParam {
    NSMutableDictionary *param = [self buildBaseParams];
    [param cj_setObject:appId forKey:@"app_id"];
    [param cj_setObject:@"tp.customer.bind_bytepay" forKey:@"method"];
    NSMutableDictionary *bizContent = [bizParam mutableCopy];
    [bizContent cj_setObject:[CJPayRequestParam commonDeviceInfoDic] forKey:@"dev_info"];
    
    NSDictionary *riskInfo = [CJPayRequestParam riskInfoDict];
    [bizContent cj_setObject:[CJPayCommonUtil dictionaryToJson:riskInfo] forKey:@"risk_info"];
    [param cj_setObject:[CJPayCommonUtil dictionaryToJson:bizContent] forKey:@"biz_content"];
    
    return param;
}

@end
