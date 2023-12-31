// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/napi/napi_runtime_proxy_quickjs_factory_impl.h"

#include "base/lynx_env.h"
#include "jsbridge/napi/napi_runtime_proxy_quickjs.h"
#include "jsbridge/quickjs/quickjs_runtime.h"

namespace lynx {
namespace piper {

std::unique_ptr<NapiRuntimeProxy> NapiRuntimeProxyQuickjsFactoryImpl::Create(
    std::shared_ptr<Runtime> runtime, runtime::TemplateDelegate *delegate) {
#if OS_IOS
  if (base::LynxEnv::GetInstance().ShouldEnableQuickjsDebug()) {
    LOGI("Creating napi proxy quickjs");
    auto qjs_runtime = std::static_pointer_cast<QuickjsRuntime>(runtime);
    auto context = qjs_runtime->getSharedContext();
    auto qjs_context = std::static_pointer_cast<QuickjsContextWrapper>(context);
    return NapiRuntimeProxyQuickjs::Create(qjs_context->getContext(), delegate);
  } else {
    return nullptr;
  }
#else
  return nullptr;
#endif
}

}  // namespace piper
}  // namespace lynx
