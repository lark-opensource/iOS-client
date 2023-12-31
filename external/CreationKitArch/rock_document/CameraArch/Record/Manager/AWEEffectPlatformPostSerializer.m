//
//  AWEEffectPlatformPostSerializer.m
//  AWEStudio
//
// Created by Li Yansong on October 22, 2018
//  Copyright  ©  Byedance. All rights reserved, 2018
//

#import "AWEEffectPlatformPostSerializer.h"

@implementation AWEEffectPlatformPostSerializer

+ (NSObject<TTHTTPRequestSerializerProtocol> *)serializer
{
    return [[AWEEffectPlatformPostSerializer alloc] init];
}


- (TTHttpRequest *)URLRequestWithRequestModel:(TTRequestModel *)requestModel
                                 commonParams:(NSDictionary *)commonParam
{
    TTHttpRequest *request = [super URLRequestWithRequestModel:requestModel commonParams:commonParam];
    return request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                         headerField:(NSDictionary *)headField
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    TTHttpRequest *request = [super URLRequestWithURL:URL headerField:headField params:params method:method constructingBodyBlock:bodyBlock commonParams:commonParam];
    
    if (params.allKeys.count) {
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:params
                                                           options:kNilOptions
                                                             error:nil];
        if (jsonData) {
            [request setHTTPBody:jsonData];
        }
    }
    
    return request;
}

- (TTHttpRequest *)URLRequestWithURL:(NSString *)URL
                              params:(NSDictionary *)params
                              method:(NSString *)method
               constructingBodyBlock:(TTConstructingBodyBlock)bodyBlock
                        commonParams:(NSDictionary *)commonParam
{
    return [self URLRequestWithURL:URL
                       headerField:nil
                            params:params
                            method:method
             constructingBodyBlock:bodyBlock
                      commonParams:commonParam];
}

@end
