//
//  BDIRPCResponse.m
//  BDiOSpy
//
//  Created by byte dance on 2021/11/22.
//

#import "BDIRPCResponse.h"

@implementation BDIRPCResponse

+ (instancetype)responseToRequest:(BDIRPCRequest *)request WithResult:(id)result
{
    return [[BDIRPCResponse alloc] initWithRspid:request.reqId result:result error:nil];
}

+ (instancetype)responseErrorWithStatus:(BDIRPCStatus *)status
{
    NSDictionary *errorDict = @{
        @"code": @(status.errorCode),
        @"message": status.message
    };
    return [[BDIRPCResponse alloc] initWithRspid:-1 result:nil error:errorDict];
}

+ (instancetype)responseErrorTo:(BDIRPCRequest *)request WithStatus:(BDIRPCStatus *)status
{
    NSDictionary *errorDict = @{
        @"code": @(status.errorCode),
        @"message": status.message
    };
    return [[BDIRPCResponse alloc] initWithRspid:request.reqId result:nil error:errorDict];
}

+ (instancetype)responsePushMessage:(id)message
{
    return [[BDIRPCResponse alloc] initWithRspid:-1 result:message error:nil];
}

- (instancetype)initWithRspid:(int)rspId result:(id)result error:(NSDictionary *)errorDict
{
    if (self = [super init]){
        _rspId = rspId;
        _result = result;
        _error = errorDict;
    }
    return self;
}

- (NSDictionary *)JSON
{
    NSMutableDictionary *jsonDict = [NSMutableDictionary dictionary];
    jsonDict[@"jsonrpc"] = @"2.0";
    jsonDict[@"id"] = @(self.rspId);
    if (self.error){
        jsonDict[@"error"] = self.error;
    } else {
        jsonDict[@"result"] = self.result;
    }
    return jsonDict;
}

@end
