//
//  TTLynxBridgeEngine.m
//  Pods
//
//  Created by momingqi on 2020/3/19.
//

#import "TTLynxBridgeEngine.h"
#import <TTBridgeUnify/TTBridgeEngine.h>
#import <TTBridgeUnify/TTBridgeCommand.h>
#import <TTBridgeUnify/TTBridgeForwarding.h>
#import <TTBridgeUnify/TTBridgeRegister.h>
#import <ByteDanceKit/BTDMacros.h>
#import <Lynx/LynxModule.h>
#import <Lynx/BDLynxBridge.h>
#import <Lynx/BDLynxBridgeMessage.h>
#import <Lynx/LynxView+Bridge.h>
#import <Lynx/BDLynxBridgeMethod.h>
#import <objc/runtime.h>
#import "TTBridgeUnify_internal.h"
#import <BDMonitorProtocol/BDMonitorProtocol.h>

@interface LynxView ()

@property (nonatomic, strong) TTLynxBridgeEngine *tt_engine;

@end

@implementation LynxView (TTBridge)

- (void)tt_installBridgeEngine:(TTLynxBridgeEngine *)bridge {
    [bridge installOnLynxView:self];
}

- (void)setTt_engine:(TTLynxBridgeEngine *)tt_engine {
    objc_setAssociatedObject(self, @selector(tt_engine), tt_engine, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (TTLynxBridgeEngine *)tt_engine {
    return objc_getAssociatedObject(self, @selector(tt_engine));
}

@end

@interface LynxView (BridgePerf)

- (NSDictionary *)bridgePerf;
- (void)setBridgePerf:(NSDictionary *)bridgePerf;

@end

@implementation LynxView (BridgePerf)

- (NSDictionary *)bridgePerf {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setBridgePerf:(NSDictionary *)bridgePerf {
    objc_setAssociatedObject(self, @selector(bridgePerf), bridgePerf, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end

@interface TTLynxBridgePerfData : NSObject

@property (nonatomic, assign) NSTimeInterval preDispatchTS;
@property (nonatomic, assign) NSTimeInterval preRegisterExecuteTS;
@property (nonatomic, assign) NSTimeInterval preCommandExecuteTS;
@property (nonatomic, assign) NSTimeInterval preCallbackTS;
@property (nonatomic, assign) NSTimeInterval postCallbackTS;

- (NSDictionary *)toDict;

@end

@implementation TTLynxBridgePerfData

- (NSDictionary *)toDict {
    return @{
        @"on_call_from_js": @(0),
        @"on_decode_end": @((uint64_t)((self.preRegisterExecuteTS - self.preDispatchTS) * 1000)),
        @"on_method_call": @((uint64_t)((self.preCommandExecuteTS - self.preDispatchTS) * 1000)),
        @"on_callback_start": @((uint64_t)((self.preCallbackTS - self.preDispatchTS) * 1000)),
        @"on_encode_end": @((uint64_t)((self.postCallbackTS - self.preDispatchTS) * 1000)),
        @"on_callback_end": @((uint64_t)((self.postCallbackTS - self.preDispatchTS) * 1000))
    };
}

@end

@interface TTLynxBridgeEngine ()<BDLynxBridgeExecutor,TTBridgeRegisterProtocol>

@property (nonatomic, weak, readwrite) NSObject *sourceObject;
@property(nonatomic, strong) TTBridgeRegister *bridgeRegister;
@property(nonatomic, weak) BDLynxBridge *bridgeCore;

@end

@implementation TTLynxBridgeEngine

- (instancetype)init
{
    self = [super init];
    if (self) {
        [TTBridgeRegister _doRegisterIfNeeded];
        [TTBridgeForwarding.sharedInstance _installAssociatedPluginsOnEngine:self];
    }
    return self;
}

- (void)installOnLynxView:(LynxView *)lynxView {
    self.sourceObject = lynxView;
    self.bridgeCore = lynxView.bridge;
    lynxView.tt_engine = self;
    [self.bridgeCore addExecutor:self];
}

- (LynxView *)lynxView {
    return [self.sourceObject isKindOfClass:LynxView.class] ? (LynxView *)self.sourceObject : nil;
}

+ (UIViewController*)correctTopViewControllerFor:(UIResponder*)responder
{
    UIResponder *topResponder = responder;
    for (; topResponder; topResponder = [topResponder nextResponder]) {
        if ([topResponder isKindOfClass:[UIViewController class]]) {
            UIViewController *viewController = (UIViewController *)topResponder;
            while (viewController.parentViewController && viewController.parentViewController != viewController.navigationController && viewController.parentViewController != viewController.tabBarController) {
                viewController = viewController.parentViewController;
            }
            return viewController;
        }
    }
    if(!topResponder && [[[UIApplication sharedApplication] delegate] respondsToSelector:@selector(window)])
    {
        topResponder = [[[UIApplication sharedApplication] delegate].window rootViewController];
    }
    
    return (UIViewController*)topResponder;
}

#pragma - mark TTBridgeEngine
- (NSURL *)sourceURL {
    return [NSURL URLWithString:[self lynxView].url];
}

- (UIViewController *)sourceController {
    if (![NSThread isMainThread]) {
        return nil;
    }
    return [self.class correctTopViewControllerFor:(UIView *)self.sourceObject];
}

- (TTBridgeRegisterEngineType)engineType {
    return TTBridgeRegisterLynx;
}

- (TTBridgeRegister *)bridgeRegister {
    if (!_bridgeRegister) {
        _bridgeRegister = TTBridgeRegister.new;
        _bridgeRegister.delegate = self;
        _bridgeRegister.engine = self;
    }
    return _bridgeRegister;
}

- (id<TTBridgeAuthorization>)authorization {
    return nil;
}

- (BOOL)respondsToBridge:(TTBridgeName)bridgeName {
    return [self.bridgeRegister respondsToBridge:bridgeName] ?: [TTBridgeRegister.sharedRegister respondsToBridge:bridgeName];
}

- (void)fireEvent:(TTBridgeName)eventName params:(NSDictionary *)params {
    [self fireEvent:eventName params:params resultBlock:nil];
}

- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(NSDictionary *)params {
    [self fireEvent:eventName msg:msg params:params resultBlock:nil];
}

- (void)fireEvent:(TTBridgeName)eventName params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [self fireEvent:eventName msg:TTBridgeMsgSuccess params:params resultBlock:resultBlock];
}

- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString * _Nullable))resultBlock {
    [self.bridgeCore callEvent:eventName params:params code:(BDLynxBridgeStatusCode)msg];
    if (resultBlock) {
        //Native2JS doesn't support the callback currently.
        resultBlock(nil);
    }
}

#pragma - BDLynxBridgeExecutor

- (BOOL)executeMethodWithMessage:(nonnull BDLynxBridgeReceivedMessage *)message onBridge:(nonnull BDLynxBridge *)bridge callback:(nonnull BDLynxBridgeCallback)callback {
    __auto_type params = message.data;
    if (![params isKindOfClass:NSDictionary.class]) {
          params = @{};
      }
    TTLynxBridgePerfData *perfData = [[TTLynxBridgePerfData alloc] init];
    perfData.preDispatchTS = [[NSDate date] timeIntervalSince1970];
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
              perfData.preCallbackTS = [[NSDate date] timeIntervalSince1970];
              command.bridgeMsg = msg;
              command.params = response;
              [TTBridgeRegister bridgeEngine:self willCallbackBridgeCommand:command];
              callback((BDLynxBridgeStatusCode)msg, response);
              perfData.postCallbackTS = [[NSDate date] timeIntervalSince1970];
              
              if (self.sourceObject && [self.sourceObject isKindOfClass:LynxView.class]) {
                  LynxView *lynxview = self.sourceObject;
                  lynxview.bridgePerf = perfData.toDict;
              }
          }
        };
        
        __auto_type preExecuteHandler = ^(TTBridgeMethodInfo *methodInfo) {
            perfData.preCommandExecuteTS = [[NSDate date] timeIntervalSince1970];
        };

        if ([self.bridgeRegister respondsToBridge:command.bridgeName]) {
          BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:self shouldHandleLocalBridgeCommand:command];
          if (!shouldHandleBridge) {
              return;
          }
            perfData.preRegisterExecuteTS = [[NSDate date] timeIntervalSince1970];
          [self.bridgeRegister executeCommand:command engine:self completion:completion];
        }
        else {
          BOOL shouldHandleBridge = [TTBridgeRegister bridgeEngine:self shouldHandleGlobalBridgeCommand:command];
          if (!shouldHandleBridge) {
              return;
          }
            perfData.preRegisterExecuteTS = [[NSDate date] timeIntervalSince1970];
          [TTBridgeRegister.sharedRegister executeCommand:command engine:self completion:completion];
        }
    };
    BOOL useUIThread = YES;
    SEL selector = NSSelectorFromString(@"useUIThread");
    if ([message respondsToSelector:selector]) {
        NSMethodSignature *signature = [[message class] instanceMethodSignatureForSelector:selector];
        if (strcmp(@encode(BOOL), [signature methodReturnType]) == 0) {
            NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
            [invocation setSelector:selector];
            [invocation setTarget:message];
            [invocation invoke];
            BOOL returnValue;
            [invocation getReturnValue:&returnValue];
            useUIThread = returnValue;
        }
    }
    
    if (useUIThread) {
        tt_dispatch_async_main_thread_safe(invokeBlock);
    } else {
        invokeBlock();
    }
    
    return YES;
}

#pragma mark - TTBridgeRegisterProtocol

- (void)didRegisterMethod:(TTBridgeName)bridgeName handler:(TTBridgeHandler)handler engineType:(TTBridgeRegisterEngineType)engineType authType:(TTBridgeAuthType)authType domains:(NSArray<NSString *> *)domains inRegister:(TTBridgeRegister *)bridgeRegister {
    if((engineType & TTBridgeRegisterLynx) == 0){
        return;
    }
    
    __block BDLynxBridgeMethod* method;
    [[self lynxView].bridge.methods enumerateObjectsUsingBlock:^(BDLynxBridgeMethod * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([obj.methodName isEqualToString:bridgeName]){
            method = obj;
            *stop = YES;
        }
    }];
    
    if(method){
        @synchronized (self.lynxView.bridge.methods) {
            [self.lynxView.bridge.methods removeObject:method];
        }
    }
}

#pragma mark - deprecated

- (void)callbackBridge:(TTBridgeName)bridgeName params:(NSDictionary *)params {
    [self fireEvent:bridgeName params:params];
}

- (void)callbackBridge:(TTBridgeName)bridgeName params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [self fireEvent:bridgeName msg:TTBridgeMsgSuccess params:params resultBlock:resultBlock];
}

- (void)callbackBridge:(TTBridgeName)bridgeName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [self fireEvent:bridgeName msg:msg params:params resultBlock:resultBlock];
}

@end
