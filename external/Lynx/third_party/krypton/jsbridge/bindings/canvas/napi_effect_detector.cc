// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_effect_detector.h"

#include <vector>
#include <utility>

#include "effect/krypton_effect_detector.h"
#include "jsbridge/bindings/canvas/napi_canvas_element.h"
#include "jsbridge/bindings/canvas/napi_image_element.h"
#include "jsbridge/bindings/canvas/napi_video_element.h"
#include "canvas/canvas_element.h"
#include "canvas/media/video_element.h"
#include "canvas/image_element.h"
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
const uint64_t kEffectDetectorClassID = reinterpret_cast<uint64_t>(&kEffectDetectorClassID);
const uint64_t kEffectDetectorConstructorID = reinterpret_cast<uint64_t>(&kEffectDetectorConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiEffectDetector>;
typedef Value (NapiEffectDetector::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiEffectDetector::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

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

NapiEffectDetector::NapiEffectDetector(const CallbackInfo& info, bool skip_init_as_base)
    : BridgeBase(info) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  ExceptionMessage::IllegalConstructor(info.Env(), InterfaceName());
  return;
}

EffectDetector* NapiEffectDetector::ToImplUnsafe() {
  return impl_.get();
}

// static
Object NapiEffectDetector::Wrap(std::unique_ptr<EffectDetector> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiEffectDetector>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiEffectDetector::Init(std::unique_ptr<EffectDetector> impl) {
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

Value NapiEffectDetector::DetectMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Detect", "1");
    return Value();
  }

  do {
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) break;
    if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) break;
    ExceptionMessage::InvalidType(info.Env(), "argument 0", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
    return Value();
  } while (false);
  size_t union_branch = 0;
  CanvasElement* arg0_image_CanvasElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiCanvasElement::Constructor(info.Env()))) {
    arg0_image_CanvasElement = ObjectWrap<NapiCanvasElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 1;
  }
  ImageElement* arg0_image_ImageElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiImageElement::Constructor(info.Env()))) {
    arg0_image_ImageElement = ObjectWrap<NapiImageElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 2;
  }
  VideoElement* arg0_image_VideoElement = nullptr;
  if (info[0].IsObject() && info[0].As<Object>().InstanceOf(NapiVideoElement::Constructor(info.Env()))) {
    arg0_image_VideoElement = ObjectWrap<NapiVideoElement>::Unwrap(info[0].As<Object>())->ToImplUnsafe();
    union_branch = 3;
  }

  switch (union_branch) {
    case 1: {
      auto&& result = impl_->Detect(arg0_image_CanvasElement);
      return result;
    }
    case 2: {
      auto&& result = impl_->Detect(arg0_image_ImageElement);
      return result;
    }
    case 3: {
      auto&& result = impl_->Detect(arg0_image_VideoElement);
      return result;
    }
    default: {
      ExceptionMessage::FailedToCallOverloadExpecting(info.Env(), "Detect()", "['CanvasElement*', 'ImageElement*', 'VideoElement*']");
      return Value();
    }
  }
}

// static
Napi::Class* NapiEffectDetector::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kEffectDetectorClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes

  // Methods
  AddInstanceMethod(props, "detect", &NapiEffectDetector::DetectMethod);

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "EffectDetector", props));
  env.SetInstanceData<Napi::Class>(kEffectDetectorClassID, clazz);
  return clazz;
}

// static
Function NapiEffectDetector::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kEffectDetectorConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kEffectDetectorConstructorID, ref);
  return ref->Value();
}

// static
void NapiEffectDetector::Install(Napi::Env env, Object& target) {
  if (target.Has("EffectDetector")) {
    return;
  }
  target.Set("EffectDetector", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
