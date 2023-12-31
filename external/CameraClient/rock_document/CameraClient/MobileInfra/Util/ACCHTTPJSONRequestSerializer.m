//
//  ACCHTTPJSONRequestSerializer.m
//  CameraClient-Pods-Aweme
//
//  Created by Pinka on 2020/2/14.
//

#import "ACCHTTPJSONRequestSerializer.h"

@implementation ACCHTTPJSONRequestSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(NSDictionary *)parameters
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    
    TTHttpRequest * request = [super URLRequestWithURL:URL headerField:headField params:parameters method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    
    if (parameters) {
        NSData * postData = [NSJSONSerialization dataWithJSONObject:parameters options:kNilOptions error:nil];
        
        [request setHTTPBody:postData];
    }

    return request;
}

@end
