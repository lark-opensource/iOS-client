// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM3_WASM_INSTANCE_H_
#define JSB_WASM_RUNTIME_WASM3_WASM_INSTANCE_H_
#include <unordered_map>
#include <vector>

#include "common/js_type.h"
#include "wasm3/m3_env.h"

namespace vmsdk {
namespace wasm {
class WasmFuncPack;
class WasmRuntime;

class WasmInstance {
 public:
  WasmInstance(WasmRuntime* rt);
  ~WasmInstance();

  IM3Module GetImpl() { return instance_; }
  void SetImpl(IM3Module inst) { instance_ = inst; }

  void AddJSCallbackEnv(WasmFuncPack* pack) { packs_.push_back(pack); }

  void PushImport(js_value import);

  js_value GetMemoryObject() { return import_memory_; }

  void SetMemoryObject(js_value js_memory);

  js_value GetTableObject() { return import_table_; }

  void SetTableObject(js_value js_table) { import_table_ = js_table; }

  void SetGlobalObject(js_value js_global, int idx);

  js_value GetGlobalObject(int idx) {
    if (import_globals_.count(idx)) {
      return import_globals_[idx];
    } else {
      return JS_NULL;
    }
  }

 private:
  WasmRuntime* rt_;
  IM3Module instance_ = nullptr;
  js_value import_memory_ = JS_NULL;
  js_value import_table_ = JS_NULL;
  std::unordered_map<int, js_value> import_globals_;
  std::vector<js_value> imports_;

  // These 'WasmFuncPack' contain JS functions which will
  // be called by Wasm and provide environments to support
  // JS functions execution. Given that wasm3 do not release
  // host function env, these packs must be deleted when
  // the WasmInstance expires.
  std::vector<WasmFuncPack*> packs_;
};

}  // namespace wasm
}  // namespace vmsdk

#endif  // JSB_WASM_RUNTIME_WASM3_WASM_INSTANCE_H_