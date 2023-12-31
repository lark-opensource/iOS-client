// Copyright 2019 The Lynx Authors. All rights reserved.

#import "inspector_v8_env.h"
#include "inspector_v8_env_provider.h"

@implementation InspectorV8Env

+ (void)initEnv {
  lynx::devtool::InspectorClient::SetJsEnvProvider(new lynx::devtool::InspectorV8EnvProvider());
}
@end
