// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM3_WASM_RUNTIME_H_
#define JSB_WASM_RUNTIME_WASM3_WASM_RUNTIME_H_
#include <memory>
#include <string>

#include "common/js_env.h"
#include "common/wasm_log.h"
#include "wasm3/m3_env.h"
#include "wasm3/wasm3.h"

namespace vmsdk {
namespace wasm {

class WasmRuntime;
class WasmFuncPack;
class WasmModule;
class WasmInstance;
class WasmMemory;
enum class TableElementType;

class WasmRuntime {
 public:
  WasmRuntime(JS_ENV* env);
  ~WasmRuntime();

  WasmModule* CreateWasmModule(void* data, size_t len);
  // TODO(wasm): handle imports.
  std::shared_ptr<WasmInstance> CreateWasmInstance(WasmModule* mod,
                                                   js_value imports_obj);

  WasmMemory* CreateWasmMemory(uint32_t initial, uint32_t maximum,
                               bool shared = false);

  WasmGlobal* CreateWasmGlobal(uint8_t type, bool mutability, double value);
  WasmTable* CreateWasmTable(uint32_t initial, uint32_t maximum,
                             TableElementType type);

  JS_ENV* GetJSEnv() const { return js_env_; }

  int FillExportsObject(js_value obj, WasmModule* mod,
                        std::shared_ptr<WasmInstance>& inst);

  static void WasmFuncPackFinalizer(void* env);

  int WasmToJs(js_value* val, M3ValueType m3_type, u64* w_val);
  int JsToWasm(const js_value val, M3ValueType m3_type, u64* w_val);

  static void Free(WasmRuntime* runtime);
  static void Dup(WasmRuntime* runtime);

 protected:
  int BindImports(const js_value import_val, IM3Module w3_mod,
                  WasmInstance* inst);

  js_value LookupImport(const js_value import_obj, const char* module_name,
                        const char* field_name);

  static std::string CreateSignature(IM3Function target);
  static char ConvertTypeIdToTypeChar(M3ValueType ty);

  int LinkTable(IM3Module mod, js_value imports_obj, WasmInstance* inst);
  int LinkMemory(IM3Module mod, js_value imports_obj, WasmInstance* inst);
  int LinkGlobal(IM3Module mod, js_value imports_obj,
                 std::shared_ptr<WasmInstance>& inst, int idx);

 private:
  int InitRuntime();

  JS_ENV* js_env_;

  IM3Environment w3_env_;

  IM3Runtime w3_rt_;

  int ref_count_;
};

}  // namespace wasm
}  // namespace vmsdk
#endif  // JSB_WASM_RUNTIME_WASM3_WASM_RUNTIME_H_
