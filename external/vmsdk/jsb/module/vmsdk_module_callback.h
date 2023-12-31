// Copyright 2019 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_JSBRIDGE_MODULE_VMSDK_MODULE_CALLBACK_H
#define VMSDK_JSBRIDGE_MODULE_VMSDK_MODULE_CALLBACK_H

#include "napi.h"

namespace vmsdk {
namespace piper {

class ModuleCallbackFunctionHolder {
 public:
  ModuleCallbackFunctionHolder(Napi::Function &&func);
  ~ModuleCallbackFunctionHolder() = default;
  Napi::Reference<Napi::Function> function_;
};

class ModuleCallback {
 public:
  static constexpr int64_t kInvalidCallbackId = -1;
  explicit ModuleCallback(int64_t callback_id);
  virtual ~ModuleCallback() = default;
  virtual void Invoke(Napi::Env env, ModuleCallbackFunctionHolder *holder) = 0;
  int64_t callback_id() const { return callback_id_; }
#if VMSDK_ENABLE_TRACING
  void SetModuleName(const std::string &module_name) {
    module_name_ = module_name;
  }
  void SetMethodName(const std::string &method_name) {
    method_name_ = method_name;
  }
  void SetFirstArg(const std::string &first_arg) { first_arg_ = first_arg; }
  std::string module_name_;
  std::string method_name_;
  // Some JSB implement such as XBridge will use first arg as JSB function name,
  // so we need first arg for tracing.
  std::string first_arg_;
#endif
 private:
  const int64_t callback_id_;
};

}  // namespace piper
}  // namespace vmsdk

#endif  // VMSDK_JSBRIDGE_MODULE_VMSDK_MODULE_CALLBACK_H
