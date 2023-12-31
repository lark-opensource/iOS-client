// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_BASE_IOS_LYNX_ENV_DARWIN_H_
#define LYNX_BASE_IOS_LYNX_ENV_DARWIN_H_

#import <Foundation/Foundation.h>
#include <string>

namespace lynx {
namespace base {

class LynxEnvDarwin {
 public:
  LynxEnvDarwin() = delete;
  ~LynxEnvDarwin() = delete;

  static void onPiperInvoked(const std::string& module_name, const std::string& method_name,
                             const std::string& param_str, const std::string& url,
                             const std::string& invoke_session);
  static void onPiperResponsed(const std::string& module_name, const std::string& method_name,
                               const std::string& url, NSDictionary* response,
                               const std::string& invoke_session);

  static void initNativeUIThread();
};

}  // namespace base
}  // namespace lynx

#endif  // LYNX_BASE_IOS_LYNX_ENV_DARWIN_H_
