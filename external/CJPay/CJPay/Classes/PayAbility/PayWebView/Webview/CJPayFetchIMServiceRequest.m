//
//  CJPayFetchIMServiceRequest.m
//  Pods
//
//  Created by youerwei on 2021/11/24.
//

#import "CJPayFetchIMServiceRequest.h"
#import "CJPayUIMacro.h"
#import "CJPayFetchIMServiceResponse.h"

@implementation CJPayFetchIMServiceRequest

+ (void)startWithAppID:(NSString *)appID completion:(void (^)(NSError * error, CJPayFetchIMServiceResponse * response))completionBlock {
    NSDictionary *requestParams = [self p_buildRequestParamsWithAppID:appID];
    [self startRequestWithUrl:[self deskServerUrlString] requestParams:requestParams callback:^(NSError *error, id jsonObj) {
        NSError *err = nil;
        CJPayFetchIMServiceResponse *response = [[CJPayFetchIMServiceResponse alloc] initWithDictionary:jsonObj error:&err];
        CJ_CALL_BLOCK(completionBlock, error, response);
    }];
}

+ (NSDictionary *)p_buildRequestParamsWithAppID:(NSString *)appID {
    NSMutableDictionary *params = [self buildBaseParams];
    [params cj_setObject:CJString(appID) forKey:@"app_id"];
    [params cj_setObject:@"tp.customer.get_link_chat_url" forKey:@"method"];
    [params cj_setObject:@"MD5" forKey:@"sign_type"];
    NSMutableDictionary *bizParam = [NSMutableDictionary new];
    [params cj_setObject:[bizParam cj_toStr] forKey:@"biz_content"];
    return params;
}

@end
