// Copyright 2021 The Lynx Authors. All rights reserved.

// This file has been auto-generated from the Jinja2 template
// jsbridge/bindings/idl-codegen/templates/napi_callback_function.h.tmpl
// by the script code_generator_napi.py.
// DO NOT MODIFY!

// clang-format off
#ifndef LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_FRAME_CALLBACK_H_
#define LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_FRAME_CALLBACK_H_

#include <utility>
#include <memory>

#include "jsbridge/napi/base.h"
#include "jsbridge/napi/callback_helper.h"

namespace lynx {
namespace worklet {

using piper::HolderStorage;
using piper::InstanceGuard;

class NapiFrameCallback {
 public:
  NapiFrameCallback(Napi::Function callback);

  NapiFrameCallback(const NapiFrameCallback& cb) = delete;

  void Invoke(int64_t arg0);

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

#endif  // LYNX_JSBRIDGE_BINDINGS_WORKLET_NAPI_FRAME_CALLBACK_H_
