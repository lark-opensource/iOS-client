// Copyright 2021 The Lynx Authors. All rights reserved.

#import "LynxUI.h"
#import <ByteWebView/BDWebView.h>
#import <BDWebView+TTBridgeUnify.h>
NS_ASSUME_NONNULL_BEGIN

@class BDWebView;
@interface BDXLynxWebView : LynxUI <BDWebView *>

+ (void)registerBridge:(void (^)(TTBridgeRegisterMaker * _Nonnull))block forContainerId:(NSString *)containerId;
+ (void)unregisterBridge:(NSString *)containerId;

@end

NS_ASSUME_NONNULL_END
