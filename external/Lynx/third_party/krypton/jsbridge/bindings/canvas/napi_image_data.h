// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_IMAGE_DATA_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_IMAGE_DATA_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class ImageData;

class NapiImageData : public BridgeBase {
 public:
  NapiImageData(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  ImageData* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<ImageData>, Napi::Env);

  void Init(std::unique_ptr<ImageData>);

  // Attributes
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
    return "ImageData";
  }

 private:
  void InitOverload1(const Napi::CallbackInfo&);
  void InitOverload2(const Napi::CallbackInfo&);
  void InitOverload3(const Napi::CallbackInfo&);
  std::unique_ptr<ImageData> impl_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_IMAGE_DATA_H_
