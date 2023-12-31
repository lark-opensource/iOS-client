// Copyright 2022 The Vmsdk Authors. All rights reserved.

#include "jsc_wasm_global.h"

#include "common/messages.h"
#include "common/wasm_log.h"
#include "common/wasm_utils.h"
#include "jsc_builtin_objects.h"
#include "jsc_class_creator.h"
#include "jsc_ext_api.h"
#include "runtime/wasm_global.h"
#include "runtime/wasm_runtime.h"

namespace vmsdk {
using vmsdk::ExceptionMessages;
namespace jsc {

JSCWasmGlobal::~JSCWasmGlobal() { delete global_; }

// static
void JSCWasmGlobal::Finalize(JSObjectRef object) {
  JSCWasmGlobal* global =
      static_cast<JSCWasmGlobal*>(JSObjectGetPrivate(object));
  if (global) {
    delete global;
  }
}

// static
JSObjectRef JSCWasmGlobal::CreateJSObject(JSContextRef ctx,
                                          JSObjectRef constructor,
                                          WasmGlobal* global,
                                          JSValueRef* exception) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition("Global", Finalize);
  JSClassRef obj_jsclass = JSClassCreate(&def);
  JSCWasmGlobal* global_data = new JSCWasmGlobal(global);
  JSObjectRef obj = JSObjectMake(ctx, obj_jsclass, global_data);

  JSValueRef maybe_prototype = JSObjectGetProperty(
      ctx, constructor, JSCBuiltinObjects::PrototypeStr(), exception);
  JSObjectRef prototype = JSValueToObject(ctx, maybe_prototype, exception);

  JSObjectSetPrototype(ctx, obj, prototype);
  return obj;
}

// static
JSObjectRef JSCWasmGlobal::CallAsConstructor(JSContextRef ctx,
                                             JSObjectRef constructor,
                                             size_t argumentCount,
                                             const JSValueRef arguments[],
                                             JSValueRef* exception) {
  WLOGI("JSCWasmGlobal::CallAsConstructor @ %s\n", __func__);

  if (argumentCount == 0 || !JSValueIsObject(ctx, arguments[0])) {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kDescriptorNeeded);
    return nullptr;
  }

  JSObjectRef globalDescriptor = JSValueToObject(ctx, arguments[0], exception);

  bool mutability;
  {
    JSValueRef mutableValue = JSObjectGetProperty(
        ctx, globalDescriptor, JSStringCreateWithUTF8CString("mutable"),
        exception);
    mutability = JSValueToBoolean(ctx, mutableValue);
  }

  JSValueRef value = JSObjectGetProperty(
      ctx, globalDescriptor, JSStringCreateWithUTF8CString("value"), exception);
  JSStringRef value_string = JSValueToStringCopy(ctx, value, exception);

  size_t type_name_length = JSStringGetMaximumUTF8CStringSize(value_string);
  char type_name[type_name_length];

  type_name_length =
      JSStringGetUTF8CString(value_string, type_name, type_name_length);

  JSValueRef argument =
      argumentCount == 2 ? arguments[1] : JSValueMakeUndefined(ctx);

  double number = JSValueToNumber(ctx, argument, exception);
  uint8_t type = WasmGlobal::StrToType(type_name);
  WasmRuntime* wasm_rt =
      reinterpret_cast<WasmRuntime*>(JSObjectGetPrivate(constructor));
  WasmGlobal* global = wasm_rt->CreateWasmGlobal(type, mutability, number);
  if (global) {
    return CreateJSObject(ctx, constructor, global, exception);
  }
  if (exception) {
    *exception =
        JSCExtAPI::CreateException(ctx, ExceptionMessages::kInternalError);
  }
  return nullptr;
}

// static
JSObjectRef JSCWasmGlobal::CreatePrototype(JSContextRef ctx,
                                           JSValueRef* exception) {
  JSClassDefinition def =
      JSClassCreator::GetClassDefinition("Global.Prototype", NULL);

  JSPropertyAttributes default_attr = JSClassCreator::DefaultAttr();

  JSStaticFunction static_funcs[] = {{"valueOf", ValueOfCallback, default_attr},
                                     {0, 0, 0}};
  def.staticFunctions = static_funcs;
  JSClassRef prototype_jsclass = JSClassCreate(&def);

  JSObjectRef prototype = JSObjectMake(ctx, prototype_jsclass, NULL);

  property_descriptor instance_values[] = {
      {"value", GetValueCallback, SetValueCallback, prop_none},
      {0, 0, 0, prop_none}};
  JSCExtAPI::DefineProperties(ctx, prototype, instance_values, exception);

  return prototype;
}

// static
JSObjectRef JSCWasmGlobal::CreateConstructor(JSContextRef ctx, WasmRuntime* rt,
                                             JSValueRef* exception) {
  JSClassDefinition def = JSClassCreator::GetClassDefinition(
      "WebAssembly.Global", NULL, CallAsConstructor);
  JSClassRef ctor_jsclass = JSClassCreate(&def);

  JSObjectRef ctor = JSObjectMake(ctx, ctor_jsclass, rt);

  JSObjectRef prototype = CreatePrototype(ctx, exception);
  JSCExtAPI::InitConstructor(ctx, ctor, "Global", prototype, exception);

  JS_ENV* env = rt->GetJSEnv();
  if (wasm_likely(env)) {
    env->SetGlobalContructor(ctor);
  }
  return ctor;
}

// static
JSValueRef JSCWasmGlobal::GetValueCallback(
    JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
    size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
  JSCWasmGlobal* global =
      static_cast<JSCWasmGlobal*>(JSObjectGetPrivate(thisObject));
  if (!global) return JSValueMakeUndefined(ctx);

  WasmGlobal* gbl = global->global_;
  js_value value;
  if (gbl) {
    gbl->get_value(&value);
    return JSCEnv::ToJSC<JSValueRef>(value);
  } else {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kInternalError);
    return JSValueMakeUndefined(ctx);
  }
}

// static
JSValueRef JSCWasmGlobal::SetValueCallback(
    JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
    size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
  JSCWasmGlobal* global =
      static_cast<JSCWasmGlobal*>(JSObjectGetPrivate(thisObject));
  if (!global) return JSValueMakeUndefined(ctx);

  if (argumentCount == 0) {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidArgs);
    return nullptr;
  }
  if (JSValueIsNull(ctx, arguments[0]) ||
      JSValueIsUndefined(ctx, arguments[0])) {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kInvalidArgs);
    return nullptr;
  }

  JSValueRef value = arguments[0];
  WasmGlobal* gbl = global->global_;
  if (!gbl->mutability()) {
    if (exception)
      *exception =
          JSCExtAPI::CreateException(ctx, ExceptionMessages::kModifyImmutable);
    return nullptr;
  }

  double number = JSValueToNumber(ctx, value, exception);
  gbl->set_value(number);

  return value;
}

// static
JSValueRef JSCWasmGlobal::ValueOfCallback(
    JSContextRef ctx, JSObjectRef function, JSObjectRef thisObject,
    size_t argumentCount, const JSValueRef arguments[], JSValueRef* exception) {
  return GetValueCallback(ctx, function, thisObject, argumentCount, arguments,
                          exception);
}

}  // namespace jsc
}  // namespace vmsdk