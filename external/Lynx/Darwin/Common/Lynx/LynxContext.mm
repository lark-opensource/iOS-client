// Copyright 2019 The Lynx Authors. All rights reserved.

#import "JSModule+Internal.h"
#import "LynxContext+Internal.h"
#import "LynxGetUIResultDarwin.h"
#import "LynxLog.h"
#import "LynxTemplateRender.h"
#import "LynxView+Internal.h"

@implementation LynxContext

- (instancetype)initWithLynxView:(LynxView *)lynxView {
  if (self = [super init]) {
    _lynxView = lynxView;
  }
  return self;
}

- (void)setJSProxy:(const std::shared_ptr<lynx::shell::JSProxyDarwin> &)proxy {
  proxy_ = proxy;
}

- (void)sendGlobalEvent:(nonnull NSString *)name withParams:(nullable NSArray *)params {
  auto eventEmitter = [self getJSModule:@"GlobalEventEmitter"];
  NSMutableArray *args = [[NSMutableArray alloc] init];
  // if name is nil, it will crash. To avoid crash, let name be @"";
  if (name == nil) {
    LLogWarn(@"Lynx sendGlobalEvent warning: name is nil");
    [args addObject:@""];
  } else {
    [args addObject:name];
  }
  // if params is nil, it will crash. To avoid crash, let params be [];
  if (params == nil) {
    LLogWarn(@"Lynx sendGlobalEvent warning: params is nil");
    [args addObject:[[NSArray alloc] init]];
  } else {
    [args addObject:params];
  }
  [eventEmitter fire:@"emit" withParams:args];
}

- (nullable JSModule *)getJSModule:(nonnull NSString *)name {
  auto module = [[JSModule alloc] initWithModuleName:name];
  [module setJSProxy:proxy_];
  return module;
}

- (NSNumber *)getLynxRuntimeId {
  if (proxy_) {
    return [NSNumber numberWithLongLong:proxy_->GetId()];
  }
  return @(-1);
}

// issue: #1510
- (void)reportModuleCustomError:(NSString *)message {
  [_lynxView.templateRender onErrorOccurred:LYNX_ERROR_CODE_MODULE_BUSINESS_ERROR message:message];
}

- (nullable LynxView *)getLynxView {
  return _lynxView;
}

- (void)dealloc {
  LLogInfo(@"LynxContext destroy: %p", self);
}

- (void)runOnTasmThread:(dispatch_block_t)task {
  [_lynxView runOnTasmThread:task];
}

@end
