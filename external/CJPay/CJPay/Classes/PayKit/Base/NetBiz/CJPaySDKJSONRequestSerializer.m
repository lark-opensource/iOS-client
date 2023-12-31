//
// Created by 张海阳 on 2019/10/15.
//

#import "CJPaySDKJSONRequestSerializer.h"


@implementation CJPaySDKJSONRequestSerializer

- (TTHttpRequest *)URLRequestWithRequestModel:(TTRequestModel *)requestModel
                                 commonParams:(NSDictionary *)commonParam {
    TTHttpRequest *request = [super URLRequestWithRequestModel:requestModel commonParams:commonParam];
    [self request:request setHTTPBodyWithParams:requestModel._requestParams];
    return request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest *request = [super URLRequestWithURL:URL
                                          headerField:headField
                                               params:params
                                               method:method
                                constructingBodyBlock:bodyBlock
                                         commonParams:commonParam];
    [self request:request setHTTPBodyWithParams:params];
    return request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(id)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest *request = [super URLRequestWithURL:URL
                                               params:params
                                               method:method
                                constructingBodyBlock:bodyBlock
                                         commonParams:commonParam];
    [self request:request setHTTPBodyWithParams:params];
    return request;
}

- (void)request:(TTHttpRequest *)request setHTTPBodyWithParams:(NSDictionary *)params {
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    NSError *jsonError = nil;
    if (![request.HTTPMethod isEqualToString:@"GET"]) {
        [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:params options:(NSJSONWritingOptions)0 error:&jsonError]];
    }
}

@end
