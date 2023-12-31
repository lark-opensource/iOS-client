// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "wasm_memory.h"

#include "common/wasm_log.h"
#include "common/wasm_utils.h"

namespace vmsdk {
namespace wasm {

WasmMemory::WasmMemory(IM3Runtime rt, uint32_t initial, uint32_t maximum,
                       bool shared)
    : mem_(nullptr), rt_(rt), inst_(nullptr) {
  m3_NewMemory(&mem_, rt, initial, maximum);
}

WasmMemory::WasmMemory(IM3Memory p_mem, IM3Runtime rt,
                       std::shared_ptr<WasmInstance>& inst)
    : mem_(p_mem), rt_(rt), inst_(inst) {}

WasmMemory::~WasmMemory() {
  // The following instruction is trivial if this memory is linked against one
  // instance which is responsible for releasing the actual memory.
  if (valid()) {
    m3_FreeMemory(mem_);
  }
}

bool WasmMemory::grow(uint32_t delta) {
  WLOGD("memory.grow from %u(+%u) -> %u", mem_->numPages, delta,
        mem_->numPages + delta);
  return m3Err_none == m3_GrowMemory(mem_, rt_, delta);
}

bool WasmMemory::valid() const { return mem_ != nullptr; }
size_t WasmMemory::pages() { return mem_->numPages; }
void* WasmMemory::buffer() { return m3_GetMemory(mem_, nullptr, 0); }
IM3Memory WasmMemory::impl() { return mem_; }

}  // namespace wasm
}  // namespace vmsdk
