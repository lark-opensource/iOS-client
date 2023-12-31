// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WAMR_WASM_MODULE_H_
#define JSB_WASM_RUNTIME_WAMR_WASM_MODULE_H_

#include "wasm_c_api.h"
#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {

class WasmModule {
 public:
  WasmModule(wasm_module_t* module, WasmRuntime* wasm_rt);
  ~WasmModule();
  void exports(js_context ctx, js_value array, js_value* exception);
  void imports(js_context ctx, js_value array, js_value* exception);
  // Temporary approach.
  wasm_module_t* impl() const { return module_; }

 private:
  wasm_module_t* module_;
  WasmRuntime* wasm_rt_;
};

}  // namespace wasm
}  // namespace vmsdk

#endif  // JSB_WASM_RUNTIME_WAMR_WASM_MODULE_H_