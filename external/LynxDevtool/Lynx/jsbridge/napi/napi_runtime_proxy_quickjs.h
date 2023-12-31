// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_QUICKJS_H_
#define LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_QUICKJS_H_

#include <memory>

#include "jsbridge/napi/napi_runtime_proxy.h"

struct LEPUSContext;

namespace lynx {
namespace piper {

class NapiRuntimeProxyQuickjs : public NapiRuntimeProxy {
 public:
  static std::unique_ptr<NapiRuntimeProxy> Create(
      LEPUSContext* context, runtime::TemplateDelegate* delegate = nullptr);
  NapiRuntimeProxyQuickjs(LEPUSContext* context,
                          runtime::TemplateDelegate* delegate);

  void Attach() override;
  void Detach() override;

 private:
  LEPUSContext* context_ = nullptr;
};

}  // namespace piper
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_NAPI_NAPI_RUNTIME_PROXY_QUICKJS_H_
