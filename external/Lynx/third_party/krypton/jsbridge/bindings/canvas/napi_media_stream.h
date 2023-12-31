// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_MEDIA_STREAM_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_MEDIA_STREAM_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class MediaStream;

class NapiMediaStream : public BridgeBase {
 public:
  NapiMediaStream(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  MediaStream* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<MediaStream>, Napi::Env);

  void Init(std::unique_ptr<MediaStream>);

  // Attributes

  // Methods
  Napi::Value SetBeautifyParamMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "MediaStream";
  }

 private:
  std::unique_ptr<MediaStream> impl_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_MEDIA_STREAM_H_
