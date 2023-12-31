// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_DEVTOOL_ENV_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_DEVTOOL_ENV_H_

#include <string>

#include "shell/renderkit/devtool_wrapper/devtool_reflect_helper.h"

namespace lynx {
namespace devtool {

class LynxBaseDevtoolEnv : public DevtoolObject {
 public:
  virtual ~LynxBaseDevtoolEnv() = default;
  virtual void Set(const std::string& key, bool value) = 0;
  virtual bool Get(const std::string& key, bool default_value) = 0;

 protected:
  LynxBaseDevtoolEnv() = default;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_DEVTOOL_ENV_H_
