//
//  BDXBridgeEngineAdapter_TTBridgeUnify.m
//  BDXBridgeKit
//
//  Created by Lizhen Hu on 2020/6/24.
//

#import "BDXBridgeEngineAdapter_TTBridgeUnify.h"
#import "BDXBridgeContainerProtocol.h"
#import "BDXBridgeMacros.h"
#import <TTBridgeUnify/TTBridgeUnify.h>
#import <BDAssert/BDAssert.h>

@interface BDXBridgeEngineAdapter_TTBridgeUnify ()

@property (nonatomic, strong) id<TTBridgeEngine> engine;

@end

@implementation BDXBridgeEngineAdapter_TTBridgeUnify

- (instancetype)initWithContainer:(id<BDXBridgeContainerProtocol>)container
{
    self = [super init];
    if (self) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        BOOL succeeded = NO;
        SEL uninstallSelector = NSSelectorFromString(@"tt_uninstallBridgeEngine");
        SEL installSelector = NSSelectorFromString(@"tt_installBridgeEngine:");
        if ([container isKindOfClass:NSClassFromString(@"WKWebView")]) {
            Class engineClass = NSClassFromString(@"BDUnifiedWebViewBridgeEngine");
            if (engineClass) {
                _engine = [engineClass new];
                if ([container respondsToSelector:uninstallSelector]) {
                    [container performSelector:uninstallSelector];
                }
                if ([container respondsToSelector:installSelector]) {
                    [container performSelector:installSelector withObject:_engine];
                    succeeded = YES;
                }
            }
        } else if ([container isKindOfClass:NSClassFromString(@"LynxView")]) {
            Class engineClass = NSClassFromString(@"TTLynxBridgeEngine");
            if (engineClass) {
                _engine = [engineClass new];
                if ([container respondsToSelector:uninstallSelector]) {
                    [container performSelector:uninstallSelector];
                }
                if ([container respondsToSelector:installSelector]) {
                    [container performSelector:installSelector withObject:_engine];
                    succeeded = YES;
                }
            }
        } else if ([container isKindOfClass:NSClassFromString(@"RCTRootView")]) {
            Class engineClass = NSClassFromString(@"BDXRNBridgeEngine");
            if (engineClass) {
                _engine = [engineClass new];
                succeeded = YES;
            }
        }
        
        BDAssert(succeeded, @"Unknown container type: %@", [container class]);
#pragma clang diagnostic pop
    }
    return self;
}

+ (void)registerGlobalMethodWithMethodName:(NSString *)methodName authType:(BDXBridgeAuthType)authType engineTypes:(BDXBridgeEngineType)engineTypes callHandler:(BDXBridgeEngineCallHandler)callHandler
{
    [self registerMethodWithMethodName:methodName authType:authType engineTypes:engineTypes callHandler:callHandler inRegistry:TTBridgeRegister.sharedRegister];
}

+ (void)deregisterGlobalMethodWithMethodName:(NSString *)methodName
{
    [TTBridgeRegister.sharedRegister unregisterBridge:methodName];
}

- (void)registerLocalMethodWithMethodName:(NSString *)methodName authType:(BDXBridgeAuthType)authType engineTypes:(BDXBridgeEngineType)engineTypes callHandler:(BDXBridgeEngineCallHandler)callHandler
{
    [self.class registerMethodWithMethodName:methodName authType:authType engineTypes:engineTypes callHandler:callHandler inRegistry:self.engine.bridgeRegister];
}

- (void)deregisterLocalMethodWithMethodName:(NSString *)methodName
{
    [self.engine.bridgeRegister unregisterBridge:methodName];
}

- (void)fireEventWithEventName:(NSString *)eventName params:(NSDictionary *)params
{
    [self.engine fireEvent:eventName params:params];
}

#pragma mark - Helpers

+ (void)registerMethodWithMethodName:(NSString *)methodName authType:(BDXBridgeAuthType)authType engineTypes:(BDXBridgeEngineType)engineTypes callHandler:(BDXBridgeEngineCallHandler)callHandler inRegistry:(TTBridgeRegister *)registry
{
    [registry registerBridge:^(TTBridgeRegisterMaker *maker) {
        TTBridgeAuthType mappedAuthType = [self.class mappedAuthType:authType];
        TTBridgeRegisterEngineType mappedEngineTypes = [self.class mappedEngineTypes:engineTypes];
        TTBridgeHandler wrappedCallHandler = ^(NSDictionary *params, TTBridgeCallback callback, id<TTBridgeEngine> engine, UIViewController *controller) {
            id<BDXBridgeContainerProtocol> container = nil;
            if ([engine.sourceObject conformsToProtocol:@protocol(BDXBridgeContainerProtocol)]) {
                container = (id<BDXBridgeContainerProtocol>)engine.sourceObject;
            }
            bdx_invoke_block(callHandler, container, params, ^(BDXBridgeStatusCode statusCode, NSDictionary *result, NSString *description) {
                TTBridgeMsg mappedStatusCode = (TTBridgeMsg)statusCode;
                bdx_invoke_block(callback, mappedStatusCode, result, nil);
            });
        };;
        maker.bridgeName(methodName).authType(mappedAuthType).engineType(mappedEngineTypes).handler(wrappedCallHandler);
    }];
}

+ (TTBridgeAuthType)mappedAuthType:(BDXBridgeAuthType)authType
{
    switch (authType) {
        case BDXBridgeAuthTypePublic: return TTBridgeAuthPublic;
        case BDXBridgeAuthTypeProtected: return TTBridgeAuthProtected;
        case BDXBridgeAuthTypePrivate: return TTBridgeAuthPrivate;
        case BDXBridgeAuthTypeSecure: return TTBridgeAuthSecure;
        default:
            BDAssert(NO, @"Unknown auth type: %@", @(authType));
            return TTBridgeAuthPrivate;
    }
}

+ (TTBridgeRegisterEngineType)mappedEngineTypes:(BDXBridgeEngineType)engineTypes
{
    TTBridgeRegisterEngineType mappedEngineTypes = 0;
    if (engineTypes & BDXBridgeEngineTypeWeb) {
        mappedEngineTypes |= TTBridgeRegisterWebView;
    }
    if (engineTypes & BDXBridgeEngineTypeLynx) {
        mappedEngineTypes |= TTBridgeRegisterLynx;
    }
    if (engineTypes & BDXBridgeEngineTypeRN) {
        mappedEngineTypes |= TTBridgeRegisterRN;
    }
    return mappedEngineTypes;
}

@end
