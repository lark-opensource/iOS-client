// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_WASM_INSTANCE_
#define JSB_WASM_JSC_WASM_INSTANCE_

#include <JavaScriptCore/JavaScriptCore.h>

#include <memory>

namespace vmsdk {
namespace wasm {
class WasmInstance;
class WasmRuntime;
}  // namespace wasm

namespace jsc {

using wasm::WasmInstance;
using wasm::WasmRuntime;

class JSCWasmInstance {
 public:
  static JSObjectRef CreateConstructor(JSContextRef ctx, WasmRuntime* rt,
                                       JSValueRef* exception);

  static JSObjectRef CreateJSObject(JSContextRef ctx, JSObjectRef constructor,
                                    std::shared_ptr<WasmInstance>& instance,
                                    JSValueRef* exception);

 private:
  static void Finalize(JSObjectRef object);

  static JSObjectRef CreatePrototype(JSContextRef ctx, JSValueRef* exception);

  static JSObjectRef CallAsConstructor(JSContextRef ctx,
                                       JSObjectRef constructor,
                                       size_t argumentCount,
                                       const JSValueRef arguments[],
                                       JSValueRef* exception);

  JSCWasmInstance(std::shared_ptr<WasmInstance>& instance);
  ~JSCWasmInstance();
  // WasmInstance has a lot of links from/to imports&exports,
  // so that it is maintained by shared_ptr.
  std::shared_ptr<WasmInstance> instance_;
};
}  // namespace jsc
}  // namespace vmsdk
#endif  // JSB_WASM_JSC_WASM_INSTANCE_