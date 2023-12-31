//
//  BDUnifiedWebViewBridgeEngine.m
//  TTBridgeUnify
//
//  Created by lizhuopeng on 2019/9/2.
//

#import "BDUnifiedWebViewBridgeEngine.h"
#import <IESJSBridgeCore/IESBridgeEngine.h>
#import <IESJSBridgeCore/IWKJSBridgePluginObject.h>
#import <BDWebCore/WKWebView+Plugins.h>
#import <IESJSBridgeCore/IESBridgeMessage.h>
#import <BDAssert/BDAssert.h>
#import <IESJSBridgeCore/IESJSBridgeCoreABTestManager.h>
#import <ByteDanceKit/BTDMacros.h>
#import "TTBridgeCommand.h"

@implementation TTBridgeCommand (BDUnifiedWebViewBridgeEngine)

+ (instancetype)commandWithIESMessage:(IESBridgeMessage *)message {
    TTBridgeCommand *command = TTBridgeCommand.new;
    command.bridgeName = message.methodName;
    command.messageType = message.messageType;
    command.eventID = message.eventID;
    command.callbackID = message.callbackID;
    NSDictionary *params = message.params;
    if (params) {
        if (![params isKindOfClass:NSDictionary.class]) {
            BDAssert(NO, @"JSB's params must be a dictionary.");
        }
        else {
            command.params = params;
        }
    }
    command.JSSDKVersion = message.JSSDKVersion;
    command.startTime = message.beginTime;
    command.endTime = message.endTime;
    command.bridgeType = [command.messageType isEqualToString:@"on"] ? TTBridgeTypeOn : TTBridgeTypeCall;
    switch (message.from) {
        case IESBridgeMessageFromIframe:
            command.protocolType = TTPiperProtocolSchemaInterception;
            break;
        case IESBridgeMessageFromJSCall:
            command.protocolType = TTPiperProtocolInjection;
            break;
        default:
            command.protocolType = TTPiperProtocolUnknown;
            break;
    }
    return command;
}

@end

@interface WKWebView ()

@property (nonatomic, strong) TTWebViewBridgeEngine *tt_engine;

@end

@interface BDUnifiedWebViewBridgeEngine ()<IESBridgeEngineInterceptor>

@property(nonatomic, strong) IWKPiperPluginObject *wkJSBObject;
@property (nonatomic, weak) NSObject *sourceObject;

@end

@implementation BDUnifiedWebViewBridgeEngine
@synthesize sourceObject = _sourceObject;


- (void)installOnWKWebView:(WKWebView *)webView {
    if (webView.tt_engine) {
        BDAssert(NO, @"%@ already has a bridge engine.", webView);
        return;
    }
    BDParameterAssert(webView != nil);
    [[TTWebViewBridgeEngine webViewEngines] addObject:self];
    self.sourceObject = webView;
    webView.tt_engine = self;
    IESPiperCoreABTestManager.sharedManager.useBridgeEngineV2 = YES;
    [webView IWK_loadPlugin:self.wkJSBObject];
    webView.ies_bridgeEngine.interceptor = self;
}

- (void)uninstallFromWKWebView:(WKWebView *)webView {
    [webView.ies_bridgeEngine deleteAllPipers];
    webView.tt_engine = nil;
    [webView IWK_removePlugin:self.wkJSBObject];
}

- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [self.iesBridgeEngine fireEvent:eventName withParams:params status:(IESPiperStatusCode)msg callback:^(id  _Nullable result) {
        if (resultBlock) {
            resultBlock([result isKindOfClass:[NSString class]] ? result : nil);
        }
    }];
}

- (IWKPiperPluginObject *)wkJSBObject {
    if (!_wkJSBObject) {
        _wkJSBObject = [IWKPiperPluginObject new];
        _wkJSBObject.protocolV1Enabled = self.schemaInterceptionEnabled;
    }
    return _wkJSBObject;
}

- (IESBridgeEngine *)iesBridgeEngine {
    return self.wkWebView.ies_bridgeEngine;
}

- (void)setSchemaInterceptionEnabled:(BOOL)schemaInterceptionEnabled {
    [super setSchemaInterceptionEnabled:schemaInterceptionEnabled];
    if (self.wkWebView) {
        self.wkJSBObject.protocolV1Enabled = schemaInterceptionEnabled;
    }
}

#pragma mark - IESBridgeEngineInterceptor

- (BOOL)bridgeEngine:(IESBridgeEngine *)engine shouldCallbackUnregisteredMessage:(IESBridgeMessage *)bridgeMessage {
    void (^invockBlock)(void) = ^{
        TTBridgeCommand *command = [TTBridgeCommand commandWithIESMessage:bridgeMessage];
        if (![self respondsToBridge:command.bridgeName]) {
            BOOL shouldCallbackUnregisteredCommand = [TTBridgeRegister bridgeEngine:self shouldCallbackUnregisteredCommand:command];
            if (!shouldCallbackUnregisteredCommand) {
                return;
            }
        }
        @weakify(self);
        __auto_type completion = ^(TTBridgeMsg msg, NSDictionary *response, void (^resultBlock)(NSString *result)) {
            @strongify(self);
            NSMutableDictionary *wrappedParams = [NSMutableDictionary dictionaryWithDictionary:response];
            [wrappedParams setValue:command.extraInfo forKey:@"extra_info"];
            bridgeMessage.params = wrappedParams;
            command.bridgeMsg = msg;
            [TTBridgeRegister bridgeEngine:self willCallbackBridgeCommand:command];
            [self.iesBridgeEngine invokeCallbackWithMessage:bridgeMessage statusCode:(IESPiperStatusCode)msg resultBlock:resultBlock];
        };
        if ([self.bridgeRegister respondsToBridge:command.bridgeName]) {
            BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:self shouldHandleLocalBridgeCommand:command];
            if (!shouldHandleBridge) {
                return;
            }
            [self.bridgeRegister executeCommand:command engine:self completion:completion];
        }
        else {
            BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:self shouldHandleGlobalBridgeCommand:command];
            if (!shouldHandleBridge) {
                return;
            }
            [TTBridgeRegister.sharedRegister executeCommand:command engine:self completion:completion];
        }
    };
    tt_dispatch_async_main_thread_safe(invockBlock);
    return NO;
}

- (NSURL *)sourceURL{
    if (self.wkJSBObject.commitURL) {
        return self.wkJSBObject.commitURL;
    }
    else if ([self.sourceObject isKindOfClass:[WKWebView class]]) {
        return self.wkWebView.URL;
    }
    return nil;
}

@end
