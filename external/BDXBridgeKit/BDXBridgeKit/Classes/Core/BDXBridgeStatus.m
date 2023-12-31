//
//  BDXBridgeStatus.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/8/19.
//

#import "BDXBridgeStatus.h"

@implementation BDXBridgeStatus

+ (instancetype)statusWithStatusCode:(BDXBridgeStatusCode)statusCode message:(NSString *)message, ...
{
    if (message) {
        va_list args;
        va_start(args, message);
        message = [[NSString alloc] initWithFormat:message arguments:args];
        va_end(args);
    }
    
    BDXBridgeStatus *status = [(id)[BDXBridgeStatus alloc] init];
    status.statusCode = statusCode;
    status.message = [message copy];
    return status;
}

+ (instancetype)statusWithStatusCode:(BDXBridgeStatusCode)statusCode
{
    return [self statusWithStatusCode:statusCode message:nil];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p, %@>", self.class, self, @{
        @"statusCode": @(self.statusCode),
        @"message": self.message ?: @"",
    }];
}

@end
