// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_BRIDGE_NATIVE_MODULE_ADAPTER_H_
#define LYNX_SHELL_RENDERKIT_BRIDGE_NATIVE_MODULE_ADAPTER_H_

#include <memory>
#include <utility>

#include "shell/renderkit/native_module.h"
#include "shell/renderkit/public/bridge_native_module.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {

class BridgeNativeModuleAdapter : public NativeModuleX {
 public:
  explicit BridgeNativeModuleAdapter(std::shared_ptr<BridgeNativeModule> module)
      : NativeModuleX("bridge"), module_(std::move(module)) {}
  std::unique_ptr<EncodableValue> InvokeMethod(
      void* lynx_view, const MethodCall& method_call) override;

 private:
  std::shared_ptr<BridgeNativeModule> module_;
};
}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_BRIDGE_NATIVE_MODULE_ADAPTER_H_
