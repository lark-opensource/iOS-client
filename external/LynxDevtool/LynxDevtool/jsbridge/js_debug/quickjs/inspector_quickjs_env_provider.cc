// Copyright 2022 The Lynx Authors. All rights reserved.

#include "jsbridge/js_debug/quickjs/inspector_quickjs_env_provider.h"

#include "jsbridge/js_debug/quickjs/inspector_client_quickjs_impl.h"

#if defined(OS_ANDROID) || defined(OS_IOS)
#include "jsbridge/quickjs/quickjs_api.h"
#include "jsbridge/quickjs/quickjs_runtime.h"
#endif

namespace lynx {
namespace devtool {
std::shared_ptr<piper::Runtime> InspectorQuickjsEnvProvider::MakeRuntime() {
  LOGI("enter InspectorQuickjsEnvProvider::MakeRuntime");
#if defined(OS_ANDROID) || defined(OS_IOS)
  LOGI("make QuickJS runtime");
  return piper::makeQuickJsRuntime();
#else
  return nullptr;
#endif
}

std::shared_ptr<InspectorClient>
InspectorQuickjsEnvProvider::MakeInspectorClient(ClientType type) {
  LOGI("enter InspectorQuickjsEnvProvider::MakeInspectorClient");
  return std::shared_ptr<InspectorClient>(new InspectorClientQuickJSImpl(type));
}
}  // namespace devtool
}  // namespace lynx
