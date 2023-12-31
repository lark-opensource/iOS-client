// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_video_element.h"

#include <vector>
#include <utility>

#include "canvas/media/video_element.h"
#include "jsbridge/bindings/canvas/napi_canvas_element.h"
#include "jsbridge/bindings/canvas/napi_media_stream.h"
#include "jsbridge/bindings/canvas/napi_video_load_options.h"
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
const uint64_t kVideoElementClassID = reinterpret_cast<uint64_t>(&kVideoElementClassID);
const uint64_t kVideoElementConstructorID = reinterpret_cast<uint64_t>(&kVideoElementConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiVideoElement>;
typedef Value (NapiVideoElement::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiVideoElement::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

void AddConstant(std::vector<Wrapped::PropertyDescriptor>& props,
                 Napi::Env env,
                 const char* name,
                 double value) {
  props.push_back(Wrapped::InstanceValue(name, Number::New(env, value), napi_enumerable));
}

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

NapiVideoElement::NapiVideoElement(const CallbackInfo& info, bool skip_init_as_base)
    : NapiEventTarget(info, true) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  Init(info);
}

void NapiVideoElement::Init(const CallbackInfo& info) {
  if (info.Length() <= 0) {
    auto impl = VideoElement::Create();
    Init(std::move(impl));
    return;
  }
  auto arg0_loadOptions = NativeValueTraits<IDLDictionary<VideoLoadOptions>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return;
  }

  auto impl = VideoElement::Create(std::move(arg0_loadOptions));
  Init(std::move(impl));
}

VideoElement* NapiVideoElement::ToImplUnsafe() {
  return impl_;
}

// static
Object NapiVideoElement::Wrap(std::unique_ptr<VideoElement> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiVideoElement>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiVideoElement::Init(std::unique_ptr<VideoElement> impl) {
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

Value NapiVideoElement::SrcAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetSrc());
}

void NapiVideoElement::SrcAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetSrc(NativeValueTraits<IDLString>::NativeValue(value));
}

Value NapiVideoElement::SrcObjectAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  auto* wrapped = impl_->GetSrcObject();

  if (!wrapped) {
    return info.Env().Null();
  }
  // Impl needs to take care of object ownership.
  DCHECK(wrapped->IsWrapped());
  return wrapped->JsObject();
}

void NapiVideoElement::SrcObjectAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetSrcObject(NativeValueTraits<IDLNullable<NapiMediaStream>>::NativeValue(value));
}

Value NapiVideoElement::CurrentTimeAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetCurrentTime());
}

void NapiVideoElement::CurrentTimeAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetCurrentTime(NativeValueTraits<IDLDouble>::NativeValue(value));
}

Value NapiVideoElement::MutedAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Napi::Boolean::New(info.Env(), impl_->GetMuted());
}

void NapiVideoElement::MutedAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetMuted(NativeValueTraits<IDLBoolean>::NativeValue(value));
}

Value NapiVideoElement::VolumeAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetVolume());
}

void NapiVideoElement::VolumeAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetVolume(NativeValueTraits<IDLDouble>::NativeValue(value));
}

Value NapiVideoElement::LoopAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Napi::Boolean::New(info.Env(), impl_->GetLoop());
}

void NapiVideoElement::LoopAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetLoop(NativeValueTraits<IDLBoolean>::NativeValue(value));
}

Value NapiVideoElement::AutoplayAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Napi::Boolean::New(info.Env(), impl_->GetAutoplay());
}

void NapiVideoElement::AutoplayAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetAutoplay(NativeValueTraits<IDLBoolean>::NativeValue(value));
}

Value NapiVideoElement::PausedAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Napi::Boolean::New(info.Env(), impl_->GetPaused());
}

Value NapiVideoElement::ReadyStateAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetReadyState());
}

Value NapiVideoElement::WidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetWidth());
}

Value NapiVideoElement::HeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetHeight());
}

Value NapiVideoElement::VideoWidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetVideoWidth());
}

Value NapiVideoElement::VideoHeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetVideoHeight());
}

Value NapiVideoElement::StateAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetState());
}

Value NapiVideoElement::DurationAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetDuration());
}

Value NapiVideoElement::PlayMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->Play();
  return info.Env().Undefined();
}

Value NapiVideoElement::PauseMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->Pause();
  return info.Env().Undefined();
}

Value NapiVideoElement::DisposeMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->Dispose();
  return info.Env().Undefined();
}

Value NapiVideoElement::GetTimestampMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->GetTimestamp();
  return Number::New(info.Env(), result);
}

Value NapiVideoElement::PaintToMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "PaintTo", "1");
    return Value();
  }

  auto arg0_canvas = NativeValueTraits<NapiCanvasElement>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  if (info.Length() <= 1) {
    impl_->PaintTo(arg0_canvas);
    return info.Env().Undefined();
  }

  auto arg1_dx = NativeValueTraits<IDLDouble>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  if (info.Length() <= 2) {
    impl_->PaintTo(arg0_canvas, arg1_dx);
    return info.Env().Undefined();
  }

  auto arg2_dy = NativeValueTraits<IDLDouble>::NativeValue(info, 2);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  if (info.Length() <= 3) {
    impl_->PaintTo(arg0_canvas, arg1_dx, arg2_dy);
    return info.Env().Undefined();
  }

  auto arg3_sx = NativeValueTraits<IDLDouble>::NativeValue(info, 3);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  if (info.Length() <= 4) {
    impl_->PaintTo(arg0_canvas, arg1_dx, arg2_dy, arg3_sx);
    return info.Env().Undefined();
  }

  auto arg4_sy = NativeValueTraits<IDLDouble>::NativeValue(info, 4);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  if (info.Length() <= 5) {
    impl_->PaintTo(arg0_canvas, arg1_dx, arg2_dy, arg3_sx, arg4_sy);
    return info.Env().Undefined();
  }

  auto arg5_sw = NativeValueTraits<IDLDouble>::NativeValue(info, 5);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  if (info.Length() <= 6) {
    impl_->PaintTo(arg0_canvas, arg1_dx, arg2_dy, arg3_sx, arg4_sy, arg5_sw);
    return info.Env().Undefined();
  }

  auto arg6_sh = NativeValueTraits<IDLDouble>::NativeValue(info, 6);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->PaintTo(arg0_canvas, arg1_dx, arg2_dy, arg3_sx, arg4_sy, arg5_sw, arg6_sh);
  return info.Env().Undefined();
}

// static
Napi::Class* NapiVideoElement::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kVideoElementClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Constants
  AddConstant(props, env, "HAVE_NOTHING", 0);
  AddConstant(props, env, "HAVE_METADATA", 1);
  AddConstant(props, env, "HAVE_CURRENT_DATA", 2);
  AddConstant(props, env, "HAVE_FUTURE_DATA", 3);
  AddConstant(props, env, "HAVE_ENOUGH_DATA", 4);

  // Attributes
  AddAttribute(props, "src",
               &NapiVideoElement::SrcAttributeGetter,
               &NapiVideoElement::SrcAttributeSetter
               );
  AddAttribute(props, "srcObject",
               &NapiVideoElement::SrcObjectAttributeGetter,
               &NapiVideoElement::SrcObjectAttributeSetter
               );
  AddAttribute(props, "currentTime",
               &NapiVideoElement::CurrentTimeAttributeGetter,
               &NapiVideoElement::CurrentTimeAttributeSetter
               );
  AddAttribute(props, "muted",
               &NapiVideoElement::MutedAttributeGetter,
               &NapiVideoElement::MutedAttributeSetter
               );
  AddAttribute(props, "volume",
               &NapiVideoElement::VolumeAttributeGetter,
               &NapiVideoElement::VolumeAttributeSetter
               );
  AddAttribute(props, "loop",
               &NapiVideoElement::LoopAttributeGetter,
               &NapiVideoElement::LoopAttributeSetter
               );
  AddAttribute(props, "autoplay",
               &NapiVideoElement::AutoplayAttributeGetter,
               &NapiVideoElement::AutoplayAttributeSetter
               );
  AddAttribute(props, "paused",
               &NapiVideoElement::PausedAttributeGetter,
               nullptr
               );
  AddAttribute(props, "readyState",
               &NapiVideoElement::ReadyStateAttributeGetter,
               nullptr
               );
  AddAttribute(props, "width",
               &NapiVideoElement::WidthAttributeGetter,
               nullptr
               );
  AddAttribute(props, "height",
               &NapiVideoElement::HeightAttributeGetter,
               nullptr
               );
  AddAttribute(props, "videoWidth",
               &NapiVideoElement::VideoWidthAttributeGetter,
               nullptr
               );
  AddAttribute(props, "videoHeight",
               &NapiVideoElement::VideoHeightAttributeGetter,
               nullptr
               );
  AddAttribute(props, "state",
               &NapiVideoElement::StateAttributeGetter,
               nullptr
               );
  AddAttribute(props, "duration",
               &NapiVideoElement::DurationAttributeGetter,
               nullptr
               );

  // Methods
  AddInstanceMethod(props, "play", &NapiVideoElement::PlayMethod);
  AddInstanceMethod(props, "pause", &NapiVideoElement::PauseMethod);
  AddInstanceMethod(props, "dispose", &NapiVideoElement::DisposeMethod);
  AddInstanceMethod(props, "getTimestamp", &NapiVideoElement::GetTimestampMethod);
  AddInstanceMethod(props, "paintTo", &NapiVideoElement::PaintToMethod);

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "VideoElement", props, nullptr, *NapiEventTarget::Class(env)));
  env.SetInstanceData<Napi::Class>(kVideoElementClassID, clazz);
  return clazz;
}

// static
Function NapiVideoElement::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kVideoElementConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kVideoElementConstructorID, ref);
  return ref->Value();
}

// static
void NapiVideoElement::Install(Napi::Env env, Object& target) {
  if (target.Has("VideoElement")) {
    return;
  }
  target.Set("VideoElement", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
