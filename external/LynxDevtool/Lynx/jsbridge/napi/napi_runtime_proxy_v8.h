// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_V8_H_
#define LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_V8_H_

#include <memory>

#include "jsbridge/napi/napi_runtime_proxy.h"
#include "jsbridge/napi/napi_runtime_proxy_v8_factory.h"

namespace lynx {
namespace piper {

class V8ContextWrapper;

class NapiRuntimeProxyV8 : public NapiRuntimeProxy {
 public:
  static std::unique_ptr<NapiRuntimeProxy> Create(
      std::shared_ptr<V8ContextWrapper> context,
      runtime::TemplateDelegate *delegate = nullptr);
  NapiRuntimeProxyV8(std::shared_ptr<V8ContextWrapper> context,
                     runtime::TemplateDelegate *delegate);

  void Attach() override;
  void Detach() override;

 private:
  // weak_ptr is a workaround for context leak in shared context mode.
  std::weak_ptr<V8ContextWrapper> context_;
};

class NapiRuntimeProxyV8FactoryImpl : public NapiRuntimeProxyV8Factory {
 public:
  std::unique_ptr<NapiRuntimeProxy> Create(
      std::shared_ptr<Runtime> runtime,
      runtime::TemplateDelegate *delegate = nullptr);
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_V8_H_
