// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_JS_MODULE_H_
#define LYNX_SHELL_RENDERKIT_JS_MODULE_H_

#include <memory>
#include <string>

#include "shell/renderkit/js_proxy_renderkit.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {

class JsModule {
 public:
  explicit JsModule(const std::string& module_name);
  void SetJSProxy(const std::shared_ptr<lynx::shell::JsProxyRenderkit> proxy);
  void Fire(const std::string& method_name, const lepus_value& params);
  void Fire(const std::string& method_name, const EncodableList& params);

 private:
  std::string module_name_;
  std::weak_ptr<lynx::shell::JsProxyRenderkit> proxy_;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_JS_MODULE_H_
