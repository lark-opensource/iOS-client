// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM_WAMR_GLOBAL_H_
#define JSB_WASM_RUNTIME_WASM_WAMR_GLOBAL_H_

#include <memory>

#include "common/js_env.h"
#include "wasm_c_api.h"

namespace vmsdk {
namespace wasm {
class WasmRuntime;
class WasmInstance;

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

  WasmGlobal(wasm_global_t* global, bool mutability, wasm_val_t* value,
             WasmRuntime* runtime);

  WasmGlobal(wasm_global_t* global, bool mutability, wasm_val_t* value,
             WasmRuntime* runtime, std::shared_ptr<WasmInstance>& inst);

  ~WasmGlobal();

  // setter and getter for value
  int set_value(double value);
  int get_value(js_value* out);

  // get metadata from here
  wasm_val_t* value() { return &value_; }
  bool mutability() { return mutability_; }

  wasm_global_t* global() { return global_; }

  void set_global(wasm_global_t* global);

  static bool mutability(wasm_global_t* global);

  uint8_t GetType();

  static uint8_t StrToType(const char* type_str);

 private:
  bool mutability_;
  WasmRuntime* runtime_;

  wasm_val_t value_;
  wasm_global_t* global_;
  std::shared_ptr<WasmInstance> inst_ = nullptr;
};
}  // namespace wasm
}  // namespace vmsdk
#endif  // JSB_WASM_RUNTIME_WASM_WAMR_GLOBAL_H_