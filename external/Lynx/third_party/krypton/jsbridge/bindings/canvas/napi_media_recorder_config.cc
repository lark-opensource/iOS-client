// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_dictionary.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_media_recorder_config.h"

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
std::unique_ptr<MediaRecorderConfig> MediaRecorderConfig::ToImpl(const Value& info) {
  if (!info.IsObject()) {
    ExceptionMessage::NonObjectReceived(info.Env(), DictionaryName());
    return nullptr;
  }
  Object obj = info.As<Object>();

  auto result = std::make_unique<MediaRecorderConfig>();

  if (obj.Has("audio")) {
    Value audio_val = obj.Get("audio");
    result->audio_ = NativeValueTraits<IDLBoolean>::NativeValue(audio_val);
    result->has_audio_ = true;
  }

  if (obj.Has("autoPauseAndResume")) {
    Value autoPauseAndResume_val = obj.Get("autoPauseAndResume");
    result->autoPauseAndResume_ = NativeValueTraits<IDLBoolean>::NativeValue(autoPauseAndResume_val);
    result->has_autoPauseAndResume_ = true;
  }

  if (obj.Has("bps")) {
    Value bps_val = obj.Get("bps");
    result->bps_ = NativeValueTraits<IDLNumber>::NativeValue(bps_val);
    result->has_bps_ = true;
  }

  if (obj.Has("deleteFilesOnDestroy")) {
    Value deleteFilesOnDestroy_val = obj.Get("deleteFilesOnDestroy");
    result->deleteFilesOnDestroy_ = NativeValueTraits<IDLBoolean>::NativeValue(deleteFilesOnDestroy_val);
    result->has_deleteFilesOnDestroy_ = true;
  }

  if (obj.Has("duration")) {
    Value duration_val = obj.Get("duration");
    result->duration_ = NativeValueTraits<IDLNumber>::NativeValue(duration_val);
    result->has_duration_ = true;
  }

  if (obj.Has("fps")) {
    Value fps_val = obj.Get("fps");
    result->fps_ = NativeValueTraits<IDLNumber>::NativeValue(fps_val);
    result->has_fps_ = true;
  }

  if (obj.Has("height")) {
    Value height_val = obj.Get("height");
    result->height_ = NativeValueTraits<IDLNumber>::NativeValue(height_val);
    result->has_height_ = true;
  }

  if (obj.Has("width")) {
    Value width_val = obj.Get("width");
    result->width_ = NativeValueTraits<IDLNumber>::NativeValue(width_val);
    result->has_width_ = true;
  }

  return result;
}

Object MediaRecorderConfig::ToJsObject(Napi::Env env) {
  auto obj = Object::New(env);

  if (hasAudio()) {
    obj["audio"] = Napi::Boolean::New(env, audio_);
  }
  if (hasAutoPauseAndResume()) {
    obj["autoPauseAndResume"] = Napi::Boolean::New(env, autoPauseAndResume_);
  }
  if (hasBps()) {
    obj["bps"] = Number::New(env, bps_);
  }
  if (hasDeleteFilesOnDestroy()) {
    obj["deleteFilesOnDestroy"] = Napi::Boolean::New(env, deleteFilesOnDestroy_);
  }
  if (hasDuration()) {
    obj["duration"] = Number::New(env, duration_);
  }
  if (hasFps()) {
    obj["fps"] = Number::New(env, fps_);
  }
  if (hasHeight()) {
    obj["height"] = Number::New(env, height_);
  }
  if (hasWidth()) {
    obj["width"] = Number::New(env, width_);
  }

  return obj;
}

}  // namespace canvas
}  // namespace lynx
