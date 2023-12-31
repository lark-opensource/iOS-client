//  Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_TASM_IOS_CONFIG_DARWIN_H_
#define LYNX_TASM_IOS_CONFIG_DARWIN_H_

#include <string>

namespace lynx {
namespace tasm {

class LynxConfigDarwin {
 public:
  LynxConfigDarwin() = delete;
  ~LynxConfigDarwin() = delete;

  static std::string getExperimentSettings(const std::string& key);
};
}  // namespace tasm
}  // namespace lynx

#endif  // LYNX_TASM_IOS_CONFIG_DARWIN_H_
