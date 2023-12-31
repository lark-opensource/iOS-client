// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_dictionary.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_dom_matrix_2d_init.h"

#include "jsbridge/napi/exception_message.h"

using Napi::Number;
using Napi::Object;
using Napi::ObjectWrap;
using Napi::String;
using Napi::TypeError;
using Napi::Value;

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
using lynx::piper::IDLTypedArray;
using lynx::piper::IDLArrayBuffer;
using lynx::piper::IDLArrayBufferView;
using lynx::piper::IDLDictionary;
using lynx::piper::IDLSequence;
using lynx::piper::NativeValueTraits;

using lynx::piper::ExceptionMessage;

namespace lynx {
namespace canvas {

// static
std::unique_ptr<DOMMatrix2DInit> DOMMatrix2DInit::ToImpl(const Value& info) {
  if (!info.IsObject()) {
    ExceptionMessage::NonObjectReceived(info.Env(), DictionaryName());
    return nullptr;
  }
  Object obj = info.As<Object>();

  auto result = std::make_unique<DOMMatrix2DInit>();

  if (obj.Has("a")) {
    Value a_val = obj.Get("a");
    result->a_ = NativeValueTraits<IDLNumber>::NativeValue(a_val);
    result->has_a_ = true;
  }

  if (obj.Has("b")) {
    Value b_val = obj.Get("b");
    result->b_ = NativeValueTraits<IDLNumber>::NativeValue(b_val);
    result->has_b_ = true;
  }

  if (obj.Has("c")) {
    Value c_val = obj.Get("c");
    result->c_ = NativeValueTraits<IDLNumber>::NativeValue(c_val);
    result->has_c_ = true;
  }

  if (obj.Has("d")) {
    Value d_val = obj.Get("d");
    result->d_ = NativeValueTraits<IDLNumber>::NativeValue(d_val);
    result->has_d_ = true;
  }

  if (obj.Has("e")) {
    Value e_val = obj.Get("e");
    result->e_ = NativeValueTraits<IDLNumber>::NativeValue(e_val);
    result->has_e_ = true;
  }

  if (obj.Has("f")) {
    Value f_val = obj.Get("f");
    result->f_ = NativeValueTraits<IDLNumber>::NativeValue(f_val);
    result->has_f_ = true;
  }

  if (obj.Has("m11")) {
    Value m11_val = obj.Get("m11");
    result->m11_ = NativeValueTraits<IDLNumber>::NativeValue(m11_val);
    result->has_m11_ = true;
  }

  if (obj.Has("m12")) {
    Value m12_val = obj.Get("m12");
    result->m12_ = NativeValueTraits<IDLNumber>::NativeValue(m12_val);
    result->has_m12_ = true;
  }

  if (obj.Has("m21")) {
    Value m21_val = obj.Get("m21");
    result->m21_ = NativeValueTraits<IDLNumber>::NativeValue(m21_val);
    result->has_m21_ = true;
  }

  if (obj.Has("m22")) {
    Value m22_val = obj.Get("m22");
    result->m22_ = NativeValueTraits<IDLNumber>::NativeValue(m22_val);
    result->has_m22_ = true;
  }

  if (obj.Has("m41")) {
    Value m41_val = obj.Get("m41");
    result->m41_ = NativeValueTraits<IDLNumber>::NativeValue(m41_val);
    result->has_m41_ = true;
  }

  if (obj.Has("m42")) {
    Value m42_val = obj.Get("m42");
    result->m42_ = NativeValueTraits<IDLNumber>::NativeValue(m42_val);
    result->has_m42_ = true;
  }

  return result;
}

Object DOMMatrix2DInit::ToJsObject(Napi::Env env) {
  auto obj = Object::New(env);

  if (hasA()) {
    obj["a"] = Number::New(env, a_);
  }
  if (hasB()) {
    obj["b"] = Number::New(env, b_);
  }
  if (hasC()) {
    obj["c"] = Number::New(env, c_);
  }
  if (hasD()) {
    obj["d"] = Number::New(env, d_);
  }
  if (hasE()) {
    obj["e"] = Number::New(env, e_);
  }
  if (hasF()) {
    obj["f"] = Number::New(env, f_);
  }
  if (hasM11()) {
    obj["m11"] = Number::New(env, m11_);
  }
  if (hasM12()) {
    obj["m12"] = Number::New(env, m12_);
  }
  if (hasM21()) {
    obj["m21"] = Number::New(env, m21_);
  }
  if (hasM22()) {
    obj["m22"] = Number::New(env, m22_);
  }
  if (hasM41()) {
    obj["m41"] = Number::New(env, m41_);
  }
  if (hasM42()) {
    obj["m42"] = Number::New(env, m42_);
  }

  return obj;
}

}  // namespace canvas
}  // namespace lynx
