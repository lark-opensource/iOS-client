//
//  FlutterBridge.h
//  FlutterIntergation
//
//  Created by bytedance on 2020/4/2.
//  Copyright © 2020 bytedance. All rights reserved.
//

#import "BDBaseFlutterBridge.h"
#import "BDMethodProtocol.h"

NS_ASSUME_NONNULL_BEGIN

@interface BDFlutterBridge : BDBaseFlutterBridge

- (void)delegateMessenger:(NSObject *)messenger;

- (void)sendEvent:(NSString *)name data:(NSDictionary *)data;

+ (void)registHandlerName:(NSString *)handlerName hander:(id<BDBridgeMethod>)handler;

+ (void)registHandlerName:(NSString *)handlerName handleClass:(Class)clazz;

+ (void)cancelRegisterHandler:(NSString *)handlerName;

@end

NS_ASSUME_NONNULL_END
