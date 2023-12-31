// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_MEDIA_RECORDER_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_MEDIA_RECORDER_H_

#include <memory>

#include "jsbridge/bindings/canvas/napi_event_target.h"
#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class MediaRecorder;

class NapiMediaRecorder : public NapiEventTarget {
 public:
  NapiMediaRecorder(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  MediaRecorder* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<MediaRecorder>, Napi::Env);

  void Init(std::unique_ptr<MediaRecorder>);

  // Attributes
  Napi::Value StateAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value MimeTypeAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value VideoBitsPerSecondAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value AudioBitsPerSecondAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value VideoWidthAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value VideoHeightAttributeGetter(const Napi::CallbackInfo&);

  // Methods
  Napi::Value IsTypeSupportedMethod(const Napi::CallbackInfo&);
  Napi::Value StartMethod(const Napi::CallbackInfo&);
  Napi::Value StopMethod(const Napi::CallbackInfo&);
  Napi::Value PauseMethod(const Napi::CallbackInfo&);
  Napi::Value ResumeMethod(const Napi::CallbackInfo&);
  Napi::Value ClipMethod(const Napi::CallbackInfo&);
  Napi::Value AddClipTimeRangeMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "MediaRecorder";
  }

 private:
  // Owned by root base.
  MediaRecorder* impl_ = nullptr;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_MEDIA_RECORDER_H_
