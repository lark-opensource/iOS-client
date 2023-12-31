//
//  BDTuringTVAppNetworkRequestSerializer.m
//  BDTuring
//
//  Created by yanming.sysu on 2020/12/8.
//

#import "BDTuringTVAppNetworkRequestSerializer.h"

static NSString * const kTTAppNetworkRequestTypeFlag = @"TT-RequestType";

@implementation BDTuringTVAppNetworkRequestSerializer

+ (NSObject<TTHTTPRequestSerializerProtocol> *)serializer {
    return [[BDTuringTVAppNetworkRequestSerializer alloc] init];
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(NSDictionary *)parameters
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam {
    TTHttpRequest * request = [super URLRequestWithURL:URL params:parameters method:method constructingBodyBlock:bodyBlock commonParams:commonParam];

    return request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL headerField:(NSDictionary *)headField params:(id)params method:(NSString *)method constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock commonParams:(NSDictionary *)commonParam {
    NSString *reqType = [headField valueForKey:kTTAppNetworkRequestTypeFlag];
    NSDictionary *reqParams = nil;
    NSData *postDate = nil;
    if ([method isEqualToString:@"POST"]) {
        // 移除类型标记
        NSMutableDictionary *mHeader = [NSMutableDictionary dictionaryWithDictionary:headField];
        mHeader[kTTAppNetworkRequestTypeFlag] = nil;
        headField = mHeader;
        
        if ([reqType isEqualToString:@"form"] && [params isKindOfClass:[NSDictionary class]]) {
            reqParams = params;
        } else if ([reqType isEqualToString:@"json"] && [params isKindOfClass:[NSDictionary class]]) {
            postDate = [NSJSONSerialization dataWithJSONObject:params options:NSJSONWritingPrettyPrinted error:nil];
        } else if ([reqType isEqualToString:@"raw"]) {
            if ([params isKindOfClass:[NSString class]]) {
                NSString *paramsString = (NSString *)params;
                postDate = [paramsString dataUsingEncoding:NSUTF8StringEncoding];
            } else if ([params isKindOfClass:[NSData class]]) {
                postDate = params;
            }
        }
    } else {
        reqParams = params;
    }
    
    TTHttpRequest * request = [super URLRequestWithURL:URL headerField:headField params:reqParams method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    if (postDate) {
        [request setHTTPBody:postDate];
    }
    
    return request;
}



@end
