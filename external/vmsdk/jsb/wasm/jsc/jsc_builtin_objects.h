// Copyright 2022 The Vmsdk Authors. All rights reserved.

#ifndef JSB_WASM_JSC_BUILTIN_OBJECT_H_
#define JSB_WASM_JSC_BUILTIN_OBJECT_H_

#include <JavaScriptCore/JavaScriptCore.h>

namespace vmsdk {
namespace jsc {

class JSCBuiltinObjects {
 public:
  static JSObjectRef GetJSFunction(JSContextRef ctx,
                                   JSValueRef* exception = NULL);
  static JSObjectRef GetFnDefineProperty(JSContextRef ctx,
                                         JSValueRef* exception);

  static JSStringRef PrototypeStr();
};

}  // namespace jsc
}  // namespace vmsdk
#endif  // JSB_WASM_JSC_BUILTIN_OBJECT_H_
