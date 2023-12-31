// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WAMR_WASM_INSTANCE_H_
#define JSB_WASM_RUNTIME_WAMR_WASM_INSTANCE_H_

#include <vector>

#include "common/js_type.h"
#include "wasm_c_api.h"

namespace vmsdk {
namespace wasm {

class WasmRuntime;

class WasmInstance {
 public:
  WasmInstance(WasmRuntime* rt);
  ~WasmInstance();

  wasm_instance_t* GetImpl() const { return instance_; }
  void SetImpl(wasm_instance_t* inst) { instance_ = inst; }

  void PushImport(js_value import);

 private:
  WasmRuntime* rt_;
  wasm_instance_t* instance_ = nullptr;
  // Keep references to those JS Values.
  std::vector<js_value> imports_;
};

}  // namespace wasm
}  // namespace vmsdk

#endif  // JSB_WASM_RUNTIME_WAMR_WASM_INSTANCE_H_