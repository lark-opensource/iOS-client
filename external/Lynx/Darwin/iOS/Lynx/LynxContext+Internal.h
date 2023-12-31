// Copyright 2019 The Lynx Authors. All rights reserved.

#import <Lynx/LynxContext.h>
#import <Lynx/LynxProviderRegistry.h>
#import <Lynx/LynxView.h>
#include "shell/ios/js_proxy_darwin.h"

@class LynxUIIntersectionObserverManager;
@class LynxUIOwner;

@interface LynxContext () {
 @public
  std::shared_ptr<lynx::shell::JSProxyDarwin> proxy_;
}

@property(nonatomic, weak) LynxUIOwner* _Nullable uiOwner;
@property(nonatomic, weak) LynxUIIntersectionObserverManager* _Nullable intersectionManager;
@property(nonatomic, weak) LynxView* _Nullable lynxView;
@property(nonatomic) LynxProviderRegistry* _Nullable providerRegistry;

- (nonnull instancetype)initWithLynxView:(LynxView* _Nullable)lynxView;
- (void)setJSProxy:(const std::shared_ptr<lynx::shell::JSProxyDarwin>&)proxy;
@end
