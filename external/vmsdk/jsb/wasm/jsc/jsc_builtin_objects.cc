// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "jsc_builtin_objects.h"

#include "common/wasm_log.h"

namespace vmsdk {
namespace jsc {

JSStringRef JSCBuiltinObjects::PrototypeStr() {
  static JSStringRef prototype_ref =
      JSStringRetain(JSStringCreateWithUTF8CString("prototype"));
  return prototype_ref;
}

JSObjectRef JSCBuiltinObjects::GetFnDefineProperty(JSContextRef ctx,
                                                   JSValueRef* exception) {
  JSObjectRef global = JSContextGetGlobalObject(ctx);
  JSValueRef js_object_val = JSObjectGetProperty(
      ctx, global, JSStringCreateWithUTF8CString("Object"), exception);
  if (!js_object_val) return nullptr;
  JSObjectRef js_object = JSValueToObject(ctx, js_object_val, exception);
  if (js_object) {
    JSValueRef fn_value = JSObjectGetProperty(
        ctx, js_object, JSStringCreateWithUTF8CString("defineProperty"),
        nullptr);
    if (fn_value) {
      return JSValueToObject(ctx, fn_value, exception);
    }
  }
  return nullptr;
}

JSObjectRef JSCBuiltinObjects::GetJSFunction(JSContextRef ctx,
                                             JSValueRef* exception) {
  static JSStringRef fun_name =
      JSStringRetain(JSStringCreateWithUTF8CString("Function"));

  JSObjectRef global = JSContextGetGlobalObject(ctx);
  JSValueRef functor = JSObjectGetProperty(ctx, global, fun_name, exception);
  if (functor) {
    return JSValueToObject(ctx, functor, exception);
  }
  return nullptr;
}

}  // namespace jsc
}  // namespace vmsdk