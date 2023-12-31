//
//  AWECloudCommandNetworkHandler.m
//  Aspects
//
//  Created by Stan Shan on 2018/10/24.
//

#import "AWECloudCommandNetworkHandler.h"
#import "NSString+AWECloudCommandUtil.h"

@implementation AWECloudCommandNetworkHandler

+ (instancetype)sharedInstance
{
    static AWECloudCommandNetworkHandler *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[AWECloudCommandNetworkHandler alloc] init];
    });
    return instance;
}

#pragma mark - AWECloudCOmmandNetworkDelegate

- (void)requestWithUrl:(NSString * _Nonnull)urlString
                method:(NSString * _Nonnull)method
                params:(NSDictionary * _Nullable)params
        requestHeaders:(NSDictionary *)requestHeaders
            completion:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completion;
{
    if (self.networkDelegate) {
        [self.networkDelegate requestWithUrl:urlString
                                      method:method
                                      params:params
                              requestHeaders:requestHeaders
                                  completion:completion];
    } else {
        if ([method isEqualToString:@"GET"]) {
            urlString = [self _requestUrlWithParams:params baseUrl:urlString];
        }
        NSMutableURLRequest *request = [self _requestWithUrl:urlString requestMethod:method requestHeaders:requestHeaders];
        [requestHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [request setValue:obj forHTTPHeaderField:key];
        }];
        if ([method isEqualToString:@"POST"]) {
            request.HTTPBody = [self _requestBodyWithParams:params];
        }
        NSURLSessionDataTask *dataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completion];
        [dataTask resume];
    }
}

- (void)uploadWithUrl:(NSString * _Nonnull)urlString
                 data:(NSData *)data
       requestHeaders:(NSDictionary *)requestHeaders
           completion:(void (^)(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error))completion
{
    if (self.networkDelegate) {
        [self.networkDelegate uploadWithUrl:urlString
                                       data:data
                             requestHeaders:requestHeaders
                                 completion:completion];
    } else {
        NSMutableURLRequest *request = [self _requestWithUrl:urlString requestMethod:@"POST" requestHeaders:requestHeaders];
        request.HTTPBody = data;
        [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:completion] resume];
    }
}

#pragma mark - Private Methods

- (NSMutableURLRequest *)_requestWithUrl:(NSString *)url requestMethod:(NSString *)requestMethod requestHeaders:(NSDictionary *)requestHeaders
{
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    request.HTTPMethod = requestMethod;
    [requestHeaders enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        [request setValue:obj forHTTPHeaderField:key];
    }];
    return request;
}

- (NSString *)_requestUrlWithParams:(NSDictionary *)params baseUrl:(NSString *)baseUrl
{
    if (!params.count) {
        return baseUrl;
    }
    NSString *paramStr = [NSString awe_queryStringWithParamDictionary:params];
    paramStr = [paramStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [baseUrl awe_urlStringByAddingComponentString:paramStr];
}

- (NSData *)_requestBodyWithParams:(NSDictionary *)params
{
    params = params.count ? params : @{};
    NSData *data = [NSJSONSerialization dataWithJSONObject:params options:0 error:nil];
    return data;
}

@end
