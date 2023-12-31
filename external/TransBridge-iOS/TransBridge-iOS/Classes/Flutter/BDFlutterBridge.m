//
//  FlutterBridge.m
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDFlutterBridge.h"
#import "BDFlutterBridgeHost.h"
#import <BDFlutterProtocol.h>
#import "BDFlutterMethodManager.h"
#import "BDFlutterMethodCallHandler.h"

@interface BDFlutterBridge()
@property (nonatomic, weak) id messenger;
@end

@implementation BDFlutterBridge

- (id<FLTBMethodChannel>)bindChannel:(NSObject *)messenger {
    self.messenger = messenger;
    id<FLTBMethodChannel> channel = [self createMethodChannelForMessager:messenger];
    [channel setMethodCallHandler:^(id<FLTBMethodCall> data, FLTBResponseCallback callback) {
        BDFlutterMethodCallHandler *callHandler = [[BDFlutterMethodCallHandler alloc] init];
        [callHandler call:data.method arguments:data.arguments forMessager:messenger completion:callback];
    }];
    return channel;
}

- (void)delegateMessenger:(NSObject *)messenger {
    id<FLTBMethodChannel> channel = [self bindChannel:messenger];
    BDFlutterBridgeHost *flutterHost = [[BDFlutterBridgeHost alloc] initWithCarrier:messenger methodChannel:channel];
    [BDBridgeHost addHost:flutterHost];
}

- (void)sendEvent:(NSString *)name data:(NSDictionary *)data {
    [[BDBridgeHost getHostByCarrier:self.messenger] sendEvent:name data:data];
}

+ (void)registHandlerName:(NSString *)handlerName handleClass:(Class)clazz {
    [[BDFlutterMethodManager sharedManager] registClass:clazz forName:handlerName];
}

+ (void)registHandlerName:(NSString *)handlerName hander:(id<BDBridgeMethod>)handler {
    [[BDFlutterMethodManager sharedManager] registMethod:handler forName:handlerName];
}

+ (void)cancelRegisterHandler:(NSString *)handlerName {
    [[BDFlutterMethodManager sharedManager] cancelRegistName:handlerName];
}

@end
