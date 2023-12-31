// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxComponentRegistry.h"
#import "LynxConfig+Internal.h"
#import "LynxDefines.h"
#import "LynxEnv.h"
#import "LynxLog.h"

#include "jsbridge/ios/piper/lynx_module_manager_darwin.h"

@implementation LynxConfig {
#if OS_IOS
  std::shared_ptr<lynx::piper::ModuleManagerDarwin> _managerPtr;
#else
  std::shared_ptr<lynx::piper::ModuleManagerRenderkit<lynx::piper::ModuleManagerDarwin> >
      _managerPtr;
#endif
}

LYNX_NOT_IMPLEMENTED(-(instancetype)init)

- (instancetype)initWithProvider:(id<LynxTemplateProvider>)provider {
  self = [super init];
  if (self) {
    _templateProvider = provider;
#if OS_IOS
    _managerPtr = std::make_shared<lynx::piper::ModuleManagerDarwin>();
#else
    _managerPtr =
        std::shared_ptr<lynx::piper::ModuleManagerRenderkit<lynx::piper::ModuleManagerDarwin> >(
            new lynx::piper::ModuleManagerRenderkit<lynx::piper::ModuleManagerDarwin>(nullptr));
#endif
    _componentRegistry = [LynxComponentScopeRegistry new];
  }
  return self;
}

- (void)registerModule:(Class<LynxModule>)module {
  _managerPtr->registerModule(module);
}

- (void)registerModule:(Class<LynxModule>)module param:(id)param {
  _managerPtr->registerModule(module, param);
}

- (void)registerMethodAuth:(LynxMethodBlock)authBlock {
  _managerPtr->registerMethodAuth(authBlock);
}

- (void)registerContext:(NSDictionary *)ctxDict sessionInfo:(LynxMethodSessionBlock)sessionInfo {
  if (!_contextDict) {
    _contextDict = [[NSMutableDictionary alloc] init];
  }
  [_contextDict addEntriesFromDictionary:ctxDict];
  _managerPtr->registerExtraInfo(ctxDict);
  _managerPtr->registerMethodSession(sessionInfo);
}

#if OS_IOS
- (std::shared_ptr<lynx::piper::ModuleManagerDarwin>)moduleManagerPtr {
  return _managerPtr;
}
#else
- (std::shared_ptr<lynx::piper::ModuleManagerRenderkit<lynx::piper::ModuleManagerDarwin> >)
    moduleManagerPtr {
  return _managerPtr;
}
#endif

- (void)registerUI:(Class)ui withName:(NSString *)name {
  if (ui == NSClassFromString(@"LynxHeliumCanvas")) {
    // canvas may be replaced by enable_canvas_optimize and settings etc.
    // !! Do not allow to register LynxHeliumCanvas here !!!
    LLogInfo(@"Ignore external register LynxHeliumCanvas for %@", name);
    return;
  }

  [_componentRegistry registerUI:ui withName:name];
}

- (void)registerShadowNode:(Class)node withName:(NSString *)name {
  [_componentRegistry registerShadowNode:node withName:name];
}

+ (LynxConfig *)globalConfig {
  return [LynxEnv sharedInstance].config;
}

+ (void)prepareGlobalConfig:(LynxConfig *)config {
  [[LynxEnv sharedInstance] prepareConfig:config];
}

- (void)setRenderkitImpl:(void *)renderkit_impl {
#if OS_OSX
  _managerPtr->SetRenderkitImpl(renderkit_impl);
#endif
}

@end
