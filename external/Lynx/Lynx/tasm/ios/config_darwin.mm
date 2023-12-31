//  Copyright 2022 The Lynx Authors. All rights reserved.

#import "config_darwin.h"
#import <Foundation/Foundation.h>
#if OS_IOS
#import "LynxEnv.h"
#endif

namespace lynx {
namespace tasm {

std::string LynxConfigDarwin::getExperimentSettings(const std::string &key) {
#if OS_IOS
  NSString *value = [LynxEnv getExperimentSettings:[NSString stringWithUTF8String:key.c_str()]];
  if (value) {
    return [value UTF8String];
  }
#endif
  return "";
}
}  // namespace tasm
}  // namespace lynx
