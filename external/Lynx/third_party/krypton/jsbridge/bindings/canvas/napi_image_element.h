// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_IMAGE_ELEMENT_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_IMAGE_ELEMENT_H_

#include <memory>

#include "jsbridge/bindings/canvas/napi_event_target.h"
#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class ImageElement;

class NapiImageElement : public NapiEventTarget {
 public:
  NapiImageElement(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  ImageElement* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<ImageElement>, Napi::Env);

  void Init(std::unique_ptr<ImageElement>);

  // Attributes
  Napi::Value CompleteAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value SrcAttributeGetter(const Napi::CallbackInfo&);
  void SrcAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value WidthAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value HeightAttributeGetter(const Napi::CallbackInfo&);

  // Methods

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "ImageElement";
  }

 private:
  void Init(const Napi::CallbackInfo&);
  // Owned by root base.
  ImageElement* impl_ = nullptr;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_IMAGE_ELEMENT_H_
