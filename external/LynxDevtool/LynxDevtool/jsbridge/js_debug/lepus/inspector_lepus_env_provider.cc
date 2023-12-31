// Copyright 2021 The Lynx Authors. All rights reserved.

#include "jsbridge/js_debug/lepus/inspector_lepus_env_provider.h"

#include "jsbridge/js_debug/lepus/inspector_client_lepus_impl.h"

namespace lynx {
namespace devtool {
std::shared_ptr<piper::Runtime> InspectorLepusEnvProvider::MakeRuntime() {
  return nullptr;
}

std::shared_ptr<InspectorClient> InspectorLepusEnvProvider::MakeInspectorClient(
    ClientType type) {
  LOGI("enter InspectorQuickJSEnvProvider::MakeInspectorClient");
  return std::shared_ptr<InspectorClient>(new InspectorClientLepusImpl(type));
}
}  // namespace devtool
}  // namespace lynx
