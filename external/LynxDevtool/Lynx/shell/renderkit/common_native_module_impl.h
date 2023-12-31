// Copyright 2021 The Lynx Authors. All rights reserved.

#ifndef LYNX_SHELL_RENDERKIT_COMMON_NATIVE_MODULE_IMPL_H_
#define LYNX_SHELL_RENDERKIT_COMMON_NATIVE_MODULE_IMPL_H_

#include <memory>
#include <string>

#include "Lynx/shell/renderkit/native_module.h"

namespace lynx {

class CommonNativeModuleImpl {
 public:
  explicit CommonNativeModuleImpl(const std::string& name)
      : module_(std::make_unique<NativeModuleX>(name)) {}
  std::unique_ptr<EncodableValue> InvokeMethod(void* lynx_view,
                                               const MethodCall& method_call) {
    return module_->InvokeMethod(lynx_view, method_call);
  }
  bool RegisterMethod(const std::string& name, NativeModuleX::Method method) {
    return module_->RegisterMethod(name, method);
  }
  friend class CommonNativeModuleAdapter;

 private:
  std::unique_ptr<NativeModuleX> module_;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_COMMON_NATIVE_MODULE_IMPL_H_
