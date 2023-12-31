// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_image_element.h"

#include <vector>
#include <utility>

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
const uint64_t kImageElementClassID = reinterpret_cast<uint64_t>(&kImageElementClassID);
const uint64_t kImageElementConstructorID = reinterpret_cast<uint64_t>(&kImageElementConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiImageElement>;
typedef Value (NapiImageElement::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiImageElement::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

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

NapiImageElement::NapiImageElement(const CallbackInfo& info, bool skip_init_as_base)
    : NapiEventTarget(info, true) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  Init(info);
}

void NapiImageElement::Init(const CallbackInfo& info) {
  auto impl = ImageElement::Create();
  Init(std::move(impl));
}

ImageElement* NapiImageElement::ToImplUnsafe() {
  return impl_;
}

// static
Object NapiImageElement::Wrap(std::unique_ptr<ImageElement> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiImageElement>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiImageElement::Init(std::unique_ptr<ImageElement> impl) {
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

Value NapiImageElement::CompleteAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Napi::Boolean::New(info.Env(), impl_->GetComplete());
}

Value NapiImageElement::SrcAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return String::New(info.Env(), impl_->GetSrc());
}

void NapiImageElement::SrcAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetSrc(NativeValueTraits<IDLNullable<IDLString>>::NativeValue(value));
}

Value NapiImageElement::WidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetWidth());
}

Value NapiImageElement::HeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetHeight());
}

// static
Napi::Class* NapiImageElement::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kImageElementClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes
  AddAttribute(props, "complete",
               &NapiImageElement::CompleteAttributeGetter,
               nullptr
               );
  AddAttribute(props, "src",
               &NapiImageElement::SrcAttributeGetter,
               &NapiImageElement::SrcAttributeSetter
               );
  AddAttribute(props, "width",
               &NapiImageElement::WidthAttributeGetter,
               nullptr
               );
  AddAttribute(props, "height",
               &NapiImageElement::HeightAttributeGetter,
               nullptr
               );

  // Methods

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "ImageElement", props, nullptr, *NapiEventTarget::Class(env)));
  env.SetInstanceData<Napi::Class>(kImageElementClassID, clazz);
  return clazz;
}

// static
Function NapiImageElement::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kImageElementConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kImageElementConstructorID, ref);
  return ref->Value();
}

// static
void NapiImageElement::Install(Napi::Env env, Object& target) {
  if (target.Has("ImageElement")) {
    return;
  }
  target.Set("ImageElement", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
