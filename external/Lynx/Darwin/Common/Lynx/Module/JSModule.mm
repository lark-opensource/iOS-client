// Copyright 2019 The Lynx Authors. All rights reserved.

#import "JSModule+Internal.h"
#import "LynxDefines.h"

@implementation JSModule {
  std::weak_ptr<lynx::shell::JSProxyDarwin> proxy_;
}

LYNX_NOT_IMPLEMENTED(-(instancetype)init)

- (instancetype)initWithModuleName:(nonnull NSString*)moduleName {
  self = [super init];
  self.moduleName = moduleName;
  return self;
}

- (void)fire:(nonnull NSString*)methodName withParams:(NSArray*)args {
  auto proxy = proxy_.lock();
  if (proxy != nullptr) {
    proxy->CallJSFunction(self.moduleName, methodName, args);
  }
}

- (void)setJSProxy:(const std::shared_ptr<lynx::shell::JSProxyDarwin>&)proxy {
  proxy_ = proxy;
}

@end
