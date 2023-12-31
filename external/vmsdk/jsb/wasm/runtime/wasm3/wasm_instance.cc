// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_instance.h"

#include "wasm_func_pack.h"
#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {

WasmInstance::WasmInstance(WasmRuntime* rt) : rt_(rt) { WasmRuntime::Dup(rt_); }

WasmInstance::~WasmInstance() {
  WLOGD("%s: finalizing wasm instance...", __func__);

  JS_ENV* js_env = rt_->GetJSEnv();
  if (!js_env->IsInvalid()) {
    js_env->ReleaseObject(import_memory_);
    for (js_value val : imports_) {
      js_env->ReleaseObject(val);
    }
    for (auto& val : import_globals_) {
      js_env->ReleaseObject(val.second);
    }
  }
  for (WasmFuncPack* pck : packs_) {
    delete pck;
  }
  if (instance_) {
    m3_UnloadModule(instance_);
    m3_FreeModule(instance_);
  }
  WasmRuntime::Free(rt_);
}

void WasmInstance::PushImport(js_value import) {
  imports_.push_back(import);
  rt_->GetJSEnv()->ReserveObject(import);
}

void WasmInstance::SetMemoryObject(js_value js_memory) {
  rt_->GetJSEnv()->ReserveObject(js_memory);
  import_memory_ = js_memory;
}

void WasmInstance::SetGlobalObject(js_value js_global, int idx) {
  rt_->GetJSEnv()->ReserveObject(js_global);
  import_globals_[idx] = js_global;
}

}  // namespace wasm
}  // namespace vmsdk
