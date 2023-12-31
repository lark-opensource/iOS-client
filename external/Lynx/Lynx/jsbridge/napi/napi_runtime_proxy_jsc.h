// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_JSC_H_
#define LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_JSC_H_

#include <memory>

#include "jsbridge/jsc/jsc_context_wrapper.h"
#include "jsbridge/napi/napi_runtime_proxy.h"

namespace lynx {
namespace piper {

class NapiRuntimeProxyJSC : public NapiRuntimeProxy {
 public:
  static std::unique_ptr<NapiRuntimeProxy> Create(
      std::shared_ptr<JSCContextWrapper> context,
      runtime::TemplateDelegate *delegate = nullptr);
  NapiRuntimeProxyJSC(std::shared_ptr<JSCContextWrapper> context,
                      runtime::TemplateDelegate *delegate);

  void Attach() override;
  void Detach() override;

 private:
  // weak_ptr is a workaround for context leak in shared context mode.
  std::weak_ptr<JSCContextWrapper> context_;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_JSC_H_
