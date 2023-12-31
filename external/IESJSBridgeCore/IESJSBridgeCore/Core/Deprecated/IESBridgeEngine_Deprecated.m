//
//  IESBridgeEngine_Deprecated.m
//  IESWebKit
//
//  Created by li keliang on 2019/4/8.
//

#import "IESBridgeEngine_Deprecated.h"
#import "IESBridgeMethod.h"
#import "IESBridgeMessage+Private.h"
#import "IESBridgeMonitor.h"

#import <ByteDanceKit/ByteDanceKit.h>
#import <libkern/OSAtomic.h>
#import <mach-o/getsect.h>
#import <mach-o/dyld.h>
#import <dlfcn.h>
#import <objc/runtime.h>

static NSMutableArray <IESBridgeMethod *> * GlobalBridgeMethods(void) {
    static NSMutableArray *p_methods = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        p_methods = [NSMutableArray new];
    });
    return p_methods;
}

@interface IESBridgeDeallocFlag_Deprecated : NSObject

@property (nonatomic, copy) void(^deallocBlock)(void);

@end

@implementation IESBridgeDeallocFlag_Deprecated

- (void)dealloc
{
    !_deallocBlock ?: _deallocBlock();
}

@end

@interface IESBridgeEngine_Deprecated ()

@property (nonatomic, readwrite, copy) NSMutableArray<IESBridgeMethod *> *internalMethods;

@end

@implementation IESBridgeEngine_Deprecated

+ (void)addGlobalMethod:(IESBridgeMethod *)method
{
    @synchronized (self) {
        [GlobalBridgeMethods() addObject:method];
    }
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _internalMethods = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)addMethod:(IESBridgeMethod *)method
{
    if ([self.internalMethods containsObject:method]) {
        NSCAssert(NO, @"IESBridgeMethod %@ has been added already.", method);
        return;
    }
    
    [self.internalMethods enumerateObjectsUsingBlock:^(IESBridgeMethod * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([method.methodName isEqualToString:obj.methodName]) {
            @synchronized (self) {
                NSLog(@"IESBridgeMethod %@ will be replaced with new handler %@.", method.methodName, method.handler);
                [self.internalMethods removeObject:obj];
            }
        }
    }];
    
    @synchronized (self) {
        [self.internalMethods addObject:method];
        [[IESBridgeAuthManager sharedManager] registerMethod:method.methodName withAuthType:method.authType];
    }
}

- (void)removeAllMethods
{
    @synchronized (self) {
        [self.internalMethods removeAllObjects];
    }
}

- (void)executeMethodsWithMessage:(IESBridgeMessage *)message
{
    if (![message.messageType isEqualToString:IESJSMessageTypeCall]) {
        NSAssert(NO, @"Execute methods with message %@ type error", message.methodName);
        return;
    }

    __block BOOL executed = NO;
    [self.methods enumerateObjectsUsingBlock:^(IESBridgeMethod * _Nonnull method, NSUInteger idx, BOOL * _Nonnull stop) {
        if (![method.methodName isEqualToString:message.methodName]) {
            return;
        }
        
        btd_dispatch_async_on_main_queue(^{
            [self executeMethod:method withMessage:message];
        });
        executed = YES;
    }];
    
    if (!executed) {
        if ([self.delegate respondsToSelector:@selector(bridgeEngine:didReceiveUnregisteredMessage:)]) {
            [self.delegate bridgeEngine:self didReceiveUnregisteredMessage:message];
        }
    }
}

- (void)sendEvent:(NSString*)event params:(NSDictionary*)params
{
    IESBridgeMessage *msg = [[IESBridgeMessage alloc] init];
    msg.messageType = IESJSMessageTypeEvent;
    msg.eventID = event;
    msg.params = params;
    [self sendBridgeMessage:msg];
}

#pragma mark - Private Methods

- (void)executeMethod:(IESBridgeMethod *)method withMessage:(IESBridgeMessage *)message
{
    NSCAssert(self.executor, @"IESBridgeEngine_Deprecated executor has not been set yet.");

    BOOL verified = [IESBridgeAuthManager.sharedManager isAuthorizedMethod:method.methodName forURL:self.executor.ies_url];
    [IESBridgeMonitor monitorJSBInvokeEventWithBridgeMessage:message bridgeMethod:method url:self.executor.ies_url isAuthorized:verified];
    if (!verified) {
        IESBridgeMessage *msg = [[IESBridgeMessage alloc] init];
        msg.messageType = IESJSMessageTypeCallback;
        msg.callbackID = message.callbackID;
        msg.params = @{@"code": @(IESPiperStatusCodeNotAuthroized)};
        [self sendBridgeMessage:msg];
        
        if ([self.delegate respondsToSelector:@selector(bridgeEngine:didReceiveUnauthorizedMethod:)]) {
            [self.delegate bridgeEngine:self didReceiveUnauthorizedMethod:method];
        }
        return;
    }
    
    IESBridgeDeallocFlag_Deprecated *debugFlag = [IESBridgeDeallocFlag_Deprecated new];
    debugFlag.deallocBlock = ^{
        NSAssert(NO, @"%@.%@ response handler was not called", method, method.methodName);
    };
    
    IESBridgeResponseBlock responseHandler = ^(IESPiperStatusCode status, NSDictionary * _Nullable response) {
        if (!debugFlag.deallocBlock) {
            NSAssert(NO, @"%@.%@ response handler was called more than once", method, method.methodName);
        }
        debugFlag.deallocBlock = nil;
        
        if (status == IESPiperStatusCodeManualCallback) {
            return;
        }
        
        IESBridgeMessage *msg = [[IESBridgeMessage alloc] init];
        msg.messageType = IESJSMessageTypeCallback;
        msg.callbackID = message.callbackID;
        msg.params = ({
            NSMutableDictionary *params = response.mutableCopy;
            params[@"code"] = @(status);
            params[@"__data"] = response;
            params.copy;
        });
        [self sendBridgeMessage:msg];
    };
    
    !method.handler ?: method.handler(message, responseHandler);
    
    if ([self.delegate respondsToSelector:@selector(bridgeEngine:didExcuteMethod:)]) {
        [self.delegate bridgeEngine:self didExcuteMethod:method];
    }
}

- (void)sendCallback:(NSString*)callbackID params:(NSDictionary*)params
{
    IESBridgeMessage *msg = [[IESBridgeMessage alloc] init];
    msg.messageType = IESJSMessageTypeCall;
    msg.callbackID = callbackID;
    msg.params = params;
    [self sendBridgeMessage:msg];
}

- (void)sendBridgeMessage:(IESBridgeMessage *)message
{
    message.statusCode = message.params[@"code"] ? [message.params[@"code"] integerValue] : IESPiperStatusCodeSucceed;

    if (message.callbackID.length == 0 && message.eventID.length == 0 && message.params.allKeys.count != 0) {
        NSAssert(NO, @"%@ message %@ callbackID or eventID was not found", self, message);
        return;
    }
    
    NSString *piperName = [@"VG91dGlhb0pTQnJpZGdl" btd_base64DecodedString];
    NSString *js = [NSString stringWithFormat:@"%@._handleMessageFromToutiao(%@);", piperName, message.wrappedParamsString];
    
    btd_dispatch_async_on_main_queue(^{
        NSCAssert(self.executor, @"IESBridgeEngine_Deprecated executor has not been set yet.");
        [self.executor ies_executeJavaScript:js completion:nil];
    });
}

#pragma mark - Accessors

- (NSArray<IESBridgeMethod *> *)methods
{
    return [GlobalBridgeMethods() arrayByAddingObjectsFromArray:self.internalMethods];
}

@end
