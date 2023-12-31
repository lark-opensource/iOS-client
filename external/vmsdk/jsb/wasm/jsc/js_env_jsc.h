// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_ENV_H_
#define JSB_WASM_JSC_ENV_H_

#include <atomic>

#include "common/js_type.h"
#include "jsc/jsc_class_creator.h"

namespace vmsdk {
namespace wasm {
class WasmMemory;
class WasmGlobal;
class WasmTable;
class WasmRuntime;
}  // namespace wasm

using wasm::WasmGlobal;
using wasm::WasmMemory;
using wasm::WasmRuntime;
using wasm::WasmTable;

namespace jsc {

class JSCEnv {
 public:
  JSCEnv(JSContextRef ctx, std::atomic<bool>* ctx_invalid);
  virtual ~JSCEnv() { wasm_rt_ = nullptr; }

  bool IsJSObject(js_value val);
  bool IsJSFunction(js_value val);
  bool IsJSWasmFunction(js_value val);
  bool IsNumber(js_value val);
  bool IsUndefined(js_value val);
  bool IsNull(js_value val);

  js_value GetUndefined() { return undef_; }
  // FIXME: for JSC, JS_NULL is not equivalent to null in JavaScript.
  js_value GetNull() { return null_; }

  js_value GetProperty(js_value target, const char* name);
  bool SetProperty(js_value obj, const char* name, js_value val);
  bool SetPropertyAtIndex(js_value obj, uint32_t index, js_value val);
  js_value MakeFunction(const char* name, void* pack);
  js_value MakePlainObject();
  js_value MakeString(const char* str);
  js_value MakeNumber(double num);
  js_value MakeException(const char* msg);

  js_value MakeMemory(WasmMemory* mem, size_t pages);
  js_value MakeGlobal(WasmGlobal* gbl);
  js_value MakeTable(WasmTable* table);

  WasmGlobal* GetGlobal(js_value val);
  WasmMemory* GetMemory(js_value val);
  WasmTable* GetTable(js_value val);

  js_value ReserveObject(js_value obj);
  void ReleaseObject(js_value obj);

  double ValueToNumber(js_value val);
  js_value ValueToObject(js_value val);
  js_value ValueToFunction(js_value val);
  js_value CallAsFunction(js_value function, js_value thisObject, size_t argc,
                          js_value args[], js_value* exception);

  template <typename To, typename From>
  inline static To ToJSC(From from) {
    return reinterpret_cast<To>(from);
  }

  inline static js_value FromJSC(JSValueRef from) {
    return reinterpret_cast<js_value>(const_cast<OpaqueJSValue*>(from));
  }

  inline static js_value* FromJSC(const JSValueRef* from) {
    return reinterpret_cast<js_value*>(const_cast<OpaqueJSValue**>(from));
  }

  inline static js_context FromJSC(JSContextRef from) {
    return reinterpret_cast<js_context>(const_cast<OpaqueJSContext*>(from));
  }

  inline void SetWasmRuntime(WasmRuntime* rt) { wasm_rt_ = rt; }

  void SetMemoryContructor(JSObjectRef constructor) {
    js_memory_constructor_ = constructor;
  }

  void SetGlobalContructor(JSObjectRef constructor) {
    js_global_constructor_ = constructor;
  }

  void SetTableContructor(JSObjectRef constructor) {
    js_table_constructor_ = constructor;
    JSValueProtect(js_ctx_, js_table_constructor_);
  }

  void SetModuleConstructor(JSObjectRef constructor) {
    js_module_constructor_ = constructor;
    JSValueProtect(js_ctx_, js_module_constructor_);
  }

  inline int IsInvalid() const {
    return (ctx_invalid_ == nullptr || ctx_invalid_->load());
  }

  inline JSObjectRef js_module_constructor() const {
    return js_module_constructor_;
  }

 private:
  JSObjectRef js_module_constructor_;
  JSObjectRef js_global_constructor_;
  JSObjectRef js_table_constructor_;
  JSObjectRef js_memory_constructor_;
  JSClassRef wasm_func_class_;
  JSContextRef js_ctx_;
  std::atomic<bool>* ctx_invalid_;
  js_value undef_;
  js_value null_;

  WasmRuntime* wasm_rt_;
  // Only used to calling wasm function from js layer, assumed
  // that argument `function` has private data of WasmFuncPack type.
  static JSValueRef CallWasmFunc(JSContextRef ctx, JSObjectRef function,
                                 JSObjectRef thisObject, size_t argc,
                                 const JSValueRef arguments[],
                                 JSValueRef* exception);
  static void WasmFuncFinalizer(JSObjectRef func);
};

}  // namespace jsc
}  // namespace vmsdk
#endif  // JSB_WASM_JSC_ENV_H_