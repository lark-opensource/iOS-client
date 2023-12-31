// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_module.h"

#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {

WasmModule::WasmModule(IM3Module module) : module_(module) {}

WasmModule::~WasmModule() {
  // When this module is not loaded to runtime.
  // It is owned by M3Runtime otherwise.
  if (module_ && module_->runtime == nullptr) {
    invalidate();
  }
}

void WasmModule::invalidate() {
  // When instantiating failed.
  m3_FreeModule(module_);
  module_ = nullptr;
}

void WasmModule::exports(js_context ctx, js_value array, js_value* exception) {}
void WasmModule::imports(js_context ctx, js_value array, js_value* exception) {}
}  // namespace wasm
}  // namespace vmsdk
