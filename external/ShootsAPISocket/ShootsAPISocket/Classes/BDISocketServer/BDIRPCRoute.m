//
//  BDIRPCRoute.m
//  BDiOSpy
//
//  Created by byte dance on 2021/11/19.
//

#import "BDIRPCRoute.h"
#import <objc/message.h>

@implementation BDIRPCRoute

+ (instancetype)CALL:(NSString *)api respondTarget:(id)target action:(SEL)action
{
    return [self instantiateWithApi:api respondTarget:target action:action];
}

+ (instancetype)instantiateWithApi:(NSString *)api respondTarget:(id)target action:(SEL)action
{
    BDIRPCRoute *route = [self new];
    route.api = api;
    route.target = target;
    route.action = action;
    return route;
}

- (BDIRPCResponse *)dispatchJsonRpcRequest:(BDIRPCRequest *)request
{
    BDIRPCResponse *(*requestMsgSend)(id, SEL, BDIRPCRequest *) = ((BDIRPCResponse *(*)(id, SEL, BDIRPCRequest *))objc_msgSend);
    return requestMsgSend(self.target, self.action, request);
}

@end
