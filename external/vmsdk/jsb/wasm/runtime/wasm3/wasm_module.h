// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "common/js_env.h"
#include "wasm3/m3_env.h"

namespace vmsdk {
namespace wasm {

class WasmModule {
 public:
  WasmModule(IM3Module module);
  ~WasmModule();

  void exports(js_context ctx, js_value array, js_value* exception);
  void imports(js_context ctx, js_value array, js_value* exception);
  // Temporary approach.
  IM3Module impl() const { return module_; }
  void expire() { module_ = nullptr; }
  void invalidate();

 private:
  IM3Module module_;
};

}  // namespace wasm
}  // namespace vmsdk
