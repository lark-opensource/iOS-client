// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_callback_function.cc.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#include "jsbridge/bindings/canvas/napi_preload_plugin_callback.h"

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
  const uint64_t kNapiPreloadPluginCallbackClassID = reinterpret_cast<uint64_t>(&kNapiPreloadPluginCallbackClassID);
}

void NapiPreloadPluginCallback::Invoke(bool arg0, std::string arg1) {
  bool valid;
  Napi::Env env = Env(&valid);
  if (!valid) {
    return;
  }

  HolderStorage *storage = reinterpret_cast<HolderStorage*>(env.GetInstanceData(kNapiPreloadPluginCallbackClassID));
  DCHECK(storage);

  auto cb = storage->PopHolder(reinterpret_cast<uintptr_t>(this));

  Napi::Value arg0_success;
  arg0_success = Napi::Boolean::New(env, arg0);

  Napi::Value arg1_err;
  arg1_err = Napi::String::New(env, arg1);

  // The JS callback object is stolen after the call.
  piper::CallbackHelper::Invoke(std::move(cb), result_, exception_handler_, { arg0_success, arg1_err });
}

NapiPreloadPluginCallback::NapiPreloadPluginCallback(Napi::Function callback) {
  Napi::Env env = callback.Env();
  HolderStorage *storage = reinterpret_cast<HolderStorage*>(env.GetInstanceData(kNapiPreloadPluginCallbackClassID));
  if (storage == nullptr) {
    storage = new HolderStorage();
    env.SetInstanceData(kNapiPreloadPluginCallbackClassID, storage, [](napi_env env, void* finalize_data,
                                                                   void* finalize_hint) { delete reinterpret_cast<HolderStorage*>(finalize_data); }, nullptr);
  }

  storage->PushHolder(reinterpret_cast<uintptr_t>(this), Napi::Persistent(callback));

  storage_guard_ = storage->instance_guard();
}

Napi::Env NapiPreloadPluginCallback::Env(bool *valid) {
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
