//
//  TTNetworkManager+IESWKAddition.m
//  BDJSBridgeAuthManager-CN-Core
//
//  Created by bytedance on 2020/8/26.
//

#import "TTNetworkManager+IESWKAddition.h"
#import <TTNetworkManager/TTDefaultHTTPRequestSerializer.h>


@interface IESWKPOSTRequestJSONSerializer : TTDefaultHTTPRequestSerializer

@end

@implementation IESWKPOSTRequestJSONSerializer

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL headerField:(NSDictionary *)headField params:(NSDictionary *)params method:(NSString *)method constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock commonParams:(NSDictionary *)commonParam
{
    TTHttpRequest *request = [super URLRequestWithURL:URL headerField:headField params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    if (params) {
        NSData *postData = [NSJSONSerialization dataWithJSONObject:params options:kNilOptions error:nil];
        [request setHTTPBody:postData];
    }
    return request;
}

@end


#pragma mark - TTNetworkManager (IESWKAddition)

@implementation TTNetworkManager (IESWKAddition)

- (TTHttpTask *)requestWithURL:(NSString *)url method:(NSString *)method params:(NSDictionary *)params callback:(TTNetworkJSONFinishBlock)callback
{
    BOOL isPost = [method isEqualToString:@"POST"];
    return [self requestForJSONWithResponse:url
                                     params:params
                                     method:method
                           needCommonParams:YES
                                headerField:isPost ? @{ @"Content-Type" : @"application/json" } : nil
                          requestSerializer:isPost ? IESWKPOSTRequestJSONSerializer.class : nil
                         responseSerializer:nil
                                 autoResume:YES
                                   callback:^(NSError *error, id obj, TTHttpResponse *response) {
                                       callback(error, obj);
                                   }];
}

@end

