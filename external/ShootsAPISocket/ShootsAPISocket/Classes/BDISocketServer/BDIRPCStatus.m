//
//  BDIRPCStatus.m
//  BDiOSpy
//
//  Created by byte dance on 2021/11/22.
//

#import "BDIRPCStatus.h"

@implementation BDIRPCStatus

+ (instancetype)serverErrorWithMessage:(NSString *)message
{
    return [BDIRPCStatus errorWithMessage:message errorCode:-32000];
}

+ (instancetype)internalErrorWithMessage:(NSString *)message
{
    return [BDIRPCStatus errorWithMessage:message errorCode:-32603];
}

+ (instancetype)invalidParamsErrorWithMessage:(NSString *)message
{
    return [BDIRPCStatus errorWithMessage:message errorCode:-32602];
}

+ (instancetype)methodNotFoundErrorWithMessage:(NSString *)message
{
    return [BDIRPCStatus errorWithMessage:message errorCode:-32601];
}

+ (instancetype)invalidRequestErrorWithMessage:(NSString *)message
{
    return [BDIRPCStatus errorWithMessage:message errorCode:-32600];
}

+ (instancetype)parseErrorWithMessage:(NSString *)message
{
    return [BDIRPCStatus errorWithMessage:message errorCode:-32700];
}

+ (instancetype)errorWithMessage:(NSString *)message errorCode:(NSInteger)errorCode
{
    return [[BDIRPCStatus alloc] initWithError:@"" statusCode:400 message:message errorCode:errorCode];
}

- (instancetype)initWithError:(NSString *)error statusCode:(NSInteger)statusCode message:(NSString *)message errorCode:(NSInteger)errorCode
{
    if (self = [super init]){
        _error = error;
        _statusCode = statusCode;
        _message = message;
        _errorCode = errorCode;
    }
    return self;
}

@end
