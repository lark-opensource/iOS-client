// Copyright 2021 The Lynx Authors. All rights reserved.
#ifndef LYNX_INSPECTOR_JS_DEBUG_LEPUS_INSPECTOR_LEPUS_ENV_PROVIDER_H
#define LYNX_INSPECTOR_JS_DEBUG_LEPUS_INSPECTOR_LEPUS_ENV_PROVIDER_H

#include "jsbridge/js_debug/inspector_js_env_provider.h"

namespace lynx {
namespace devtool {

class InspectorLepusEnvProvider : public InspectorJsEnvProvider {
 public:
  std::shared_ptr<piper::Runtime> MakeRuntime() override;
  std::shared_ptr<InspectorClient> MakeInspectorClient(
      ClientType type) override;
};

}  // namespace devtool
}  // namespace lynx

#endif  // LYNX_INSPECTOR_JS_DEBUG_LEPUS_INSPECTOR_LEPUS_ENV_PROVIDER_H
