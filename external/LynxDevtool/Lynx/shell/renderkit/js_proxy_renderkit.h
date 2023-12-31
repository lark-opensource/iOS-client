//
// Created by admin on 2021/8/16.
//

#ifndef LYNX_SHELL_RENDERKIT_JS_PROXY_RENDERKIT_H_
#define LYNX_SHELL_RENDERKIT_JS_PROXY_RENDERKIT_H_

#include <memory>
#include <string>
#include <utility>

#include "shell/lynx_shell.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {
namespace shell {
class JsProxyRenderkit {
 public:
  JsProxyRenderkit(std::shared_ptr<LynxActor<runtime::LynxRuntime>> actor)
      : actor_(std::move(actor)) {}
  ~JsProxyRenderkit() = default;
  void CallJSFunction(std::string module_id, std::string method_id,
                      const lepus::Value& params);

  void CallJSFunction(std::string module_id, std::string method_id,
                      const EncodableList& params);

  void CallJSIntersectionObserver(int32_t observer_id, int32_t callback_id,
                                  const std::string& data) {}

  void EvaluateScript(const std::string& url, std::string script,
                      int32_t callback_id);

  void RejectDynamicComponentLoad(const std::string& url, int32_t callback_id,
                                  int32_t err_code, const std::string& err_msg);

 private:
  std::shared_ptr<LynxActor<runtime::LynxRuntime>> actor_;
};
}  // namespace shell
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_JS_PROXY_RENDERKIT_H_
