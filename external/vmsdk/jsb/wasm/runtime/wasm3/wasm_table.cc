// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_table.h"

#include <string>

#include "common/wasm_log.h"
#include "wasm3/m3_env.h"
#include "wasm_func_pack.h"
#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {

WasmTable::WasmTable(WasmRuntime* runtime, uint32_t initial, uint32_t maximum,
                     TableElementType type)
    : runtime_(runtime), table_(nullptr), inst_(nullptr) {
  // FIXME: support extern reference type.
  DCHECK(type == TableElementType::FuncRef);
  m3_NewTable(&table_, kFuncRef, initial, maximum);
  WasmRuntime::Dup(runtime_);
}

WasmTable::WasmTable(WasmRuntime* runtime, IM3Table table,
                     std::shared_ptr<WasmInstance>& inst)
    : runtime_(runtime), table_(table), inst_(inst) {
  WasmRuntime::Dup(runtime_);
}

WasmTable::~WasmTable() {
  if (table_) {
    m3_FreeTable(table_);
  }
  WasmRuntime::Free(runtime_);
}

size_t WasmTable::size() { return table_->info.curSize; }

// return the function ref at tbl[index]
js_value WasmTable::get(size_t index) {
  // NOTE: valid index is ensured by caller.
  WLOGD("get(%zu) from table[%zu]!\n", index, size());
  elem_ref target = table_->funcs[index];
  if (target) {
    WasmFuncPack* func_data = new WasmFuncPack(target, runtime_, inst_);
    return runtime_->GetJSEnv()->MakeFunction(nullptr, func_data);
  } else {
    return runtime_->GetJSEnv()->GetNull();
  }
}

bool WasmTable::set(size_t index, WasmFuncPack* func_data) {
  // NOTE: valid index is ensured by caller.
  WLOGD("set table[%zu] = %p!\n", index, func_data);
  table_->funcs[index] = func_data ? func_data->GetWasmFunc() : NULL;
  return true;
}

bool WasmTable::grow(size_t num) {
  WLOGD("grow table from [%zu] to [%zu]!\n", size(), size() + num);
  return m3Err_none == m3_GrowTable(table_, num);
}

bool WasmTable::is_valid_elem(js_value target) const {
  // check the value is compatible for this table, 'funcref' or 'anyref'.
  // Only 'funcref' is allowed yet.
  return runtime_->GetJSEnv()->IsJSWasmFunction(target);
}

}  // namespace wasm
}  // namespace vmsdk