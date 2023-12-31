// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_LYNX_CONTEXT_H_
#define LYNX_SHELL_RENDERKIT_LYNX_CONTEXT_H_

#include <encodable_value.h>

#include <memory>
#include <string>

#include "shell/renderkit/js_module.h"
#include "shell/renderkit/js_proxy_renderkit.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {

class LynxViewBase;

class LynxContext {
 public:
  explicit LynxContext(LynxViewBase* lynx_view);
  void SendGlobalEvent(const std::string& name, const lepus_value& params);
  void SendGlobalEvent(const std::string& name, const EncodableList& params);
  std::unique_ptr<JsModule> GetJsModule(const std::string& name);

  int GetLynxRuntimeId();
  void ReportModuleCustomError(const std::string& message);
  LynxViewBase* GetLynxView();
  void SetJSProxy(std::shared_ptr<lynx::shell::JsProxyRenderkit> proxy);

 private:
  std::shared_ptr<lynx::shell::JsProxyRenderkit> proxy_;
  LynxViewBase* lynx_view_ = nullptr;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_LYNX_CONTEXT_H_
