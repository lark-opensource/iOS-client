// Copyright 2021 The Lynx Authors. All rights reserved.

#include "jsbridge/napi/napi_runtime_proxy_jsc.h"

#include <JavaScriptCore/JavaScript.h>

#include <utility>

#include "jsbridge/napi/shim/shim_napi_env_jsc.h"

namespace lynx {
namespace piper {

// static
std::unique_ptr<NapiRuntimeProxy> NapiRuntimeProxyJSC::Create(
    std::shared_ptr<JSCContextWrapper> context,
    runtime::TemplateDelegate *delegate) {
  return std::unique_ptr<NapiRuntimeProxy>(
      new NapiRuntimeProxyJSC(std::move(context), delegate));
}

NapiRuntimeProxyJSC::NapiRuntimeProxyJSC(
    std::shared_ptr<JSCContextWrapper> context,
    runtime::TemplateDelegate *delegate)
    : NapiRuntimeProxy(delegate), context_(context) {}

void NapiRuntimeProxyJSC::Attach() {
  auto ctx = context_.lock();
  if (ctx) {
    napi_attach_jsc(env_, ctx->getContext());
  }
}

void NapiRuntimeProxyJSC::Detach() {
  NapiRuntimeProxy::Detach();
  napi_detach_jsc(env_);
}

}  // namespace piper
}  // namespace lynx
