// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_GYROSCOPE_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_GYROSCOPE_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class Gyroscope;

class NapiGyroscope : public BridgeBase {
 public:
  NapiGyroscope(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  Gyroscope* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<Gyroscope>, Napi::Env);

  void Init(std::unique_ptr<Gyroscope>);

  // Attributes
  Napi::Value XAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value YAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value ZAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value RollAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value PitchAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value YawAttributeGetter(const Napi::CallbackInfo&);

  // Methods
  Napi::Value StartMethod(const Napi::CallbackInfo&);
  Napi::Value StopMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "Gyroscope";
  }

 private:
  void Init(const Napi::CallbackInfo&);
  std::unique_ptr<Gyroscope> impl_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_GYROSCOPE_H_
