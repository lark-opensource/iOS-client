// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_dictionary.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_video_load_options.h"

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
std::unique_ptr<VideoLoadOptions> VideoLoadOptions::ToImpl(const Value& info) {
  if (!info.IsObject()) {
    ExceptionMessage::NonObjectReceived(info.Env(), DictionaryName());
    return nullptr;
  }
  Object obj = info.As<Object>();

  auto result = std::make_unique<VideoLoadOptions>();

  if (obj.Has("useCustomPlayer")) {
    Value useCustomPlayer_val = obj.Get("useCustomPlayer");
    result->useCustomPlayer_ = NativeValueTraits<IDLBoolean>::NativeValue(useCustomPlayer_val);
    result->has_useCustomPlayer_ = true;
  }

  return result;
}

Object VideoLoadOptions::ToJsObject(Napi::Env env) {
  auto obj = Object::New(env);

  if (hasUseCustomPlayer()) {
    obj["useCustomPlayer"] = Napi::Boolean::New(env, useCustomPlayer_);
  }

  return obj;
}

}  // namespace canvas
}  // namespace lynx
