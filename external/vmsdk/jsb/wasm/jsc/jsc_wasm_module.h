// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_WASM_MODULE_
#define JSB_WASM_JSC_WASM_MODULE_

#include <JavaScriptCore/JavaScriptCore.h>

namespace vmsdk {
namespace wasm {
class WasmModule;
class WasmRuntime;
}  // namespace wasm
using wasm::WasmModule;
using wasm::WasmRuntime;
namespace jsc {

class JSCWasmModule {
 public:
  static JSObjectRef CreateConstructor(JSContextRef ctx, WasmRuntime* rt,
                                       JSValueRef* exception);

  static JSObjectRef CreateJSObject(JSContextRef ctx, JSObjectRef constructor,
                                    WasmModule* module, JSValueRef* exception);

  static bool IsWasmModuleObject(JSContextRef ctx, JSObjectRef constructor,
                                 JSObjectRef target, JSValueRef* exception);

  WasmModule* GetModulePtr() const { return module_; }

 private:
  static void Finalize(JSObjectRef object);

  static JSObjectRef CreatePrototype(JSContextRef ctx, JSValueRef* exception);

  static JSObjectRef CallAsConstructor(JSContextRef ctx,
                                       JSObjectRef constructor,
                                       size_t argumentCount,
                                       const JSValueRef arguments[],
                                       JSValueRef* exception);

  static uint8_t* GetWireBytes(JSContextRef ctx, JSValueRef val,
                               size_t* byteLength, JSValueRef* exception);

  static JSValueRef ExportsCallback(JSContextRef ctx, JSObjectRef function,
                                    JSObjectRef thisObject,
                                    size_t argumentCount,
                                    const JSValueRef arguments[],
                                    JSValueRef* exception);
  static JSValueRef ImportsCallback(JSContextRef ctx, JSObjectRef function,
                                    JSObjectRef thisObject,
                                    size_t argumentCount,
                                    const JSValueRef arguments[],
                                    JSValueRef* exception);

  JSCWasmModule(WasmModule* mod) : module_(mod) {}
  ~JSCWasmModule();

  WasmModule* module_;
};

}  // namespace jsc
}  // namespace vmsdk
#endif  // JSB_WASM_JSC_WASM_MODULE_
