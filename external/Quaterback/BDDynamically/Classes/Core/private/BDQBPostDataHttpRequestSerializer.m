//
//  TTTInstallIDPostDataHttpRequestSerializer.m
//  Pods
//
//  Created by fengyadong on 2017/8/3.
//
//

#import "BDQBPostDataHttpRequestSerializer.h"

@implementation BDQBPostDataHttpRequestSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(NSDictionary *)parameters
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest * request = [super URLRequestWithURL:URL params:parameters method:method constructingBodyBlock:bodyBlock commonParams:commonParam];

    [request setValue:@"application/json"
          forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[NSJSONSerialization dataWithJSONObject:parameters options:0 error:NULL]];

    return request;
    
}

@end
