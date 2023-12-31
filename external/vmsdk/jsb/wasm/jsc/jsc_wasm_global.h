// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_WASM_GLOBAL_H_
#define JSB_WASM_JSC_WASM_GLOBAL_H_

#include <JavaScriptCore/JavaScriptCore.h>

namespace vmsdk {
namespace wasm {
class WasmGlobal;
class WasmRuntime;
}  // namespace wasm
namespace jsc {
using wasm::WasmGlobal;
using wasm::WasmRuntime;

class JSCWasmGlobal {
 public:
  static JSObjectRef CreateConstructor(JSContextRef ctx, WasmRuntime* rt,
                                       JSValueRef* exception);

  static JSObjectRef CreateJSObject(JSContextRef ctx, JSObjectRef constructor,
                                    WasmGlobal* global, JSValueRef* exception);

  WasmGlobal* global() { return global_; }

 protected:
  static void Finalize(JSObjectRef object);

  static JSObjectRef CreatePrototype(JSContextRef ctx, JSValueRef* exception);

  static JSObjectRef CallAsConstructor(JSContextRef ctx,
                                       JSObjectRef constructor,
                                       size_t argumentCount,
                                       const JSValueRef arguments[],
                                       JSValueRef* exception);

  static JSValueRef GetValueCallback(JSContextRef ctx, JSObjectRef function,
                                     JSObjectRef thisObject,
                                     size_t argumentCount,
                                     const JSValueRef arguments[],
                                     JSValueRef* exception);

  static JSValueRef SetValueCallback(JSContextRef ctx, JSObjectRef function,
                                     JSObjectRef thisObject,
                                     size_t argumentCount,
                                     const JSValueRef arguments[],
                                     JSValueRef* exception);

  static JSValueRef ValueOfCallback(JSContextRef ctx, JSObjectRef function,
                                    JSObjectRef thisObject,
                                    size_t argumentCount,
                                    const JSValueRef arguments[],
                                    JSValueRef* exception);

 private:
  JSCWasmGlobal(WasmGlobal* global) : global_(global) {}
  // TODO(yangwenming): check re-export cases.
  ~JSCWasmGlobal();

  WasmGlobal* global_;
};
}  // namespace jsc
}  // namespace vmsdk

#endif  // JSB_WASM_JSC_WASM_GLOBAL_H_