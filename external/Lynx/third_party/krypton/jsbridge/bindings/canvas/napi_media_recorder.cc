// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_media_recorder.h"

#include <vector>
#include <utility>

#include "recorder/media_recorder.h"
#include "jsbridge/bindings/canvas/napi_media_recorder_config.h"
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
const uint64_t kMediaRecorderClassID = reinterpret_cast<uint64_t>(&kMediaRecorderClassID);
const uint64_t kMediaRecorderConstructorID = reinterpret_cast<uint64_t>(&kMediaRecorderConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiMediaRecorder>;
typedef Value (NapiMediaRecorder::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiMediaRecorder::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

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

NapiMediaRecorder::NapiMediaRecorder(const CallbackInfo& info, bool skip_init_as_base)
    : NapiEventTarget(info, true) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  ExceptionMessage::IllegalConstructor(info.Env(), InterfaceName());
  return;
}

MediaRecorder* NapiMediaRecorder::ToImplUnsafe() {
  return impl_;
}

// static
Object NapiMediaRecorder::Wrap(std::unique_ptr<MediaRecorder> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiMediaRecorder>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiMediaRecorder::Init(std::unique_ptr<MediaRecorder> impl) {
  DCHECK(impl);
  DCHECK(!impl_);

  impl_ = impl.release();

  // Also initialize base part as its initialization was skipped.
  NapiEventTarget::Init(std::unique_ptr<EventTarget>(impl_));

  uintptr_t ptr = reinterpret_cast<uintptr_t>(&*impl_);
  uint32_t ptr_high = static_cast<uint32_t>((uint64_t)ptr >> 32);
  uint32_t ptr_low = static_cast<uint32_t>(ptr & 0xffffffff);
  JsObject().Set("_ptr_high", ptr_high);
  JsObject().Set("_ptr_low", ptr_low);
}

Value NapiMediaRecorder::StateAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetState());
}

Value NapiMediaRecorder::MimeTypeAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetMimeType());
}

Value NapiMediaRecorder::VideoBitsPerSecondAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetVideoBitsPerSecond());
}

Value NapiMediaRecorder::AudioBitsPerSecondAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetAudioBitsPerSecond());
}

Value NapiMediaRecorder::VideoWidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetVideoWidth());
}

Value NapiMediaRecorder::VideoHeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetVideoHeight());
}

Value NapiMediaRecorder::IsTypeSupportedMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "IsTypeSupported", "1");
    return Value();
  }

  auto arg0_mimeType = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto&& result = impl_->IsTypeSupported(std::move(arg0_mimeType));
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiMediaRecorder::StartMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->Start();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiMediaRecorder::StopMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->Stop();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiMediaRecorder::PauseMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->Pause();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiMediaRecorder::ResumeMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->Resume();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiMediaRecorder::ClipMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->Clip();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiMediaRecorder::AddClipTimeRangeMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "AddClipTimeRange", "2");
    return Value();
  }

  auto arg0_before = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_after = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->AddClipTimeRange(arg0_before, arg1_after);
  return Number::New(info.Env(), result);
}

// static
Napi::Class* NapiMediaRecorder::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kMediaRecorderClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes
  AddAttribute(props, "state",
               &NapiMediaRecorder::StateAttributeGetter,
               nullptr
               );
  AddAttribute(props, "mimeType",
               &NapiMediaRecorder::MimeTypeAttributeGetter,
               nullptr
               );
  AddAttribute(props, "videoBitsPerSecond",
               &NapiMediaRecorder::VideoBitsPerSecondAttributeGetter,
               nullptr
               );
  AddAttribute(props, "audioBitsPerSecond",
               &NapiMediaRecorder::AudioBitsPerSecondAttributeGetter,
               nullptr
               );
  AddAttribute(props, "videoWidth",
               &NapiMediaRecorder::VideoWidthAttributeGetter,
               nullptr
               );
  AddAttribute(props, "videoHeight",
               &NapiMediaRecorder::VideoHeightAttributeGetter,
               nullptr
               );

  // Methods
  AddInstanceMethod(props, "isTypeSupported", &NapiMediaRecorder::IsTypeSupportedMethod);
  AddInstanceMethod(props, "start", &NapiMediaRecorder::StartMethod);
  AddInstanceMethod(props, "stop", &NapiMediaRecorder::StopMethod);
  AddInstanceMethod(props, "pause", &NapiMediaRecorder::PauseMethod);
  AddInstanceMethod(props, "resume", &NapiMediaRecorder::ResumeMethod);
  AddInstanceMethod(props, "clip", &NapiMediaRecorder::ClipMethod);
  AddInstanceMethod(props, "addClipTimeRange", &NapiMediaRecorder::AddClipTimeRangeMethod);

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "MediaRecorder", props, nullptr, *NapiEventTarget::Class(env)));
  env.SetInstanceData<Napi::Class>(kMediaRecorderClassID, clazz);
  return clazz;
}

// static
Function NapiMediaRecorder::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kMediaRecorderConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kMediaRecorderConstructorID, ref);
  return ref->Value();
}

// static
void NapiMediaRecorder::Install(Napi::Env env, Object& target) {
  if (target.Has("MediaRecorder")) {
    return;
  }
  target.Set("MediaRecorder", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
