// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_memory.h"

#include <stdlib.h>

#include <memory>

#include "common/wasm_log.h"
#include "common/wasm_utils.h"
#include "wasm_c_api.h"

namespace vmsdk {
namespace wasm {
class WasmInstance;

WasmMemory::WasmMemory(uint32_t initial, uint32_t maximum, bool shared)
    : memory_(nullptr), data_(nullptr), pages_(initial) {}

WasmMemory::WasmMemory(wasm_memory_t* memory)
    : memory_(memory), data_(nullptr) {}

WasmMemory::WasmMemory(wasm_memory_t* memory,
                       std::shared_ptr<WasmInstance>& inst)
    : memory_(memory), inst_(inst) {}

WasmMemory::~WasmMemory() {
  if (data_) {
    assert(!memory_ && "export memory is excluded with new memory!");
    free(data_);
    data_ = nullptr;
  }
}

void* WasmMemory::buffer() {
  // memory by exports
  if (wasm_likely(memory_)) {
    return wasm_memory_data(memory_);
  }
  // memory created by new
  if (!data_) {
    data_ = static_cast<uint8_t*>(
        calloc(pages() * WasmMemory::kWasmPageSize, sizeof(uint8_t)));
  }
  return data_;
}

size_t WasmMemory::pages() {
  // create by exports
  if (wasm_likely(memory_)) {
    return wasm_memory_data_size(memory_) / WasmMemory::kWasmPageSize;
  }
  // memory created by new
  return pages_;
}

bool WasmMemory::grow(uint32_t delta) {
  // TODO(zode): Grow memory from [size] to [sz].
  WLOGI("TODO(): WasmMemory::grow has not implemented yet!");
  return false;
}
}  // namespace wasm
}  // namespace vmsdk