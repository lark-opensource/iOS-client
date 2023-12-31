//
//  TTPostDataHttpRequestSerializer.m
//  TTNetworkManager
//
//  Created by dongyangfan on 2020/2/6.
//

#import "TTPostDataHttpRequestSerializer.h"
#import "TTNetworkManagerLog.h"

@implementation TTPostDataHttpRequestSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(NSDictionary *)parameters
                              method:(NSString *)method
                constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest * request = [super URLRequestWithURL:URL params:parameters method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    
    return [self setRequestBody:request withParameters:parameters];
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest * request = [super URLRequestWithURL:URL headerField:headField params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    return [self setRequestBody:request withParameters:params];
}

- (TTHttpRequest *)setRequestBody:(TTHttpRequest *)request withParameters:(NSDictionary *)parameters {
    [request setValue:@"application/json; encoding=utf-8" forHTTPHeaderField:@"Content-Type"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    NSError *error = nil;
    if (![NSJSONSerialization isValidJSONObject:parameters]) {
        LOGE(@"parameters is not a valid json");
        return nil;
    }
    NSData * postData = [NSJSONSerialization dataWithJSONObject:parameters options:NSJSONWritingPrettyPrinted error:&error];
    if (error != nil) {
        LOGE(@"postData JSON serialization failed");
        return nil;
    }
    [request setHTTPBody:postData];
    return request;
}

@end
