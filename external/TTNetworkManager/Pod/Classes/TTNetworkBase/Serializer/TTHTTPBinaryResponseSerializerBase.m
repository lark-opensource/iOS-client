//
//  TTHTTPBinaryResponseSerializer.m
//  Pods
//
//  Created by tyh on 2017/8/31.
//
//

#import "TTHTTPBinaryResponseSerializerBase.h"

@implementation TTHTTPBinaryResponseSerializerBase

+ (NSObject<TTBinaryResponseSerializerProtocol> *)serializer
{
    return [[TTHTTPBinaryResponseSerializerBase alloc] init];
}

- (id)responseObjectForResponse:(TTHttpResponse *)response
                           data:(NSData *)data
                  responseError:(NSError *)responseError
                    resultError:(NSError *__autoreleasing *)resultError
{
    NSError * jsonParseError = responseError;
    id responseObject = data;
    if (resultError) {
        *resultError = jsonParseError;
    }
    return responseObject;
}


@end
