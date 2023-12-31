// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_COMMON_NATIVE_MODULE_ADAPTER_H_
#define LYNX_SHELL_RENDERKIT_COMMON_NATIVE_MODULE_ADAPTER_H_

#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "shell/renderkit/common_native_module_impl.h"
#include "shell/renderkit/native_module.h"
#include "shell/renderkit/public/common_native_module.h"
#include "shell/renderkit/public/encodable_value.h"

namespace lynx {

class CommonNativeModuleAdapter : public NativeModuleX {
 public:
  explicit CommonNativeModuleAdapter(std::shared_ptr<CommonNativeModule> module)
      : NativeModuleX(module->module_name()), module_(std::move(module)) {}
  virtual ~CommonNativeModuleAdapter() = default;
  std::unique_ptr<EncodableValue> InvokeMethod(
      void* lynx_view, const MethodCall& method_call) override;
  std::vector<std::string> MethodNames() override {
    return module_->impl_->module_->MethodNames();
  }

 private:
  std::shared_ptr<CommonNativeModule> module_;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_COMMON_NATIVE_MODULE_ADAPTER_H_
