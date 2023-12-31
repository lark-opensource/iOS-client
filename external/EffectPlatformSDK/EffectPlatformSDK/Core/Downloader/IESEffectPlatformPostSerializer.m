//
//  IESEffectPlatformPostSerializer.m
//  AWEStudio
//
//  Created by 李彦松 on 2018/10/22.
//  Copyright © 2018年 bytedance. All rights reserved.
//

#import "IESEffectPlatformPostSerializer.h"

@implementation IESEffectPlatformPostSerializer

+ (NSObject<TTHTTPRequestSerializerProtocol> *)serializer
{
    return [[IESEffectPlatformPostSerializer alloc] init];
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
