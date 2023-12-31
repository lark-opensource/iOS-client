// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_QUICKJS_FACTORY_H_
#define LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_QUICKJS_FACTORY_H_

#include <memory>

#include "jsbridge/napi/napi_runtime_proxy.h"

namespace lynx {
namespace piper {

// Used by Devtool on iOS.
class NapiRuntimeProxyQuickjsFactory {
 public:
  BASE_EXPORT virtual std::unique_ptr<NapiRuntimeProxy> Create(
      std::shared_ptr<Runtime> runtime,
      runtime::TemplateDelegate *delegate = nullptr) = 0;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_QUICKJS_FACTORY_H_
