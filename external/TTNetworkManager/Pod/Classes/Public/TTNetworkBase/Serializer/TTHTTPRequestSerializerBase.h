//
//  TTHTTPRequestSerializerBase.h
//  Pods
//
//  Created by ZhangLeonardo on 15/9/6.
//
//  Interface and base class for network request serialization

#import "TTHTTPRequestSerializerProtocol.h"

@interface TTHTTPRequestSerializerBase : NSObject<TTHTTPRequestSerializerProtocol>

+ (TTHttpRequest *)hashRequest:(TTHttpRequest *)request body:(NSData *)body;

@end
