// Copyright 2019 The Lynx Authors. All rights reserved.
#ifndef LYNX_INSPECTOR_JS_DEBUG_V8_INSPECTOR_V8_ENV_PROVIDER_H_
#define LYNX_INSPECTOR_JS_DEBUG_V8_INSPECTOR_V8_ENV_PROVIDER_H_

#include "jsbridge/js_debug/inspector_js_env_provider.h"

namespace lynx {
namespace devtool {

class InspectorV8EnvProvider : public InspectorJsEnvProvider {
 public:
  std::shared_ptr<piper::Runtime> MakeRuntime() override;
  std::shared_ptr<InspectorClient> MakeInspectorClient(
      ClientType type) override;
};

}  // namespace devtool
}  // namespace lynx

#endif /* LYNX_INSPECTOR_JS_DEBUG_V8_INSPECTOR_V8_ENV_PROVIDER_H_ */
