// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_image_data.h"

#include <vector>
#include <utility>

#include "canvas/image_data.h"
#include "jsbridge/napi/exception_state.h"
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
const uint64_t kImageDataClassID = reinterpret_cast<uint64_t>(&kImageDataClassID);
const uint64_t kImageDataConstructorID = reinterpret_cast<uint64_t>(&kImageDataConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiImageData>;
typedef Value (NapiImageData::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiImageData::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

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

NapiImageData::NapiImageData(const CallbackInfo& info, bool skip_init_as_base)
    : BridgeBase(info) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  if (info.Length() == 1) {
    InitOverload1(info);
    return;
  }
  if (info.Length() == 2) {
    if (info[0].IsUint8ClampedArray()) {
      InitOverload2(info);
      return;
    }
    if (info[0].IsNumber()) {
      InitOverload3(info);
      return;
    }
    InitOverload3(info);
    return;
  }
  if (info.Length() == 3) {
    InitOverload2(info);
    return;
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "ImageData constructor");
  return;
}

void NapiImageData::InitOverload1(const CallbackInfo& info) {
  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Constructor", "1");
    return;
  }

  auto arg0_image_data = NativeValueTraits<NapiImageData>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return;
  }

  auto impl = ImageData::Create(arg0_image_data);
  Init(std::move(impl));
}

void NapiImageData::InitOverload2(const CallbackInfo& info) {
  piper::ExceptionState exception_state(info.Env());
  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Constructor", "2");
    return;
  }

  auto arg0_data = NativeValueTraits<IDLUint8ClampedArray>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return;
  }

  auto arg1_sw = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  if (info.Length() <= 2) {
    auto impl = ImageData::Create(exception_state, arg0_data, arg1_sw);
    if (exception_state.HadException()) {
      return;
    }
    Init(std::move(impl));
    return;
  }
  auto arg2_sh = NativeValueTraits<IDLNumber>::NativeValue(info, 2);

  auto impl = ImageData::Create(exception_state, arg0_data, arg1_sw, arg2_sh);
  if (exception_state.HadException()) {
    return;
  }
  Init(std::move(impl));
}

void NapiImageData::InitOverload3(const CallbackInfo& info) {
  piper::ExceptionState exception_state(info.Env());
  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Constructor", "2");
    return;
  }

  auto arg0_width = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_height = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto impl = ImageData::Create(exception_state, arg0_width, arg1_height);
  if (exception_state.HadException()) {
    return;
  }
  Init(std::move(impl));
}

ImageData* NapiImageData::ToImplUnsafe() {
  return impl_.get();
}

// static
Object NapiImageData::Wrap(std::unique_ptr<ImageData> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiImageData>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiImageData::Init(std::unique_ptr<ImageData> impl) {
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

Value NapiImageData::WidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetWidth());
}

Value NapiImageData::HeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetHeight());
}

// static
Napi::Class* NapiImageData::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kImageDataClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes
  AddAttribute(props, "width",
               &NapiImageData::WidthAttributeGetter,
               nullptr
               );
  AddAttribute(props, "height",
               &NapiImageData::HeightAttributeGetter,
               nullptr
               );

  // Methods

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "ImageData", props));
  env.SetInstanceData<Napi::Class>(kImageDataClassID, clazz);
  return clazz;
}

// static
Function NapiImageData::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kImageDataConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kImageDataConstructorID, ref);
  return ref->Value();
}

// static
void NapiImageData::Install(Napi::Env env, Object& target) {
  if (target.Has("ImageData")) {
    return;
  }
  target.Set("ImageData", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
