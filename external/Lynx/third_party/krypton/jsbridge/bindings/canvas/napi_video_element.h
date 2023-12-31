// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_VIDEO_ELEMENT_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_VIDEO_ELEMENT_H_

#include <memory>

#include "jsbridge/bindings/canvas/napi_event_target.h"
#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class VideoElement;

class NapiVideoElement : public NapiEventTarget {
 public:
  NapiVideoElement(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  VideoElement* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<VideoElement>, Napi::Env);

  void Init(std::unique_ptr<VideoElement>);

  // Attributes
  Napi::Value SrcAttributeGetter(const Napi::CallbackInfo&);
  void SrcAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value SrcObjectAttributeGetter(const Napi::CallbackInfo&);
  void SrcObjectAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value CurrentTimeAttributeGetter(const Napi::CallbackInfo&);
  void CurrentTimeAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value MutedAttributeGetter(const Napi::CallbackInfo&);
  void MutedAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value VolumeAttributeGetter(const Napi::CallbackInfo&);
  void VolumeAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value LoopAttributeGetter(const Napi::CallbackInfo&);
  void LoopAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value AutoplayAttributeGetter(const Napi::CallbackInfo&);
  void AutoplayAttributeSetter(const Napi::CallbackInfo&, const Napi::Value&);
  Napi::Value PausedAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value ReadyStateAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value WidthAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value HeightAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value VideoWidthAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value VideoHeightAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value StateAttributeGetter(const Napi::CallbackInfo&);
  Napi::Value DurationAttributeGetter(const Napi::CallbackInfo&);

  // Methods
  Napi::Value PlayMethod(const Napi::CallbackInfo&);
  Napi::Value PauseMethod(const Napi::CallbackInfo&);
  Napi::Value DisposeMethod(const Napi::CallbackInfo&);
  Napi::Value GetTimestampMethod(const Napi::CallbackInfo&);
  Napi::Value PaintToMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "VideoElement";
  }

 private:
  void Init(const Napi::CallbackInfo&);
  // Owned by root base.
  VideoElement* impl_ = nullptr;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_VIDEO_ELEMENT_H_
