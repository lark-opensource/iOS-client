// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_callback_function.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_get_user_media_callback.h"

#include "jsbridge/bindings/canvas/napi_media_stream.h"

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

namespace lynx {
namespace canvas {
namespace {
  const uint64_t kNapiGetUserMediaCallbackClassID = reinterpret_cast<uint64_t>(&kNapiGetUserMediaCallbackClassID);
}

void NapiGetUserMediaCallback::Invoke(std::unique_ptr<MediaStream> arg0, std::optional<std::string> arg1_optional) {
  bool valid;
  Napi::Env env = Env(&valid);
  if (!valid) {
    return;
  }

  HolderStorage *storage = reinterpret_cast<HolderStorage*>(env.GetInstanceData(kNapiGetUserMediaCallbackClassID));
  DCHECK(storage);

  auto cb = storage->PopHolder(reinterpret_cast<uintptr_t>(this));

  Napi::Value arg0_stream;
  arg0_stream = arg0->IsWrapped() ? arg0->JsObject() : NapiMediaStream::Wrap(std::move(arg0), env);

  Napi::Value arg1_err;
  if (arg1_optional.has_value()) {
    auto&& arg1 = *arg1_optional;
    arg1_err = Napi::String::New(env, arg1);
  } else {
    arg1_err = env.Undefined();
  }

  // The JS callback object is stolen after the call.
  piper::CallbackHelper::Invoke(std::move(cb), result_, exception_handler_, { arg0_stream, arg1_err });
}

NapiGetUserMediaCallback::NapiGetUserMediaCallback(Napi::Function callback) {
  Napi::Env env = callback.Env();
  HolderStorage *storage = reinterpret_cast<HolderStorage*>(env.GetInstanceData(kNapiGetUserMediaCallbackClassID));
  if (storage == nullptr) {
    storage = new HolderStorage();
    env.SetInstanceData(kNapiGetUserMediaCallbackClassID, storage, [](napi_env env, void* finalize_data,
                                                                   void* finalize_hint) { delete reinterpret_cast<HolderStorage*>(finalize_data); }, nullptr);
  }

  storage->PushHolder(reinterpret_cast<uintptr_t>(this), Napi::Persistent(callback));

  storage_guard_ = storage->instance_guard();
}

Napi::Env NapiGetUserMediaCallback::Env(bool *valid) {
  if (valid != nullptr) {
    *valid = false;
  }

  auto strong_guard = storage_guard_.lock();
  if (!strong_guard) {
    // if valid is nullptr, it must be valid.
    DCHECK(valid);
    return Napi::Env(nullptr);
  }

  auto storage = strong_guard->Get();
  auto &cb = storage->PeekHolder(reinterpret_cast<uintptr_t>(this));
  if (cb.IsEmpty()) {
    // if valid is nullptr, it must be valid.
    DCHECK(valid);
    return Napi::Env(nullptr);
  }

  if (valid != nullptr) {
    *valid = true;
  }
  return cb.Env();
}

}  // namespace canvas
}  // namespace lynx
