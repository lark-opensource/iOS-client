// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_dictionary.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_webgl_context_attributes.h"

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
std::unique_ptr<WebGLContextAttributes> WebGLContextAttributes::ToImpl(const Value& info) {
  if (!info.IsObject()) {
    ExceptionMessage::NonObjectReceived(info.Env(), DictionaryName());
    return nullptr;
  }
  Object obj = info.As<Object>();

  auto result = std::make_unique<WebGLContextAttributes>();

  if (obj.Has("alpha")) {
    Value alpha_val = obj.Get("alpha");
    result->alpha_ = NativeValueTraits<IDLBoolean>::NativeValue(alpha_val);
    result->has_alpha_ = true;
  }

  if (obj.Has("antialias")) {
    Value antialias_val = obj.Get("antialias");
    result->antialias_ = NativeValueTraits<IDLBoolean>::NativeValue(antialias_val);
    result->has_antialias_ = true;
  }

  if (obj.Has("depth")) {
    Value depth_val = obj.Get("depth");
    result->depth_ = NativeValueTraits<IDLBoolean>::NativeValue(depth_val);
    result->has_depth_ = true;
  }

  if (obj.Has("desynchronized")) {
    Value desynchronized_val = obj.Get("desynchronized");
    result->desynchronized_ = NativeValueTraits<IDLBoolean>::NativeValue(desynchronized_val);
    result->has_desynchronized_ = true;
  }

  if (obj.Has("enableMSAA")) {
    Value enableMSAA_val = obj.Get("enableMSAA");
    result->enableMSAA_ = NativeValueTraits<IDLBoolean>::NativeValue(enableMSAA_val);
    result->has_enableMSAA_ = true;
  }

  if (obj.Has("failIfMajorPerformanceCaveat")) {
    Value failIfMajorPerformanceCaveat_val = obj.Get("failIfMajorPerformanceCaveat");
    result->failIfMajorPerformanceCaveat_ = NativeValueTraits<IDLBoolean>::NativeValue(failIfMajorPerformanceCaveat_val);
    result->has_failIfMajorPerformanceCaveat_ = true;
  }

  if (obj.Has("premultipliedAlpha")) {
    Value premultipliedAlpha_val = obj.Get("premultipliedAlpha");
    result->premultipliedAlpha_ = NativeValueTraits<IDLBoolean>::NativeValue(premultipliedAlpha_val);
    result->has_premultipliedAlpha_ = true;
  }

  if (obj.Has("preserveDrawingBuffer")) {
    Value preserveDrawingBuffer_val = obj.Get("preserveDrawingBuffer");
    result->preserveDrawingBuffer_ = NativeValueTraits<IDLBoolean>::NativeValue(preserveDrawingBuffer_val);
    result->has_preserveDrawingBuffer_ = true;
  }

  if (obj.Has("stencil")) {
    Value stencil_val = obj.Get("stencil");
    result->stencil_ = NativeValueTraits<IDLBoolean>::NativeValue(stencil_val);
    result->has_stencil_ = true;
  }

  return result;
}

Object WebGLContextAttributes::ToJsObject(Napi::Env env) {
  auto obj = Object::New(env);

  if (hasAlpha()) {
    obj["alpha"] = Napi::Boolean::New(env, alpha_);
  }
  if (hasAntialias()) {
    obj["antialias"] = Napi::Boolean::New(env, antialias_);
  }
  if (hasDepth()) {
    obj["depth"] = Napi::Boolean::New(env, depth_);
  }
  if (hasDesynchronized()) {
    obj["desynchronized"] = Napi::Boolean::New(env, desynchronized_);
  }
  if (hasEnableMSAA()) {
    obj["enableMSAA"] = Napi::Boolean::New(env, enableMSAA_);
  }
  if (hasFailIfMajorPerformanceCaveat()) {
    obj["failIfMajorPerformanceCaveat"] = Napi::Boolean::New(env, failIfMajorPerformanceCaveat_);
  }
  if (hasPremultipliedAlpha()) {
    obj["premultipliedAlpha"] = Napi::Boolean::New(env, premultipliedAlpha_);
  }
  if (hasPreserveDrawingBuffer()) {
    obj["preserveDrawingBuffer"] = Napi::Boolean::New(env, preserveDrawingBuffer_);
  }
  if (hasStencil()) {
    obj["stencil"] = Napi::Boolean::New(env, stencil_);
  }

  return obj;
}

}  // namespace canvas
}  // namespace lynx
