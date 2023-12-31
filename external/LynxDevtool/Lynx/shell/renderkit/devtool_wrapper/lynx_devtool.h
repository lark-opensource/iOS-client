// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_DEVTOOL_H_
#define LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_DEVTOOL_H_

#include <memory>
#include <string>
#include <vector>

#include "shell/renderkit/devtool_wrapper/lynx_base_inspector_owner.h"
#include "shell/renderkit/lynx_page_reload_helper.h"
#include "shell/renderkit/public/lynx_template_data.h"
#include "shell/renderkit/public/lynx_view_base.h"

namespace lynx {

namespace devtool {
class LynxBaseRedbox;
}

class LynxDevtool {
 public:
  explicit LynxDevtool(LynxViewBase* view);
  ~LynxDevtool() = default;

  void OnLoadFromLocalFile(const std::vector<uint8_t>& tem,
                           const std::string& url, LynxTemplateData* data);
  void OnLoadFromURL(const std::string& url, LynxTemplateData* data);
  void OnTemplateAssemblerCreated(intptr_t ptr);
  void OnEnterForeground();
  void OnEnterBackground();
  void OnLoadFinished();
  void AttachLynxView(LynxViewBase* view);

  void ShowErrorMessage(const std::string& message);

  void SetSharedVM(const std::unique_ptr<LynxGroup>& group);

  void DestroyDebugger();

 private:
  LynxViewBase* lynx_view_;
  std::shared_ptr<devtool::LynxBaseInspectorOwner> owner_;
  std::shared_ptr<devtool::LynxPageReloadHelper> reloader_;
  std::shared_ptr<devtool::LynxBaseRedbox> redbox_;
};
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_DEVTOOL_WRAPPER_LYNX_DEVTOOL_H_
