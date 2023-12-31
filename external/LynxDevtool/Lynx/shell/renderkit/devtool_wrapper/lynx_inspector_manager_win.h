// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_INSPECTOR_MANAGER_WIN_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_INSPECTOR_MANAGER_WIN_H_

#include <memory>
#include <string>

#include "inspector/inspector_manager.h"
#include "shell/renderkit/devtool_wrapper/lynx_base_inspector_owner.h"
#include "shell/renderkit/public/lynx_view_base.h"

namespace lynx {
namespace devtool {
class LynxInspectorManagerWin
    : public std::enable_shared_from_this<LynxInspectorManagerWin> {
 public:
  explicit LynxInspectorManagerWin(
      const std::shared_ptr<LynxBaseInspectorOwner>& owner);
  ~LynxInspectorManagerWin() = default;

  void Init();

  void OnTemplateAssemblerCreated(intptr_t ptr);

  void Call(const std::string& function, const std::string& params);

  intptr_t GetLynxDevtoolFunction();

  intptr_t GetFirstPerfContainer();

  void SetLynxEnvKey(const std::string& key, bool value);

  void SendConsoleMessage(const std::string& message, int32_t level,
                          int64_t time_stamp);

  void RunOnJSThread(intptr_t closure);

  intptr_t GetNativePtr();

  intptr_t GetJavascriptDebugger();

  intptr_t CreateInspectorRuntimeManager();

 private:
  int32_t connection_id_;
  std::weak_ptr<LynxBaseInspectorOwner> owner_;
  std::shared_ptr<InspectorManager> inspector_manager_;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_INSPECTOR_MANAGER_WIN_H_
