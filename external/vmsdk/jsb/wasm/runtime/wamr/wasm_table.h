// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM_WAMR_TABLE_H_
#define JSB_WASM_RUNTIME_WASM_WAMR_TABLE_H_

#include <stdint.h>
#include <stdlib.h>

#include <memory>

#include "common/js_env.h"

struct wasm_ref_t;
struct wasm_table_t;

namespace vmsdk {
namespace wasm {
class WasmFuncPack;
class WasmInstance;
class WasmRuntime;

typedef wasm_ref_t wasm_ref;
enum class TableElementType { FuncRef = 0, AnyRef = 1 };

class WasmTable {
 public:
  using elem_ref = wasm_ref;

  WasmTable(WasmRuntime* runtime, wasm_table_t* table);
  WasmTable(WasmRuntime* runtime, wasm_table_t* table,
            std::shared_ptr<WasmInstance>& inst);
  ~WasmTable();

  size_t size();
  // return the function ref at tbl[index]
  js_value get(size_t index);
  bool set(size_t index, WasmFuncPack* value);
  bool grow(size_t num);
  bool is_valid_elem(js_value) const;

  std::shared_ptr<WasmInstance>& GetInstance() { return inst_; }

 private:
  WasmRuntime* runtime_;
  wasm_table_t* table_;
  std::shared_ptr<WasmInstance> inst_ = nullptr;
};

}  // namespace wasm
}  // namespace vmsdk
#endif  // JSB_WASM_RUNTIME_WASM_WAMR_TABLE_H_