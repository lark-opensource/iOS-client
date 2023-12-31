// Copyright 2023 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_WINDOW_DEVTOOL_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_WINDOW_DEVTOOL_H_

#include "shell/renderkit/devtool_wrapper/devtool_reflect_helper.h"

namespace lynx {
namespace devtool {

class LynxBaseWindowDevTool : public DevtoolObject {
 public:
  LynxBaseWindowDevTool() = default;
  virtual ~LynxBaseWindowDevTool() = default;

  virtual void OpenDevtoolLynxView(double dpi) = 0;
  virtual void CloseDevToolLynxView() = 0;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_WINDOW_DEVTOOL_H_
