// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_offscreen_canvas.h"

#include <vector>
#include <utility>

#include "canvas/offscreen_canvas.h"
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
const uint64_t kOffscreenCanvasClassID = reinterpret_cast<uint64_t>(&kOffscreenCanvasClassID);
const uint64_t kOffscreenCanvasConstructorID = reinterpret_cast<uint64_t>(&kOffscreenCanvasConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiOffscreenCanvas>;
typedef Value (NapiOffscreenCanvas::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiOffscreenCanvas::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

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

NapiOffscreenCanvas::NapiOffscreenCanvas(const CallbackInfo& info, bool skip_init_as_base)
    : BridgeBase(info) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  Init(info);
}

void NapiOffscreenCanvas::Init(const CallbackInfo& info) {
  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Constructor", "2");
    return;
  }

  auto arg0_width = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  auto arg1_height = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto impl = OffscreenCanvas::Create(arg0_width, arg1_height);
  Init(std::move(impl));
}

OffscreenCanvas* NapiOffscreenCanvas::ToImplUnsafe() {
  return impl_.get();
}

// static
Object NapiOffscreenCanvas::Wrap(std::unique_ptr<OffscreenCanvas> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiOffscreenCanvas>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiOffscreenCanvas::Init(std::unique_ptr<OffscreenCanvas> impl) {
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

Value NapiOffscreenCanvas::WidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetWidth());
}

void NapiOffscreenCanvas::WidthAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetWidth(NativeValueTraits<IDLNumber>::NativeValue(value));
}

Value NapiOffscreenCanvas::HeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetHeight());
}

void NapiOffscreenCanvas::HeightAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetHeight(NativeValueTraits<IDLNumber>::NativeValue(value));
}

// static
Napi::Class* NapiOffscreenCanvas::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kOffscreenCanvasClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes
  AddAttribute(props, "width",
               &NapiOffscreenCanvas::WidthAttributeGetter,
               &NapiOffscreenCanvas::WidthAttributeSetter
               );
  AddAttribute(props, "height",
               &NapiOffscreenCanvas::HeightAttributeGetter,
               &NapiOffscreenCanvas::HeightAttributeSetter
               );

  // Methods

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "OffscreenCanvas", props));
  env.SetInstanceData<Napi::Class>(kOffscreenCanvasClassID, clazz);
  return clazz;
}

// static
Function NapiOffscreenCanvas::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kOffscreenCanvasConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kOffscreenCanvasConstructorID, ref);
  return ref->Value();
}

// static
void NapiOffscreenCanvas::Install(Napi::Env env, Object& target) {
  if (target.Has("OffscreenCanvas")) {
    return;
  }
  target.Set("OffscreenCanvas", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
