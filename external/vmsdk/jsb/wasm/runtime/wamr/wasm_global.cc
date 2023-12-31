// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_global.h"

#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {

WasmGlobal::WasmGlobal(wasm_global_t* global, bool mutability,
                       wasm_val_t* value, WasmRuntime* runtime)
    : mutability_(mutability), runtime_(runtime), global_(global) {
  wasm_val_copy(&value_, value);
  if (global_) {
    wasm_global_set(global_, &value_);
  }
  WasmRuntime::Dup(runtime_);
}

WasmGlobal::WasmGlobal(wasm_global_t* global, bool mutability,
                       wasm_val_t* value, WasmRuntime* runtime,
                       std::shared_ptr<WasmInstance>& inst)
    : WasmGlobal(global, mutability, value, runtime) {
  inst_ = inst;
  WasmRuntime::Dup(runtime_);
}

WasmGlobal::~WasmGlobal() {
  if (global_) {
    wasm_global_delete(global_);
  }
  WasmRuntime::Free(runtime_);
}

void WasmGlobal::set_global(wasm_global_t* global) {
  global_ = global;
  wasm_global_get(global_, &value_);
}

int WasmGlobal::set_value(double value) {
  if (runtime_->NumberToWasm(value, &value_)) {
    return 1;
  }
  if (global_) {
    wasm_global_set(global_, &value_);
  }
  return 0;
}

int WasmGlobal::get_value(js_value* out) {
  if (global_) {
    wasm_global_get(global_, &value_);
  }
  runtime_->WasmToJs(out, &value_);
  return 0;
}

// static
bool WasmGlobal::mutability(wasm_global_t* global) {
  wasm_globaltype_t* val_type = wasm_global_type(global);
  wasm_mutability_t mutability = wasm_globaltype_mutability(val_type);
  return mutability == WASM_VAR;
}

uint8_t WasmGlobal::GetType() {
  wasm_globaltype_t* gbl_type = wasm_global_type(global_);
  const wasm_valtype_t* type = wasm_globaltype_content(gbl_type);
  switch (wasm_valtype_kind(type)) {
    case WASM_I32:
      return kTypeI32;
    case WASM_I64:
      return kTypeI64;
    case WASM_F32:
      return kTypeF32;
    case WASM_F64:
      return kTypeF64;
    case WASM_FUNCREF:
    case WASM_ANYREF:
    default:
      return kTypeNone;
  }
}

// static
uint8_t WasmGlobal::StrToType(const char* type_str) {
  if (!strcmp(type_str, "i32")) {
    return kTypeI32;
  } else if (!strcmp(type_str, "i64")) {
    return kTypeI64;
  } else if (!strcmp(type_str, "f32")) {
    return kTypeF32;
  } else if (!strcmp(type_str, "f64")) {
    return kTypeF64;
  } else if (!strcmp(type_str, "externref")) {
    return kTypeExternref;
  } else if (!strcmp(type_str, "anyfunc")) {
    return kTypeAnyfunc;
  } else {
    return kTypeNone;
  }
}

}  // namespace wasm
}  // namespace vmsdk