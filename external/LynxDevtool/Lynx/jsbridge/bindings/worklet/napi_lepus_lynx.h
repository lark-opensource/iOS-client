// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LEPUS_LYNX_H_
#define LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LEPUS_LYNX_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace worklet {

using piper::BridgeBase;
using piper::ImplBase;

class LepusLynx;

class NapiLepusLynx : public BridgeBase {
 public:
  NapiLepusLynx(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  LepusLynx* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<LepusLynx>, Napi::Env);

  void Init(std::unique_ptr<LepusLynx>);

  // Attributes

  // Methods
  Napi::Value TriggerLepusBridgeMethod(const Napi::CallbackInfo&);
  Napi::Value TriggerLepusBridgeSyncMethod(const Napi::CallbackInfo&);
  Napi::Value SetTimeoutMethod(const Napi::CallbackInfo&);
  Napi::Value ClearTimeoutMethod(const Napi::CallbackInfo&);
  Napi::Value SetIntervalMethod(const Napi::CallbackInfo&);
  Napi::Value ClearIntervalMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "LepusLynx";
  }

 private:
  std::unique_ptr<LepusLynx> impl_;
};

}  // namespace worklet
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LEPUS_LYNX_H_
