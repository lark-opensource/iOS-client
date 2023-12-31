//
//  IESBridgeMethod.m
//  IESWebKit
//
//  Created by li keliang on 2019/4/8.
//

#import "IESBridgeMethod.h"

@implementation IESBridgeMethod

- (instancetype)initWithMethodName:(NSString *)methodName methodNamespace:(nonnull NSString *)methodNamespace authType:(IESPiperAuthType)authType handler:(IESBridgeHandler)handler
{
    self = [super init];
    if (self) {
        _methodName = [methodName copy];
        _methodNamespace = [methodNamespace copy];
        _authType = authType;
        _handler = [handler copy];
    }
    return self;
}

@end
