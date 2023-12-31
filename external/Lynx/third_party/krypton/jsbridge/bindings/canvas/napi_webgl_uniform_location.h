// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_WEBGL_UNIFORM_LOCATION_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_WEBGL_UNIFORM_LOCATION_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class WebGLUniformLocation;

class NapiWebGLUniformLocation : public BridgeBase {
 public:
  NapiWebGLUniformLocation(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  WebGLUniformLocation* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<WebGLUniformLocation>, Napi::Env);

  void Init(std::unique_ptr<WebGLUniformLocation>);

  // Attributes

  // Methods

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "WebGLUniformLocation";
  }

 private:
  std::unique_ptr<WebGLUniformLocation> impl_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_WEBGL_UNIFORM_LOCATION_H_
