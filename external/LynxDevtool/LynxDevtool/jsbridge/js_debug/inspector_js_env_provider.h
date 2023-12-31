// Copyright 2019 The Lynx Authors. All rights reserved.

#ifndef LYNX_INSPECTOR_JS_ENV_PROVIDER_H_
#define LYNX_INSPECTOR_JS_ENV_PROVIDER_H_

#include "jsbridge/js_debug/inspector_client.h"
#include "jsbridge/jsi/jsi.h"

namespace lynx {
namespace devtool {

class InspectorJsEnvProvider {
 public:
  virtual ~InspectorJsEnvProvider(){};
  virtual std::shared_ptr<piper::Runtime> MakeRuntime() = 0;
  virtual std::shared_ptr<InspectorClient> MakeInspectorClient(
      ClientType type) = 0;
};

}  // namespace devtool
}  // namespace lynx

#endif /* LYNX_INSPECTOR_JS_ENV_PROVIDER_H_ */
