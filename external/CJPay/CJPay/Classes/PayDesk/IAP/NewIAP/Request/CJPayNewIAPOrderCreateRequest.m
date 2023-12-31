//
//  CJPayNewIAPOrderCreateRequest.m
//  Pods
//
//  Created by 尚怀军 on 2022/3/7.
//

#import "CJPayNewIAPOrderCreateRequest.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayNewIAPOrderCreateRequest

+ (void)startRequest:(NSString *)appid
              params:(NSDictionary *)params
                exts:(NSDictionary *)extParams
          completion:(void(^)(NSError *error, CJPayNewIAPOrderCreateResponse *response))completionBlock {
    NSDictionary *requestParams = [self buildParams:appid
                                             params:params
                                          extParams:extParams];
    [self startRequestWithUrl:[self p_buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayNewIAPOrderCreateResponse *response = [[CJPayNewIAPOrderCreateResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)p_buildServerUrl {
    return [NSString stringWithFormat:@"%@/%@",[self deskServerUrlString],@"cd-trade-newcreate"];
}

+ (NSDictionary *)buildParams:(NSString *)appid
                       params: (NSDictionary *)params
                    extParams:(NSDictionary *)extParams {
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"3.0" needTimestamp:NO];
    [requestParams cj_setObject:appid forKey:@"app_id"];
    [requestParams cj_setObject:@"tp.subscribe.IapNewCreateOrder" forKey:@"method"];
    
    NSMutableDictionary *bizContent = [NSMutableDictionary new];
    [bizContent cj_setObject:@"cashdesk.sdk.pay.create" forKey:@"method"];
    [bizContent cj_setObject:@"2.0" forKey:@"version"];
    [bizContent cj_setObject:[CJPayRequestParam getRiskInfoParams] forKey:@"risk_info"];
    [bizContent cj_setObject:params forKey:@"params"];
    [bizContent cj_setObject:extParams forKey:@"exts"];
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
