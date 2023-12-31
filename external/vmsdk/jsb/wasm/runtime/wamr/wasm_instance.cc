// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_instance.h"

#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {

WasmInstance::WasmInstance(WasmRuntime* rt) : rt_(rt) { WasmRuntime::Dup(rt_); }

WasmInstance::~WasmInstance() {
  if (instance_) wasm_instance_delete(instance_);
  JS_ENV* js_env = rt_->GetJSEnv();
  if (!js_env->IsInvalid()) {
    for (js_value val : imports_) {
      js_env->ReleaseObject(val);
    }
  }
  WasmRuntime::Free(rt_);
}

void WasmInstance::PushImport(js_value import) {
  imports_.push_back(import);
  rt_->GetJSEnv()->ReserveObject(import);
}
}  // namespace wasm
}  // namespace vmsdk