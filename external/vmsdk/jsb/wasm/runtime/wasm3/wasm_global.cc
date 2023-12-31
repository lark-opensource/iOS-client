// Copyright 2023 The Vmsdk Authors. All rights reserved.

#include "wasm_global.h"

#include "wasm3/wasm3.h"
#include "wasm_runtime.h"

namespace vmsdk {
namespace wasm {

WasmGlobal::WasmGlobal(WasmRuntime* wasm_rt, bool mutability, double value,
                       uint8_t type)
    : wasm_rt_(wasm_rt),
      mutability_(mutability),
      global_(nullptr),
      inst_(nullptr) {
  WasmRuntime::Dup(wasm_rt);

  // Wasm3 global only support four number types.
  // The value here must be filtered and converted by `ToWebAssemblyValue()`,
  // see https://webassembly.github.io/spec/js-api/#towebassemblyvalue
  switch (type) {
    case kTypeI32:
      value_.type = c_m3Type_i32;
      value_.value.i32 = (i32)value;
      break;
    case kTypeI64:
      value_.type = c_m3Type_i64;
      value_.value.i64 = (i64)value;
      break;
    case kTypeF32:
      value_.type = c_m3Type_f32;
      value_.value.f32 = (f32)value;
      break;
    case kTypeF64:
      value_.type = c_m3Type_f64;
      value_.value.f64 = (f64)value;
      break;
    default:
      return;
  }
}

WasmGlobal::WasmGlobal(WasmRuntime* wasm_rt, IM3Global global,
                       std::shared_ptr<WasmInstance>& inst)
    : wasm_rt_(wasm_rt),
      mutability_(global->isMutable),
      global_(global),
      inst_(inst) {
  WasmRuntime::Dup(wasm_rt);
}

WasmGlobal::~WasmGlobal() {
  if (global_) {
    global_ = nullptr;
  }
  WasmRuntime::Free(wasm_rt_);
}

// The value here must be filtered and converted by `ToWebAssemblyValue()`,
int WasmGlobal::set_value(double value) {
  // There is no need to compare type here because `ToWebAssemblyValue` have
  // done this.
  M3ValueType type = global_ ? m3_GetGlobalType(global_) : value_.type;
  value_.type = type;

  switch (type) {
    case c_m3Type_i32:
      value_.value.i32 = (i32)value;
      break;
    case c_m3Type_i64:
      value_.value.i64 = (i64)value;
      break;
    case c_m3Type_f32:
      value_.value.f32 = (f32)value;
      break;
    case c_m3Type_f64:
      value_.value.f64 = (f64)value;
      break;
    default:
      return 1;
  }

  if (global_) {
    return m3_SetGlobal(global_, &value_) != m3Err_none;
  }

  return 0;
}

int WasmGlobal::get_value(js_value* out) {
  M3TaggedValue tagged;
  int result = 0;

  if (global_) {
    result = m3_GetGlobal(global_, &tagged) == m3Err_none;
  } else {
    tagged = value_;
  }

  wasm_rt_->WasmToJs(out, tagged.type, &tagged.value.i64);
  return result;
}

int WasmGlobal::SetLinkedValue(double value) {
  if (!global_) {
    return 1;
  }

  M3ValueType type = m3_GetGlobalType(global_);
  switch (type) {
    case c_m3Type_i32:
      global_->intValue = (i32)value;
      break;
    case c_m3Type_i64:
      global_->intValue = (i64)value;
      break;
    case c_m3Type_f32:
      global_->f32Value = (f32)value;
      break;
    case c_m3Type_f64:
      global_->f64Value = (f64)value;
      break;
    default:
      return 1;
  }

  return 0;
}

u8 WasmGlobal::GetType() {
  M3ValueType type = global_ ? m3_GetGlobalType(global_) : value_.type;
  switch (type) {
    case c_m3Type_i32:
      return kTypeI32;
    case c_m3Type_i64:
      return kTypeI64;
    case c_m3Type_f32:
      return kTypeF32;
    case c_m3Type_f64:
      return kTypeF64;
    default:
      return kTypeNone;
  }
}

// static
u8 WasmGlobal::StrToType(const char* type_str) {
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
