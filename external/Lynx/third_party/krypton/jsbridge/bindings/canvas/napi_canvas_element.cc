// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_canvas_element.h"

#include <vector>
#include <utility>

#include "canvas/canvas_element.h"
#include "canvas/canvas_context.h"
#include "canvas/bound_rect.h"
#include "jsbridge/bindings/canvas/napi_canvas_context.h"
#include "jsbridge/bindings/canvas/napi_bound_rect.h"
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
const uint64_t kCanvasElementClassID = reinterpret_cast<uint64_t>(&kCanvasElementClassID);
const uint64_t kCanvasElementConstructorID = reinterpret_cast<uint64_t>(&kCanvasElementConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiCanvasElement>;
typedef Value (NapiCanvasElement::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiCanvasElement::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

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

NapiCanvasElement::NapiCanvasElement(const CallbackInfo& info, bool skip_init_as_base)
    : NapiEventTarget(info, true) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  if (info.Length() == 0) {
    InitOverload1(info);
    return;
  }
  if (info.Length() == 1) {
    InitOverload2(info);
    return;
  }
  if (info.Length() == 2) {
    InitOverload2(info);
    return;
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "CanvasElement constructor");
  return;
}

void NapiCanvasElement::InitOverload1(const CallbackInfo& info) {
  auto impl = CanvasElement::Create();
  Init(std::move(impl));
}

void NapiCanvasElement::InitOverload2(const CallbackInfo& info) {
  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "Constructor", "1");
    return;
  }

  auto arg0_id = NativeValueTraits<IDLString>::NativeValue(info, 0);

  if (info.Length() <= 1) {
    auto impl = CanvasElement::Create(std::move(arg0_id));
    Init(std::move(impl));
    return;
  }
  auto arg1_legacyBehaviors = NativeValueTraits<IDLBoolean>::NativeValue(info, 1);

  auto impl = CanvasElement::Create(std::move(arg0_id), arg1_legacyBehaviors);
  Init(std::move(impl));
}

NapiCanvasElement::~NapiCanvasElement() {
  LOGI("NapiCanvasElement Destrutor ") << this << (" CanvasElement ") << ToImplUnsafe();
}

CanvasElement* NapiCanvasElement::ToImplUnsafe() {
  return impl_;
}

// static
Object NapiCanvasElement::Wrap(std::unique_ptr<CanvasElement> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiCanvasElement>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiCanvasElement::Init(std::unique_ptr<CanvasElement> impl) {
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

Value NapiCanvasElement::WidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetWidth());
}

void NapiCanvasElement::WidthAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetWidth(NativeValueTraits<IDLNumber>::NativeValue(value));
}

Value NapiCanvasElement::HeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetHeight());
}

void NapiCanvasElement::HeightAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetHeight(NativeValueTraits<IDLNumber>::NativeValue(value));
}

Value NapiCanvasElement::ClientWidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetClientWidth());
}

void NapiCanvasElement::ClientWidthAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetClientWidth(NativeValueTraits<IDLNumber>::NativeValue(value));
}

Value NapiCanvasElement::ClientHeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetClientHeight());
}

void NapiCanvasElement::ClientHeightAttributeSetter(const CallbackInfo& info, const Value& value) {
  DCHECK(impl_);

  impl_->SetClientHeight(NativeValueTraits<IDLNumber>::NativeValue(value));
}

Value NapiCanvasElement::TouchDec95WidthAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetTouchDec95Width());
}

Value NapiCanvasElement::TouchDec95HeightAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Number::New(info.Env(), impl_->GetTouchDec95Height());
}

Value NapiCanvasElement::IsSurfaceCreatedAttributeGetter(const CallbackInfo& info) {
  DCHECK(impl_);

  return Napi::Boolean::New(info.Env(), impl_->GetIsSurfaceCreated());
}

Value NapiCanvasElement::GetContextMethodOverload1(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetContext", "1");
    return Value();
  }

  auto arg0_type = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto&& result = impl_->GetContext(std::move(arg0_type));
  return result ? (result->IsWrapped() ? result->JsObject() : NapiCanvasContext::Wrap(std::unique_ptr<CanvasContext>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasElement::GetContextMethodOverload2(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "GetContext", "2");
    return Value();
  }

  auto arg0_type = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto arg1_contextAttributes = NativeValueTraits<IDLDictionary<WebGLContextAttributes>>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->GetContext(std::move(arg0_type), std::move(arg1_contextAttributes));
  return result ? (result->IsWrapped() ? result->JsObject() : NapiCanvasContext::Wrap(std::unique_ptr<CanvasContext>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasElement::GetBoundingClientRectMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->GetBoundingClientRect();
  return result ? (result->IsWrapped() ? result->JsObject() : NapiBoundRect::Wrap(std::unique_ptr<BoundRect>(std::move(result)), info.Env())) : info.Env().Null();
}

Value NapiCanvasElement::ToDataURLMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() <= 0) {
    auto&& result = impl_->ToDataURL();
    return String::New(info.Env(), result);
  }

  auto arg0_type = NativeValueTraits<IDLString>::NativeValue(info, 0);

  if (info.Length() <= 1) {
    auto&& result = impl_->ToDataURL(std::move(arg0_type));
    return String::New(info.Env(), result);
  }

  auto arg1_encoderOptions = NativeValueTraits<IDLNullable<IDLDouble>>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->ToDataURL(std::move(arg0_type), arg1_encoderOptions);
  return String::New(info.Env(), result);
}

Value NapiCanvasElement::AttachToCanvasViewMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "AttachToCanvasView", "1");
    return Value();
  }

  auto arg0_name = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto&& result = impl_->AttachToCanvasView(std::move(arg0_name));
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiCanvasElement::DetachFromCanvasViewMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  auto&& result = impl_->DetachFromCanvasView();
  return Napi::Boolean::New(info.Env(), result);
}

Value NapiCanvasElement::GetContextMethod(const CallbackInfo& info) {
  const size_t arg_count = std::min<size_t>(info.Length(), 2u);
  if (arg_count == 1) {
    return GetContextMethodOverload1(info);
  }
  if (arg_count == 2) {
    return GetContextMethodOverload2(info);
  }
  ExceptionMessage::FailedToCallOverload(info.Env(), "GetContext()");
  return info.Env().Undefined();
}

// static
Napi::Class* NapiCanvasElement::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kCanvasElementClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes
  AddAttribute(props, "width",
               &NapiCanvasElement::WidthAttributeGetter,
               &NapiCanvasElement::WidthAttributeSetter
               );
  AddAttribute(props, "height",
               &NapiCanvasElement::HeightAttributeGetter,
               &NapiCanvasElement::HeightAttributeSetter
               );
  AddAttribute(props, "clientWidth",
               &NapiCanvasElement::ClientWidthAttributeGetter,
               &NapiCanvasElement::ClientWidthAttributeSetter
               );
  AddAttribute(props, "clientHeight",
               &NapiCanvasElement::ClientHeightAttributeGetter,
               &NapiCanvasElement::ClientHeightAttributeSetter
               );
  AddAttribute(props, "touch_width",
               &NapiCanvasElement::TouchDec95WidthAttributeGetter,
               nullptr
               );
  AddAttribute(props, "touch_height",
               &NapiCanvasElement::TouchDec95HeightAttributeGetter,
               nullptr
               );
  AddAttribute(props, "isSurfaceCreated",
               &NapiCanvasElement::IsSurfaceCreatedAttributeGetter,
               nullptr
               );

  // Methods
  AddInstanceMethod(props, "getContext", &NapiCanvasElement::GetContextMethod);
  AddInstanceMethod(props, "getBoundingClientRect", &NapiCanvasElement::GetBoundingClientRectMethod);
  AddInstanceMethod(props, "toDataURL", &NapiCanvasElement::ToDataURLMethod);
  AddInstanceMethod(props, "attachToCanvasView", &NapiCanvasElement::AttachToCanvasViewMethod);
  AddInstanceMethod(props, "detachFromCanvasView", &NapiCanvasElement::DetachFromCanvasViewMethod);

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "CanvasElement", props, nullptr, *NapiEventTarget::Class(env)));
  env.SetInstanceData<Napi::Class>(kCanvasElementClassID, clazz);
  return clazz;
}

// static
Function NapiCanvasElement::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kCanvasElementConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kCanvasElementConstructorID, ref);
  return ref->Value();
}

// static
void NapiCanvasElement::Install(Napi::Env env, Object& target) {
  if (target.Has("CanvasElement")) {
    return;
  }
  target.Set("CanvasElement", Constructor(env));
}

}  // namespace canvas
}  // namespace lynx
