// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LEPUS_ELEMENT_H_
#define LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LEPUS_ELEMENT_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace worklet {

using piper::BridgeBase;
using piper::ImplBase;

class LepusElement;

class NapiLepusElement : public BridgeBase {
 public:
  NapiLepusElement(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  LepusElement* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<LepusElement>, Napi::Env);

  void Init(std::unique_ptr<LepusElement>);

  // Attributes

  // Methods
  Napi::Value SetAttributesMethod(const Napi::CallbackInfo&);
  Napi::Value SetStylesMethod(const Napi::CallbackInfo&);
  Napi::Value GetAttributesMethod(const Napi::CallbackInfo&);
  Napi::Value GetComputedStylesMethod(const Napi::CallbackInfo&);
  Napi::Value GetDatasetMethod(const Napi::CallbackInfo&);
  Napi::Value ScrollByMethod(const Napi::CallbackInfo&);
  Napi::Value GetBoundingClientRectMethod(const Napi::CallbackInfo&);
  Napi::Value InvokeMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "LepusElement";
  }

 private:
  std::unique_ptr<LepusElement> impl_;
};

}  // namespace worklet
}  // namespace lynx

#endif  // LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_LEPUS_ELEMENT_H_
