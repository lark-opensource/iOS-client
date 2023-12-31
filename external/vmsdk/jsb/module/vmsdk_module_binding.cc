// Copyright 2019 The Vmsdk Authors. All rights reserved.

#include "jsb/module/vmsdk_module_binding.h"

#include "basic/log/logging.h"

namespace vmsdk {
namespace piper {

/**
 * Public API to install the VmsdkModule system.
 */
VmsdkModuleBinding::VmsdkModuleBinding(
    const VmsdkModuleProviderFunction &moduleProvider)
    : moduleProvider_(moduleProvider) {}

VmsdkModuleBindingWrap::VmsdkModuleBindingWrap(const Napi::CallbackInfo &info) {
  Napi::External value = info[0].As<Napi::External>();
  binding_ = reinterpret_cast<VmsdkModuleBinding *>(value.Data());
}

Napi::Value VmsdkModuleBindingWrap::CreateFromVmsdkModuleBinding(
    Napi::Env env, VmsdkModuleBinding *binding) {
  Napi::EscapableHandleScope scp(env);
  Napi::External v = Napi::External::New(env, binding, nullptr, nullptr);
  Napi::Value bindingPtr = Napi::Value::From(env, v);

  if (!binding->constructor_.IsEmpty()) {
    Napi::Value cst = binding->constructor_.Value();
    if (cst.IsFunction()) {
      return scp.Escape(cst.As<Napi::Function>().New({bindingPtr}));
    }
  }

  using Wrapped = Napi::ObjectWrap<VmsdkModuleBindingWrap>;
  Wrapped::PropertyDescriptor accessor = Wrapped::InstanceMethod(
      Napi::String::New(env, "get"), &VmsdkModuleBindingWrap::GetterCallBack,
      napi_enumerable);

  Napi::Function bindingConstructor =
      Wrapped::DefineClass(env, "VmsdkModuleBindingWrap", {accessor}).Get(env);

  binding->constructor_ = Napi::Persistent<Napi::Function>(bindingConstructor);
  return scp.Escape(bindingConstructor.New({bindingPtr}));
}

// binding NativeModule.get("name") function for NativeModule
Napi::Value VmsdkModuleBindingWrap::GetterCallBack(
    const Napi::CallbackInfo &info) {
  // get module name
  std::string name = info[0].As<Napi::String>().Utf8Value();
  Napi::Object thisObj = info.This().As<Napi::Object>();
  VmsdkModuleBindingWrap *binding =
      Napi::ObjectWrap<VmsdkModuleBindingWrap>::Unwrap(thisObj);
  std::shared_ptr<VmsdkModule> module = binding->binding_->GetModule(name);
  if (module == nullptr) {
    return info.Env().Null();
  }

  return VmsdkModuleWrap::CreateFromVmsdkModule(info.Env(), module.get());
}

}  // namespace piper
}  // namespace vmsdk
