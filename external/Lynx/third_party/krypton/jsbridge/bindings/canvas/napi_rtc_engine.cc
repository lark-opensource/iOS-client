// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_rtc_engine.h"

#include <vector>
#include <utility>

#include "rtc/krypton_rtc_engine.h"
#include "jsbridge/napi/exception_message.h"
#include "jsbridge/napi/napi_base_wrap.h"

using Napi::Array;
using Napi::CallbackInfo;
using Napi::Error;
using Napi::Function;
using Napi::FunctionReference;
using Napi::Number;
using Napi::Object;
using Napi::ObjectWrap;
using Napi::String;
using Napi::TypeError;
using Napi::Value;

using Napi::ArrayBuffer;
using Napi::Int8Array;
using Napi::Uint8Array;
using Napi::Int16Array;
using Napi::Uint16Array;
using Napi::Int32Array;
using Napi::Uint32Array;
using Napi::Float32Array;
using Napi::Float64Array;
using Napi::DataView;

using lynx::piper::IDLBoolean;
using lynx::piper::IDLDouble;
using lynx::piper::IDLFloat;
using lynx::piper::IDLFunction;
using lynx::piper::IDLNumber;
using lynx::piper::IDLString;
using lynx::piper::IDLUnrestrictedFloat;
using lynx::piper::IDLUnrestrictedDouble;
using lynx::piper::IDLNullable;
using lynx::piper::IDLObject;
using lynx::piper::IDLInt8Array;
using lynx::piper::IDLInt16Array;
using lynx::piper::IDLInt32Array;
using lynx::piper::IDLUint8ClampedArray;
using lynx::piper::IDLUint8Array;
using lynx::piper::IDLUint16Array;
using lynx::piper::IDLUint32Array;
using lynx::piper::IDLFloat32Array;
using lynx::piper::IDLFloat64Array;
using lynx::piper::IDLArrayBuffer;
using lynx::piper::IDLArrayBufferView;
using lynx::piper::IDLDictionary;
using lynx::piper::IDLSequence;
using lynx::piper::NativeValueTraits;

using lynx::piper::ExceptionMessage;

namespace lynx {
namespace canvas {

namespace {
const uint64_t kRtcEngineClassID = reinterpret_cast<uint64_t>(&kRtcEngineClassID);
const uint64_t kRtcEngineConstructorID = reinterpret_cast<uint64_t>(&kRtcEngineConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiRtcEngine>;
typedef Value (NapiRtcEngine::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiRtcEngine::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

__attribute__((unused))
void AddAttribute(std::vector<Wrapped::PropertyDescriptor>& props,
                  const char* name,
                  InstanceCallback getter,
                  InstanceSetterCallback setter) {
  props.push_back(
      Wrapped::InstanceAccessor(name, getter, setter, napi_default_jsproperty));
}

__attribute__((unused))
void AddInstanceMethod(std::vector<Wrapped::PropertyDescriptor>& props,
                       const char* name,
                       InstanceCallback method) {
  props.push_back(
      Wrapped::InstanceMethod(name, method, napi_default_jsproperty));
}
}  // namespace

NapiRtcEngine::NapiRtcEngine(const CallbackInfo& info, bool skip_init_as_base)
    : BridgeBase(info) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  ExceptionMessage::IllegalConstructor(info.Env(), InterfaceName());
  return;
}

RtcEngine* NapiRtcEngine::ToImplUnsafe() {
  return impl_.get();
}

// static
Object NapiRtcEngine::Wrap(std::unique_ptr<RtcEngine> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiRtcEngine>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiRtcEngine::Init(std::unique_ptr<RtcEngine> impl) {
  DCHECK(impl);
  DCHECK(!impl_);

  impl_ = std::move(impl);
  // We only associate and call OnWrapped() once, when we init the root base.
  impl_->AssociateWithWrapper(this);

  uintptr_t ptr = reinterpret_cast<uintptr_t>(&*impl_);
  uint32_t ptr_high = static_cast<uint32_t>((uint64_t)ptr >> 32);
  uint32_t ptr_low = static_cast<uint32_t>(ptr & 0xffffffff);
  JsObject().Set("_ptr_high", ptr_high);
  JsObject().Set("_ptr_low", ptr_low);
}

Value NapiRtcEngine::AppIdAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetAppId());
}

Value NapiRtcEngine::JoinChannelMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "JoinChannel", "3");
    return Value();
  }

  auto arg0_channelId = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto arg1_userId = NativeValueTraits<IDLString>::NativeValue(info, 1);

  auto arg2_token = NativeValueTraits<IDLString>::NativeValue(info, 2);

  auto&& result = impl_->JoinChannel(std::move(arg0_channelId), std::move(arg1_userId), std::move(arg2_token));
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::LeaveChannelMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->LeaveChannel();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::EnableLocalAudioMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->EnableLocalAudio();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::DisableLocalAudioMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->DisableLocalAudio();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::MuteLocalAudioStreamMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->MuteLocalAudioStream();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::UnmuteLocalAudioStreamMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->UnmuteLocalAudioStream();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::MuteRemoteAudioStreamMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "MuteRemoteAudioStream", "1");
    return Value();
  }

  auto arg0_userId = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto&& result = impl_->MuteRemoteAudioStream(std::move(arg0_userId));
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::UnmuteRemoteAudioStreamMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "UnmuteRemoteAudioStream", "1");
    return Value();
  }

  auto arg0_userId = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto&& result = impl_->UnmuteRemoteAudioStream(std::move(arg0_userId));
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::MuteAllRemoteAudioStreamMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->MuteAllRemoteAudioStream();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::UnmuteAllRemoteAudioStreamMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->UnmuteAllRemoteAudioStream();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::AdjustPlaybackSignalVolumeMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "AdjustPlaybackSignalVolume", "1");
    return Value();
  }

  auto arg0_volume = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto&& result = impl_->AdjustPlaybackSignalVolume(arg0_volume);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::AdjustRecordingSignalVolumeMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "AdjustRecordingSignalVolume", "1");
    return Value();
  }

  auto arg0_volume = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto&& result = impl_->AdjustRecordingSignalVolume(arg0_volume);
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiRtcEngine::EnableAudioVolumeIndicationMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "EnableAudioVolumeIndication", "1");
    return Value();
  }

  auto arg0_interval = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto&& result = impl_->EnableAudioVolumeIndication(arg0_interval);
  return Napi::Boolean::New(info.Env(), result);
}

// static
Napi::Class* NapiRtcEngine::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kRtcEngineClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes
  AddAttribute(props, "appId",
               &NapiRtcEngine::AppIdAttributeGetter,
               nullptr
               );

  // Methods
  AddInstanceMethod(props, "joinChannel", &NapiRtcEngine::JoinChannelMethod);
  AddInstanceMethod(props, "leaveChannel", &NapiRtcEngine::LeaveChannelMethod);
  AddInstanceMethod(props, "enableLocalAudio", &NapiRtcEngine::EnableLocalAudioMethod);
  AddInstanceMethod(props, "disableLocalAudio", &NapiRtcEngine::DisableLocalAudioMethod);
  AddInstanceMethod(props, "muteLocalAudioStream", &NapiRtcEngine::MuteLocalAudioStreamMethod);
  AddInstanceMethod(props, "unmuteLocalAudioStream", &NapiRtcEngine::UnmuteLocalAudioStreamMethod);
  AddInstanceMethod(props, "muteRemoteAudioStream", &NapiRtcEngine::MuteRemoteAudioStreamMethod);
  AddInstanceMethod(props, "unmuteRemoteAudioStream", &NapiRtcEngine::UnmuteRemoteAudioStreamMethod);
  AddInstanceMethod(props, "muteAllRemoteAudioStream", &NapiRtcEngine::MuteAllRemoteAudioStreamMethod);
  AddInstanceMethod(props, "unmuteAllRemoteAudioStream", &NapiRtcEngine::UnmuteAllRemoteAudioStreamMethod);
  AddInstanceMethod(props, "adjustPlaybackSignalVolume", &NapiRtcEngine::AdjustPlaybackSignalVolumeMethod);
  AddInstanceMethod(props, "adjustRecordingSignalVolume", &NapiRtcEngine::AdjustRecordingSignalVolumeMethod);
  AddInstanceMethod(props, "enableAudioVolumeIndication", &NapiRtcEngine::EnableAudioVolumeIndicationMethod);

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "RtcEngine", props));
  env.SetInstanceData<Napi::Class>(kRtcEngineClassID, clazz);
  return clazz;
}

// static
Function NapiRtcEngine::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kRtcEngineConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kRtcEngineConstructorID, ref);
  return ref->Value();
}

// static
void NapiRtcEngine::Install(Napi::Env env, Object& target) {
  if (target.Has("RtcEngine")) {
    return;
  }
  target.Set("RtcEngine", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
