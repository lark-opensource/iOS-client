//
//  BDPJSONRequestSerializer.m
//  Timor
//
//  Created by 维旭光 on 2019/3/4.
//

#import "BDPHTTPRequestSerializer.h"
#import <ECOInfra/JSONValue+BDPExtension.h>
#import <ECOInfra/NSDictionary+BDPExtension.h>

static const NSTimeInterval kGeneralRequestTimeout = 10.0;
static NSTimeInterval kCurrentRequestTimeout = 0.0;

@implementation BDPHTTPRequestSerializer

+ (void)setTimeoutInterval:(NSTimeInterval)timeoutInterval
{
    kCurrentRequestTimeout = timeoutInterval;
}

+ (NSTimeInterval)timeoutInterval
{
    NSTimeInterval interval;
    if (kCurrentRequestTimeout > 0) {
        interval = kCurrentRequestTimeout;
        //每取一次值后，把值归零
        kCurrentRequestTimeout = 0.0;
    }else
    {
        interval = kGeneralRequestTimeout;;
    }
    return interval;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(id)parameters
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest * request = [super URLRequestWithURL:URL params:parameters method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    [self _formatParams:request params:parameters];
    
    return request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(id)parameters
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    headField = [headField bdp_dictionaryWithCapitalizedKeys];
    TTHttpRequest * request = [super URLRequestWithURL:URL headerField:headField params:parameters method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    [self _formatParams:request params:parameters];
    if (headField != nil) {
        [headField enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
    }else
    {
        [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    }
    //如果不指定，默认采用application/json; encoding=utf-8
    if (![headField objectForKey:@"Content-Type"]) {
        [request setValue:@"application/json; encoding=utf-8" forHTTPHeaderField:@"Content-Type"];
        [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    }
    
    return request;
}

- (void)_formatParams:(TTHttpRequest *)request params:(id)params
{
    request.timeoutInterval = [[self class] timeoutInterval];
    
    if([request.HTTPMethod isEqualToString:@"POST"]) {
        if ([params isKindOfClass:[NSDictionary class]]) {
            id data = [params objectForKey:BDPParamBodyKey];
            if (data) {
                [request setHTTPBody:data];
            }else
            {
                NSData *data = [NSJSONSerialization dataWithJSONObject:(NSDictionary *)params options:NSJSONWritingPrettyPrinted error:nil];
                [request setHTTPBody:data];
            }
        }
    }
}

@end
