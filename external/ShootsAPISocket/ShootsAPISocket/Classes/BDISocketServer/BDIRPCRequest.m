//
//  BDIRPCRequest.m
//  BDiOSpy
//
//  Created by byte dance on 2021/11/22.
//

#import "BDIRPCRequest.h"

@implementation BDIRPCRequest

+ (instancetype)instantiateWithPayload:(NSDictionary *)payloadDict
{
    BDIRPCRequest *request = [[self alloc] init];
    request.reqId = 0;
    if ([payloadDict[@"id"] isKindOfClass:[NSNumber class]]){
        request.reqId = [payloadDict[@"id"] intValue];
    }
    request.method = payloadDict[@"method"];
    request.params = payloadDict[@"params"];
    return request;
}

@end
