//
//  CJPayIAPConfigRequest.m
//  Aweme
//
//  Created by bytedance on 2022/12/16.
//

#import "CJPayIAPConfigRequest.h"
#import "CJPayIAPConfigResponse.h"
#import "CJPaySDKMacro.h"
#import "CJPayRequestParam.h"

@implementation CJPayIAPConfigRequest

+ (void)startRequest:(NSDictionary *)params
          completion:(void(^)(NSError *error, CJPayIAPConfigResponse *response))completionBlock {
    NSDictionary *requestParams = [self buildWithParms:params];
    [self startRequestWithUrl:[self p_buildServerUrl]
                requestParams:requestParams
                     callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayIAPConfigResponse *response = [[CJPayIAPConfigResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSString *)p_buildServerUrl {
    return [NSString stringWithFormat:@"%@/%@",[self deskServerUrlString],@"cd-trade-IapConfig"];
}

+ (NSDictionary *)buildWithParms: (NSDictionary *)params {
    NSMutableDictionary *requestParams = [self buildBaseParamsWithVersion:@"3.0" needTimestamp:NO];
    [requestParams cj_setObject:@"tp.subscribe.IapConfig" forKey:@"method"];
    [requestParams cj_setObject:[params cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    
    NSMutableDictionary *bizContent = [NSMutableDictionary new];
    [bizContent addEntriesFromDictionary:params];
    [bizContent cj_setObject:[CJPayRequestParam commonDeviceInfoDic] forKey:@"dev_info"];
    [bizContent cj_setObject:[params cj_stringValueForKey:@"merchant_id"] forKey:@"merchant_id"];
    [bizContent cj_setObject:[params cj_stringValueForKey:@"app_id"] forKey:@"app_id"];
    [bizContent cj_setObject:[params cj_stringValueForKey:@"uid"] forKey:@"uid"];
    
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
