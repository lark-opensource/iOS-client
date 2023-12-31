// Copyright 2021 The Lynx Authors. All rights reserved

#ifndef LYNX_SHELL_RENDERKIT_NATIVE_MODULE_H_
#define LYNX_SHELL_RENDERKIT_NATIVE_MODULE_H_

#include <functional>
#include <memory>
#include <string>
#include <unordered_map>
#include <vector>

#include "shell/renderkit/method_call.h"
#include "shell/renderkit/public/encodable_value.h"
#include "shell/renderkit/public/method_result.h"

namespace lynx {

class NativeModuleBase {
 public:
  using ValueType = EncodableValue;

  explicit NativeModuleBase(const std::string& name);
  virtual ~NativeModuleBase();
  std::string Name() { return module_name_; }
  virtual std::vector<std::string> MethodNames() { return {}; };

  virtual std::unique_ptr<EncodableValue> InvokeMethod(
      void* lynx_view, const MethodCall& method_call) = 0;

 private:
  std::string module_name_;
};

class NativeModuleX : public NativeModuleBase {
 public:
  using NativeModuleBase::NativeModuleBase;
  using Method = std::function<std::unique_ptr<EncodableValue>(
      void* lynx_view, const EncodableList&)>;
  using MethodMap = std::unordered_map<std::string, Method>;

  bool RegisterMethod(const std::string& name, Method method) {
    if (method == nullptr) {
      return false;
    }
    if (methods_.find(std::string(name)) != methods_.end()) {
      return false;
    }
    methods_.emplace(name, method);
    return true;
  }

  std::unique_ptr<EncodableValue> InvokeMethod(
      void* lynx_view, const MethodCall& method_call) override {
    for (const auto& method : methods_) {
      if (method_call.method_name() == method.first) {
        auto param_list = lynx::get<EncodableList>(*method_call.arguments());
        return method.second(lynx_view, param_list);
      }
    }
    return std::make_unique<EncodableValue>();
  }

  std::vector<std::string> MethodNames() override {
    std::vector<std::string> method_names;
    for (auto method : methods_) {
      method_names.push_back(method.first);
    }
    return method_names;
  }

 protected:
  MethodMap methods_;
};

}  // namespace lynx

#endif  // LYNX_SHELL_RENDERKIT_NATIVE_MODULE_H_
