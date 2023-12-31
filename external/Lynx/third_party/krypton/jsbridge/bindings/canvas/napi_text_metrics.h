// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_TEXT_METRICS_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_TEXT_METRICS_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class TextMetrics;

class NapiTextMetrics : public BridgeBase {
 public:
  NapiTextMetrics(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  TextMetrics* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<TextMetrics>, Napi::Env);

  void Init(std::unique_ptr<TextMetrics>);

  // Attributes
  Napi::Value WidthAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value ActualBoundingBoxLeftAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value ActualBoundingBoxRightAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value FontBoundingBoxAscentAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value FontBoundingBoxDescentAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value ActualBoundingBoxAscentAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value ActualBoundingBoxDescentAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value MissingGlyphCountAttributeGetter(const Napi::CallbackInfo&);

  // Methods

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "TextMetrics";
  }

 private:
  std::unique_ptr<TextMetrics> impl_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_TEXT_METRICS_H_
