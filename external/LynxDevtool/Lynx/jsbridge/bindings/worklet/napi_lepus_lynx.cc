// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_interface.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/worklet/napi_lepus_lynx.h"

#include <vector>
#include <utility>

#include "jsbridge/bindings/worklet/napi_frame_callback.h"
#include "jsbridge/bindings/worklet/napi_func_callback.h"
#include "jsbridge/bindings/worklet/napi_lepus_element.h"
#include "worklet/lepus_element.h"
#include "worklet/lepus_lynx.h"
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
namespace worklet {

namespace {
const uint64_t kLepusLynxClassID = reinterpret_cast<uint64_t>(&kLepusLynxClassID);
const uint64_t kLepusLynxConstructorID = reinterpret_cast<uint64_t>(&kLepusLynxConstructorID);

using Wrapped = piper::NapiBaseWrapped<NapiLepusLynx>;
typedef Value (NapiLepusLynx::*InstanceCallback)(const CallbackInfo& info);
typedef void (NapiLepusLynx::*InstanceSetterCallback)(const CallbackInfo& info, const Value& value);

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

NapiLepusLynx::NapiLepusLynx(const CallbackInfo& info, bool skip_init_as_base)
    : BridgeBase(info) {
  // If this is a base class or created by native, skip initialization since
  // impl side needs to have control over the construction of the impl object.
  if (skip_init_as_base || (info.Length() == 1 && info[0].IsExternal())) {
    return;
  }
  ExceptionMessage::IllegalConstructor(info.Env(), InterfaceName());
  return;
}

LepusLynx* NapiLepusLynx::ToImplUnsafe() {
  return impl_.get();
}

// static
Object NapiLepusLynx::Wrap(std::unique_ptr<LepusLynx> impl, Napi::Env env) {
  DCHECK(impl);
  auto obj = Constructor(env).New({Napi::External::New(env, nullptr, nullptr, nullptr)});
  ObjectWrap<NapiLepusLynx>::Unwrap(obj)->Init(std::move(impl));
  return obj;
}

void NapiLepusLynx::Init(std::unique_ptr<LepusLynx> impl) {
  DCHECK(impl);
  DCHECK(!impl_);

  impl_ = std::move(impl);
  // We only associate and call OnWrapped() once, when we init the root base.
  impl_->AssociateWithWrapper(this);
}

Value NapiLepusLynx::TriggerLepusBridgeMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 3) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TriggerLepusBridge", "3");
    return Value();
  }

  auto arg0_methodName = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto arg1_methodDetail = NativeValueTraits<IDLObject>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  auto arg2_cb = NativeValueTraits<IDLFunction<NapiFuncCallback>>::NativeValue(info, 2);
  if (info.Env().IsExceptionPending()) {
    return info.Env().Undefined();
  }

  impl_->TriggerLepusBridge(std::move(arg0_methodName), arg1_methodDetail, std::move(arg2_cb));
  return info.Env().Undefined();
}

Value NapiLepusLynx::TriggerLepusBridgeSyncMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "TriggerLepusBridgeSync", "2");
    return Value();
  }

  auto arg0_methodName = NativeValueTraits<IDLString>::NativeValue(info, 0);

  auto arg1_methodDetail = NativeValueTraits<IDLObject>::NativeValue(info, 1);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto&& result = impl_->TriggerLepusBridgeSync(std::move(arg0_methodName), arg1_methodDetail);
  return result;
}

Value NapiLepusLynx::SetTimeoutMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "SetTimeout", "2");
    return Value();
  }

  auto arg0_cb = NativeValueTraits<IDLFunction<NapiFuncCallback>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_delay = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->SetTimeout(std::move(arg0_cb), arg1_delay);
  return Number::New(info.Env(), result);
}

Value NapiLepusLynx::ClearTimeoutMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "ClearTimeout", "1");
    return Value();
  }

  auto arg0_id = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  impl_->ClearTimeout(arg0_id);
  return info.Env().Undefined();
}

Value NapiLepusLynx::SetIntervalMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 2) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "SetInterval", "2");
    return Value();
  }

  auto arg0_cb = NativeValueTraits<IDLFunction<NapiFuncCallback>>::NativeValue(info, 0);
  if (info.Env().IsExceptionPending()) {
    return Value();
  }

  auto arg1_delay = NativeValueTraits<IDLNumber>::NativeValue(info, 1);

  auto&& result = impl_->SetInterval(std::move(arg0_cb), arg1_delay);
  return Number::New(info.Env(), result);
}

Value NapiLepusLynx::ClearIntervalMethod(const CallbackInfo& info) {
  DCHECK(impl_);

  if (info.Length() < 1) {
    ExceptionMessage::NotEnoughArguments(info.Env(), InterfaceName(), "ClearInterval", "1");
    return Value();
  }

  auto arg0_id = NativeValueTraits<IDLNumber>::NativeValue(info, 0);

  impl_->ClearInterval(arg0_id);
  return info.Env().Undefined();
}

// static
Napi::Class* NapiLepusLynx::Class(Napi::Env env) {
  auto* clazz = env.GetInstanceData<Napi::Class>(kLepusLynxClassID);
  if (clazz) {
    return clazz;
  }

  std::vector<Wrapped::PropertyDescriptor> props;

  // Attributes

  // Methods
  AddInstanceMethod(props, "triggerLepusBridge", &NapiLepusLynx::TriggerLepusBridgeMethod);
  AddInstanceMethod(props, "triggerLepusBridgeSync", &NapiLepusLynx::TriggerLepusBridgeSyncMethod);
  AddInstanceMethod(props, "setTimeout", &NapiLepusLynx::SetTimeoutMethod);
  AddInstanceMethod(props, "clearTimeout", &NapiLepusLynx::ClearTimeoutMethod);
  AddInstanceMethod(props, "setInterval", &NapiLepusLynx::SetIntervalMethod);
  AddInstanceMethod(props, "clearInterval", &NapiLepusLynx::ClearIntervalMethod);

  // Cache the class
  clazz = new Napi::Class(Wrapped::DefineClass(env, "LepusLynx", props));
  env.SetInstanceData<Napi::Class>(kLepusLynxClassID, clazz);
  return clazz;
}

// static
Function NapiLepusLynx::Constructor(Napi::Env env) {
  FunctionReference* ref = env.GetInstanceData<FunctionReference>(kLepusLynxConstructorID);
  if (ref) {
    return ref->Value();
  }

  // Cache the constructor for future use
  ref = new FunctionReference();
  ref->Reset(Class(env)->Get(env), 1);
  env.SetInstanceData<FunctionReference>(kLepusLynxConstructorID, ref);
  return ref->Value();
}

// static
void NapiLepusLynx::Install(Napi::Env env, Object& target) {
  if (target.Has("LepusLynx")) {
    return;
  }
  target.Set("LepusLynx", Constructor(env));
}

}  // namespace worklet
}  // namespace lynx
