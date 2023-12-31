// Copyright 2019 The Lynx Authors. All rights reserved.
#include "inspector_v8_env_provider.h"

#if !(defined(OS_IOS) && (defined(__i386__) || defined(__arm__)))
#include "jsbridge/js_debug/v8/inspector_client_v8_impl.h"
#include "jsbridge/v8/v8_api.h"
#include "jsbridge/v8/v8_runtime.h"
#endif

namespace lynx {
namespace devtool {

std::shared_ptr<piper::Runtime> InspectorV8EnvProvider::MakeRuntime() {
  LOGI("enter InspectorV8EnvProvider::MakeRuntime");
#if !(defined(OS_IOS) && (defined(__i386__) || defined(__arm__)))
  LOGI("make V8 runtime");
  return piper::makeV8Runtime();
#else
  return nullptr;
#endif
}

std::shared_ptr<InspectorClient> InspectorV8EnvProvider::MakeInspectorClient(
    ClientType type) {
  LOGI("enter InspectorV8EnvProvider::MakeInspectorClient");
#if !(defined(OS_IOS) && (defined(__i386__) || defined(__arm__)))
  return std::shared_ptr<InspectorClient>(new InspectorClientV8Impl(type));
#else
  return nullptr;
#endif
}

}  // namespace devtool
}  // namespace lynx
