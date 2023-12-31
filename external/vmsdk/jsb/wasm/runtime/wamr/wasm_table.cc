// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_table.h"

#include <string>

#include "common/wasm_log.h"
#include "wasm_c_api.h"
#include "wasm_func_pack.h"
#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {
class WasmInstance;

WasmTable::WasmTable(WasmRuntime* runtime, wasm_table_t* table)
    : runtime_(runtime), table_(table) {
  WasmRuntime::Dup(runtime_);
}

WasmTable::WasmTable(WasmRuntime* runtime, wasm_table_t* table,
                     std::shared_ptr<WasmInstance>& inst)
    : runtime_(runtime), table_(table), inst_(inst) {
  WasmRuntime::Dup(runtime_);
}

WasmTable::~WasmTable() {
  if (table_) {
    wasm_table_delete(table_);
  };
  WasmRuntime::Free(runtime_);
}

size_t WasmTable::size() {
  if (table_) {
    return wasm_table_size(table_);
  }
  return 0;
}

js_value WasmTable::get(size_t index) {
  WLOGD("get table[%zu]\n", index);
  auto elem = wasm_table_get(table_, index);
  if (!elem) {
    WLOGI("table[%zu] does not exit yet!\n", index);
    return JS_NULL;
  }
  wasm_func_t* func = wasm_ref_as_func(elem);
  if (!func) {
    WLOGI("WebAssembly Table only support func element now!\n");
    return JS_NULL;
  }
  WasmFuncPack* func_data = new WasmFuncPack(func, runtime_, inst_);
  // create anonymous js wasm function
  return runtime_->GetJSEnv()->MakeFunction(NULL, func_data);
}

bool WasmTable::set(size_t index, WasmFuncPack* value) {
  if (!value) {
    WLOGI("SetTableIndex with invalid WasmFuncPack!\n");
    return false;
  }

  wasm_func_t* func = value->GetWasmFunc();
  WasmTable::elem_ref* func_ref = wasm_func_as_ref(func);

  return table_ && wasm_table_set(table_, index, (wasm_ref_t*)func_ref);
}

bool WasmTable::grow(size_t num) {
  if (table_ && wasm_table_grow(table_, num, NULL)) {
    return true;
  }
  WLOGI("grow table from [%zu] to [%zu] failed!\n", size(), size() + num);
  return false;
}

bool WasmTable::is_valid_elem(js_value target) const {
  // check the value is compatible for this table, 'funcref' or 'anyref'.
  // Only 'funcref' is allowed yet.
  return runtime_->GetJSEnv()->IsJSWasmFunction(target);
}

}  // namespace wasm
}  // namespace vmsdk