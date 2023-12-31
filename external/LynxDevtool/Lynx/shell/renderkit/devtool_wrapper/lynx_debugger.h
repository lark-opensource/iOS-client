// Copyright 2022 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_DEBUGGER_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_DEBUGGER_H_

#include <string>
#include <unordered_map>

#include "lynx_export.h"
#include "shell/renderkit/devtool_wrapper/lynx_base_debug_bridge.h"

namespace lynx {
namespace devtool {

class LYNX_EXPORT LynxDebugger {
 public:
  static bool ConnectDevtool(
      const std::string& url,
      const std::unordered_map<std::string, std::string>& options);

  static void SetOpenCardCallback(LynxDevtoolOpenCardCallback callback);

  static bool OpenDebugPanel(double dpi);

  static void CloseDebugPanel();
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_DEBUGGER_H_
