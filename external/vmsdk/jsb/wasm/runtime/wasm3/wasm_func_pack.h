// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM3_FUNC_PACK_H_
#define JSB_WASM_RUNTIME_WASM3_FUNC_PACK_H_

#include <memory>
#include <string>

#include "common/js_env.h"
#include "common/wasm_log.h"
#include "wasm3/m3_env.h"

namespace vmsdk {
namespace wasm {
class WasmRuntime;
class WasmInstance;

class WasmFuncPack {
 public:
  WasmFuncPack(js_value js_func, WasmRuntime* rt);
  WasmFuncPack(IM3Function w_func, WasmRuntime* rt,
               std::shared_ptr<WasmInstance>& inst);

  ~WasmFuncPack();

  IM3Function GetWasmFunc() const { return func_.wasm_func; }

  static js_value CallWasmFunc(void* pack, size_t argc,
                               const js_value arguments[],
                               js_value* exception = nullptr);

  static const void* WasmCallback(IM3Runtime runtime, IM3ImportContext _ctx,
                                  u64* _sp, void* _mem);

 private:
  WasmFuncPack(const WasmFuncPack&) = delete;

  union {
    IM3Function wasm_func;
    js_value js_func;
  } func_;
  WasmRuntime* runtime_;
  std::shared_ptr<WasmInstance> inst_ = nullptr;
};
}  // namespace wasm
}  // namespace vmsdk

#endif  // JSB_WASM_RUNTIME_WASM3_FUNC_PACK_H_