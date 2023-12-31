// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_WASM_MEMORY_
#define JSB_WASM_JSC_WASM_MEMORY_

#include <JavaScriptCore/JavaScriptCore.h>

namespace vmsdk {
namespace wasm {
class WasmMemory;
class WasmRuntime;
}  // namespace wasm
namespace jsc {
using wasm::WasmMemory;
using wasm::WasmRuntime;

class JSCWasmMemory {
 public:
  // return the WebAssembly.Memory() Constructor
  static JSObjectRef CreateConstructor(JSContextRef ctx, WasmRuntime* rt,
                                       JSValueRef* exception);

  static JSObjectRef CreateJSObject(JSContextRef ctx, JSObjectRef constructor,
                                    WasmMemory* memory, size_t pages,
                                    JSValueRef* exception);
  WasmMemory* memory() { return memory_; }

 protected:
  static void Finalize(JSObjectRef object);

  static JSObjectRef CreatePrototype(JSContextRef ctx, JSValueRef* exception);

  static JSObjectRef CallAsConstructor(JSContextRef ctx,
                                       JSObjectRef constructor,
                                       size_t argumentCount,
                                       const JSValueRef arguments[],
                                       JSValueRef* exception);

  static JSValueRef GetBufferCallback(JSContextRef ctx, JSObjectRef function,
                                      JSObjectRef thisObject,
                                      size_t argumentCount,
                                      const JSValueRef arguments[],
                                      JSValueRef* exception);

  static JSValueRef GrowCallback(JSContextRef ctx, JSObjectRef function,
                                 JSObjectRef thisObject, size_t argumentCount,
                                 const JSValueRef arguments[],
                                 JSValueRef* exception);

 private:
  static constexpr uint32_t kMaxPagesNum = 65536;
  JSCWasmMemory(WasmMemory* memory, size_t pages)
      : memory_(memory), pages_(pages), buffer_(nullptr) {}
  ~JSCWasmMemory();

  WasmMemory* memory_;
  size_t pages_;
  JSObjectRef buffer_;
};

}  // namespace jsc
}  // namespace vmsdk

#endif  // JSB_WASM_JSC_WASM_MEMORY_