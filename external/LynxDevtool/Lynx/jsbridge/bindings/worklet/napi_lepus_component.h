// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LEPUS_COMPONENT_H_
#define LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LEPUS_COMPONENT_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace worklet {

using piper::BridgeBase;
using piper::ImplBase;

class LepusComponent;

class NapiLepusComponent : public BridgeBase {
 public:
  NapiLepusComponent(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  LepusComponent* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<LepusComponent>, Napi::Env);

  void Init(std::unique_ptr<LepusComponent>);

  // Attributes

  // Methods
  Napi::Value QuerySelectorMethod(const Napi::CallbackInfo&);
  Napi::Value QuerySelectorAllMethod(const Napi::CallbackInfo&);
  Napi::Value RequestAnimationFrameMethod(const Napi::CallbackInfo&);
  Napi::Value CancelAnimationFrameMethod(const Napi::CallbackInfo&);
  Napi::Value TriggerEventMethod(const Napi::CallbackInfo&);
  Napi::Value GetStoreMethod(const Napi::CallbackInfo&);
  Napi::Value SetStoreMethod(const Napi::CallbackInfo&);
  Napi::Value GetDataMethod(const Napi::CallbackInfo&);
  Napi::Value SetDataMethod(const Napi::CallbackInfo&);
  Napi::Value GetPropertiesMethod(const Napi::CallbackInfo&);
  Napi::Value CallJSFunctionMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "LepusComponent";
  }

 private:
  std::unique_ptr<LepusComponent> impl_;
};

}  // namespace worklet
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LEPUS_COMPONENT_H_
