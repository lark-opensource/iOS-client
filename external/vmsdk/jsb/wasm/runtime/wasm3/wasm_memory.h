// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM3_WASM_MEMORY_H_
#define JSB_WASM_RUNTIME_WASM3_WASM_MEMORY_H_

#include <memory>

#include "wasm3/m3_env.h"

namespace vmsdk {
namespace wasm {
class WasmInstance;

class WasmMemory {
 public:
  static constexpr int kWasmPageSize = 65536;

  WasmMemory(IM3Runtime rt, uint32_t initial, uint32_t maximum,
             bool shared = false);
  WasmMemory(IM3Memory mem, IM3Runtime rt, std::shared_ptr<WasmInstance>& inst);
  ~WasmMemory();

  bool valid() const;
  size_t pages();
  void* buffer();
  IM3Memory impl();

  bool grow(uint32_t delta);

 private:
  IM3Memory mem_;
  IM3Runtime rt_;
  std::shared_ptr<WasmInstance> inst_;
};

}  // namespace wasm
}  // namespace vmsdk
#endif  // JSB_WASM_RUNTIME_WASM3_WASM_MEMORY_H_