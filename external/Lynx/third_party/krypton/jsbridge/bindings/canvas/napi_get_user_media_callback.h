// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_callback_function.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef JSBRIDGE_BINDINGS_CANVAS_NAPI_GET_USER_MEDIA_CALLBACK_H_
#define JSBRIDGE_BINDINGS_CANVAS_NAPI_GET_USER_MEDIA_CALLBACK_H_

#include <utility>
#include <memory>

#include <optional>
#include "jsbridge/napi/base.h"
#include "jsbridge/napi/callback_helper.h"

#include "canvas/media/media_stream.h"

namespace lynx {
namespace canvas {

using piper::HolderStorage;
using piper::InstanceGuard;

class NapiGetUserMediaCallback {
 public:
  NapiGetUserMediaCallback(Napi::Function callback);

  NapiGetUserMediaCallback(const NapiGetUserMediaCallback& cb) = delete;

  void Invoke(std::unique_ptr<MediaStream> arg0, std::optional<std::string> arg1);

  Napi::Value GetResult() { return result_; }
  Napi::Env Env(bool *valid);

  void SetExceptionHandler(std::function<void(Napi::Env)> handler) {
    exception_handler_ = std::move(handler);
  }

 private:
  std::weak_ptr<InstanceGuard> storage_guard_;
  Napi::Value result_;
  std::function<void(Napi::Env)> exception_handler_;
};

}  // namespace canvas
}  // namespace lynx

#endif  // JSBRIDGE_BINDINGS_CANVAS_NAPI_GET_USER_MEDIA_CALLBACK_H_
