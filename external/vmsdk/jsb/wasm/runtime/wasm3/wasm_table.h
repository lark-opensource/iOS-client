// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM3_WASM_TABLE_H_
#define JSB_WASM_RUNTIME_WASM3_WASM_TABLE_H_

#include <stdint.h>
#include <stdlib.h>

#include <memory>

#include "common/js_env.h"
#include "wasm3/wasm3.h"

namespace vmsdk {
namespace wasm {
class WasmInstance;
class WasmFuncPack;
class WasmRuntime;

enum class TableElementType { FuncRef = 0, AnyRef = 1 };
class WasmTable {
 public:
  using elem_ref = IM3Function;

  // create WasmTable with IM3Table
  WasmTable(WasmRuntime* runtime, uint32_t initial, uint32_t maximum,
            TableElementType type);
  WasmTable(WasmRuntime* runtime, IM3Table table,
            std::shared_ptr<WasmInstance>& inst);
  ~WasmTable();

  size_t size();
  // return the function ref at tbl[index]
  js_value get(size_t index);
  bool set(size_t index, WasmFuncPack* value);
  bool grow(size_t num);
  bool is_valid_elem(js_value) const;

  bool valid() const { return table_ != nullptr; }
  IM3Table impl() const { return table_; }
  std::shared_ptr<WasmInstance>& GetInstance() { return inst_; }

 private:
  WasmRuntime* runtime_;
  IM3Table table_;
  std::shared_ptr<WasmInstance> inst_ = nullptr;
};

}  // namespace wasm
}  // namespace vmsdk
#endif  // JSB_WASM_RUNTIME_WASM3_WASM_TABLE_H_