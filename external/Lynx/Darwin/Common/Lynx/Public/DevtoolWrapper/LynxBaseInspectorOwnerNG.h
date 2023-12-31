// Copyright 2021 The Lynx Authors. All rights reserved.

#import "CustomizedMessage.h"
#import "LynxBaseInspectorOwner.h"

@protocol MessageHandler <NSObject>

@required
- (void)onMessage:(NSString *)message;

@end

@protocol LynxBaseInspectorOwnerNG <LynxBaseInspectorOwner>

@required
- (void)sendMessage:(CustomizedMessage *)message;
- (void)subscribeMessage:(NSString *)type withHandler:(id<MessageHandler>)handler;
- (void)unsubscribeMessage:(NSString *)type;

- (void)invokeCdp:(NSString *)type message:(NSString *)message callback:(LynxCallbackBlock)callback;

// methods below only support iOS platform now, empty implementation on macOS now
- (void)responseCdpWithUtf8String:(const char *)response;

@end
