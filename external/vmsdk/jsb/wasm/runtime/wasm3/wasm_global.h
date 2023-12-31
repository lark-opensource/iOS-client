// Copyright 2023 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM3_GLOBAL_H_
#define JSB_WASM_RUNTIME_WASM3_GLOBAL_H_

#include "wasm3/m3_env.h"
#include "wasm_instance.h"
#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {
// Global class for wasm3 engine, including IM3Global pointer for import/export
// and IM3TaggedValue for standalone global.value from javascript.
class WasmGlobal {
 public:
  enum ValueType {
    kTypeNone,
    kTypeI32,
    kTypeI64,
    kTypeF32,
    kTypeF64,
    kTypeV128,
    kTypeExternref,
    kTypeAnyfunc
  };

  WasmGlobal(WasmRuntime* wasm_rt, bool mutability, double value, uint8_t type);
  WasmGlobal(WasmRuntime* wasm_rt, IM3Global global,
             std::shared_ptr<WasmInstance>& inst);
  ~WasmGlobal();

  int set_value(double value);
  int get_value(js_value* out);

  void ImportGlobal(IM3Global global) { global_ = global; }

  bool mutability() { return mutability_; }

  IM3Global impl() const { return global_; }

  std::shared_ptr<WasmInstance>& GetInstance() { return inst_; }

  void SetInstance(std::shared_ptr<WasmInstance>& inst) { inst_ = inst; }

  int SetLinkedValue(double value);

  u8 GetType();

  static u8 StrToType(const char* type_str);

 private:
  WasmGlobal(const WasmGlobal&) = delete;
  WasmGlobal(WasmGlobal&&) = delete;
  WasmGlobal& operator=(WasmGlobal&&) = delete;

  WasmRuntime* wasm_rt_;

  bool mutability_ = false;
  // Global imported into or exported from wasm3 engine.
  // No need to free.
  IM3Global global_ = nullptr;
  // This value is constructed by JavaScript `new WebAssembly.Global(xxx)`;
  // It may not equals to the value in `this->global_` because if
  // `global_` is not NULL, this member should be deprecated and never used
  // again. Although, if we follow WebAssembly JS-API spec, this->value_ should
  // always equal to the value in this->global_. But, based on the fact that
  // wasm3's instance is destoryed after runtime did, this->global_ will not
  // deleted uitil wasm program exited, so we can always use global_ once it is
  // not null.
  M3TaggedValue value_;

  std::shared_ptr<WasmInstance> inst_ = nullptr;
};

}  // namespace wasm
}  // namespace vmsdk

#endif  // JSB_WASM_RUNTIME_WASM3_GLOBAL_H_