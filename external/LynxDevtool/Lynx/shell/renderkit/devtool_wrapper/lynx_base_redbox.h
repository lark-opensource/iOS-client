// Copyright 2022 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_REDBOX_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_REDBOX_H_
#include <memory>
#include <string>

namespace lynx {

class LynxViewBase;

namespace devtool {

class LynxPageReloadHelper;

enum class RedboxLogLevel { kInfo = 0, kWarning, kError };

class LynxBaseRedbox {
 public:
  virtual void ShowErrorMessage(const std::string& message) = 0;
  virtual void Init(LynxViewBase* view,
                    const std::shared_ptr<LynxBaseRedbox>& shared_self) = 0;
  virtual void SetPageReloadHelper(
      const std::shared_ptr<lynx::devtool::LynxPageReloadHelper>&
          reload_helper) = 0;
  virtual void OnLoadLynxView() = 0;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_BASE_REDBOX_H_
