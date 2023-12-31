// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_WASM_TABLE_
#define JSB_WASM_JSC_WASM_TABLE_

#include <JavaScriptCore/JavaScriptCore.h>

namespace vmsdk {
namespace wasm {
class WasmTable;
class WasmRuntime;
}  // namespace wasm
namespace jsc {
using wasm::WasmRuntime;
using wasm::WasmTable;

class JSCWasmTable {
 public:
  // return the WebAssembly.Table() Constructor
  // ctx : A JavaScript execution context
  // wctx: WebAssemlby execution context representing the "WebAssembly"
  // namespace
  static JSObjectRef CreateConstructor(JSContextRef ctx, WasmRuntime* rt,
                                       JSValueRef* exception);

  // create JSObject with self Constructor
  static JSObjectRef CreateJSObject(JSContextRef ctx, JSObjectRef constructor,
                                    WasmTable* table, JSValueRef* exception);

  static bool IsJSCWasmTable(JSContextRef ctx, JSValueRef target);

  WasmTable* table() { return table_; }

 protected:
  static void Finalize(JSObjectRef object);

  static JSObjectRef CreatePrototype(JSContextRef ctx, JSValueRef* exception);

  static JSObjectRef CallAsConstructor(JSContextRef ctx,
                                       JSObjectRef constructor,
                                       size_t argumentCount,
                                       const JSValueRef arguments[],
                                       JSValueRef* exception);

  static JSValueRef GetLengthCallback(JSContextRef ctx, JSObjectRef function,
                                      JSObjectRef thisObject,
                                      size_t argumentCount,
                                      const JSValueRef arguments[],
                                      JSValueRef* exception);
  static JSValueRef GetIndexCallback(JSContextRef ctx, JSObjectRef function,
                                     JSObjectRef thisObject,
                                     size_t argumentCount,
                                     const JSValueRef arguments[],
                                     JSValueRef* exception);
  static JSValueRef SetIndexCallback(JSContextRef ctx, JSObjectRef function,
                                     JSObjectRef thisObject,
                                     size_t argumentCount,
                                     const JSValueRef arguments[],
                                     JSValueRef* exception);
  static JSValueRef GrowCallback(JSContextRef ctx, JSObjectRef function,
                                 JSObjectRef thisObject, size_t argumentCount,
                                 const JSValueRef arguments[],
                                 JSValueRef* exception);

 private:
  //  Default max table size of wasm3 we used is 100000. Table imported from JS
  //  will be compared with wasm3 table declaration. If the table size in JS is
  //  not specified, max size in JS and wasm3 will be different. This will cause
  //  import failure.
  enum { MaxSaneTableSize = 100000 };
  JSCWasmTable(WasmTable* table) : table_(table){};
  ~JSCWasmTable();

  static JSClassDefinition class_def_;
  static JSClassRef class_ref_;

  WasmTable* table_;
};
}  // namespace jsc
}  // namespace vmsdk
#endif  // JSB_WASM_JSC_WASM_TABLE_