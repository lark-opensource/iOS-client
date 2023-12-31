// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_RUNTIME_WASM_WAMR_RUNTIME_H_
#define JSB_WASM_RUNTIME_WASM_WAMR_RUNTIME_H_

#include <memory>

#include "common/js_env.h"
#include "wasm_c_api.h"
#include "wasm_global.h"
#include "wasm_instance.h"
#include "wasm_memory.h"
#include "wasm_module.h"
#include "wasm_table.h"

namespace vmsdk {
namespace wasm {

class WasmModule;
class WasmInstance;
class WasmFuncPack;
enum class TableElementType;

// abstract class for wasm-rutime which represents
// the underline engines which maybe the "wamr",
// "wasmtime", ... etc.
// FIXME(): we only focus on "wamr" and ignore the
// subclassing that we will implement later.
class WasmRuntime {
 public:
  WasmRuntime(JS_ENV* env);
  ~WasmRuntime();

  wasm_store_t* GetStore() { return wasm_store_; }

  WasmModule* CreateWasmModule(void* data, size_t len);
  // TODO(wasm): handle imports.
  std::shared_ptr<WasmInstance> CreateWasmInstance(WasmModule* mod,
                                                   js_value imports_obj);
  // table
  WasmTable* CreateWasmTable(uint32_t initial, uint32_t maximum,
                             TableElementType);

  // memory
  WasmMemory* CreateWasmMemory(uint32_t initial, uint32_t maximum,
                               bool shared = false);

  // global
  WasmGlobal* CreateWasmGlobal(uint8_t type, bool mutability, double number);

  JS_ENV* GetJSEnv() const { return js_env_; }

  int FillExportsObject(js_value obj, WasmModule* mod,
                        std::shared_ptr<WasmInstance>& inst);

  static void WasmFuncPackFinalizer(void* env);

  void WasmToJs(js_value* val, wasm_val_t* w_val);
  int JsToWasm(const js_value val, wasm_val_t* w_val);
  int NumberToWasm(double dvalue, wasm_val_t* w_val);

  wasm_valkind_t WasmType(uint8_t type);

  static void Free(WasmRuntime* runtime);
  static void Dup(WasmRuntime* runtime);

 protected:
  int BindImports(const js_value import_val, wasm_importtype_vec_t* iv,
                  wasm_extern_t** imports, WasmInstance* inst);
  js_value LookupImport(const js_value import_obj, wasm_importtype_t* ity);

 private:
  int InitRuntime();

  // If another js engine is wanted, just modify this js_env_.
  JS_ENV* js_env_;
  wasm_engine_t* wasm_engine_;
  wasm_store_t* wasm_store_;
  int ref_count_;
};

}  // namespace wasm
}  // namespace vmsdk
#endif  // JSB_WASM_RUNTIME_WASM_WAMR_RUNTIME_H_
