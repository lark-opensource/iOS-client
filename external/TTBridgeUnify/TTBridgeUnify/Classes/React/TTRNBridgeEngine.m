//
//  TTRNBridgeEngine.m
//  BridgeUnifyDemo
//
//  Created by lizhuopeng on 2018/11/6.
//  Copyright © 2018 Bytedance. All rights reserved.
//

#import "TTRNBridgeEngine.h"
#import "TTBridgeCommand.h"
#import "TTBridgeForwarding.h"
#import <React/RCTBridge.h>
#import <React/RCTUIManager.h>
#import "TTBridgeAuthorization.h"
#import "TTBridgeUnify_internal.h"
#import <BDMonitorProtocol/BDMonitorProtocol.h>

@interface TTRNBridgeEngine ()

@property (nonatomic, weak) NSObject *sourceObject;
@property (nonatomic, strong) NSMutableArray<NSString *> *events;
@property(nonatomic, strong) TTBridgeRegister *bridgeRegister;

@end

@implementation TTRNBridgeEngine

- (instancetype)init
{
    self = [super init];
    if (self) {
        [TTBridgeRegister _doRegisterIfNeeded];
        [TTBridgeForwarding.sharedInstance _installAssociatedPluginsOnEngine:self];
    }
    return self;
}

- (RCTUIManager *)UIManager {
    return [self.bridge moduleForClass:[RCTUIManager class]];
}

- (NSMutableArray<NSString *> *)events {
    if (!_events) {
        _events = [NSMutableArray array];
    }
    return _events;
}

- (NSArray<NSString *> *)supportedEvents
{
    return self.events;
}

- (void)calendarEventReminderReceived:(NSNotification *)notification
{
    NSString *eventName = notification.userInfo[@"name"];
    [self sendEventWithName:@"EventReminder" body:@{@"name": eventName}];
}

#pragma mark - RCTBridgeModule

RCT_EXPORT_MODULE(TTBridge)

- (dispatch_queue_t)methodQueue {
    return dispatch_get_main_queue();
}

RCT_EXPORT_METHOD(call:(NSString *)methodName params:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback) {
    if ([params[@"rootTag"] isKindOfClass:NSNumber.class]) {
        NSNumber *rootTag = params[@"rootTag"];
        self.sourceObject = [[self UIManager] viewForReactTag:rootTag];
    }


    TTBridgeCommand *command = [[TTBridgeCommand alloc] init];
    command.bridgeName = methodName;
    command.params = [params copy];
    command.bridgeType = TTBridgeTypeCall;
    __auto_type completion = ^(TTBridgeMsg msg, NSDictionary *response, void (^resultBlock)(NSString *result)) {
        if (msg != TTBridgeMsgSuccess) {
            NSString *monitorName = [NSString stringWithFormat:@"js%@_invoke_method",@"bridge"];
            [BDMonitorProtocol hmdTrackService:monitorName
                                        metric:@{}
                                      category:@{@"status_code": @(msg),
                                                 @"engine_type" : @(self.engineType),
                                                 @"method_name" : methodName ?: @""
                                      }
                                         extra:@{@"webpage_url" : self.sourceURL.absoluteString ?: @"",}];
        }
        if (callback) {
            NSMutableDictionary *param = [NSMutableDictionary dictionary];
            param[@"code"] = @(msg);
            param[@"data"] = response ?: @{};
            command.bridgeMsg = msg;
            [TTBridgeRegister bridgeEngine:self willCallbackBridgeCommand:command];
            callback(@[[param copy]]);
            if (resultBlock) {
                resultBlock(nil);
            }
        }
    };
    if (![self respondsToBridge:command.bridgeName]) {
         BOOL shouldCallbackUnregisteredCommand = [TTBridgeRegister bridgeEngine:self shouldCallbackUnregisteredCommand:command];
         if (!shouldCallbackUnregisteredCommand) {
             return;
         }
    }
    if ([self.bridgeRegister respondsToBridge:methodName]) {
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
}

RCT_EXPORT_METHOD(on:(NSString *)methodName params:(NSDictionary *)params callback:(RCTResponseSenderBlock)callback) {
    NSParameterAssert(methodName);
    if (!methodName) {
        return;
    }
    if ([self.events containsObject:methodName]) {
        return;
    }
    if ([params[@"rootTag"] isKindOfClass:NSNumber.class]) {
        NSNumber *rootTag = params[@"rootTag"];
        self.sourceObject = [[self UIManager] viewForReactTag:rootTag];
    }

    [self.events addObject:methodName];
    [self addListener:methodName];
    __auto_type completion = ^(TTBridgeMsg msg, NSDictionary *response, void (^resultBlock)(NSString *result)) {
        if (callback) {
            NSMutableDictionary *param = [NSMutableDictionary dictionary];
            param[@"code"] = @(msg);
            param[@"data"] = response ?: @{};
          
            callback(@[[param copy]]);
            if (resultBlock) {
                resultBlock(nil);
            }
        }
    };
    TTBridgeCommand *command = [[TTBridgeCommand alloc] init];
    command.bridgeName = methodName;
    command.params = [params copy];
    command.bridgeType = TTBridgeTypeOn;
    
    if ([self.bridgeRegister respondsToBridge:methodName]) {
        [self.bridgeRegister executeCommand:command engine:self completion:completion];
    }
    else {
        [TTBridgeRegister.sharedRegister executeCommand:command engine:self completion:completion];
    }
}

#pragma mark - TTBridgeEngine

- (NSURL *)sourceURL {
    return self.bridge.bundleURL;
}

- (UIViewController *)sourceController {
    if (!_sourceController) {
        return [self.class correctTopViewControllerFor:(UIView *)self.sourceObject];
    }
    return _sourceController;
}

- (TTBridgeRegisterEngineType)engineType {
    return TTBridgeRegisterRN;
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

- (void)fireEvent:(TTBridgeName)eventName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    TTBridgeCommand *command = [TTBridgeCommand new];
    command.callbackID = eventName;
    command.bridgeName = eventName;
    command.bridgeType = TTBridgeTypeOn;
    NSMutableDictionary *wrapParams = [NSMutableDictionary dictionary];
    wrapParams[@"code"] = @(msg);
    wrapParams[@"data"] = params ?: @{};
    [self sendEventWithName:eventName body:[wrapParams copy]];
}

- (BOOL)respondsToBridge:(TTBridgeName)bridgeName {
    return [self.bridgeRegister respondsToBridge:bridgeName] ?: [TTBridgeRegister.sharedRegister respondsToBridge:bridgeName];
}

- (void)callbackBridge:(TTBridgeName)bridgeName params:(NSDictionary *)params {
    [self fireEvent:bridgeName params:params];
}

- (void)callbackBridge:(TTBridgeName)bridgeName params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [self fireEvent:bridgeName msg:TTBridgeMsgSuccess params:params resultBlock:resultBlock];
}

- (void)callbackBridge:(TTBridgeName)bridgeName msg:(TTBridgeMsg)msg params:(NSDictionary *)params resultBlock:(void (^)(NSString *))resultBlock {
    [self fireEvent:bridgeName msg:msg params:params resultBlock:resultBlock];
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
    if(!topResponder)
    {
        topResponder = [[[UIApplication sharedApplication] delegate].window rootViewController];
    }
    
    return (UIViewController*)topResponder;
}

- (TTBridgeRegister *)bridgeRegister {
    if (!_bridgeRegister) {
        _bridgeRegister = TTBridgeRegister.new;
    }
    return _bridgeRegister;
}

@end

@implementation RCTBridge (TTRNBridgeEngine)

- (TTRNBridgeEngine *)tt_engine {
    return [self moduleForName:@"TTBridge"];
}

@end
