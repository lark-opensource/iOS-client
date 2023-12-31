// Copyright 2019 The Vmsdk Authors. All rights reserved.

#ifndef VMSDK_JSBRIDGE_MODULE_VMSDK_MODULE_BINDING_H
#define VMSDK_JSBRIDGE_MODULE_VMSDK_MODULE_BINDING_H
#include "jsb/module/vmsdk_module.h"
#include "napi.h"

namespace vmsdk {
namespace piper {
/**
 * Represents the JavaScript binding for the VmsdkModule system.
 */
class VmsdkModuleBindingWrap;

class VmsdkModuleBinding {
 public:
  explicit VmsdkModuleBinding(
      const VmsdkModuleProviderFunction &moduleProvider);
  ~VmsdkModuleBinding() = default;

  std::shared_ptr<VmsdkModule> GetModule(std::string &name) {
    return moduleProvider_(name);
  }

 private:
  VmsdkModuleProviderFunction moduleProvider_;
  Napi::Reference<Napi::Function> constructor_;
  friend class VmsdkModuleBindingWrap;
};

// Wrapper to create Napi::Value from c++ VmsdkModuleBinding object
class VmsdkModuleBindingWrap : public Napi::ScriptWrappable {
 public:
  explicit VmsdkModuleBindingWrap(const Napi::CallbackInfo &info);
  static Napi::Value CreateFromVmsdkModuleBinding(Napi::Env env,
                                                  VmsdkModuleBinding *binding);
  // binding NativeModule.get("name") function for NativeModule
  Napi::Value GetterCallBack(const Napi::CallbackInfo &info);

 private:
  VmsdkModuleBinding *binding_;
};

}  // namespace piper
}  // namespace vmsdk

#endif  // VMSDK_JSBRIDGE_MODULE_VMSDK_MODULE_BINDING_H
