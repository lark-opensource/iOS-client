// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_RTC_ENGINE_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_RTC_ENGINE_H_

#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/native_value_traits.h"

namespace lynx {
namespace canvas {

using piper::BridgeBase;
using piper::ImplBase;

class RtcEngine;

class NapiRtcEngine : public BridgeBase {
 public:
  NapiRtcEngine(const Napi::CallbackInfo&, bool skip_init_as_base = false);

  RtcEngine* ToImplUnsafe();

  static Napi::Object Wrap(std::unique_ptr<RtcEngine>, Napi::Env);

  void Init(std::unique_ptr<RtcEngine>);

  // Attributes
  Napi::Value AppIdAttributeGetter(const Napi::CallbackInfo&);

  // Methods
  Napi::Value JoinChannelMethod(const Napi::CallbackInfo&);
  Napi::Value LeaveChannelMethod(const Napi::CallbackInfo&);
  Napi::Value EnableLocalAudioMethod(const Napi::CallbackInfo&);
  Napi::Value DisableLocalAudioMethod(const Napi::CallbackInfo&);
  Napi::Value MuteLocalAudioStreamMethod(const Napi::CallbackInfo&);
  Napi::Value UnmuteLocalAudioStreamMethod(const Napi::CallbackInfo&);
  Napi::Value MuteRemoteAudioStreamMethod(const Napi::CallbackInfo&);
  Napi::Value UnmuteRemoteAudioStreamMethod(const Napi::CallbackInfo&);
  Napi::Value MuteAllRemoteAudioStreamMethod(const Napi::CallbackInfo&);
  Napi::Value UnmuteAllRemoteAudioStreamMethod(const Napi::CallbackInfo&);
  Napi::Value AdjustPlaybackSignalVolumeMethod(const Napi::CallbackInfo&);
  Napi::Value AdjustRecordingSignalVolumeMethod(const Napi::CallbackInfo&);
  Napi::Value EnableAudioVolumeIndicationMethod(const Napi::CallbackInfo&);

  // Overload Hubs

  // Overloads

  // Injection hook
  static void Install(Napi::Env, Napi::Object&);

  static Napi::Function Constructor(Napi::Env);
  static Napi::Class* Class(Napi::Env);

  // Interface name
  static constexpr const char* InterfaceName() {
    return "RtcEngine";
  }

 private:
  std::unique_ptr<RtcEngine> impl_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_RTC_ENGINE_H_
