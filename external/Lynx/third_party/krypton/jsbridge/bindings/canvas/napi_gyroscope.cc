// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_gyroscope.h"

#include <vector>
#include <utility>

#include "canvas/gyroscope.h"
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
const uint64_t kGyroscopeClassID = reinterpret_cast<uint64_t>(&kGyroscopeClassID);
const uint64_t kGyroscopeConstructorID = reinterpret_cast<uint64_t>(&kGyroscopeConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiGyroscope>;
typedef Value (NapiGyroscope::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiGyroscope::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

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

NapiGyroscope::NapiGyroscope(const CallbackInfo& info, bool skip_init_as_base)
    : BridgeBase(info) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  Init(info);
}

void NapiGyroscope::Init(const CallbackInfo& info) {
  auto impl = Gyroscope::Create();
  Init(std::move(impl));
}

Gyroscope* NapiGyroscope::ToImplUnsafe() {
  return impl_.get();
}

// static
Object NapiGyroscope::Wrap(std::unique_ptr<Gyroscope> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiGyroscope>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiGyroscope::Init(std::unique_ptr<Gyroscope> impl) {
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

Value NapiGyroscope::XAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetX());
}

Value NapiGyroscope::YAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetY());
}

Value NapiGyroscope::ZAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetZ());
}

Value NapiGyroscope::RollAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetRoll());
}

Value NapiGyroscope::PitchAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetPitch());
}

Value NapiGyroscope::YawAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetYaw());
}

Value NapiGyroscope::StartMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Start", "1");
    return Value();
  }

  auto arg0_frequency = NativeValueTraits<IDLDouble>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->Start(arg0_frequency);
  return info.Env().Undefined();
}

Value NapiGyroscope::StopMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  impl_->Stop();
  return info.Env().Undefined();
}

// static
Napi::Class* NapiGyroscope::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kGyroscopeClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes
  AddAttribute(props, "x",
               &NapiGyroscope::XAttributeGetter,
               nullptr
               );
  AddAttribute(props, "y",
               &NapiGyroscope::YAttributeGetter,
               nullptr
               );
  AddAttribute(props, "z",
               &NapiGyroscope::ZAttributeGetter,
               nullptr
               );
  AddAttribute(props, "roll",
               &NapiGyroscope::RollAttributeGetter,
               nullptr
               );
  AddAttribute(props, "pitch",
               &NapiGyroscope::PitchAttributeGetter,
               nullptr
               );
  AddAttribute(props, "yaw",
               &NapiGyroscope::YawAttributeGetter,
               nullptr
               );

  // Methods
  AddInstanceMethod(props, "start", &NapiGyroscope::StartMethod);
  AddInstanceMethod(props, "stop", &NapiGyroscope::StopMethod);

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "Gyroscope", props));
  env.SetInstanceData<Napi::Class>(kGyroscopeClassID, clazz);
  return clazz;
}

// static
Function NapiGyroscope::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kGyroscopeConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kGyroscopeConstructorID, ref);
  return ref->Value();
}

// static
void NapiGyroscope::Install(Napi::Env env, Object& target) {
  if (target.Has("Gyroscope")) {
    return;
  }
  target.Set("Gyroscope", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
