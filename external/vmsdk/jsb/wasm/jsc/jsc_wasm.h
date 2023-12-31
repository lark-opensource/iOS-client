// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_WASM_EXT_H_
#define JSB_WASM_JSC_WASM_EXT_H_

#include <JavaScriptCore/JavaScriptCore.h>

#include <functional>
#include <mutex>

namespace vmsdk {
namespace wasm {
class WasmRuntime;
}  // namespace wasm

namespace jsc {

class JSCWasmExt {
 public:
  static void RegisterWebAssembly(JSContextRef ctx,
                                  std::atomic<bool>* ctx_invalid);

  static constexpr const char* kWasmName = "WebAssembly";
  static constexpr const char* kModuleName = "Module";
  static constexpr const char* kGlobalName = "Global";
  static constexpr const char* kInstanceName = "Instance";
  static constexpr const char* kMemoryName = "Memory";
  static constexpr const char* kTableName = "Table";

 protected:
  static JSObjectRef CreateWasmObject(JSContextRef ctx,
                                      wasm::WasmRuntime** rt_ptr,
                                      std::atomic<bool>* ctx_invalid);
  static void Finalize(JSObjectRef obj);
};

}  // namespace jsc
}  // namespace vmsdk
#endif  // JSB_WASM_JSC_WASM_EXT_H_
