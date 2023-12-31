// Copyright 2022 The Lynx Authors. All rights reserved.

#ifndef LYNX_DEVTOOL_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_QUICKJS_FACTORY_IMPL_H_
#define LYNX_DEVTOOL_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_QUICKJS_FACTORY_IMPL_H_

#include <memory>

#include "jsbridge/napi/napi_runtime_proxy.h"
#include "jsbridge/napi/napi_runtime_proxy_quickjs_factory.h"

namespace lynx {
namespace piper {

class NapiRuntimeProxyQuickjsFactoryImpl
    : public NapiRuntimeProxyQuickjsFactory {
 public:
  std::unique_ptr<NapiRuntimeProxy> Create(
      std::shared_ptr<Runtime> runtime,
      runtime::TemplateDelegate *delegate = nullptr);
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_DEVTOOL_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_QUICKJS_FACTORY_IMPL_H_
