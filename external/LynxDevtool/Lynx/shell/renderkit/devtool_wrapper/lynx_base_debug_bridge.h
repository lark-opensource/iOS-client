// Copyright 2022 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_DEBUG_BRIDGE_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_DEBUG_BRIDGE_H_

#include <functional>
#include <string>
#include <unordered_map>

#include "shell/renderkit/devtool_wrapper/devtool_reflect_helper.h"

namespace lynx {
namespace devtool {

using LynxDevtoolOpenCardCallback = std::function<void(const std::string &)>;

class LynxBaseDebugBridge : public DevtoolObject {
 public:
  virtual ~LynxBaseDebugBridge() = default;
  virtual bool Enable(
      const std::string &url,
      const std::unordered_map<std::string, std::string> &options) = 0;
  virtual void SetOpenCardCallback(LynxDevtoolOpenCardCallback callback) = 0;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_DEBUG_BRIDGE_H_
