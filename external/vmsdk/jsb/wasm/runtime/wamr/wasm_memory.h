// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM_WAMR_MEMORY_H_
#define JSB_WASM_RUNTIME_WASM_WAMR_MEMORY_H_

#include <cstdint>
#include <memory>

#include "wasm_c_api.h"

namespace vmsdk {
namespace wasm {
class WasmInstance;

class WasmMemory {
 public:
  static constexpr int kWasmPageSize = 65536;
  explicit WasmMemory(wasm_memory_t* memory);
  WasmMemory(uint32_t initial, uint32_t maximum, bool shared);
  WasmMemory(wasm_memory_t* memory, std::shared_ptr<WasmInstance>& inst);
  ~WasmMemory();

  wasm_memory_t* wamr_memory() { return memory_; }

  size_t pages();
  void* buffer();
  bool grow(uint32_t delta);

 private:
  wasm_memory_t* memory_;
  void* data_ = nullptr;
  size_t pages_;
  std::shared_ptr<WasmInstance> inst_ = nullptr;
};

}  // namespace wasm
}  // namespace vmsdk

#endif  // JSB_WASM_RUNTIME_WASM_WAMR_MEMORY_H_