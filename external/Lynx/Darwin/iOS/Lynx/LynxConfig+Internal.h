// Copyright 2019 The Lynx Authors. All rights reserved.

#import "LynxConfig.h"
#include "jsbridge/ios/piper/lynx_module_manager_darwin.h"

@interface LynxConfig ()
- (std::shared_ptr<lynx::piper::ModuleManagerDarwin>)moduleManagerPtr;
@end
