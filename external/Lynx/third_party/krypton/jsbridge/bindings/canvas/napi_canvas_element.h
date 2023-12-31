// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_CANVAS_ELEMENT_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_CANVAS_ELEMENT_H_

#include <memory>

#include "jsbridge/bindings/canvas/napi_event_target.h"
#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class CanvasElement;

class NapiCanvasElement : public NapiEventTarget {
 public:
  NapiCanvasElement(const Napi::CallbackInfo&, bool skip_init_as_base = false);
  ~NapiCanvasElement() override;

  CanvasElement* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<CanvasElement>, Napi::Env);

  void Init(std::unique_ptr<CanvasElement>);

  // Attributes
  Napi::Value WidthAttributeGetter(const Napi::CallbackInfo&);
  void WidthAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value HeightAttributeGetter(const Napi::CallbackInfo&);
  void HeightAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value ClientWidthAttributeGetter(const Napi::CallbackInfo&);
  void ClientWidthAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value ClientHeightAttributeGetter(const Napi::CallbackInfo&);
  void ClientHeightAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value TouchDec95WidthAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value TouchDec95HeightAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value IsSurfaceCreatedAttributeGetter(const Napi::CallbackInfo&);

  // Methods
  Napi::Value GetBoundingClientRectMethod(const Napi::CallbackInfo&);
  Napi::Value ToDataURLMethod(const Napi::CallbackInfo&);
  Napi::Value AttachToCanvasViewMethod(const Napi::CallbackInfo&);
  Napi::Value DetachFromCanvasViewMethod(const Napi::CallbackInfo&);

  // Overload Hubs
  Napi::Value GetContextMethod(const Napi::CallbackInfo&);

  // Overloads
  Napi::Value GetContextMethodOverload1(const Napi::CallbackInfo&);
  Napi::Value GetContextMethodOverload2(const Napi::CallbackInfo&);

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "CanvasElement";
  }

 private:
  void InitOverload1(const Napi::CallbackInfo&);
  void InitOverload2(const Napi::CallbackInfo&);
  // Owned by root base.
  CanvasElement* impl_ = nullptr;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_CANVAS_ELEMENT_H_
