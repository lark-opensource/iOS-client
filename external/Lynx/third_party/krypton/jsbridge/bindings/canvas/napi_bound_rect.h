// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_BOUND_RECT_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_BOUND_RECT_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class BoundRect;

class NapiBoundRect : public BridgeBase {
 public:
  NapiBoundRect(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  BoundRect* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<BoundRect>, Napi::Env);

  void Init(std::unique_ptr<BoundRect>);

  // Attributes
  Napi::Value XAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value YAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value WidthAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value HeightAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value TopAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value RightAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value BottomAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value LeftAttributeGetter(const Napi::CallbackInfo&);

  // Methods

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "BoundRect";
  }

 private:
  void Init(const Napi::CallbackInfo&);
  std::unique_ptr<BoundRect> impl_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_BOUND_RECT_H_
