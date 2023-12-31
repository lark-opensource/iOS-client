// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxInstanceTrace.h"

#if LYNX_ENABLE_TRACING
#import "tracing/platform/instance_trace_plugin_darwin.h"
#endif

@implementation LynxInstanceTrace {
#if LYNX_ENABLE_TRACING
  std::unique_ptr<lynx::base::tracing::InstanceTracePluginDarwin> _instance_trace_plugin;
#endif
}

+ (instancetype)shareInstance {
  static LynxInstanceTrace *instance;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    instance = [[self alloc] init];
  });
  return instance;
}

- (id)init {
  if (self = [super init]) {
#if LYNX_ENABLE_TRACING
    _instance_trace_plugin = std::make_unique<lynx::base::tracing::InstanceTracePluginDarwin>();
#endif
  }
  return self;
}

- (intptr_t)getInstanceTracePlugin {
#if LYNX_ENABLE_TRACING
  return reinterpret_cast<intptr_t>(_instance_trace_plugin.get());
#endif
  return 0;
}

@end
