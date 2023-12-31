//
//  JSWorkerBridgeEngine.m
//  TTBridgeUnify
//
//  Created by bytedance on 2021/10/14.
//

#import "JSWorkerBridgeEngine.h"
#import "JSWorkerBridge.h"
#import <TTBridgeUnify/TTBridgeCommand.h>
#import <objc/runtime.h>
#import <TTBridgeUnify/TTBridgeForwarding.h>
#import <TTBridgeUnify/TTBridgeRegister.h>
#import <ByteDanceKit/BTDMacros.h>
#import "TTBridgeUnify_internal.h"
#import "JSWorkerBridgeModule.h"
#import "JSWorkerBridgePool.h"
#import <IESJSBridgeCore/IESBridgeMessage.h>
#import <IESJSBridgeCore/IESBridgeEngine.h>

@interface JsWorkerIOS ()

@property (nonatomic, strong, readonly) JSWorkerBridgeEngine *tt_engine;

@end

@implementation JsWorkerIOS (TTBridge)

- (void)tt_installIESBridgeEngine:(IESBridgeEngine *)bridge {
    self.tt_engine.iesBridgeEngine = bridge;
}

- (void)tt_installBridgeEngine:(JSWorkerBridgeEngine *)bridge {
    [bridge installOnWorker:self];
}

- (void)setTt_engine:(JSWorkerBridgeEngine *)tt_engine {
    objc_setAssociatedObject(self, @selector(tt_engine), tt_engine, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (JSWorkerBridgeEngine *)tt_engine {
    return objc_getAssociatedObject(self, @selector(tt_engine));
}

@end

@interface JSWorkerBridgeEngine () <JSWorkerBridgeExecutor>

@property (nonatomic, weak, readwrite) NSObject *sourceObject;
@property(nonatomic, strong) TTBridgeRegister *bridgeRegister;
@property(nonatomic, weak) JSWorkerBridge *bridgeCore;
@property (nonatomic,assign) BOOL webViewBridgeCompatibility;

@end

@implementation JSWorkerBridgeEngine

@synthesize sourceController;
@synthesize sourceObject;
@synthesize sourceURL;

- (instancetype)init
{
    return [self initWithWebViewBridgeCompatibility:NO];
}

- (instancetype)initWithWebViewBridgeCompatibility:(BOOL)compatibility {
    self = [super init];
    if (self) {
        self.webViewBridgeCompatibility = compatibility;
        [TTBridgeRegister _doRegisterIfNeeded];
        [TTBridgeForwarding.sharedInstance _installAssociatedPluginsOnEngine:self];
    }
    return self;
}

- (TTBridgeRegister *)bridgeRegister {
    if (!_bridgeRegister) {
        _bridgeRegister = TTBridgeRegister.new;
    }
    return _bridgeRegister;
}

- (TTBridgeRegisterEngineType)engineType {
    if(self.webViewBridgeCompatibility){
        return TTBridgeRegisterWebView;
    }
    else {
        return TTBridgeRegisterJSWorker;
    }
}

- (id<TTBridgeAuthorization>)authorization {
    return nil;
}

- (void)installOnWorker:(JsWorkerIOS *)worker {
    NSString* containerID = [[NSUUID UUID] UUIDString];
    JSWorkerBridge* bridge = [JSWorkerBridge new];
    [worker registerModule:JSWorkerBridgeModule.class param:@{@"containerID":containerID}];
    [JSWorkerBridgePool registerBridge:bridge forContainerID:containerID];
    [bridge addExecutor:self];
    self.sourceObject = worker;
}

#pragma mark - executor

- (BOOL)executeMethodWithMessage:(nonnull JSWorkerBridgeReceivedMessage *)message onBridge:(nonnull JSWorkerBridge *)bridge callback:(nonnull JSWorkerBridgeCallback)callback {
    __auto_type params = message.data;
    if (![params isKindOfClass:NSDictionary.class]) {
          params = @{};
      }
    void (^invokeBlock)(void) = ^{
        TTBridgeCommand *command = [[TTBridgeCommand alloc] init];
        command.bridgeName = message.methodName;
        command.params = [params copy];
        command.bridgeType = TTBridgeTypeCall;

        if (![self respondsToBridge:command.bridgeName]) {
          BOOL shouldCallbackUnregisteredCommand = [TTBridgeRegister bridgeEngine:self shouldCallbackUnregisteredCommand:command];
          if (!shouldCallbackUnregisteredCommand) {
              return;
          }
        }

        @weakify(self);
        __auto_type completion = ^(TTBridgeMsg msg, NSDictionary *response, void (^resultBlock)(NSString *result)) {
          if (callback) {
              @strongify(self);
              command.bridgeMsg = msg;
              command.params = response;
              [TTBridgeRegister bridgeEngine:self willCallbackBridgeCommand:command];
              callback((JSWorkerBridgeStatusCode)msg,response);
          }
        };

        if ([self.bridgeRegister respondsToBridge:command.bridgeName]) {
          BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:self shouldHandleLocalBridgeCommand:command];
          if (!shouldHandleBridge) {
              return;
          }
          [self.bridgeRegister executeCommand:command engine:self completion:completion];
        } else if ([TTBridgeRegister.sharedRegister respondsToBridge:command.bridgeName engineType:[self engineType]]) {
            BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:self shouldHandleGlobalBridgeCommand:command];
            if (!shouldHandleBridge) {
                return;
            }
            [TTBridgeRegister.sharedRegister executeCommand:command engine:self completion:completion];
        } else {
            // TOOD: temp
            NSTimeInterval preDispatchTS = [[NSDate date] timeIntervalSince1970];
            NSDictionary *messageBody = message.rawData[@"rawData"];
            IESBridgeMessage *bridgeMessage = [[IESBridgeMessage alloc] initWithDictionary:messageBody callback:^(NSString * _Nullable result) {
                NSData *data = [result dataUsingEncoding:NSUTF8StringEncoding];
                NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
                command.bridgeMsg = TTBridgeMsgSuccess;
                command.params = json[@"__params"];
                callback((JSWorkerBridgeStatusCode)TTBridgeMsgSuccess, json[@"__params"]);
            }];
            bridgeMessage.methodName = message.methodName;
            bridgeMessage.from = IESBridgeMessageFromJSCall;
            bridgeMessage.protocolVersion = message.protocolVersion;
            bridgeMessage.perfData.preDispatchTS = preDispatchTS;
            bridgeMessage.perfData.postDecodeTS = [[NSDate date] timeIntervalSince1970];
            [self.iesBridgeEngine handleBridgeMessage:bridgeMessage];
        }
    };
    tt_dispatch_async_main_thread_safe(invokeBlock);
    return YES;
}

- (BOOL)respondsToBridge:(TTBridgeName)bridgeName {
    return [self.bridgeRegister respondsToBridge:bridgeName] ?: [TTBridgeRegister.sharedRegister respondsToBridge:bridgeName];
}

- (void)fireEvent:(TTBridgeName)eventName params:(nullable NSDictionary *)params {
}
- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(nullable NSDictionary *)params {
}
- (void)fireEvent:(TTBridgeName)eventName params:(nullable NSDictionary *)params resultBlock:(nullable void (^)(NSString * _Nullable))resultBlock {
}
- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(nullable NSDictionary *)params resultBlock:(nullable void (^)(NSString * _Nullable))resultBlock {
}

#pragma mark - deprecated

- (void)callbackBridge:(TTBridgeName)bridgeName params:(NSDictionary *)params {
}

- (void)callbackBridge:(TTBridgeName)bridgeName params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
}

- (void)callbackBridge:(TTBridgeName)bridgeName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
}



@end
