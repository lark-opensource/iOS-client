// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WAMR_FUNC_PACK_H_
#define JSB_WASM_RUNTIME_WAMR_FUNC_PACK_H_

#include <memory>

#include "common/js_env.h"
#include "wasm_c_api.h"

namespace vmsdk {
namespace wasm {
class WasmRuntime;
class WasmInstance;

class WasmFuncPack {
 public:
  WasmFuncPack(js_value js_func, WasmRuntime* rt);
  WasmFuncPack(wasm_func_t* w_func, WasmRuntime* rt,
               std::shared_ptr<WasmInstance>& inst);
  ~WasmFuncPack();

  wasm_func_t* GetWasmFunc() const { return func_.wasm_func; }

  static js_value CallWasmFunc(void* pack, size_t argc,
                               const js_value arguments[],
                               js_value* exception = nullptr);
  static wasm_trap_t* WasmCallback(void* env, const wasm_val_vec_t* args,
                                   wasm_val_vec_t* results);

 private:
  union {
    wasm_func_t* wasm_func;
    js_value js_func;
  } func_;
  WasmRuntime* runtime_;
  // FuncType ftype_;
  // Only when ftype_ equals to kWasmFunction, field 'inst_'
  // can have a valid value rather than nullptr.
  std::shared_ptr<WasmInstance> inst_ = nullptr;
};

}  // namespace wasm
}  // namespace vmsdk

#endif  // JSB_WASM_RUNTIME_WAMR_FUNC_PACK_H_